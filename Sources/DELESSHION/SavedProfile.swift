import Foundation

/// Non-secret connection metadata for a saved login. The password itself
/// never lives here — it's stored separately in the Keychain, keyed by `id`.
struct SavedProfile: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var host: String
    var port: String
    var username: String
}
