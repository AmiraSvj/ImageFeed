import Foundation

// Используем стандартные NetworkError вместо AuthServiceError

final class OAuth2Service {
    static let shared = OAuth2Service()

    private let dataStorage = OAuth2TokenStorage.shared
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?

    private(set) var authToken: String? {
        get {
            return dataStorage.token
        }
        set {
            dataStorage.token = newValue
        }
    }

    private init() { }

    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        // Защита от состояния гонки: если код уже используется, возвращаем ошибку
        guard lastCode != code else {
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        // Отменяем предыдущий запрос (если он есть) и запоминаем новый код
        task?.cancel()
        lastCode = code
        
        guard let request = makeOAuthTokenRequest(code: code) else {
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.task = nil
                self.lastCode = nil
                
                switch result {
                case .success(let body):
                    let authToken = body.accessToken
                    self.authToken = authToken
                    completion(.success(authToken))
                case .failure(let error):
                    print("[fetchOAuthToken]: NetworkError - \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
        
        self.task = task
        task.resume()
    }

    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard
            var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token") 
        else {
            assertionFailure("Failed to create URL")
            return nil
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
        ]
        
        guard let authTokenUrl = urlComponents.url else {
            return nil
        }
        
        var request = URLRequest(url: authTokenUrl)
        request.httpMethod = "POST"
        return request
    }

    private struct OAuthTokenResponseBody: Codable {
        let accessToken: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
        }
    }
}

 