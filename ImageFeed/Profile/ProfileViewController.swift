import UIKit
import WebKit

import Kingfisher

final class ProfileViewController: UIViewController {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var loginNameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!

    private var profileImageServiceObserver: NSObjectProtocol?
    private var profileServiceObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black")
        
        if let profile = ProfileService.shared.profile {
            updateProfileDetails(profile: profile)
        }
        
        profileImageServiceObserver = NotificationCenter.default
            .addObserver(
                forName: ProfileImageService.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                self.updateAvatar()
            }
        
        profileServiceObserver = NotificationCenter.default
            .addObserver(
                forName: ProfileService.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self, let profile = ProfileService.shared.profile else { return }
                self.updateProfileDetails(profile: profile)
            }
        
        updateAvatar()
        fetchIfNeeded()
    }

    private func fetchIfNeeded() {
        if ProfileService.shared.profile == nil, let token = OAuth2TokenStorage.shared.token {
            ProfileService.shared.fetchProfile(token) { result in
                if case let .success(profile) = result {
                    ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in }
                }
            }
        }
    }

    private func updateAvatar() {
        guard
            let profileImageURL = ProfileImageService.shared.avatarURL,
            let imageUrl = URL(string: profileImageURL)
        else { return }

        let placeholderImage = UIImage(systemName: "person.circle.fill")?
            .withTintColor(.lightGray, renderingMode: .alwaysOriginal)
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 70, weight: .regular, scale: .large))

        let processor = RoundCornerImageProcessor(cornerRadius: 35)
        avatarImageView.kf.indicatorType = .activity
        avatarImageView.kf.setImage(
            with: imageUrl,
            placeholder: placeholderImage,
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .cacheOriginalImage
            ]) { result in
                switch result {
                case .success(let value):
                    print(value.image)
                    print(value.cacheType)
                    print(value.source)
                case .failure(let error):
                    print(error)
                }
            }
    }
    
    private func updateProfileDetails(profile: Profile) {
        nameLabel.text = profile.name.isEmpty
        ? "Имя не указано"
        : profile.name
        loginNameLabel.text = profile.loginName.isEmpty
        ? "@неизвестный_пользователь"
        : profile.loginName
        descriptionLabel.text = (profile.bio?.isEmpty ?? true)
        ? "Профиль не заполнен"
        : profile.bio
    }

    @IBAction func didTapLogoutButton() {
        // Очищаем токен
        OAuth2TokenStorage.shared.token = nil
        
        // Очищаем данные профиля
        ProfileService.shared.clearProfile()
        ProfileImageService.shared.clearAvatarURL()
        
        // Очищаем веб‑куки/данные сайтов (чтобы Unsplash не помнил сессию)
        let dataStore = WKWebsiteDataStore.default()
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        dataStore.fetchDataRecords(ofTypes: types) { records in
            dataStore.removeData(ofTypes: types, for: records) {}
        }
        
        // Переключаемся на AuthViewController внутри UINavigationController
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("Invalid window configuration")
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let authVC = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as! AuthViewController
        let nav = UINavigationController(rootViewController: authVC)
        window.rootViewController = nav
        window.makeKeyAndVisible()
    }
} 