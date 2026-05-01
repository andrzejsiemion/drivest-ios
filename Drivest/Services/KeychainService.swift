import Foundation
import Security
import os

enum KeychainService {
    private static let log = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Drivest", category: "Keychain")

    @discardableResult
    static func save(_ value: String, for key: String) -> Bool {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData:   data,
        ]
        SecItemDelete(query as CFDictionary)
        let result = SecItemAdd(query as CFDictionary, nil)
        if result != errSecSuccess {
            log.error("Keychain save failed for key \(key): \(result)")
        }
        return result == errSecSuccess
    }

    static func load(for key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }

    @discardableResult
    static func delete(for key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key,
        ]
        let result = SecItemDelete(query as CFDictionary)
        if result != errSecSuccess && result != errSecItemNotFound {
            log.error("Keychain delete failed for key \(key): \(result)")
        }
        return result == errSecSuccess || result == errSecItemNotFound
    }
}

// MARK: - Key constants
extension KeychainService {
    static let volvoRefreshToken  = "volvo.refreshToken"
    static let volvoClientID      = "volvo.clientID"
    static let volvoClientSecret  = "volvo.clientSecret"
    static let volvoVCCAPIKey     = "volvo.vccAPIKey"

    static let toyotaRefreshToken = "toyota.refreshToken"
    static let toyotaUsername     = "toyota.username"
}
