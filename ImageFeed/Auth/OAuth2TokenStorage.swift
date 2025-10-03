import Foundation
import SwiftKeychainWrapper

final class OAuth2TokenStorage {
    static let shared = OAuth2TokenStorage()
    private init() {}
    
    private let tokenKey = "token"

    var token: String? {
        get {
            let token = KeychainWrapper.standard.string(forKey: tokenKey)
            print("🔑 [OAuth2TokenStorage] Получение токена: \(token != nil ? "найден" : "не найден")")
            return token
        }
        set {
            if let token = newValue {
                print("💾 [OAuth2TokenStorage] Сохранение токена: \(token.prefix(10))...")
                _ = KeychainWrapper.standard.set(token, forKey: tokenKey)
            } else {
                print("🗑️ [OAuth2TokenStorage] Удаление токена")
                _ = KeychainWrapper.standard.removeObject(forKey: tokenKey)
            }
        }
    }
} 