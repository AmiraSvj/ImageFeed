import Foundation

// MARK: - ImagesListService
final class ImagesListService {
    static let shared = ImagesListService()
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListServiceDidChange")
    
    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    private var currentTask: URLSessionTask?
    private let urlSession = URLSession.shared
    private let tokenStorage = OAuth2TokenStorage.shared
    
    private init() {}
    
    func fetchPhotosNextPage() {
        // Проверяем, не идет ли уже загрузка
        guard currentTask == nil else { return }
        
        // Определяем номер следующей страницы
        let nextPage = (lastLoadedPage ?? 0) + 1
        
        // Создаем запрос
        guard let request = createPhotosRequest(page: nextPage, perPage: 10) else {
            print("[ImagesListService] Ошибка создания запроса")
            return
        }
        
        // Выполняем запрос
        currentTask = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            DispatchQueue.main.async {
                self?.currentTask = nil
                switch result {
                case .success(let photoResults):
                    let newPhotos = photoResults.map { Photo(from: $0) }
                    self?.photos.append(contentsOf: newPhotos)
                    self?.lastLoadedPage = nextPage
                    NotificationCenter.default.post(
                        name: ImagesListService.didChangeNotification,
                        object: self
                    )
                case .failure(let error):
                    print("[ImagesListService] Ошибка загрузки фотографий: \(error)")
                }
            }
        }
    }
    
    private func createPhotosRequest(page: Int, perPage: Int) -> URLRequest? {
        guard let token = tokenStorage.token else {
            print("[ImagesListService] Отсутствует токен авторизации")
            return nil
        }
        
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
        
        return request
    }
}
