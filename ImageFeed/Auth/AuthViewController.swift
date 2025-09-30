import UIKit

final class AuthViewController: UIViewController {
    
    @IBOutlet private var logoImageView: UIImageView!
    @IBOutlet private var loginButton: UIButton!
    private let oauth2Service = OAuth2Service.shared
    private var isFetchingToken = false
    private var isShowingAlert = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🔐 AuthViewController viewDidLoad")
        setupUI()
        configureBackButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("🔐 AuthViewController viewWillAppear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("🔐 AuthViewController viewDidAppear")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func setupUI() {
        // Фон уже установлен в сториборде, не нужно дублировать
        // view.backgroundColor = UIColor(named: "YP Black")
        
        // Настраиваем только то, что не установлено в сториборде
        logoImageView.contentMode = .scaleAspectFit
        
        // Кнопка уже настроена в сториборде, добавляем только target
        loginButton.addTarget(self, action: #selector(didTapLoginButton), for: .touchUpInside)
    }
    
    private func configureBackButton() {
        // Устанавливаем черную стрелку для кнопки "Назад"
        navigationController?.navigationBar.backIndicatorImage = UIImage(named: "nav_back_button")
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav_back_button")
        
        // Убираем текст кнопки "Назад"
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // Устанавливаем черный цвет для стрелки
        navigationController?.navigationBar.tintColor = UIColor(named: "YP Black")
    }
    
    @IBAction private func didTapLoginButton(_ sender: UIButton) {
        print("🔐 Login button tapped")
        
        // Создаем WebViewViewController программно
        let webViewController = WebViewViewController()
        webViewController.delegate = self
        
        // Создаем NavigationController для WebViewViewController
        let navigationController = UINavigationController(rootViewController: webViewController)
        
        // Показываем модально
        present(navigationController, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        // Проверяем, что view controller находится в иерархии и активен
        guard isViewLoaded && view.window != nil && isBeingDismissed == false && isMovingFromParent == false else {
            print("View controller not in hierarchy or being dismissed, skipping alert: \(title)")
            return
        }
        
        // Проверяем, не показывается ли уже алерт
        if isShowingAlert || presentedViewController != nil {
            print("Alert already showing, skipping: \(title) - \(message)")
            return
        }
        
        isShowingAlert = true
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.isShowingAlert = false
        })
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Дополнительная проверка перед показом
            guard self.isViewLoaded && self.view.window != nil && self.isBeingDismissed == false && self.isMovingFromParent == false else {
                print("View controller no longer valid before alert presentation, skipping")
                self.isShowingAlert = false
                return
            }
            
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - Private Methods
    
    /// Парсит сообщение об ошибке из данных ответа
    private func parseErrorMessage(from data: Data?) -> String? {
        guard let data = data else { return nil }
        
        if let responseString = String(data: data, encoding: .utf8) {
            if responseString.contains("redirect_uri is not valid") {
                return "Неверный redirect URI. Проверьте настройки приложения в Unsplash."
            } else if responseString.contains("requested scope is not valid") {
                return "Неверные разрешения (Permissions). Проверьте настройки разрешений в вашем приложении Unsplash."
            } else if responseString.contains("code has already been used") {
                return "Код авторизации уже использован. Начните процесс авторизации заново."
            } else if responseString.contains("client_id is invalid") {
                return "Неверный Access Key. Проверьте настройки приложения в Unsplash."
            } else if responseString.contains("client_secret is invalid") {
                return "Неверный Secret Key. Проверьте настройки приложения в Unsplash."
            } else if responseString.contains("invalid_client") {
                return "Ошибка аутентификации клиента. Проверьте Access Key и Secret Key."
            } else {
                return responseString
            }
        }
        
        return nil
    }
    

    
    /// Сохраняет данные пользователя
    private func saveUserData() {
        print("💾 User data saved successfully")
        print("   - Token stored in OAuth2TokenStorage by OAuth2Service")
        print("   - Access key: \(String(Constants.accessKey.prefix(10)))...")
        print("   - Scope: \(Constants.accessScope)")
    }
}

// MARK: - WebViewViewControllerDelegate
extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        print("✅ Authentication successful with code: \(code)")
        
        // Сначала получаем токен
        OAuth2Service.shared.fetchOAuthToken(code: code) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let token):
                    print("🎉 Token received and saved: \(String(token.prefix(10)))...")
                    // Закрываем WebView
                    vc.dismiss(animated: true) { [weak self] in
                        // После закрытия WebView переключаемся на главный экран
                        self?.switchToMainScreen(animated: false)
                    }
                case .failure(let error):
                    print("❌ Failed to get token: \(error)")
                    // Показываем ошибку и остаемся на экране авторизации
                    self?.showAlert(title: "Ошибка авторизации", message: error.localizedDescription)
                }
            }
        }
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        print("❌ Authentication cancelled")
        
        // Закрываем WebView
        vc.dismiss(animated: true)
    }
    
    private func switchToMainScreen(animated: Bool) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            print("❌ Failed to get window")
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarViewController") as? UITabBarController else {
            print("❌ Failed to create TabBarController")
            return
        }
        
        if animated {
            UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve, animations: {
                window.rootViewController = tabBarController
            })
        } else {
            UIView.performWithoutAnimation {
                window.rootViewController = tabBarController
                window.layoutIfNeeded()
            }
        }
        print("🎉 Switched to main screen")
    }
} 