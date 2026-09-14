import SwiftUI
import SwiftTerm

/// Bridges SwiftTerm's AppKit `LocalProcessTerminalView` (a full VT100/xterm
/// emulator wired to a real pty-backed child process) into SwiftUI.
/// `LocalProcessTerminalView` owns `terminalDelegate` itself and reposts the
/// messages we care about to `processDelegate` — see its doc comment.
struct SSHTerminalRepresentable: NSViewRepresentable {
    @ObservedObject var viewModel: SessionViewModel

    func makeNSView(context: Context) -> SSHProcessTerminalView {
        let terminalView = SSHProcessTerminalView(frame: .zero)
        terminalView.processDelegate = context.coordinator
        viewModel.attachTerminal(terminalView)
        return terminalView
    }

    func updateNSView(_ nsView: SSHProcessTerminalView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    final class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        private let viewModel: SessionViewModel

        init(viewModel: SessionViewModel) {
            self.viewModel = viewModel
        }

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}

        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

        func processTerminated(source: TerminalView, exitCode: Int32?) {
            let viewModel = viewModel
            Task { @MainActor in
                viewModel.handleProcessTerminated(exitCode: exitCode)
            }
        }
    }
}
