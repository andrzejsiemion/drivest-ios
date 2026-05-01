import Foundation

enum ToyotaAPIConstants {
    // These are Toyota's own public app credentials, not user-specific secrets.
    // They are identical to those used by Toyota's official mobile app and are
    // publicly documented in the open-source pytoyoda project.
    // They cannot be injected at runtime on iOS without a server-side proxy.
    static let clientID = "oneapp"
    static let basicAuthHeader = "basic b25lYXBwOm9uZWFwcA==" // base64("oneapp:oneapp")
    static let apiKey = "tTZipv6liF74PwMfk9Ed68AQ0bISswwf3iHQdqcF"
    static let appVersion = "2.14.0"
    static let brand   = "T"
    static let channel = "ONEAPP"
    static let region  = "EU"
    static let userAgent = "okhttp/4.10.0"
    static let redirectURI = "com.toyota.oneapp:/oauth2Callback"

    static let tokenURL = URL(string: "https://b2c-login.toyota-europe.com/oauth2/realms/root/realms/tme/access_token")!
    static let telemetryURL = URL(string: "https://ctpa-oneapi.tceu-ctp-prd.toyotaconnectedeurope.io/v3/telemetry")!

    static var isConfigured: Bool {
        KeychainService.load(for: KeychainService.toyotaRefreshToken) != nil
    }

    static var savedUsername: String? {
        KeychainService.load(for: KeychainService.toyotaUsername)
    }
}
