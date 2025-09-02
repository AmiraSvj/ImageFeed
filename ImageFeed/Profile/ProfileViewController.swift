import UIKit

import Kingfisher

final class ProfileViewController: UIViewController {
    private var avatarImageView: UIImageView!
    private var nameLabel: UILabel!
    private var loginNameLabel: UILabel!
    private var descriptionLabel: UILabel!
    private var logoutButton: UIButton!

    private var profileImageServiceObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Обновляем профиль из ProfileService
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
        updateAvatar()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(named: "YP Black")
        setupAvatarView()
        setupNameLabel()
        setupDescriptionLabel()
        setupLogoutButton()
    }

    private func setupAvatarView() {
        let profileImage = UIImage(systemName: "person.circle.fill")?
            .withTintColor(.lightGray, renderingMode: .alwaysOriginal)
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 70, weight: .regular, scale: .large))
        avatarImageView = UIImageView(image: profileImage)
        avatarImageView.contentMode = .scaleAspectFit
        avatarImageView.clipsToBounds = true
        
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(avatarImageView)
        
        let size: CGFloat = 70
        
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            avatarImageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            
            avatarImageView.widthAnchor.constraint(equalToConstant: size),
            avatarImageView.heightAnchor.constraint(equalToConstant: size)
        ])
        
        // Make avatar circular
        avatarImageView.layer.cornerRadius = size / 2
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
    }
    
    private func setupNameLabel() {
        nameLabel = UILabel()
        nameLabel.text = "Имя не указано"
        nameLabel.textColor = .white
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor)
        ])
        
        loginNameLabel = UILabel()
        loginNameLabel.text = "@неизвестный_пользователь"
        loginNameLabel.textColor = .gray
        loginNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginNameLabel)
        
        NSLayoutConstraint.activate([
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            loginNameLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor)
        ])
    }
    
    private func setupDescriptionLabel() {
        descriptionLabel = UILabel()
        descriptionLabel.text = "Профиль не заполнен"
        descriptionLabel.textColor = .white
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: avatarImageView.leadingAnchor)
        ])
    }
    
    private func setupLogoutButton() {
        logoutButton = UIButton.systemButton(
            with: UIImage(named: "logout_button")!,
            target: self,
            action: #selector(didTapLogoutButton)
        )
        
        logoutButton.tintColor = UIColor(red: 0.96, green: 0.42, blue: 0.42, alpha: 1.0) // #F56B6C
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoutButton)
        
        NSLayoutConstraint.activate([
            logoutButton.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            logoutButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -36)
        ])
    }

    private func updateAvatar() {
        guard
            let profileImageURL = ProfileImageService.shared.avatarURL,
            let imageUrl = URL(string: profileImageURL)
        else { return }

        print("imageUrl: \(imageUrl)")

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

    @objc private func didTapLogoutButton() {
        print("🔄 ProfileViewController: Кнопка выхода нажата")
        
        // Очищаем токен
        OAuth2TokenStorage.shared.token = nil
        print("✅ ProfileViewController: Токен очищен")
        
        // Очищаем данные профиля
        ProfileService.shared.clearProfile()
        ProfileImageService.shared.avatarURL = nil
        print("✅ ProfileViewController: Данные профиля очищены")
        
        // Возвращаемся на SplashViewController
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            assertionFailure("Invalid window configuration")
            return
        }
        
        let splashViewController = SplashViewController()
        window.rootViewController = splashViewController
        window.makeKeyAndVisible()
        print("✅ ProfileViewController: Переключено на SplashViewController")
    }
} 