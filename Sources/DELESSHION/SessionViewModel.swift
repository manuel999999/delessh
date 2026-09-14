import Foundation

@MainActor
final class SessionViewModel: ObservableObject {
    @Published var host = ""
    @Published var port = "22"
    @Published var username = ""
    @Published var password = ""
    @Published var isConnected = false
    @Published var errorMessage: String?
    @Published var savedProfiles: [SavedProfile] = ProfileStore.loadAll()

    private weak var terminalView: SSHProcessTerminalView?

    var canConnect: Bool {
        !host.isEmpty && !username.isEmpty && !isConnected
    }

    func attachTerminal(_ terminalView: SSHProcessTerminalView) {
        self.terminalView = terminalView
    }

    func connect() async {
        guard let portNumber = Int(port) else {
            errorMessage = "Port must be a number."
            return
        }
        guard let terminalView else { return }

        errorMessage = nil
        terminalView.connect(host: host, port: portNumber, username: username, password: password)
        isConnected = true
        terminalView.window?.makeFirstResponder(terminalView)
    }

    func disconnect() async {
        terminalView?.terminate()
        isConnected = false
    }

    func sendCommand(_ text: String) {
        guard isConnected, !text.isEmpty else { return }
        let bytes = Array((text + "\n").utf8)
        terminalView?.process.send(data: bytes[...])
        terminalView?.window?.makeFirstResponder(terminalView)
    }

    func handleProcessTerminated(exitCode: Int32?) {
        isConnected = false
        if let exitCode, exitCode != 0 {
            errorMessage = "ssh exited with status \(exitCode)."
        }
    }

    // MARK: - Saved profiles

    func loadProfile(_ profile: SavedProfile) {
        host = profile.host
        port = profile.port
        username = profile.username
        password = KeychainStore.loadPassword(for: profile.id) ?? ""
    }

    func saveCurrentAsProfile(name: String) {
        let profile = SavedProfile(name: name, host: host, port: port, username: username)
        KeychainStore.savePassword(password, for: profile.id)
        savedProfiles.append(profile)
        ProfileStore.saveAll(savedProfiles)
    }

    func deleteProfile(_ profile: SavedProfile) {
        KeychainStore.deletePassword(for: profile.id)
        savedProfiles.removeAll { $0.id == profile.id }
        ProfileStore.saveAll(savedProfiles)
    }
}
