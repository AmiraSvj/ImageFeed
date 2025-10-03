import XCTest
@testable import ImageFeed

final class ProfileViewControllerTests: XCTestCase {
    
    var viewController: ProfileViewController!
    
    override func setUp() {
        super.setUp()
        // Создаем viewController из storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        viewController = storyboard.instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController
        viewController.loadViewIfNeeded()
    }
    
    override func tearDown() {
        viewController = nil
        super.tearDown()
    }
    
    // MARK: - Profile Details Update Tests
    
    func testUpdateProfileDetailsWithValidProfile() {
        // Given
        let testProfile = Profile(
            username: "test_user",
            name: "John Doe",
            loginName: "@test_user",
            bio: "Test bio"
        )
        
        // When
        viewController.updateProfileDetails(profile: testProfile)
        
        // Then
        XCTAssertEqual(viewController.nameLabel.text, "John Doe")
        XCTAssertEqual(viewController.loginNameLabel.text, "@test_user")
        XCTAssertEqual(viewController.descriptionLabel.text, "Test bio")
    }
    
    func testUpdateProfileDetailsWithEmptyName() {
        // Given
        let testProfile = Profile(
            username: "test_user",
            name: "",
            loginName: "@test_user",
            bio: "Test bio"
        )
        
        // When
        viewController.updateProfileDetails(profile: testProfile)
        
        // Then
        XCTAssertEqual(viewController.nameLabel.text, "Имя не указано")
        XCTAssertEqual(viewController.loginNameLabel.text, "@test_user")
        XCTAssertEqual(viewController.descriptionLabel.text, "Test bio")
    }
    
    func testUpdateProfileDetailsWithEmptyBio() {
        // Given
        let testProfile = Profile(
            username: "test_user",
            name: "John Doe",
            loginName: "@test_user",
            bio: ""
        )
        
        // When
        viewController.updateProfileDetails(profile: testProfile)
        
        // Then
        XCTAssertEqual(viewController.nameLabel.text, "John Doe")
        XCTAssertEqual(viewController.loginNameLabel.text, "@test_user")
        XCTAssertEqual(viewController.descriptionLabel.text, "Профиль не заполнен")
    }
    
    func testUpdateProfileDetailsWithNilBio() {
        // Given
        let testProfile = Profile(
            username: "test_user",
            name: "John Doe",
            loginName: "@test_user",
            bio: nil
        )
        
        // When
        viewController.updateProfileDetails(profile: testProfile)
        
        // Then
        XCTAssertEqual(viewController.nameLabel.text, "John Doe")
        XCTAssertEqual(viewController.loginNameLabel.text, "@test_user")
        XCTAssertEqual(viewController.descriptionLabel.text, "Профиль не заполнен")
    }
    
    // MARK: - Logout Tests
    
    func testLogoutButtonTapped() {
        // Given
        let expectation = XCTestExpectation(description: "Logout confirmation shown")
        
        // When
        viewController.didTapLogoutButton()
        
        // Then
        // Проверяем, что показывается алерт подтверждения
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.viewController.presentedViewController is UIAlertController)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLogoutConfirmationAlertContent() {
        // Given
        let expectation = XCTestExpectation(description: "Logout confirmation alert content")
        
        // When
        viewController.didTapLogoutButton()
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let alert = self.viewController.presentedViewController as? UIAlertController else {
                XCTFail("Expected UIAlertController")
                return
            }
            
            XCTAssertEqual(alert.title, "Пока, пока!")
            XCTAssertEqual(alert.message, "Уверены, что хотите выйти?")
            XCTAssertEqual(alert.actions.count, 2)
            
            let cancelAction = alert.actions.first { $0.title == "Нет" }
            let logoutAction = alert.actions.first { $0.title == "Да, выйти" }
            
            XCTAssertNotNil(cancelAction)
            XCTAssertNotNil(logoutAction)
            XCTAssertEqual(logoutAction?.style, .destructive)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - View Lifecycle Tests
    
    func testViewDidLoad() {
        // Given
        let newViewController = ProfileViewController()
        
        // When
        newViewController.viewDidLoad()
        
        // Then
        XCTAssertEqual(newViewController.view.backgroundColor, UIColor(named: "YP Black"))
    }
    
    // MARK: - Notification Tests
    
    func testProfileServiceNotificationHandling() {
        // Given
        let expectation = XCTestExpectation(description: "Profile service notification")
        
        // When
        NotificationCenter.default.post(
            name: ProfileService.didChangeNotification,
            object: nil
        )
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testProfileImageServiceNotificationHandling() {
        // Given
        let expectation = XCTestExpectation(description: "Profile image service notification")
        
        // When
        NotificationCenter.default.post(
            name: ProfileImageService.didChangeNotification,
            object: nil
        )
        
        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - UI Elements Tests
    
    func testUIElementsExist() {
        // Then
        XCTAssertNotNil(viewController.avatarImageView)
        XCTAssertNotNil(viewController.nameLabel)
        XCTAssertNotNil(viewController.loginNameLabel)
        XCTAssertNotNil(viewController.descriptionLabel)
        XCTAssertNotNil(viewController.logoutButton)
    }
    
    func testLogoutButtonAction() {
        // Given
        let logoutButton = viewController.logoutButton!
        
        // When
        let actions = logoutButton.actions(forTarget: viewController, forControlEvent: .touchUpInside)
        
        // Then
        XCTAssertNotNil(actions)
        XCTAssertTrue(actions?.contains("didTapLogoutButton") ?? false)
    }
}