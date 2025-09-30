import Foundation

// MARK: - Validation Protocol
protocol Validatable {
    func validate() -> Bool
}

// MARK: - OAuth Token Response Model
struct OAuthTokenResponseBody: Decodable, Validatable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let createdAt: Int
    
    // Опциональные поля, которые могут прийти от Unsplash
    let refreshToken: String?
    let expiresIn: Int?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case createdAt = "created_at"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
    
    // MARK: - Validation
    func validate() -> Bool {
        // Проверяем, что обязательные поля не пустые
        guard accessToken.count > 0,
              tokenType.count > 0,
              scope.count > 0,
              createdAt > 0 else {
            return false
        }
        
        // Проверяем, что token_type равен "bearer"
        guard tokenType.lowercased() == "bearer" else {
            return false
        }
        
        return true
    }
    
    // MARK: - Custom Initializer with Validation
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        accessToken = try container.decode(String.self, forKey: .accessToken)
        tokenType = try container.decode(String.self, forKey: .tokenType)
        scope = try container.decode(String.self, forKey: .scope)
        createdAt = try container.decode(Int.self, forKey: .createdAt)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        expiresIn = try container.decodeIfPresent(Int.self, forKey: .expiresIn)
        
        // Валидируем данные после декодирования
        guard validate() else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Invalid OAuth token response data"
            ))
        }
    }
}

final class OAuth2Service {
    static let shared = OAuth2Service() // 1
    
    private init() {} // 2
    
    private let storage = OAuth2TokenStorage()
    private var isFetching = false
    
    // MARK: - OAuth Token Request
    /// Собирает URLRequest для обмена кода авторизации на access_token.
    /// Используются URLComponents: схема, хост, путь и параметры запроса.
    /// Метод запроса — POST.
    private func makeOAuthTokenRequest(code: String) -> Result<URLRequest, Error> {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "unsplash.com"
        components.path = "/oauth/token"
        
        guard let url = components.url else {
            return .failure(NetworkError.invalidRequest)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "client_id": Constants.accessKey,
            "client_secret": Constants.secretKey,
            "redirect_uri": Constants.redirectURI,
            "code": code,
            "grant_type": "authorization_code"
        ]
        let bodyString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        return .success(request)
    }
    
    // MARK: - Networking
    /// Выполняет запрос обмена кода на токен, сохраняет Bearer-токен и возвращает его.
    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Если токен уже есть — возвращаем сразу
        if let existing = storage.token {
            DispatchQueue.main.async { completion(.success(existing)) }
            return
        }
        // Не даём параллельные запросы
        if isFetching { return }
        isFetching = true
        
        switch makeOAuthTokenRequest(code: code) {
        case .failure(let error):
            isFetching = false
            DispatchQueue.main.async { completion(.failure(error)) }
            return
        case .success(let request):
            let task = URLSession.shared.data(for: request) { [weak self] result in
                guard let self = self else { return }
                self.isFetching = false
                
                switch result {
                case .success(let data):
                    // Проверяем, что данные не пустые
                    guard data.count > 0 else {
                        print("❌ Empty response data received")
                        DispatchQueue.main.async {
                            completion(.failure(NetworkError.decodingError(NSError(domain: "EmptyData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty response data"]))))
                        }
                        return
                    }
                    
                    print("✅ Success response received")
                    print("📊 Response data size: \(data.count) bytes")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📄 Response body: \(responseString)")
                    }
                    
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .useDefaultKeys
                        decoder.dateDecodingStrategy = .secondsSince1970
                        
                        let response = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                        guard response.validate() else {
                            print("❌ Validation failed for decoded response")
                            DispatchQueue.main.async {
                                completion(.failure(NetworkError.decodingError(NSError(domain: "ValidationError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Response validation failed"]))))
                            }
                            return
                        }
                        let bearer = response.accessToken
                        self.storage.token = bearer
                        DispatchQueue.main.async { completion(.success(bearer)) }
                    } catch {
                        print("❌ JSON decoding error: \(error)")
                        DispatchQueue.main.async { completion(.failure(NetworkError.decodingError(error))) }
                    }
                case .failure(let error):
                    print("❌ Request failed with error: \(error)")
                    DispatchQueue.main.async { completion(.failure(error)) }
                }
            }
            task.resume()
        }
    }
} 