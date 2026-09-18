import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appDelegate: AppDelegate
    @StateObject private var viewModel = SessionViewModel()
    @State private var showingSavedProfiles = false
    @State private var showingGoTo = false
    @State private var showingExtractor = false
    @State private var extractorInput = ""

    var body: some View {
        VStack(spacing: 0) {
            SSHTerminalRepresentable(viewModel: viewModel)
                .frame(minWidth: 640, minHeight: 380)

            Divider()

            controlsBar
                .padding(10)
                .background(.bar)
        }
        .frame(minWidth: 640, minHeight: 480)
        .onAppear {
            appDelegate.disconnectHandler = { [weak viewModel] in
                await viewModel?.disconnect()
            }
        }
    }

    private var controlsBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 8) {
                TextField("Host", text: $viewModel.host)
                    .frame(minWidth: 140)
                TextField("Port", text: $viewModel.port)
                    .frame(width: 50)
                TextField("Username", text: $viewModel.username)
                    .frame(minWidth: 100)
                SecureField("Password", text: $viewModel.password)
                    .frame(minWidth: 100)

                Button {
                    showingSavedProfiles.toggle()
                } label: {
                    Image(systemName: "person.crop.circle.badge.clock")
                }
                .popover(isPresented: $showingSavedProfiles) {
                    SavedProfilesPopover(viewModel: viewModel, isPresented: $showingSavedProfiles)
                }
            }

            HStack {
                if viewModel.isConnected {
                    Button("Disconnect") {
                        Task { await viewModel.disconnect() }
                    }
                } else {
                    Button("Connect") {
                        Task { await viewModel.connect() }
                    }
                    .disabled(!viewModel.canConnect)
                    .keyboardShortcut(.defaultAction)
                }

                if viewModel.isConnected {
                    Button("Go To") {
                        showingGoTo.toggle()
                    }
                    .popover(isPresented: $showingGoTo) {
                        GoToPopover(viewModel: viewModel, isPresented: $showingGoTo)
                    }

                    Button("ls") {
                        viewModel.sendCommand("ls")
                    }

                    Button("Extractor") {
                        if !extractorInput.isEmpty {
                            showingExtractor = true
                        }
                    }
                    .popover(isPresented: $showingExtractor) {
                        ExtractorPopover(
                            items: extractorInput.split(separator: " ").map(String.init),
                            isPresented: $showingExtractor
                        )
                    }

                    TextField("Extractor text", text: $extractorInput)
                        .frame(minWidth: 140)
                }

                Spacer()

                Circle()
                    .fill(viewModel.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(viewModel.isConnected ? "Connected" : "Not connected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
}
