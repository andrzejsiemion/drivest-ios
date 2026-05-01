import SwiftUI
import SwiftData
import UIKit

struct VolvoSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var vehicles: [Vehicle]

    @State private var refreshTokenInput: String = ""
    @State private var clientIDInput: String = ""
    @State private var clientSecretInput: String = ""
    @State private var vccAPIKeyInput: String = ""
    @State private var credentialsVisible: Bool = false
    @State private var tokenError: String? = nil

    private var isConnected: Bool { KeychainService.load(for: KeychainService.volvoRefreshToken) != nil }
    private var clientIDSet: Bool { KeychainService.load(for: KeychainService.volvoClientID) != nil }
    private var clientSecretSet: Bool { KeychainService.load(for: KeychainService.volvoClientSecret) != nil }
    private var vccAPIKeySet: Bool { KeychainService.load(for: KeychainService.volvoVCCAPIKey) != nil }

    var body: some View {
        Form {
            // MARK: Account
            Section {
                if isConnected {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text("Volvo account connected")
                    }
                    Button("Disconnect", role: .destructive) { disconnect() }
                } else {
                    Text("Paste your Volvo refresh_token.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("refresh_token", text: $refreshTokenInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button {
                        if let s = UIPasteboard.general.string, !s.isEmpty {
                            refreshTokenInput = s
                        }
                    } label: {
                        Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                    }
                    Button("Save Token") { saveToken() }
                        .disabled(refreshTokenInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    if let error = tokenError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            } header: {
                Text("Account")
            }

            // MARK: Developer Credentials
            Section {
                HStack {
                    Label("Client ID", systemImage: clientIDSet ? "checkmark.circle.fill" : "minus.circle")
                        .foregroundStyle(clientIDSet ? .green : .secondary)
                    Spacer()
                }
                credentialRow(label: "Client ID", value: $clientIDInput)

                HStack {
                    Label("Client Secret", systemImage: clientSecretSet ? "checkmark.circle.fill" : "minus.circle")
                        .foregroundStyle(clientSecretSet ? .green : .secondary)
                    Spacer()
                }
                credentialRow(label: "Client Secret", value: $clientSecretInput)

                HStack {
                    Label("VCC API Key", systemImage: vccAPIKeySet ? "checkmark.circle.fill" : "minus.circle")
                        .foregroundStyle(vccAPIKeySet ? .green : .secondary)
                    Spacer()
                }
                credentialRow(label: "VCC API Key", value: $vccAPIKeyInput)

                Button("Save Credentials") { saveCredentials() }
                    .disabled(
                        clientIDInput.trimmingCharacters(in: .whitespaces).isEmpty ||
                        clientSecretInput.trimmingCharacters(in: .whitespaces).isEmpty ||
                        vccAPIKeyInput.trimmingCharacters(in: .whitespaces).isEmpty
                    )
            } header: {
                HStack {
                    Text("Developer Credentials")
                    Spacer()
                    Button {
                        credentialsVisible.toggle()
                    } label: {
                        Image(systemName: credentialsVisible ? "eye.slash" : "eye")
                            .font(.footnote)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            } footer: {
                Text("Fields are empty — enter new values to update stored credentials.")
            }
            .onDisappear {
                clientIDInput = ""
                clientSecretInput = ""
                vccAPIKeyInput = ""
            }
        }
        .navigationTitle("Volvo")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func credentialRow(label: String, value: Binding<String>) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)
            if credentialsVisible {
                TextField(label, text: value)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))
                    .multilineTextAlignment(.trailing)
            } else {
                SecureField(label, text: value)
                    .font(.system(.body, design: .monospaced))
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    // MARK: - Actions

    private func saveToken() {
        let token = refreshTokenInput.trimmingCharacters(in: .whitespaces)
        guard !token.isEmpty else { return }

        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        let isValidFormat = token.count >= 20 && token.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }

        guard isValidFormat else {
            tokenError = "Invalid token format"
            return
        }

        tokenError = nil
        KeychainService.save(token, for: KeychainService.volvoRefreshToken)
        refreshTokenInput = ""
    }

    private func saveCredentials() {
        let id     = clientIDInput.trimmingCharacters(in: .whitespaces)
        let secret = clientSecretInput.trimmingCharacters(in: .whitespaces)
        let key    = vccAPIKeyInput.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty, !secret.isEmpty, !key.isEmpty else { return }
        KeychainService.save(id,     for: KeychainService.volvoClientID)
        KeychainService.save(secret, for: KeychainService.volvoClientSecret)
        KeychainService.save(key,    for: KeychainService.volvoVCCAPIKey)
        clientIDInput = ""
        clientSecretInput = ""
        vccAPIKeyInput = ""
    }

    private func disconnect() {
        KeychainService.delete(for: KeychainService.volvoRefreshToken)
        for vehicle in vehicles where vehicle.vin != nil {
            vehicle.vin = nil
            vehicle.volvoLastSyncAt = nil
        }
        Persistence.save(modelContext)
    }
}
