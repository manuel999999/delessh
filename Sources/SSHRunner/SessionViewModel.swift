import Foundation
import NIOPosix
import SwiftTerm

@MainActor
final class SessionViewModel: ObservableObject {
    @Published var host = ""
    @Published var port = "22"
    @Published var username = ""
    @Published var password = ""
    @Published var isConnected = false
    @Published var isBusy = false
    @Published var errorMessage: String?
    @Published var savedProfiles: [SavedProfile] = ProfileStore.loadAll()

    private let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private var client: SSHClient?
    private var session: InteractiveSSHSession?
    private weak var terminalView: TerminalView?

    var canConnect: Bool {
        !host.isEmpty && !username.isEmpty && !isBusy && !isConnected
    }

    func attachTerminal(_ terminalView: TerminalView) {
        self.terminalView = terminalView
    }

    func connect() async {
        guard let portNumber = Int(port) else {
            errorMessage = "Port must be a number."
            return
        }

        errorMessage = nil
        isBusy = true
        defer { isBusy = false }

        let newClient = SSHClient(group: group)
        do {
            try await newClient.connect(host: host, port: portNumber, username: username, password: password)

            let terminal = terminalView?.getTerminal()
            let cols = terminal?.cols ?? 80
            let rows = terminal?.rows ?? 24

            let newSession = try await newClient.openShell(
                cols: cols,
                rows: rows,
                onData: { [weak self] bytes in
                    Task { @MainActor in
                        self?.terminalView?.feed(byteArray: bytes)
                    }
                },
                onClose: { [weak self] error in
                    Task { @MainActor in
                        self?.handleSessionClosed(error: error)
                    }
                }
            )

            client = newClient
            session = newSession
            isConnected = true
            terminalView?.feed(text: "Connected to \(host):\(portNumber) as \(username).\r\n")
            terminalView?.window?.makeFirstResponder(terminalView)
        } catch {
            errorMessage = "Connection failed: \(error.localizedDescription)"
        }
    }

    func disconnect() async {
        isBusy = true
        defer { isBusy = false }

        session?.close()
        session = nil
        try? await client?.disconnect()
        client = nil
        isConnected = false
    }

    func sendInput(_ data: ArraySlice<UInt8>) {
        session?.send(data)
    }

    func sendCommand(_ text: String) {
        guard isConnected, !text.isEmpty else { return }
        let bytes = Array((text + "\n").utf8)
        session?.send(bytes[...])
        terminalView?.window?.makeFirstResponder(terminalView)
    }

    func terminalSizeChanged(cols: Int, rows: Int) {
        session?.resize(cols: cols, rows: rows)
    }

    private func handleSessionClosed(error: Error?) {
        session = nil
        isConnected = false
        if let error {
            errorMessage = "Session ended: \(error.localizedDescription)"
        }
        terminalView?.feed(text: "\r\n[Connection closed]\r\n")
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
