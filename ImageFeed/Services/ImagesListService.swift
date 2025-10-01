import Foundation
import UIKit

// MARK: - ImagesListService
final class ImagesListService {
    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    
    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    private var currentTask: URLSessionTask?
    private var isUsingMockData = false
    private let urlSession = URLSession.shared
    private let tokenStorage = OAuth2TokenStorage.shared
    
    private init() {}
    
    func fetchPhotosNextPage() {
        print("🔄 [ImagesListService] fetchPhotosNextPage вызван")
        
        // Проверяем, не идет ли уже загрузка
        guard currentTask == nil else {
            print("⏳ [ImagesListService] Загрузка уже идет, пропускаем")
            return
        }
        
        // Если уже загружены мок-данные, не загружаем больше
        if isUsingMockData || photos.contains(where: { $0.id.hasPrefix("mock_") }) {
            print("⚠️ [ImagesListService] Мок-данные уже загружены, пропускаем загрузку")
            return
        }
        
        // Определяем номер следующей страницы
        let nextPage = (lastLoadedPage ?? 0) + 1
        print("📄 [ImagesListService] Загружаем страницу: \(nextPage)")
        
        // Создаем запрос
        guard let request = createPhotosRequest(page: nextPage, perPage: 10) else {
            print("❌ [ImagesListService] Ошибка создания запроса")
            return
        }
        
        print("🌐 [ImagesListService] Отправляем запрос: \(request.url?.absoluteString ?? "unknown")")
        
        // Выполняем запрос
        print("🚀 [ImagesListService] Начинаем выполнение запроса...")
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            print("📡 [ImagesListService] Получен ответ от сервера")
            DispatchQueue.main.async {
                self?.currentTask = nil
                print("🔄 [ImagesListService] Обрабатываем результат на главном потоке")
                switch result {
                case .success(let photoResults):
                    print("✅ [ImagesListService] Получено \(photoResults.count) фотографий")
                    let newPhotos = photoResults.map { Photo(from: $0) }
                    self?.photos.append(contentsOf: newPhotos)
                    self?.lastLoadedPage = nextPage
                    print("📊 [ImagesListService] Всего фотографий: \(self?.photos.count ?? 0)")
                    print("🔔 [ImagesListService] Отправляем уведомление didChangeNotification")
                    
                    NotificationCenter.default.post(
                        name: ImagesListService.didChangeNotification,
                        object: self
                    )
                case .failure(let error):
                    print("❌ [ImagesListService] Ошибка загрузки фотографий: \(error)")
                    
                    // Проверяем, является ли это ошибкой 403 (Rate Limit)
                    if let networkError = error as? NetworkError,
                       case .httpStatusCode(403) = networkError {
                        print("⚠️ [ImagesListService] Превышен лимит запросов к Unsplash API")
                        
                        // Загружаем мок-данные вместо реальных фотографий
                        self?.loadMockPhotos()
                    }
                    
                    // Проверяем, является ли это ошибкой 429 (Rate Limit)
                    if let urlError = error as? URLError {
                        print("🌐 [ImagesListService] URLError код: \(urlError.code.rawValue)")
                        if urlError.code == .timedOut {
                            print("⏰ [ImagesListService] Таймаут запроса")
                        }
                    }
                    
                    // Показываем уведомление об ошибке пользователю только если нет других алертов
                    DispatchQueue.main.async {
                        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                              let window = windowScene.windows.first,
                              window.rootViewController?.presentedViewController == nil else {
                            print("⚠️ [ImagesListService] Алерт уже показан, пропускаем")
                            return
                        }
                        
                        let alert = UIAlertController(
                            title: "Превышен лимит запросов",
                            message: "Превышен лимит запросов к Unsplash API. Попробуйте позже.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        
                        window.rootViewController?.present(alert, animated: true)
                    }
                }
            }
        }
        
        currentTask = task
        task.resume()
    }
    
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        print("❤️ [ImagesListService] changeLike вызван для photoId: \(photoId), isLike: \(isLike)")
        
        guard let token = tokenStorage.token else {
            print("❌ [ImagesListService] Отсутствует токен авторизации")
            completion(.failure(NetworkError.unauthorized))
            return
        }
        
        guard let request = createLikeRequest(photoId: photoId, isLike: isLike, token: token) else {
            print("❌ [ImagesListService] Ошибка создания запроса лайка")
            completion(.failure(NetworkError.invalidRequest))
            return
        }
        
        print("🌐 [ImagesListService] Отправляем запрос лайка: \(request.url?.absoluteString ?? "unknown")")
        print("🔍 [ImagesListService] HTTP метод: \(request.httpMethod ?? "unknown")")
        print("🔍 [ImagesListService] Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        // Используем обычный dataTask для отладки
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            print("📡 [ImagesListService] Получен ответ на запрос лайка")
            print("🔍 [ImagesListService] Data: \(data != nil ? "есть" : "нет")")
            print("🔍 [ImagesListService] Response: \(response != nil ? "есть" : "нет")")
            print("🔍 [ImagesListService] Error: \(error?.localizedDescription ?? "нет")")
            
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ [ImagesListService] Ошибка запроса лайка: \(error)")
                    if let urlError = error as? URLError {
                        print("🔍 [ImagesListService] URLError код: \(urlError.code.rawValue)")
                        print("🔍 [ImagesListService] URLError описание: \(urlError.localizedDescription)")
                        
                        if urlError.code == .timedOut {
                            print("⏰ [ImagesListService] Запрос превысил таймаут")
                        }
                    }
                    completion(.failure(error))
                    return
                }
                
