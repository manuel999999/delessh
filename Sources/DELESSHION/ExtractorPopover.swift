import AppKit
import SwiftUI

struct ExtractorPopover: View {
    let items: [String]
    @Binding var isPresented: Bool
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Extractor")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(items, id: \.self) { item in
                    Button {
                        appendItem(item)
                    } label: {
                        Text(item)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.borderless)
                }
            }

            Divider()

            TextField("Result", text: $text)

            HStack {
                Button("Clear") {
                    text = ""
                }

                Spacer()

                Button("Copy") {
                    copyToPasteboard()
                }
                .disabled(text.isEmpty)
            }
        }
        .padding()
        .frame(width: 320)
    }

    private func appendItem(_ item: String) {
        text = text.isEmpty ? item : text + " " + item
    }

    private func copyToPasteboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
