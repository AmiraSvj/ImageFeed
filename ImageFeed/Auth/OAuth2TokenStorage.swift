import Foundation

final class OAuth2TokenStorage {
	private let userDefaults = UserDefaults.standard
	private let tokenKey = "bearer_token"
	
	var token: String? {
		get { userDefaults.string(forKey: tokenKey) }
		set { userDefaults.set(newValue, forKey: tokenKey) }
	}
} 