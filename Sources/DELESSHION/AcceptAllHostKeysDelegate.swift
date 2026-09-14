import NIOCore
import NIOSSH

/// Accepts any host key without verification.
///
/// This is trust-on-first-use-*less*: it never checks the server's identity at all,
/// which leaves connections open to MITM tampering. A real client should pin/verify
/// host keys (e.g. against `~/.ssh/known_hosts`) before shipping this beyond local use.
final class AcceptAllHostKeysDelegate: NIOSSHClientServerAuthenticationDelegate {
    func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
        validationCompletePromise.succeed(())
    }
}
