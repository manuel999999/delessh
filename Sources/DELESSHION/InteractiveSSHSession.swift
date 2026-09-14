import NIOCore
import NIOSSH

/// A live interactive shell channel: bytes typed by the user go in via
/// `send`, bytes from the remote shell arrive via the `onData` callback
/// passed to `SSHClient.openShell`.
final class InteractiveSSHSession {
    private let channel: Channel

    init(channel: Channel) {
        self.channel = channel
    }

    func send(_ bytes: ArraySlice<UInt8>) {
        var buffer = channel.allocator.buffer(capacity: bytes.count)
        buffer.writeBytes(bytes)
        let data = SSHChannelData(type: .channel, data: .byteBuffer(buffer))
        channel.writeAndFlush(data, promise: nil)
    }

    func resize(cols: Int, rows: Int) {
        let event = SSHChannelRequestEvent.WindowChangeRequest(
            terminalCharacterWidth: cols,
            terminalRowHeight: rows,
            terminalPixelWidth: 0,
            terminalPixelHeight: 0
        )
        channel.triggerUserOutboundEvent(event, promise: nil)
    }

    func close() {
        channel.close(promise: nil)
    }
}
