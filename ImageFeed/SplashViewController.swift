import UIKit

final class SplashViewController: UIViewController {
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"

    private let profileService = ProfileService.shared
    private let storage = OAuth2TokenStorage.shared
    private var isPresentingAuth: Bool = false

    private let logoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "splash_screen_logo"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black")
        setupLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Анимируем появление логотипа
        animateLogoAppearance()
    }
    
    private func animateLogoAppearance() {
        // Начальное состояние - логотип прозрачный и увеличенный
        logoImageView.alpha = 0
        logoImageView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        
        // Анимация появления
        UIView.animate(withDuration: 1.0, delay: 0.2, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.curveEaseOut], animations: {
            self.logoImageView.alpha = 1.0
            self.logoImageView.transform = .identity
        }) { _ in
            // После анимации логотипа проверяем авторизацию
            self.checkAuthentication()
        }
    }
    
    private func checkAuthentication() {
        if let token = storage.token {
            print("🔑 [SplashViewController] Токен найден: \(token.prefix(10))...")
            fetchProfile(token: token)
        } else {
            print("❌ [SplashViewController] Токен не найден, показываем авторизацию")
            // Сразу открываем авторизацию, чтобы не было промежуточного экрана
            presentAuth()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    private func setupLayout() {
        view.addSubview(logoImageView)
        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            logoImageView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.5),
            logoImageView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.5)
        ])
    }

    private func switchToTabBarController() {
        print("🔄 [SplashViewController] Переключаемся на TabBarController...")
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("Invalid window configuration")
            return
        }
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
        window.rootViewController = tabBarController
        print("✅ [SplashViewController] Переключение завершено")
    }

    // Кнопки на сплеше не показываем — он должен выглядеть как Launch Screen

    private func presentAuth() {
        guard !isPresentingAuth, presentedViewController == nil else { return }
        isPresentingAuth = true

        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let authViewController = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else {
            assertionFailure("Failed to instantiate AuthViewController from storyboard")
            isPresentingAuth = false
            return
        }
        authViewController.delegate = self
        let navController = UINavigationController(rootViewController: authViewController)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    private func fetchProfile(token: String) {
        print("🔑 [SplashViewController] Токен найден, загружаем профиль...")
        
        // Показываем анимацию загрузки
        UIBlockingProgressHUD.show()
        
        profileService.fetchProfile(token) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                UIBlockingProgressHUD.dismiss()
                
                switch result {
                case let .success(profile):
                    print("✅ [SplashViewController] Профиль загружен: \(profile.username)")
                    ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in }
                    self.switchToTabBarController()

                case let .failure(error):
                    print("❌ [SplashViewController] Ошибка загрузки профиля: \(error)")
                    
                    // Если ошибка 403 (Rate Limit), все равно переходим к приложению
                    if let networkError = error as? NetworkError,
                       case .httpStatusCode(403) = networkError {
                        print("⚠️ [SplashViewController] Превышен лимит API, но переходим к приложению")
                        self.switchToTabBarController()
                    } else {
                        self.isPresentingAuth = false
                    }
                }
            }
        }
    }
}

extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        vc.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.isPresentingAuth = false
            if let token = self.storage.token {
                self.fetchProfile(token: token)
            }
        }
    }
}
