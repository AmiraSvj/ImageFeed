import Foundation
import UIKit
@testable import ImageFeed

// MARK: - ImagesListService Stub
class ImagesListServiceStub: ImagesListServiceProtocol {
    var photos: [Photo] = []
    var shouldReturnError = false
    var fetchPhotosNextPageCalled = false
    var changeLikeCalled = false
    
    var lastPhotoId: String?
    var lastIsLike: Bool?
    
    func fetchPhotosNextPage() {
        fetchPhotosNextPageCalled = true
    }
    
    func changeLike(photoId: String, isLike: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        changeLikeCalled = true
        lastPhotoId = photoId
        lastIsLike = isLike
        
        if shouldReturnError {
            completion(.failure(ImagesListServiceError.networkError))
        } else {
            // Обновляем состояние лайка в массиве фотографий
            if let index = photos.firstIndex(where: { $0.id == photoId }) {
                photos[index] = Photo(
                    id: photos[index].id,
                    size: photos[index].size,
                    createdAt: photos[index].createdAt,
                    welcomeDescription: photos[index].welcomeDescription,
                    thumbImageURL: photos[index].thumbImageURL,
                    largeImageURL: photos[index].largeImageURL,
                    isLiked: isLike
                )
            }
            completion(.success(()))
        }
    }
}

// MARK: - PhotoFeedCell Protocol
protocol PhotoFeedCellProtocol {
    var photoId: String? { get set }
    func configure(with url: URL, date: String, isLiked: Bool, photoId: String, completion: @escaping () -> Void)
    func setIsLiked(_ isLiked: Bool)
}

// MARK: - PhotoFeedCell Stub
class PhotoFeedCellStub: PhotoFeedCellProtocol {
    var photoId: String?
    var configureCalled = false
    var setIsLikedCalled = false
    var lastURL: URL?
    var lastDate: String?
    var lastIsLiked: Bool?
    var lastPhotoId: String?
    var lastCompletion: (() -> Void)?
    
    func configure(with url: URL, date: String, isLiked: Bool, photoId: String, completion: @escaping () -> Void) {
        configureCalled = true
        lastURL = url
        lastDate = date
        lastIsLiked = isLiked
        lastPhotoId = photoId
        lastCompletion = completion
    }
    
    func setIsLiked(_ isLiked: Bool) {
        setIsLikedCalled = true
        lastIsLiked = isLiked
    }
}

// MARK: - PhotoFeedController Spy
class PhotoFeedControllerSpy: PhotoFeedControllerProtocol {
    var reloadDataCalled = false
    var reloadRowsCalled = false
    var presentAlertCalled = false
    var showProgressCalled = false
    var dismissProgressCalled = false
    
    var lastIndexPath: IndexPath?
    var lastAlertTitle: String?
    var lastAlertMessage: String?
    
    func reloadData() {
        reloadDataCalled = true
    }
    
    func reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        reloadRowsCalled = true
        lastIndexPath = indexPaths.first
    }
    
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        if let alert = viewControllerToPresent as? UIAlertController {
            presentAlertCalled = true
            lastAlertTitle = alert.title
            lastAlertMessage = alert.message
        }
    }
    
    func showProgress() {
        showProgressCalled = true
    }
    
    func dismissProgress() {
        dismissProgressCalled = true
    }
}

// MARK: - Error Types
enum ImagesListServiceError: Error {
    case networkError
    case invalidResponse
}

// MARK: - Protocols
protocol ImagesListServiceProtocol {
    var photos: [Photo] { get }
    func fetchPhotosNextPage()
    func changeLike(photoId: String, isLike: Bool, completion: @escaping (Result<Void, Error>) -> Void)
}

protocol PhotoFeedControllerProtocol {
    func reloadData()
    func reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation)
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
    func showProgress()
    func dismissProgress()
}

// MARK: - Test Data
extension ImagesListServiceStub {
    static func createTestPhotos(count: Int) -> [Photo] {
        return (0..<count).map { index in
            Photo(
                id: "photo_\(index)",
                size: CGSize(width: 100, height: 100),
                createdAt: Date(),
                welcomeDescription: "Test photo \(index)",
                thumbImageURL: "https://example.com/thumb_\(index).jpg",
                largeImageURL: "https://example.com/large_\(index).jpg",
                isLiked: index % 2 == 0
            )
        }
    }
}
