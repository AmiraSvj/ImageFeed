import Foundation

struct UserResult: Codable {
    let profileImage: ProfileImage
    
    enum CodingKeys: String, CodingKey {
        case profileImage = "profile_image"
    }
}

struct ProfileImage: Codable {
    let small: String
    let medium: String
    let large: String
}

final class ProfileImageService {
    static let shared = ProfileImageService()
    
    static let didChangeNotification = Notification.Name("ProfileImageProviderDidChange")
    

    private var task: URLSessionTask?
    
    var avatarURL: String? {
        didSet {
            NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
        }
    }
    
    private init() {}
    
    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void) {
        task?.cancel()

        guard let token = OAuth2TokenStorage.shared.token else {
            completion(.failure(NSError(domain: "ProfileImageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authorization token missing"])))
            return
        }

        guard let request = makeProfileImageRequest(username: username, token: token) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            switch result {
            case .success(let userResult):
                guard let self else { return }

                self.avatarURL = userResult.profileImage.small
                completion(.success(userResult.profileImage.small))

            case .failure(let error):
                print("[ProfileImageService.fetchProfileImageURL]: NetworkError - \(error.localizedDescription) username=\(username)")
                completion(.failure(error))
            }
        }

        self.task = task
        task.resume()
    }
    
    private func makeProfileImageRequest(username: String, token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    func clearAvatarURL() {
        avatarURL = nil
        print("🔐 [ProfileImageService]: URL аватара очищен")
    }
    
    func clearAvatar() {
        clearAvatarURL()
    }
} 