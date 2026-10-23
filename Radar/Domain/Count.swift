import Foundation

struct Count: Equatable, Sendable {
    enum Value: Equatable, Sendable {
        case exact(Int)
        case partial(lowerBound: Int)
        case unknown
    }

    let value: Value
    static let unknown = Count(value: .unknown)

    private init(value: Value) {
        self.value = value
    }

    /// Only a deduplicated snapshot can supply this count; never use a search API total.
    init<Item>(snapshot: SourceSnapshot<Item>) {
        value = snapshot.isComplete ? .exact(snapshot.items.count) : .partial(lowerBound: snapshot.items.count)
    }

    var displayText: String {
        switch value {
        case .unknown: "—"
        case .exact(let total): total > 99 ? "99+" : String(total)
        case .partial(let lowerBound): lowerBound == 0 ? "…" : "\(min(lowerBound, 99))+"
        }
    }

    var accessibilityDescription: String {
        switch value {
        case .unknown: "Total desconhecido"
        case .exact(let total): "Total exato: \(total)"
        case .partial(let lowerBound):
            lowerBound == 0 ? "Consulta parcial, total ainda desconhecido" : "Pelo menos \(lowerBound)"
        }
    }
}
