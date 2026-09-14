import Foundation

/// Persists the non-secret profile list to UserDefaults. Passwords are never
/// stored here — see `KeychainStore`.
enum ProfileStore {
    private static let key = "SSHRunner.savedProfiles"

    static func loadAll() -> [SavedProfile] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([SavedProfile].self, from: data)) ?? []
    }

    static func saveAll(_ profiles: [SavedProfile]) {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
