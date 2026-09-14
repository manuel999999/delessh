import NIOCore
import NIOPosix
import NIOSSH

/// A minimal SSH client: connect once with a password, then open an
/// interactive shell channel (PTY + shell) over the connection.
final class SSHClient {
    private let group: EventLoopGroup
    private var channel: Channel?

    init(group: EventLoopGroup) {
        self.group = group
    }

    func connect(host: String, port: Int, username: String, password: String) async throws {
        let bootstrap = ClientBootstrap(group: group)
            .channelInitializer { channel in
                channel.eventLoop.makeCompletedFuture {
                    let sshHandler = NIOSSHHandler(
                        role: .client(
                            .init(
                                userAuthDelegate: PasswordAuthDelegate(username: username, password: password),
                                serverAuthDelegate: AcceptAllHostKeysDelegate()
                            )
                        ),
                        allocator: channel.allocator,
                        inboundChildChannelInitializer: nil
                    )
                    try channel.pipeline.syncOperations.addHandler(sshHandler)
                }
            }
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(IPPROTO_TCP), TCP_NODELAY), value: 1)

        self.channel = try await bootstrap.connect(host: host, port: port).get()
    }

    /// Opens an interactive shell channel with a PTY attached. `onData` fires
    /// for every chunk of output from the remote shell; `onClose` fires once,
    /// when the channel closes (with an error if it closed abnormally).
    ///
    /// Both callbacks run on the SSH connection's NIO event loop, not the
    /// main thread — callers touching UI state must hop back themselves.
    func openShell(
        cols: Int,
        rows: Int,
        onData: @escaping (ArraySlice<UInt8>) -> Void,
        onClose: @escaping (Error?) -> Void
    ) async throws -> InteractiveSSHSession {
        guard let channel else { throw SSHClientError.notConnected }
        let sshHandler = try await channel.pipeline.handler(type: NIOSSHHandler.self).get()

        let childChannel: Channel = try await withCheckedThrowingContinuation { continuation in
            let createPromise = channel.eventLoop.makePromise(of: Channel.self)

            sshHandler.createChannel(createPromise) { childChannel, channelType in
                guard channelType == .session else {
                    return channel.eventLoop.makeFailedFuture(SSHClientError.invalidChannelType)
                }

                return childChannel.eventLoop.makeCompletedFuture {
                    let shellHandler = SSHInteractiveShellHandler(
                        cols: cols,
                        rows: rows,
                        onData: onData,
                        onClose: onClose
                    )
                    try childChannel.pipeline.syncOperations.addHandler(shellHandler)
                }
            }

            createPromise.futureResult.whenComplete { result in
                continuation.resume(with: result)
            }
        }

        return InteractiveSSHSession(channel: childChannel)
    }

    func disconnect() async throws {
        guard let channel else { return }
        self.channel = nil
        try await channel.close().get()
    }
}
