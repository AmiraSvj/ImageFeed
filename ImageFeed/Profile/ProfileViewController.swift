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
    private var gradientViews: [AnimatedGradientView] = []

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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Убеждаемся, что анимации остановлены, если профиль уже загружен
        if ProfileService.shared.profile != nil {
            stopGradientAnimations()
        }
    }

    private func fetchIfNeeded() {
        if ProfileService.shared.profile == nil, let token = OAuth2TokenStorage.shared.token {
            // Запускаем анимации только когда начинаем реальную загрузку
            setupGradientAnimations()
            
            ProfileService.shared.fetchProfile(token) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let profile):
                        ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in }
                        // Останавливаем анимации после успешной загрузки
                        self?.stopGradientAnimations()
                    case .failure:
                        // Останавливаем анимации даже при ошибке
                        self?.stopGradientAnimations()
                    }
                }
            }
        } else {
            // Если профиль уже загружен, останавливаем анимации
            stopGradientAnimations()
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
                    // Анимации уже остановлены в fetchIfNeeded
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
        
        // Анимации уже остановлены в fetchIfNeeded
    }

    @IBAction func didTapLogoutButton() {
        showLogoutConfirmation()
    }
    
    private func showLogoutConfirmation() {
        let alert = UIAlertController(
            title: "Пока, пока!",
            message: "Уверены, что хотите выйти?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Нет", style: .cancel))
        alert.addAction(UIAlertAction(title: "Да, выйти", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })
        
        present(alert, animated: true)
    }
    
    private func performLogout() {
        // Показываем индикатор загрузки
        UIBlockingProgressHUD.show()
        
        // Выполняем логаут
        ProfileLogoutService.shared.logout()
        
        // Скрываем индикатор и переходим на экран авторизации
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIBlockingProgressHUD.dismiss()
            self.switchToSplashScreen()
        }
    }
    
    private func switchToSplashScreen() {
        // Переключаемся на SplashViewController
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            assertionFailure("Invalid window configuration")
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let splashVC = storyboard.instantiateViewController(withIdentifier: "SplashViewController")
        
        // Анимированный переход
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = splashVC
        }
    }
    
    private func setupGradientAnimations() {
        print("🎬 [ProfileViewController] Запускаем анимации загрузки профиля")
        
        addGradientToView(avatarImageView)
        addGradientToView(nameLabel)
        addGradientToView(loginNameLabel)
        addGradientToView(descriptionLabel)
        
        // Запускаем анимации
        gradientViews.forEach { $0.startAnimation() }
    }
    
    private func addGradientToView(_ view: UIView) {
        let gradientView = AnimatedGradientView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.isUserInteractionEnabled = false
        
        // Добавляем градиент как дочерний элемент к конкретному view, а не к self.view
        view.addSubview(gradientView)
        gradientViews.append(gradientView)
        
        NSLayoutConstraint.activate([
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientView.topAnchor.constraint(equalTo: view.topAnchor),
            gradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func stopGradientAnimations() {
        print("🛑 [ProfileViewController] Останавливаем анимации профиля")
        print("🔍 [ProfileViewController] Количество градиентных view: \(gradientViews.count)")
        
        gradientViews.forEach { gradientView in
            gradientView.stopAnimation()
            gradientView.removeFromSuperview()
        }
        gradientViews.removeAll()
        
        print("✅ [ProfileViewController] Анимации остановлены")
    }
    
    deinit {
        stopGradientAnimations()
    }
} 