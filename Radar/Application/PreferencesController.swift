import Foundation
import Observation

@MainActor
@Observable
final class PreferencesController {
    let storage: PreferencesStore
    private let store: RadarStore
    private var loadID = UUID()
    private(set) var snapshot = RadarPreferences()
    private(set) var message: String?

    init(storage: PreferencesStore, store: RadarStore) { self.storage = storage; self.store = store }

    func load() async {
        let attempt = UUID(); loadID = attempt
        do {
            let value = try await storage.snapshot()
            guard loadID == attempt else { return }
            snapshot = value; message = nil
            store.repositoryCategories = Dictionary(uniqueKeysWithValues: value.categories.compactMap { name, category in
                RadarPreferences.repository(name).map { ($0, category) }
            })
        } catch { if loadID == attempt { message = Self.message(error) } }
    }

    func selectDisplay(_ id: UInt32?) async {
        do { try await storage.saveDisplay(id); await load() }
        catch { message = Self.message(error) }
    }

    func selectCategory(_ category: RepositoryCategory?, repository: String) async {
        do { try await storage.saveCategory(category, repository: repository); await load() }
        catch { message = Self.message(error) }
    }

    static func message(_ error: Error) -> String {
        (error as? PreferencesError)?.message ?? PreferencesError.unavailable.message
    }
}
