import Foundation

enum NetworkError: Error {
	case httpStatusCode(Int, Data?) // Добавляем Data для получения тела ответа при ошибках
	case urlRequestError(Error)
	case urlSessionError
	case invalidRequest
	case decodingError(Error)
}

extension URLSession {
    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionTask {
        let task = dataTask(with: request, completionHandler: { data, response, error in
            let completeOnMain: (Result<Data, Error>) -> Void = { result in
                if Thread.isMainThread {
                    completion(result)
                } else {
                    DispatchQueue.main.async { completion(result) }
                }
            }
            
            if let data = data, let response = response, let statusCode = (response as? HTTPURLResponse)?.statusCode {
                if 200 ..< 300 ~= statusCode {
                    completeOnMain(.success(data)) // 3
                } else {
                    // При HTTP ошибках передаем тело ответа для анализа
                    print("🌐 HTTP Error Response:")
                    print("   Status Code: \(statusCode)")
                    print("   Response Size: \(data.count) bytes")
                    
                    // Выводим тело ответа для анализа ошибки Unsplash API
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📄 Error Response Body: \(responseString)")
                        if responseString.contains("redirect_uri is not valid") { print("💡 Tip: Check redirect_uri parameter - should match exactly what's configured in your app") }
                        if responseString.contains("requested scope is not valid") { print("💡 Tip: Check Permissions in your Unsplash app settings") }
                        if responseString.contains("code has already been used") { print("💡 Tip: Authorization codes can only be used once. Start a new authorization flow") }
                        if responseString.contains("client_id is invalid") { print("💡 Tip: Check your access key in Constants.swift") }
                        if responseString.contains("client_secret is invalid") { print("💡 Tip: Check your secret key in Constants.swift") }
                    }
                    
                    completeOnMain(.failure(NetworkError.httpStatusCode(statusCode, data))) // 4
                }
            } else if let error = error {
                completeOnMain(.failure(NetworkError.urlRequestError(error))) // 5 
            } else {
                completeOnMain(.failure(NetworkError.urlSessionError)) // 6
            }
        })

        return task
    }
} 