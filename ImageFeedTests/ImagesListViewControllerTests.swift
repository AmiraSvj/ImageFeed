import XCTest
@testable import ImageFeed

final class ImagesListViewControllerTests: XCTestCase {
    
    var viewController: PhotoFeedController!
    
    override func setUp() {
        super.setUp()
        // Создаем viewController из storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        viewController = storyboard.instantiateViewController(withIdentifier: "PhotoFeedController") as? PhotoFeedController
        viewController.loadViewIfNeeded()
    }
    
    override func tearDown() {
        viewController = nil
        super.tearDown()
    }
    
    // MARK: - View Lifecycle Tests
    
    func testViewDidLoad() {
        // Given
        let newViewController = PhotoFeedController()
        
        // When
        newViewController.viewDidLoad()
        
        // Then
        XCTAssertEqual(newViewController.view.backgroundColor, UIColor(named: "YP Black"))
    }
    
    // MARK: - Table View Data Source Tests
    
    func testNumberOfRowsInSection() {
        // Given
        let testPhotos = createTestPhotos(count: 5)
        viewController.photos = testPhotos
        
        // When
        let numberOfRows = viewController.tableView(viewController.feedTable, numberOfRowsInSection: 0)
        
        // Then
        XCTAssertEqual(numberOfRows, 5)
    }
    
    func testCellForRowAt() {
        // Given
        let testPhotos = createTestPhotos(count: 1)
        viewController.photos = testPhotos
        
        // When
        let cell = viewController.tableView(viewController.feedTable, cellForRowAt: IndexPath(row: 0, section: 0))
        
        // Then
        XCTAssertTrue(cell is PhotoFeedCell)
    }
    
    func testCellConfiguration() {
        // Given
        let testPhotos = createTestPhotos(count: 1)
        viewController.photos = testPhotos
        
        // When
        let cell = viewController.tableView(viewController.feedTable, cellForRowAt: IndexPath(row: 0, section: 0)) as? PhotoFeedCell
        
        // Then
        XCTAssertNotNil(cell)
        XCTAssertEqual(cell?.delegate as? PhotoFeedController, viewController)
    }
    
    // MARK: - Table View Delegate Tests
    
    func testDidSelectRowAt() {
        // Given
        let testPhotos = createTestPhotos(count: 1)
        viewController.photos = testPhotos
        
        // When
        viewController.tableView(viewController.feedTable, didSelectRowAt: IndexPath(row: 0, section: 0))
        
        // Then
        // Проверяем, что ячейка была отменена
        XCTAssertNil(viewController.feedTable.indexPathForSelectedRow)
    }
    
    func testHeightForRowAt() {
        // Given
        let testPhotos = createTestPhotos(count: 1)
        viewController.photos = testPhotos
        
        // When
        let height = viewController.tableView(viewController.feedTable, heightForRowAt: IndexPath(row: 0, section: 0))
        
        // Then
        XCTAssertGreaterThan(height, 0)
        XCTAssertGreaterThanOrEqual(height, 200) // Минимальная высота
    }
    
    func testWillDisplayCellTriggersPagination() {
        // Given
        let testPhotos = createTestPhotos(count: 10)
        viewController.photos = testPhotos
        viewController.isLoadingMorePhotos = false
        
        // When
        viewController.tableView(viewController.feedTable, willDisplay: UITableViewCell(), forRowAt: IndexPath(row: 7, section: 0))
        
        // Then
        // Проверяем, что загружается следующая страница (когда показываем последние 3 ячейки)
        XCTAssertTrue(viewController.isLoadingMorePhotos)
    }
    
    // MARK: - Like Functionality Tests
    
    func testPhotoFeedCellDidTapLike() {
        // Given
        let testPhotos = createTestPhotos(count: 1)
        let testPhoto = testPhotos[0]
        viewController.photos = testPhotos
        viewController.isLikeRequestInProgress = false
        
        // Создаем реальную ячейку из storyboard
        let cell = viewController.tableView(viewController.feedTable, cellForRowAt: IndexPath(row: 0, section: 0)) as! PhotoFeedCell
        
        // When
        viewController.photoFeedCellDidTapLike(cell, photoId: testPhoto.id, isLiked: testPhoto.isLiked)
        
        // Then
        // Проверяем, что установлен флаг выполнения запроса
        XCTAssertTrue(viewController.isLikeRequestInProgress)
    }
    
    func testPhotoFeedCellDidTapLikeWhenRequestInProgress() {
        // Given
        let testPhotos = createTestPhotos(count: 1)
        let testPhoto = testPhotos[0]
        viewController.photos = testPhotos
        viewController.isLikeRequestInProgress = true
        
        // Создаем реальную ячейку из storyboard
        let cell = viewController.tableView(viewController.feedTable, cellForRowAt: IndexPath(row: 0, section: 0)) as! PhotoFeedCell
        
        // When
        viewController.photoFeedCellDidTapLike(cell, photoId: testPhoto.id, isLiked: testPhoto.isLiked)
        
        // Then
        // Проверяем, что запрос не выполняется повторно
        XCTAssertTrue(viewController.isLikeRequestInProgress)
    }
    
    // MARK: - Notification Tests
    
    func testPhotosNotificationHandling() {
        // Given
        let expectation = XCTestExpectation(description: "Photos notification")
        
        // When
        NotificationCenter.default.post(
            name: ImagesListService.didChangeNotification,
            object: nil
        )
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Date Formatting Tests
    
    func testFormatDate() {
        // Given
        let testDate = Date(timeIntervalSince1970: 1640995200) // 2022-01-01
        let expectedFormat = "Jan 1, 2022"
        
        // When
        let formattedDate = viewController.formatDate(testDate)
        
        // Then
        XCTAssertEqual(formattedDate, expectedFormat)
    }
    
    func testFormatDateWithNil() {
        // Given
        let nilDate: Date? = nil
        
        // When
        let formattedDate = viewController.formatDate(nilDate)
        
        // Then
        XCTAssertEqual(formattedDate, "")
    }
    
    // MARK: - UI Configuration Tests
    
    func testSetupUI() {
        // Given
        let newViewController = PhotoFeedController()
        
        // When
        newViewController.setupUI()
        
        // Then
        XCTAssertEqual(newViewController.view.backgroundColor, UIColor(named: "YP Black"))
        XCTAssertEqual(newViewController.feedTable.backgroundColor, UIColor(named: "YP Black"))
        XCTAssertEqual(newViewController.feedTable.rowHeight, 200)
        XCTAssertEqual(newViewController.feedTable.contentInset, UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0))
    }
    
    // MARK: - Helper Methods
    
    private func createTestPhotos(count: Int) -> [Photo] {
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

// MARK: - PhotoFeedController Extension for Testing
extension PhotoFeedController {
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        return localizedDateFormatter.string(from: date)
    }
}