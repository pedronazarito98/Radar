import Darwin
import Foundation

/// State is confined to one private serial queue. Both pipes are drained concurrently;
/// stderr contributes to the cap but its contents are never retained or exposed.
final class BoundedGitHubProcess: @unchecked Sendable {
    private let queue = DispatchQueue(label: "dev.pedronazarito.Radar.gh-process")
    private let process = Process()
    private let stdout = Pipe()
    private let stderr = Pipe()
    private let limit: Int
    private var stdoutSource: DispatchSourceRead?
    private var stderrSource: DispatchSourceRead?
    private var continuation: CheckedContinuation<GitHubProcessResult, Error>?
    private var timeout: DispatchWorkItem?
    private var output = Data()
    private var byteCount = 0
    private var stdoutEnded = false
    private var stderrEnded = false
    private var exited = false
    private var started = false
    private var finished = false
    private var stopping = false
    private var failure: SourceProblem?

    init(limit: Int = 5 * 1_024 * 1_024) { self.limit = limit }

    func run(executable: URL, arguments: [String]) async throws -> GitHubProcessResult {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                queue.async { self.start(executable: executable, arguments: arguments, continuation: continuation) }
            }
        } onCancel: { self.queue.async { self.stop(with: .cancelled) } }
    }

    private func start(executable: URL, arguments: [String], continuation: CheckedContinuation<GitHubProcessResult, Error>) {
        self.continuation = continuation
        guard failure == nil else {
            exited = true; stdoutEnded = true; stderrEnded = true
            completeIfReady()
            return
        }
        process.executableURL = executable
        process.arguments = arguments
        process.environment = GitHubCLIEnvironment.values
        process.currentDirectoryURL = URL(fileURLWithPath: "/", isDirectory: true)
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = stdout
        process.standardError = stderr
        process.terminationHandler = { [weak self] _ in
            self?.queue.async { [weak self] in
                guard let self else { return }
                self.exited = true
                self.completeIfReady()
            }
        }
        do {
            stdoutSource = try makeReadSource(stdout.fileHandleForReading, isOutput: true)
            stderrSource = try makeReadSource(stderr.fileHandleForReading, isOutput: false)
            try process.run()
            started = true
            try? stdout.fileHandleForWriting.close()
            try? stderr.fileHandleForWriting.close()
            let work = DispatchWorkItem { [weak self] in self?.stop(with: .timeout) }
            timeout = work
            queue.asyncAfter(deadline: .now() + 15, execute: work)
        } catch {
            failure = .transportUnavailable
            exited = true; stdoutEnded = true; stderrEnded = true
            completeIfReady()
        }
    }

    private func makeReadSource(_ handle: FileHandle, isOutput: Bool) throws -> DispatchSourceRead {
        let descriptor = handle.fileDescriptor
        let flags = fcntl(descriptor, F_GETFL)
        guard flags != -1, fcntl(descriptor, F_SETFL, flags | O_NONBLOCK) != -1 else {
            throw GitHubCLIError.source(.transportUnavailable)
        }
        let confirmedFlags = fcntl(descriptor, F_GETFL)
        guard confirmedFlags != -1, confirmedFlags & O_NONBLOCK != 0 else {
            throw GitHubCLIError.source(.transportUnavailable)
        }
        let source = DispatchSource.makeReadSource(fileDescriptor: descriptor, queue: queue)
        source.setEventHandler { [weak self] in
            guard let self, !self.finished else { return }
            var buffer = [UInt8](repeating: 0, count: 16_384)
            // Bounded turns let the other pipe and timeout run even under continuous output.
            for _ in 0..<16 {
                let count = Darwin.read(descriptor, &buffer, buffer.count)
                if count > 0 { self.consume(Data(buffer.prefix(count)), isOutput: isOutput) }
                else if count == 0 { self.consume(Data(), isOutput: isOutput); return }
                else if errno == EAGAIN || errno == EWOULDBLOCK { return }
                else if errno != EINTR { self.stop(with: .transportUnavailable); return }
                if self.finished { return }
            }
        }
        source.setCancelHandler { try? handle.close() }
        source.resume()
        return source
    }

    private func consume(_ data: Data, isOutput: Bool) {
        guard !finished else { return }
        if data.isEmpty {
            if isOutput {
                stdoutEnded = true
                stdoutSource?.cancel()
            } else {
                stderrEnded = true
                stderrSource?.cancel()
            }
        } else if failure == nil {
            guard data.count <= limit - byteCount else { stop(with: .resourceLimit); return }
            byteCount += data.count
            if isOutput { output.append(data) }
        }
        completeIfReady()
    }

    private func stop(with problem: SourceProblem) {
        guard !finished else { return }
        if failure == nil { failure = problem }
        guard started, !stopping else { return }
        stopping = true
        if process.isRunning { process.terminate() }
        queue.asyncAfter(deadline: .now() + 1) { [self] in
            // Only this Process, never a name/group/global kill. Recheck liveness before signal.
            if !finished, process.isRunning { _ = Darwin.kill(process.processIdentifier, SIGKILL) }
        }
        queue.asyncAfter(deadline: .now() + 2) { [self] in
            guard !finished, !process.isRunning else { return }
            // A descendant retaining a pipe cannot hold a failed request indefinitely.
            // Forced closure is failure-only; successful results always require observed EOF.
            exited = true
            stdoutSource?.cancel()
            stderrSource?.cancel()
            stdoutEnded = true; stderrEnded = true
            completeIfReady()
        }
    }

    private func completeIfReady() {
        guard !finished, exited, stdoutEnded, stderrEnded, let continuation else { return }
        finished = true
        self.continuation = nil
        timeout?.cancel(); timeout = nil
        process.terminationHandler = nil
        stdoutSource?.cancel()
        stderrSource?.cancel()
        if stdoutSource == nil { try? stdout.fileHandleForReading.close() }
        if stderrSource == nil { try? stderr.fileHandleForReading.close() }
        try? stdout.fileHandleForWriting.close()
        try? stderr.fileHandleForWriting.close()
        if let failure { continuation.resume(throwing: GitHubCLIError.source(failure)) }
        else { continuation.resume(returning: GitHubProcessResult(output: output, exitCode: process.terminationStatus)) }
        output.removeAll(keepingCapacity: false)
    }
}
