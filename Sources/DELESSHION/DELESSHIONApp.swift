import SwiftUI

/// Plain `swift run` builds don't produce an `.app` bundle, so macOS doesn't
/// treat the process as a normal foreground app and won't hand it keyboard
/// focus automatically. Force activation on launch so the window (and Tab
/// key, etc.) actually reaches us instead of whatever app was frontmost.
///
/// Also makes closing the window quit the app (the default WindowGroup
/// lifecycle would otherwise leave the process — and its SSH socket —
/// running in the background), and gives the active session a chance to
/// close gracefully before the process exits.
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var disconnectHandler: (() async -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let disconnectHandler else { return .terminateNow }

        Task {
            await disconnectHandler()
            NSApp.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}

@main
struct DELESSHIONApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("DELESSHION") {
            ContentView()
                .environmentObject(appDelegate)
        }
        .windowResizability(.contentSize)
    }
}
