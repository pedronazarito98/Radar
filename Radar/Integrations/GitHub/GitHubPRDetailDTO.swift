import Foundation

struct GitHubPRDetailDTO: Decodable {
    let number: Int
    let state: String
    let draft: Bool
    let merged: Bool
    let head: Head
    let base: Base
    struct Head: Decodable { let sha: String; let ref: String }
    struct Base: Decodable { let repo: GitHubRepositoryDTO }

    func observation(for item: PullRequestItem) throws -> (GitCommitSHA, PullRequestLifecycle) {
        guard number == item.id.number, base.repo.full_name.lowercased() == item.repositoryName.fullName,
              let repositoryID = GitHubRepositoryID(base.repo.id), let sha = GitCommitSHA(head.sha),
              state == "open" || state == "closed", !(merged && state == "open") else {
            throw GitHubCLIError.source(.invalidResponse)
        }
        if case let .stable(expected) = item.id.repository, expected != repositoryID {
            throw GitHubCLIError.source(.invalidResponse)
        }
        return (sha, merged ? .merged : state == "closed" ? .closed : draft ? .draft : .open)
    }
}

struct GitHubCheckPageDTO: Decodable {
    let total_count: Int
    let check_runs: [GitHubCheckDTO]
}

struct GitHubCheckDTO: Decodable {
    let id: Int64
    let name: String
    let head_sha: String
    let status: String
    let conclusion: String?

    func signal(sha: GitCommitSHA) throws -> CISignal {
        guard id > 0, !name.isEmpty, GitCommitSHA(head_sha) == sha else { throw GitHubCLIError.source(.invalidResponse) }
        let state: CISignalState
        if status == "completed" {
            state = switch conclusion {
            case "success": .success
            case "failure": .failure
            case "timed_out": .timedOut
            case "action_required": .actionRequired
            case "cancelled": .cancelled
            case "neutral": .neutral
            case "skipped": .skipped
            default: .unknown
            }
        } else {
            state = switch status {
            case "queued", "requested": .queued
            case "pending": .pending
            case "in_progress": .inProgress
            case "waiting": .waiting
            default: .unknown
            }
        }
        return CISignal(origin: .checkRun(id: id, name: name), headSHA: sha, state: state)
    }
}

struct GitHubSuiteProbeDTO: Decodable {
    let total_count: Int
    let check_suites: [Suite]
    struct Suite: Decodable { let head_sha: String }
}

struct GitHubStatusDTO: Decodable {
    let context: String
    let state: String

    func signal(sha: GitCommitSHA) throws -> CISignal {
        guard !context.isEmpty else { throw GitHubCLIError.source(.invalidResponse) }
        let value: CISignalState = switch state {
        case "success": .success
        case "failure": .failure
        case "error": .error
        case "pending": .pending
        default: .unknown
        }
        return CISignal(origin: .commitStatus(context: context), headSHA: sha, state: value)
    }
}

struct GitHubReviewDTO: Decodable {
    let id: Int64
    let user: GitHubUserDTO?
    let state: String
    let commit_id: String?
    let submitted_at: String?

    func review() throws -> PullRequestReview {
        guard id > 0 else { throw GitHubCLIError.source(.invalidResponse) }
        let value: PullRequestReviewState = switch state {
        case "APPROVED": .approved
        case "CHANGES_REQUESTED": .changesRequested
        case "COMMENTED": .commented
        case "PENDING": .pending
        case "DISMISSED": .dismissed
        default: .unknown
        }
        let sha = commit_id.flatMap(GitCommitSHA.init)
        let formatter = ISO8601DateFormatter()
        var submitted = submitted_at.flatMap { formatter.date(from: $0) }
        if submitted == nil, let submitted_at {
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            submitted = formatter.date(from: submitted_at)
        }
        guard commit_id == nil || sha != nil, submitted_at == nil || submitted != nil,
              value == .pending || (sha != nil && submitted != nil),
              user == nil || user.flatMap({ GitHubUserID($0.id) }) != nil else {
            throw GitHubCLIError.source(.invalidResponse)
        }
        return PullRequestReview(id: id, authorID: user.flatMap { GitHubUserID($0.id) }, state: value,
            commitSHA: sha, submittedAt: submitted)
    }
}

struct GitHubReviewRequestsDTO: Decodable {
    let users: [Identifier]
    let teams: [Identifier]
    struct Identifier: Decodable { let id: Int64 }
}
