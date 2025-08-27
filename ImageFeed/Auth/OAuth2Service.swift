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
        guard !accessToken.isEmpty,
              !tokenType.isEmpty,
              !scope.isEmpty,
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
    private func makeOAuthTokenRequest(code: String) -> URLRequest {
        let url = URL(string: "https://unsplash.com/oauth/token")!
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
        
        return request
    }
    
    // MARK: - Networking
    /// Выполняет запрос обмена кода на токен, сохраняет Bearer-токен и возвращает его.
    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Если токен уже есть — возвращаем сразу
        if let existing = storage.token {
            completion(.success(existing))
            return
        }
        // Не даём параллельные запросы
        if isFetching { return }
        isFetching = true
        
        let request = makeOAuthTokenRequest(code: code)
        
        // MARK: - Использование расширения URLSession
        // В этом проекте предлагаем попробовать ещё один способ оформления работы: 
        // использовать расширение к URLSession вместо NetworkClient
        
        let task = URLSession.shared.data(for: request) { [weak self] result in
            guard let self = self else { return }
            self.isFetching = false
            
            switch result {
            case .success(let data):
                // Проверяем, что данные не пустые
                guard !data.isEmpty else {
                    print("❌ Empty response data received")
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.decodingError(NSError(domain: "EmptyData", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty response data"]))))
                    }
                    return
                }
                
                // 2. Если он попадает в интервал 200..<300, через вызов completion «верните» полученные данные через Result.success
                print("✅ Success response received")
                print("📊 Response data size: \(data.count) bytes")
                
                // Пытаемся вывести тело ответа как строку для отладки
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Response body: \(responseString)")
                }
                
                do {
                    let decoder = JSONDecoder()
                    // Настраиваем декодер для более гибкого парсинга
                    decoder.keyDecodingStrategy = .useDefaultKeys
                    decoder.dateDecodingStrategy = .secondsSince1970
                    
                    let response = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                    
                    // Дополнительная валидация после декодирования
                    guard response.validate() else {
                        print("❌ Validation failed for decoded response")
                        DispatchQueue.main.async {
                            completion(.failure(NetworkError.decodingError(NSError(domain: "ValidationError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Response validation failed"]))))
                        }
                        return
                    }
                    
                    let bearer = response.accessToken
                    
                    print("🔑 Successfully decoded and validated access token: \(String(bearer.prefix(10)))...")
                    print("📋 Token type: \(response.tokenType)")
                    print("🔒 Scope: \(response.scope)")
                    print("⏰ Created at: \(response.createdAt)")
                    
                    if let refreshToken = response.refreshToken {
                        print("🔄 Refresh token available: \(String(refreshToken.prefix(10)))...")
                    }
                    
                    if let expiresIn = response.expiresIn {
                        print("⏳ Token expires in: \(expiresIn) seconds")
                    }
                    
                    self.storage.token = bearer
                    // Этот блок можно вызвать на главном потоке
                    DispatchQueue.main.async {
                        completion(.success(bearer))
                    }
                } catch let DecodingError.keyNotFound(key, context) {
                    print("❌ JSON decoding error: Missing key '\(key.stringValue)' at path: \(context.codingPath)")
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.decodingError(DecodingError.keyNotFound(key, context))))
                    }
                } catch let DecodingError.typeMismatch(type, context) {
                    print("❌ JSON decoding error: Type mismatch for type '\(type)' at path: \(context.codingPath)")
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.decodingError(DecodingError.typeMismatch(type, context))))
                    }
                } catch let DecodingError.valueNotFound(type, context) {
                    print("❌ JSON decoding error: Value not found for type '\(type)' at path: \(context.codingPath)")
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.decodingError(DecodingError.valueNotFound(type, context))))
                    }
                } catch let DecodingError.dataCorrupted(context) {
                    print("❌ JSON decoding error: Data corrupted at path: \(context.codingPath)")
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.decodingError(DecodingError.dataCorrupted(context))))
                    }
                } catch {
                    print("❌ Unexpected JSON decoding error: \(error)")
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.decodingError(error)))
                    }
                }
                
            case .failure(let error):
                // 3. В случае неуспешного статус-кода или получения сетевой ошибки надо «вернуть» её через Result.failure
                print("❌ Request failed with error: \(error)")
                
                // Детальная обработка ошибок Unsplash API
                if case let NetworkError.httpStatusCode(statusCode, responseData) = error {
                    print("🌐 HTTP Status Code: \(statusCode)")
                    
                    // Анализируем тело ответа при ошибке, если оно доступно
                    if let data = responseData, !data.isEmpty {
                        print("📊 Error Response Data Size: \(data.count) bytes")
                        
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("📄 Error Response Body: \(responseString)")
                            
                            // Дополнительный анализ ошибок на основе тела ответа
                            if responseString.contains("redirect_uri is not valid") {
                                print("🔍 Specific Error: redirect_uri is not valid")
                                print("💡 Solution: Check that redirect_uri in your request matches exactly what's configured in your Unsplash app")
                                print("   Current value: \(Constants.redirectURI)")
                            }
                            if responseString.contains("requested scope is not valid") {
                                print("🔍 Specific Error: requested scope is not valid")
                                print("💡 Solution: Check Permissions in your Unsplash app settings")
                                print("   Current scope: \(Constants.accessScope)")
                            }
                            if responseString.contains("code has already been used") {
                                print("🔍 Specific Error: code has already been used")
                                print("💡 Solution: Authorization codes can only be used once. Start a new authorization flow")
                            }
                            if responseString.contains("client_id is invalid") {
                                print("🔍 Specific Error: client_id is invalid")
                                print("💡 Solution: Check your access key in Constants.swift")
                                print("   Current access key: \(String(Constants.accessKey.prefix(10)))...")
                            }
                            if responseString.contains("client_secret is invalid") {
                                print("🔍 Specific Error: client_secret is invalid")
                                print("💡 Solution: Check your secret key in Constants.swift")
                                print("   Current secret key: \(String(Constants.secretKey.prefix(10)))...")
                            }
                            if responseString.contains("invalid_client") {
                                print("🔍 Specific Error: invalid_client")
                                print("💡 Solution: This usually means the client_secret is not being sent correctly")
                                print("   - Make sure client_secret is in POST body, not URL parameters")
                                print("   - Check that Content-Type is 'application/x-www-form-urlencoded'")
                                print("   - Verify your app credentials in Unsplash dashboard")
                                print("   - Current access key: \(String(Constants.accessKey.prefix(10)))...")
                                print("   - Current secret key: \(String(Constants.secretKey.prefix(10)))...")
                            }
                        }
                    } else {
                        print("💡 Tip: Check the response body for detailed error information from Unsplash API")
                    }
                    
                    // Специфичные сообщения для известных ошибок Unsplash API
                    switch statusCode {
                    case 400:
                        print("🔍 Common 400 errors from Unsplash API:")
                        print("   - 'redirect_uri is not valid' - Check redirect_uri parameter spelling and value")
                        print("   - 'requested scope is not valid' - Check Permissions in your app settings")
                        print("   - 'code has already been used' - Authorization code can only be used once")
                        print("   - 'grant_type is invalid' - Should be 'authorization_code'")
                    case 401:
                        print("🔍 Common 401 errors from Unsplash API:")
                        print("   - 'client_id is invalid' - Check your access key")
                        print("   - 'client_secret is invalid' - Check your secret key")
                        print("   - 'Invalid client' - Verify your app credentials")
                    case 403:
                        print("🔍 Common 403 errors from Unsplash API:")
                        print("   - 'Forbidden' - Check your app permissions and rate limits")
                        print("   - 'Insufficient scope' - Your app doesn't have required permissions")
                    case 422:
                        print("🔍 Common 422 errors from Unsplash API:")
                        print("   - 'Unprocessable Entity' - Request format is correct but semantically invalid")
                        print("   - 'Invalid parameters' - Check all required parameters")
                    case 429:
                        print("🔍 Common 429 errors from Unsplash API:")
                        print("   - 'Too Many Requests' - Rate limit exceeded, wait before retrying")
                    case 500...599:
                        print("🔍 Server error from Unsplash API:")
                        print("   - Internal server error, try again later")
                        print("   - Check Unsplash API status page")
                    default:
                        print("🔍 Unknown HTTP status code: \(statusCode)")
                        print("   - Check Unsplash API documentation for this status code")
                    }
                }
                
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
    }
} 