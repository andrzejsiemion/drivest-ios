enum VolvoAPIConstants {
    static var clientID: String     { KeychainService.load(for: KeychainService.volvoClientID)     ?? "" }
    static var clientSecret: String { KeychainService.load(for: KeychainService.volvoClientSecret) ?? "" }
    static var vccAPIKey: String    { KeychainService.load(for: KeychainService.volvoVCCAPIKey)    ?? "" }

    static var isConfigured: Bool {
        !clientID.isEmpty && !clientSecret.isEmpty && !vccAPIKey.isEmpty
    }
}
