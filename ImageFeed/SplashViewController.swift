import UIKit

class SplashViewController: UIViewController {
    
    private let storage = OAuth2TokenStorage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("🚀 SplashViewController viewDidAppear")
        print("🔑 Token exists: \(storage.token != nil)")
        
        if storage.token != nil {
            print("✅ User is authenticated, switching to TabBarController")
            switchToTabBarController()
        } else {
            print("❌ No token, showing authentication screen")
            // Показываем экран авторизации через segue
            performSegue(withIdentifier: "ShowAuthenticationScreen", sender: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(named: "YP Black")
    }
    
    private func switchToTabBarController() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            assertionFailure("Invalid window configuration")
            return
        }
        
        // Получаем TabBarController из сториборда
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarViewController") as? UITabBarController else {
            assertionFailure("Failed to instantiate TabBarController from storyboard")
            return
        }
        
        window.rootViewController = tabBarController
        
        // Обновляем статус бар
        tabBarController.setNeedsStatusBarAppearanceUpdate()
    }
    
    private func showAuthViewController() {
        // Используем segue из сториборда
        performSegue(withIdentifier: "ShowAuthenticationScreen", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowAuthenticationScreen" {
            if let navigationController = segue.destination as? UINavigationController,
               let authViewController = navigationController.topViewController as? AuthViewController {
                authViewController.delegate = self
            }
        }
    }
}

// MARK: - AuthViewControllerDelegate
extension SplashViewController: AuthViewControllerDelegate {
    func didAuthenticate(_ vc: AuthViewController) {
        // Этот метод больше не используется, но оставляем для совместимости
        print("🎉 Authentication successful (legacy method)")
    }
} 
