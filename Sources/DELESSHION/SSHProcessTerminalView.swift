import AppKit
import SwiftTerm

/// Drives an interactive SSH session by launching the system `/usr/bin/ssh`
/// inside a real pseudo-terminal (via SwiftTerm's `LocalProcessTerminalView`)
/// instead of speaking the SSH protocol ourselves.
///
/// This trades fine-grained protocol control for full compatibility with
/// whatever the system OpenSSH supports (RSA host keys, every KEX/cipher
/// suite, agent auth, `~/.ssh/config`, ProxyJump, ...). swift-nio-ssh only
/// implements a narrow, modern algorithm set and can't complete a handshake
/// against servers that don't offer it (e.g. RSA-only host keys).
final class SSHProcessTerminalView: LocalProcessTerminalView {
    /// Host key checking is disabled to match the previous NIOSSH client's
    /// "accept any host key" behavior. This is trust-on-first-use-*less*:
    /// it never verifies the server's identity, leaving connections open to
    /// MITM tampering. A real client should verify host keys instead.
    private static let insecureHostKeyOptions = [
        "-o", "StrictHostKeyChecking=no",
        "-o", "UserKnownHostsFile=/dev/null",
    ]

    /// Saved password to auto-type at the first "password:" prompt, mirroring
    /// what `sshpass` does by watching the pty rather than speaking the
    /// protocol. Only fires once per connection so a wrong password doesn't
    /// loop, and the user can still type it manually if this doesn't match.
    private var pendingPassword: String?
    private var passwordSent = false
    private var promptTail: [UInt8] = []
    private let promptTailLimit = 32

    func connect(host: String, port: Int, username: String, password: String) {
        pendingPassword = password.isEmpty ? nil : password
        passwordSent = false
        promptTail.removeAll()

        let args = [
            "-tt",
            "-p", String(port),
        ] + Self.insecureHostKeyOptions + [
            "-o", "ServerAliveInterval=30",
            "\(username)@\(host)",
        ]
        startProcess(executable: "/usr/bin/ssh", args: args)
    }

    override func dataReceived(slice: ArraySlice<UInt8>) {
        super.dataReceived(slice: slice)
        checkForPasswordPrompt(slice)
    }

    private func checkForPasswordPrompt(_ slice: ArraySlice<UInt8>) {
        guard !passwordSent, let password = pendingPassword else { return }

        promptTail.append(contentsOf: slice)
        if promptTail.count > promptTailLimit {
            promptTail.removeFirst(promptTail.count - promptTailLimit)
        }

        guard String(decoding: promptTail, as: UTF8.self).lowercased().contains("password:") else { return }

        passwordSent = true
        process.send(data: Array((password + "\n").utf8)[...])
    }
}
