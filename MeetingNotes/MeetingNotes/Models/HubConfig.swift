import Foundation

struct HubConfig: Codable {
    var baseURL: String
    var apiKey: String

    static let keychainService = "com.meetingnotes.hub"
    static let urlKey = "hubBaseURL"
    static let apiKeyKey = "hubAPIKey"

    static func load() -> HubConfig? {
        guard let url = KeychainHelper.load(key: urlKey),
              let apiKey = KeychainHelper.load(key: apiKeyKey) else { return nil }
        return HubConfig(baseURL: url, apiKey: apiKey)
    }

    func save() {
        KeychainHelper.save(key: HubConfig.urlKey, value: baseURL)
        KeychainHelper.save(key: HubConfig.apiKeyKey, value: apiKey)
    }
}

enum KeychainHelper {
    static func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: HubConfig.keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: HubConfig.keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
