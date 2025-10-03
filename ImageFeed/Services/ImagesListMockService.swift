import Foundation

// MARK: - Mock Service для тестирования без авторизации
final class ImagesListMockService {
    static let shared = ImagesListMockService()
    static let didChangeNotification = Notification.Name(rawValue: "ImagesListMockServiceDidChange")
    
    private(set) var photos: [Photo] = []
    private var lastLoadedPage: Int?
    
    private init() {}
    
    func fetchPhotosNextPage() {
        print("🔄 [ImagesListMockService] fetchPhotosNextPage вызван")
        
        let nextPage = (lastLoadedPage ?? 0) + 1
        print("📄 [ImagesListMockService] Загружаем моковую страницу: \(nextPage)")
        
        // Создаем моковые фотографии
        let mockPhotos = createMockPhotos(page: nextPage)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.photos.append(contentsOf: mockPhotos)
            self?.lastLoadedPage = nextPage
            
            print("✅ [ImagesListMockService] Добавлено \(mockPhotos.count) моковых фотографий")
            print("📊 [ImagesListMockService] Всего фотографий: \(self?.photos.count ?? 0)")
            
            NotificationCenter.default.post(
                name: ImagesListMockService.didChangeNotification,
                object: self
            )
        }
    }
    
    private func createMockPhotos(page: Int) -> [Photo] {
        var photos: [Photo] = []
        
        // Используем локальные изображения из Assets для мок-данных
        let mockImageNames = [
            "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
            "10", "11", "12", "13", "14", "15", "16", "17", "18", "19"
        ]
        
        for i in 1...10 {
            let photoId = "mock_\(page)_\(i)"
            let imageIndex = ((page - 1) * 10 + i - 1) % mockImageNames.count
            let imageName = mockImageNames[imageIndex]
            
            // Создаем URL для локального изображения
            let thumbURL = "mock://\(imageName)"
            let largeURL = "mock://\(imageName)"
            
            let photo = Photo(
                id: photoId,
                size: CGSize(width: 400, height: 300 + i * 20), // Разные размеры
                createdAt: Date().addingTimeInterval(-Double(i * 3600)), // Разные даты
                welcomeDescription: "Mock photo \(page)-\(i) (\(imageName))",
                thumbImageURL: thumbURL,
                largeImageURL: largeURL,
                isLiked: i % 3 == 0 // Каждая третья фотография лайкнута
            )
            photos.append(photo)
        }
        
        return photos
    }
}

