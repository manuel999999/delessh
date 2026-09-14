import SwiftUI
import SwiftTerm

/// Bridges SwiftTerm's AppKit `TerminalView` (a full VT100/xterm emulator)
/// into SwiftUI. Keystrokes go out through the delegate's `send`; incoming
/// SSH output is fed in directly via `SessionViewModel.attachTerminal`.
struct SSHTerminalRepresentable: NSViewRepresentable {
    @ObservedObject var viewModel: SessionViewModel

    func makeNSView(context: Context) -> TerminalView {
        let terminalView = TerminalView(frame: .zero)
        terminalView.terminalDelegate = context.coordinator
        viewModel.attachTerminal(terminalView)
        return terminalView
    }

    func updateNSView(_ nsView: TerminalView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    final class Coordinator: NSObject, TerminalViewDelegate {
        private let viewModel: SessionViewModel

        init(viewModel: SessionViewModel) {
            self.viewModel = viewModel
        }

        func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
            let viewModel = viewModel
            Task { @MainActor in
                viewModel.terminalSizeChanged(cols: newCols, rows: newRows)
            }
        }

        func setTerminalTitle(source: TerminalView, title: String) {}

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

        func send(source: TerminalView, data: ArraySlice<UInt8>) {
            let viewModel = viewModel
            Task { @MainActor in
                viewModel.sendInput(data)
            }
        }

        func scrolled(source: TerminalView, position: Double) {}

        func rangeChanged(source: TerminalView, startY: Int, endY: Int) {}
    }
}
