import SwiftUI

struct GoToPopover: View {
    @ObservedObject var viewModel: SessionViewModel
    @Binding var isPresented: Bool
    @State private var path = ""

    private let quickPaths = [
        "/var/www/html/webgltest",
        "/var/www/html/stolltest",
        "/var/www/html/naturekasttest"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Go To")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(quickPaths, id: \.self) { quickPath in
                    Button {
                        path = quickPath
                    } label: {
                        Text(quickPath)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.borderless)
                }
            }

            Divider()

            HStack {
                TextField("Path", text: $path)
                Button("Proceed") {
                    viewModel.sendCommand("cd \(path)")
                    isPresented = false
                }
                .disabled(path.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 320)
    }
}
