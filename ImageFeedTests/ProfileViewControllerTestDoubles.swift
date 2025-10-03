import Foundation
@testable import ImageFeed

// MARK: - ProfileService Stub
class ProfileServiceStub: ProfileServiceProtocol {
    var profile: Profile?
    var shouldReturnError = false
    
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        if shouldReturnError {
            completion(.failure(ProfileServiceError.networkError))
        } else {
            completion(.success(profile ?? Profile(username: "test_user", name: "Test User", loginName: "@test_user", bio: "Test bio")))
        }
    }
}

// MARK: - ProfileImageService Stub
class ProfileImageServiceStub: ProfileImageServiceProtocol {
    var avatarURL: String?
    var shouldReturnError = false
    
    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void) {
        if shouldReturnError {
            completion(.failure(ProfileImageServiceError.networkError))
        } else {
            completion(.success(avatarURL ?? "https://example.com/avatar.jpg"))
        }
    }
}

// MARK: - ProfileLogoutService Stub
class ProfileLogoutServiceStub: ProfileLogoutServiceProtocol {
    var logoutCalled = false
    
    func logout() {
        logoutCalled = true
    }
}

// MARK: - ProfileViewController Spy
class ProfileViewControllerSpy: ProfileViewControllerProtocol {
    var updateProfileDetailsCalled = false
    var updateAvatarCalled = false
    var showLogoutConfirmationCalled = false
    var switchToSplashScreenCalled = false
    var setupGradientAnimationsCalled = false
    var stopGradientAnimationsCalled = false
    
    var lastProfile: Profile?
    var lastAvatarURL: String?
    
    func updateProfileDetails(profile: Profile) {
        updateProfileDetailsCalled = true
        lastProfile = profile
    }
    
    func updateAvatar() {
        updateAvatarCalled = true
    }
    
    func showLogoutConfirmation() {
        showLogoutConfirmationCalled = true
    }
    
    func switchToSplashScreen() {
        switchToSplashScreenCalled = true
    }
    
    func setupGradientAnimations() {
        setupGradientAnimationsCalled = true
    }
    
    func stopGradientAnimations() {
        stopGradientAnimationsCalled = true
    }
}

// MARK: - Error Types
enum ProfileServiceError: Error {
    case networkError
}

enum ProfileImageServiceError: Error {
    case networkError
}

// MARK: - Protocols
protocol ProfileServiceProtocol {
    var profile: Profile? { get }
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void)
}

protocol ProfileImageServiceProtocol {
    var avatarURL: String? { get }
    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void)
}

protocol ProfileLogoutServiceProtocol {
    func logout()
}

protocol ProfileViewControllerProtocol {
    func updateProfileDetails(profile: Profile)
    func updateAvatar()
    func showLogoutConfirmation()
    func switchToSplashScreen()
    func setupGradientAnimations()
    func stopGradientAnimations()
}
