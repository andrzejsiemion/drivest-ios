import SwiftUI

struct IntegrationsView: View {
    var body: some View {
        List {
            NavigationLink {
                VolvoSettingsView()
            } label: {
                HStack {
                    Text("Volvo")
                    Spacer()
                    if KeychainService.load(for: KeychainService.volvoRefreshToken) != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.footnote)
                    }
                }
            }
            NavigationLink {
                ToyotaSettingsView()
            } label: {
                HStack {
                    Text("Toyota")
                    Spacer()
                    if ToyotaAPIConstants.isConfigured {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.footnote)
                    }
                }
            }
            Link(destination: URL(string: "shortcuts://")!) {
                HStack {
                    Text("Set auto fetch in Shortcuts")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
        }
        .navigationTitle("Integrations")
        .navigationBarTitleDisplayMode(.inline)
    }
}
