import Foundation

enum Constants {
    static let accessKey = "g4AtEFdHrB3KOinvvNvM_exFT9zS68WTjGn_zqMIDzU"
    static let secretKey = "lkSavUfOXGu9gygHPttC-BzjSg3zdXqWFVbybrvZs3o"
    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope = "public"
    static var defaultBaseURL: URL? {
        return URL(string: "https://api.unsplash.com")
    }
    static let applicationID = "797310"
    
    static func validateCredentials() -> Bool {
        return accessKey.count > 0 && secretKey.count > 0 && redirectURI.count > 0
    }
} 