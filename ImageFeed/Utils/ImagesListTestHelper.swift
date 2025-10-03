import Foundation

// MARK: - Test Helper для проверки функциональности ленты
class ImagesListTestHelper {
    
    /// Проверяет, что массив фотографий содержит ожидаемое количество элементов
    static func validatePhotosCount(_ photos: [Photo], expectedCount: Int) -> Bool {
        return photos.count >= expectedCount
    }
    
    /// Проверяет, что все фотографии имеют необходимые поля
    static func validatePhotoData(_ photos: [Photo]) -> Bool {
        return photos.allSatisfy { photo in
            !photo.id.isEmpty &&
            !photo.thumbImageURL.isEmpty &&
            !photo.largeImageURL.isEmpty
        }
    }
    
    /// Проверяет, что фотографии загружены в правильном порядке
    static func validatePhotosOrder(_ photos: [Photo]) -> Bool {
        // Проверяем, что фотографии отсортированы по дате создания (новые первые)
        for i in 0..<photos.count - 1 {
            guard let date1 = photos[i].createdAt,
                  let date2 = photos[i + 1].createdAt else {
                continue
            }
            
            if date1 < date2 {
                return false
            }
        }
        return true
    }
    
    /// Логирует информацию о загруженных фотографиях
    static func logPhotosInfo(_ photos: [Photo]) {
        print("=== Images List Info ===")
        print("Total photos loaded: \(photos.count)")
        
        if let firstPhoto = photos.first {
            print("First photo ID: \(firstPhoto.id)")
            print("First photo date: \(firstPhoto.createdAt?.description ?? "No date")")
        }
        
        if let lastPhoto = photos.last {
            print("Last photo ID: \(lastPhoto.id)")
            print("Last photo date: \(lastPhoto.createdAt?.description ?? "No date")")
        }
        
        print("========================")
    }
}