                guard let data = data, let response = response else {
                    print("❌ [ImagesListService] Нет данных или ответа")
                    completion(.failure(NetworkError.noData))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 [ImagesListService] HTTP статус: \(httpResponse.statusCode)")
                    
                    if 200..<300 ~= httpResponse.statusCode {
                        print("✅ [ImagesListService] Лайк успешно изменен")
                        
                        // Парсим ответ
                        do {
                            let likeResponse = try JSONDecoder().decode(LikeResponse.self, from: data)
                            print("🔍 [ImagesListService] Новое состояние лайка: \(likeResponse.photo.likedByUser)")
                            self?.updatePhotoLikeStatus(photoId: photoId, isLiked: likeResponse.photo.likedByUser)
                            completion(.success(()))
                        } catch {
                            print("❌ [ImagesListService] Ошибка декодирования ответа: \(error)")
                            if let dataString = String(data: data, encoding: .utf8) {
                                print("📄 [ImagesListService] Ответ сервера: \(dataString)")
                            }
                            completion(.failure(NetworkError.decodingError(error)))
                        }
                    } else {
                        print("❌ [ImagesListService] HTTP ошибка: \(httpResponse.statusCode)")
                        if let dataString = String(data: data, encoding: .utf8) {
                            print("📄 [ImagesListService] Ответ сервера: \(dataString)")
                        }
                        completion(.failure(NetworkError.httpStatusCode(httpResponse.statusCode)))
                    }
                } else {
                    print("❌ [ImagesListService] Неверный тип ответа")
                    completion(.failure(NetworkError.urlSessionError))
                }
            }
        }
        
        // Добавляем таймер для отслеживания зависших запросов
        DispatchQueue.main.asyncAfter(deadline: .now() + 35.0) {
            if task.state == .running {
                print("⚠️ [ImagesListService] Запрос лайка все еще выполняется через 35 секунд")
                task.cancel()
            }
        }
        
        print("🚀 [ImagesListService] Задача лайка запущена: \(task.taskIdentifier)")
        task.resume() // ВАЖНО: запускаем задачу!
    }
    
    private func updatePhotoLikeStatus(photoId: String, isLiked: Bool) {
        print("🔄 [ImagesListService] Обновляем статус лайка для photoId: \(photoId), isLiked: \(isLiked)")
        
        if let index = photos.firstIndex(where: { $0.id == photoId }) {
            let photo = photos[index]
            print("🔍 [ImagesListService] Найден фото с индексом: \(index), текущий статус лайка: \(photo.isLiked)")
            
            let newPhoto = Photo(
                id: photo.id,
                size: photo.size,
                createdAt: photo.createdAt,
                welcomeDescription: photo.welcomeDescription,
                thumbImageURL: photo.thumbImageURL,
                largeImageURL: photo.largeImageURL,
                isLiked: isLiked
            )
            photos[index] = newPhoto
            
            print("✅ [ImagesListService] Статус лайка обновлен в локальной модели")
            
            // Отправляем уведомление об изменении
            NotificationCenter.default.post(
                name: ImagesListService.didChangeNotification,
                object: self
            )
            print("🔔 [ImagesListService] Отправлено уведомление об изменении лайка")
        } else {
            print("❌ [ImagesListService] Фото с photoId: \(photoId) не найдено в локальной модели")
        }
    }
    
    private func createLikeRequest(photoId: String, isLike: Bool, token: String) -> URLRequest? {
        let urlString = "\(Constants.defaultBaseURL)/photos/\(photoId)/like"
        guard let url = URL(string: urlString) else {
            print("❌ [ImagesListService] Ошибка создания URL для лайка")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("v1", forHTTPHeaderField: "Accept-Version")
        request.httpMethod = isLike ? "POST" : "DELETE"
        request.timeoutInterval = 30.0 // Увеличиваем таймаут до 30 секунд
        
        return request
    }
    
    func clearPhotos() {
        photos = []
        lastLoadedPage = nil
        currentTask?.cancel()
        currentTask = nil
        isUsingMockData = false
        print("🔐 [ImagesListService]: Список фотографий очищен")
    }
    
    private func loadMockPhotos() {
        print("🎭 [ImagesListService] Загружаем мок-данные вместо реальных фотографий")
        
        // Проверяем, не загружены ли уже мок-данные
        if isUsingMockData || photos.contains(where: { $0.id.hasPrefix("mock_") }) {
            print("⚠️ [ImagesListService] Мок-данные уже загружены, пропускаем")
            return
        }
        
        // Создаем мок-фотографии
        let mockPhotos = (0..<10).map { index in
            Photo(
                id: "mock_\(index)",
                size: CGSize(width: 1000, height: 1000),
                createdAt: Date(),
                welcomeDescription: "Mock photo \(index + 1)",
                thumbImageURL: "mock://\(index)",
                largeImageURL: "mock://\(index)",
                isLiked: Bool.random()
            )
        }
        
        photos = mockPhotos
        lastLoadedPage = 1
        isUsingMockData = true
        
        print("✅ [ImagesListService] Загружено \(mockPhotos.count) мок-фотографий")
        
        // Отправляем уведомление об обновлении
        NotificationCenter.default.post(
            name: ImagesListService.didChangeNotification,
            object: self
        )
    }
    
    private func createPhotosRequest(page: Int, perPage: Int) -> URLRequest? {
        guard let token = tokenStorage.token else {
            print("❌ [ImagesListService] Отсутствует токен авторизации")
            return nil
        }
        print("🔑 [ImagesListService] Токен найден: \(token.prefix(10))...")
        
        var urlComponents = URLComponents(string: "\(Constants.defaultBaseURL)/photos")
        urlComponents?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "order_by", value: "latest")
        ]
        
        guard let url = urlComponents?.url else {
            print("[ImagesListService] Ошибка создания URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0 // 10 секунд таймаут
        
        return request
    }
}

