import Foundation
import SwiftKeychainWrapper

final class OAuth2TokenStorage {
    static let shared = OAuth2TokenStorage()
    private init() {}
    
    private let tokenKey = "token"

    var token: String? {
        get {
            return KeychainWrapper.standard.string(forKey: tokenKey)
        }
        set {
            if let token = newValue {
                _ = KeychainWrapper.standard.set(token, forKey: tokenKey)
            } else {
                _ = KeychainWrapper.standard.removeObject(forKey: tokenKey)
            }
        }
    }
} 