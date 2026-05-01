import SwiftUI

struct ToyotaSettingsView: View {
    @State private var usernameInput: String = ""
    @State private var passwordInput: String = ""
    @State private var isSigningIn = false
    @State private var signInError: String? = nil

    private var isConnected: Bool { ToyotaAPIConstants.isConfigured }

    var body: some View {
        Form {
            // MARK: Account
            Section {
                if isConnected {
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        if let username = ToyotaAPIConstants.savedUsername {
                            Text("Signed in as \(username)")
                        } else {
                            Text("Toyota account connected")
                        }
                    }
                    Button("Disconnect", role: .destructive) { disconnect() }
                } else {
                    TextField("Email", text: $usernameInput)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $passwordInput)

                    Button {
                        Task { await signIn() }
                    } label: {
                        if isSigningIn {
                            HStack {
                                ProgressView()
                                Text("Signing in…")
                            }
                        } else {
                            Text("Sign In")
                        }
                    }
                    .disabled(usernameInput.trimmingCharacters(in: .whitespaces).isEmpty ||
                              passwordInput.isEmpty || isSigningIn)

                    if let error = signInError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            } header: {
                Text("Account")
            } footer: {
                Text("Toyota Connected Services — EU only. Unofficial API; may stop working without notice.")
                    .font(.caption)
            }
        }
        .navigationTitle("Toyota")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Actions

    private func signIn() async {
        let username = usernameInput.trimmingCharacters(in: .whitespaces)
        let password = passwordInput
        guard !username.isEmpty, !password.isEmpty else { return }

        isSigningIn = true
        signInError = nil
        defer { isSigningIn = false }

        do {
            let client = ToyotaAPIClient()
            let tokens = try await client.login(username: username, password: password)
            KeychainService.save(tokens.refreshToken, for: KeychainService.toyotaRefreshToken)
            KeychainService.save(username, for: KeychainService.toyotaUsername)
            passwordInput = ""
        } catch {
            signInError = (error as? ToyotaAPIError)?.userMessage ?? error.localizedDescription
        }
    }

    private func disconnect() {
        KeychainService.delete(for: KeychainService.toyotaRefreshToken)
        KeychainService.delete(for: KeychainService.toyotaUsername)
    }
}
