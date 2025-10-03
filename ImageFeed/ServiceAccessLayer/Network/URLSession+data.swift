import Foundation

enum NetworkError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
    case invalidRequest
    case unauthorized
    case noData
    case decodingError(Error)
}

extension URLSession {
    func data(
        for request: URLRequest,
        completion: @escaping(Result<Data, Error>) -> Void
    ) -> URLSessionTask {
        let fulfillCompletionOnTheMainThread: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        
        let task = dataTask(with: request, completionHandler: { data, response, error in
            print("🔍 [URLSession] Получен ответ: data=\(data != nil ? "есть" : "нет"), response=\(response != nil ? "есть" : "нет"), error=\(error?.localizedDescription ?? "нет")")
            
            if let data = data, let response = response, let statusCode = (response as? HTTPURLResponse)?.statusCode {
                print("📊 [URLSession] HTTP статус: \(statusCode)")
                if 200 ..< 300 ~= statusCode {
                    print("✅ [URLSession] Успешный ответ, размер данных: \(data.count) байт")
                    fulfillCompletionOnTheMainThread(.success(data))
                } else {
                    print("❌ [URLSession] HTTP ошибка - код \(statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📄 [URLSession] Ответ сервера: \(responseString)")
                    }
                    fulfillCompletionOnTheMainThread(.failure(NetworkError.httpStatusCode(statusCode)))
                }
            } else if let error = error {
                print("❌ [URLSession] Ошибка запроса: \(error.localizedDescription)")
                fulfillCompletionOnTheMainThread(.failure(NetworkError.urlRequestError(error)))
            } else {
                print("❌ [URLSession] Неизвестная ошибка")
                fulfillCompletionOnTheMainThread(.failure(NetworkError.urlSessionError))
            }
        })
        
        return task
    }
}

extension URLSession {
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {
        let decoder = JSONDecoder()
        
        let task = data(for: request) { (result: Result<Data, Error>) in
            switch result {
            case .success(let data):
                print("🔍 [URLSession] Начинаем декодирование данных размером \(data.count) байт")
                do {
                    let decodedObject = try decoder.decode(T.self, from: data)
                    print("✅ [URLSession] Декодирование успешно завершено")
                    completion(.success(decodedObject))
                } catch {
                    print("❌ [URLSession] Ошибка декодирования: \(error.localizedDescription)")
                    if let dataString = String(data: data, encoding: .utf8) {
                        print("📄 [URLSession] Данные для декодирования: \(dataString.prefix(500))...")
                    }
                    completion(.failure(NetworkError.decodingError(error)))
                }

            case .failure(let error):
                print("❌ [URLSession] Ошибка получения данных: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

        return task
    }
} 