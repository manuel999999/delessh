import SwiftUI

struct SavedProfilesPopover: View {
    @ObservedObject var viewModel: SessionViewModel
    @Binding var isPresented: Bool
    @State private var newProfileName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Saved Logins")
                .font(.headline)

            if viewModel.savedProfiles.isEmpty {
                Text("No saved logins yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                List {
                    ForEach(viewModel.savedProfiles) { profile in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(profile.name)
                                Text("\(profile.username)@\(profile.host):\(profile.port)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                viewModel.loadProfile(profile)
                                isPresented = false
                            } label: {
                                Text("Load")
                            }
                            Button(role: .destructive) {
                                viewModel.deleteProfile(profile)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .frame(minHeight: 120, maxHeight: 220)
            }

            Divider()

            Text("Save current fields")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                TextField("Profile name", text: $newProfileName)
                Button("Save") {
                    guard !newProfileName.isEmpty else { return }
                    viewModel.saveCurrentAsProfile(name: newProfileName)
                    newProfileName = ""
                }
                .disabled(newProfileName.isEmpty || viewModel.host.isEmpty || viewModel.username.isEmpty)
            }
        }
        .padding()
        .frame(width: 320)
    }
}
