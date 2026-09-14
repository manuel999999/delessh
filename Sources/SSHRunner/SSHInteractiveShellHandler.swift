import NIOCore
import NIOSSH

/// Drives one interactive SSH session channel: requests a PTY + shell on
/// activation, then streams raw bytes both ways instead of buffering a
/// single command's output.
final class SSHInteractiveShellHandler: ChannelInboundHandler {
    typealias InboundIn = SSHChannelData

    private let cols: Int
    private let rows: Int
    private let onData: (ArraySlice<UInt8>) -> Void
    private let onClose: (Error?) -> Void
    private var closed = false

    init(
        cols: Int,
        rows: Int,
        onData: @escaping (ArraySlice<UInt8>) -> Void,
        onClose: @escaping (Error?) -> Void
    ) {
        self.cols = cols
        self.rows = rows
        self.onData = onData
        self.onClose = onClose
    }

    func channelActive(context: ChannelHandlerContext) {
        let ptyRequest = SSHChannelRequestEvent.PseudoTerminalRequest(
            wantReply: true,
            term: "xterm-256color",
            terminalCharacterWidth: cols,
            terminalRowHeight: rows,
            terminalPixelWidth: 0,
            terminalPixelHeight: 0,
            terminalModes: SSHTerminalModes([:])
        )
        context.triggerUserOutboundEvent(ptyRequest).whenFailure { [weak self] error in
            self?.finish(error, context: context)
        }

        let shellRequest = SSHChannelRequestEvent.ShellRequest(wantReply: true)
        context.triggerUserOutboundEvent(shellRequest).whenFailure { [weak self] error in
            self?.finish(error, context: context)
        }

        context.fireChannelActive()
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let data = self.unwrapInboundIn(data)
        guard case .byteBuffer(let bytes) = data.data else { return }
        let byteArray = bytes.getBytes(at: bytes.readerIndex, length: bytes.readableBytes) ?? []
        onData(byteArray[...])
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        finish(error, context: context)
        context.close(promise: nil)
    }

    func channelInactive(context: ChannelHandlerContext) {
        finish(nil, context: context)
        context.fireChannelInactive()
    }

    private func finish(_ error: Error?, context: ChannelHandlerContext) {
        guard !closed else { return }
        closed = true
        onClose(error)
    }
}
