import Foundation

enum JiraReferenceProvenance: String, Hashable, Sendable {
    case title
    case branch
}

struct JiraKeyReference: Hashable, Sendable {
    let site: JiraSiteIdentity
    let key: JiraIssueKey
    let provenance: Set<JiraReferenceProvenance>
}

/// Matches a complete key before comparing it with the authorized project set.
/// Unicode letters/numbers/marks count as token characters even though Jira keys are ASCII.
struct JiraKeyReferenceExtractor: Sendable {
    func references(title: String, branch: String?, scope: SourceScope) -> [JiraKeyReference] {
        guard case let .jira(site, projects) = scope.resources,
              let pattern = try? NSRegularExpression(
                pattern: #"(?<![\p{L}\p{N}\p{M}_])([A-Za-z][A-Za-z0-9_]*-[0-9]+)(?![\p{L}\p{N}\p{M}_])"#
              ) else { return [] }
        var found: [JiraIssueKey: Set<JiraReferenceProvenance>] = [:]
        for (text, origin) in [(title, JiraReferenceProvenance.title), (branch ?? "", .branch)] {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            pattern.enumerateMatches(in: text, range: range) { match, _, _ in
                guard let match, let range = Range(match.range(at: 1), in: text),
                      let key = JiraIssueKey(String(text[range])), projects.contains(key.projectKey) else { return }
                found[key, default: []].insert(origin)
            }
        }
        return found.keys.sorted { $0.rawValue < $1.rawValue }.map {
            JiraKeyReference(site: site, key: $0, provenance: found[$0] ?? [])
        }
    }
}
