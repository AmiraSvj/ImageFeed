import UIKit

protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController)
}

final class AuthViewController: UIViewController {
    private let showWebViewSegueIdentifier = "ShowWebView"
    private let oauth2Service = OAuth2Service.shared
    
    weak var delegate: AuthViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureBackButton()
        view.backgroundColor = UIColor(named: "YP Black")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier {
            guard
                let webViewViewController = segue.destination as? WebViewViewController
            else {
                assertionFailure("Failed to prepare for \(showWebViewSegueIdentifier)")
                return
            }
            webViewViewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
    private func configureBackButton() {
        navigationController?.navigationBar.backIndicatorImage = UIImage(named: "nav_back_button")
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "nav_back_button")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = UIColor(named: "ypBlack")
    }
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        // Не закрываем WebView сразу; показываем блокирующий HUD и ждём результат запроса токена
        UIBlockingProgressHUD.show()
        fetchOAuthToken(code) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success:
                vc.dismiss(animated: true) {
                    // Сразу подтянем профиль и аватар
                    if let token = OAuth2TokenStorage.shared.token {
                        ProfileService.shared.fetchProfile(token) { result in
                            if case let .success(profile) = result {
                                ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in }
                            }
                        }
                    }
                    // Переходим на таббар как корень
                    if let window = UIApplication.shared.windows.first {
                        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
                            .instantiateViewController(withIdentifier: "TabBarViewController")
                        window.rootViewController = tabBarController
                        window.makeKeyAndVisible()
                    }
                    self.delegate?.didAuthenticate(self)
                }
            case let .failure(error):
                print("[AuthViewController.fetchOAuthToken]: NetworkError - \(error.localizedDescription)")
                self.showAuthErrorAlert()
            }
        }
    }

    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        vc.dismiss(animated: true)
    }
}

extension AuthViewController {
    private func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        oauth2Service.fetchOAuthToken(code) { result in
            completion(result)
        }
    }
}

extension AuthViewController {
    func showAuthErrorAlert() {
        let alertController = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "Ок", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}
