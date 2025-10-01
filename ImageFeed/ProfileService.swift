import Foundation
import UIKit

struct Profile {
    let username: String
    let name: String
    let loginName: String
    let bio: String?
}

struct ProfileResult: Codable {
    let username: String
    let firstName: String?
    let lastName: String?
    let name: String?
    let bio: String?

    private enum CodingKeys: String, CodingKey {
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case name
        case bio
    }
}

final class ProfileService {
    static let shared = ProfileService()
    private init() {}

    static let didChangeNotification = Notification.Name("ProfileServiceDidChange")

    private var task: URLSessionTask?
    private let urlSession = URLSession.shared
    private(set) var profile: Profile?

    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        task?.cancel()

        guard let request = makeProfileRequest(token: token) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<ProfileResult, Error>) in
            switch result {
            case .success(let profileResult):
                let composedName: String = {
                    if let name = profileResult.name, !name.isEmpty { return name }
                    let first = profileResult.firstName ?? ""
                    let last = profileResult.lastName ?? ""
                    let full = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
                    return full.isEmpty ? profileResult.username : full
                }()

                let profile = Profile(
                    username: profileResult.username,
                    name: composedName,
                    loginName: "@\(profileResult.username)",
                    bio: profileResult.bio
                )
                self?.profile = profile
                NotificationCenter.default.post(name: ProfileService.didChangeNotification, object: nil)
                completion(.success(profile))
            case .failure(let error):
                print("[ProfileService.fetchProfile]: NetworkError - \(error.localizedDescription)")
                
                // Обрабатываем ошибку 403 (Rate Limit)
                if let networkError = error as? NetworkError,
                   case .httpStatusCode(403) = networkError {
                    print("⚠️ [ProfileService] Превышен лимит запросов к Unsplash API")
                    // Показываем уведомление пользователю только если нет других алертов
                    DispatchQueue.main.async {
                        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                              let window = windowScene.windows.first,
                              window.rootViewController?.presentedViewController == nil else {
                            print("⚠️ [ProfileService] Алерт уже показан, пропускаем")
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
                
                completion(.failure(error))
            }
            self?.task = nil
        }

        self.task = task
        task.resume()
    }

    private func makeProfileRequest(token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/me") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    func clearProfile() {
        profile = nil
    }
} 