import UIKit

final class ProfileViewController: UIViewController {
    @IBOutlet private var avatarImageView: UIImageView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var loginNameLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    @IBOutlet private var logoutButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func setupUI() {
        view.backgroundColor = UIColor(named: "YP Black")
        
        // Настраиваем UI элементы
        avatarImageView.image = UIImage(named: "avatar")
        avatarImageView.contentMode = .scaleAspectFit
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 35
        avatarImageView.layer.masksToBounds = true
        
        nameLabel.text = "Екатерина Новикова"
        nameLabel.font = UIFont.systemFont(ofSize: 23, weight: .semibold)
        nameLabel.textColor = .white
        nameLabel.numberOfLines = 0
        
        loginNameLabel.text = "@ekaterina_nov"
        loginNameLabel.font = UIFont.systemFont(ofSize: 13)
        loginNameLabel.textColor = UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1.0)
        
        descriptionLabel.text = "Hello, World!"
        descriptionLabel.font = UIFont.systemFont(ofSize: 13)
        descriptionLabel.textColor = .white
        descriptionLabel.numberOfLines = 0
        
        logoutButton.setImage(UIImage(named: "logout_button"), for: .normal)
        logoutButton.tintColor = .red
        
        logoutButton.addTarget(self, action: #selector(didTapLogoutButton), for: .touchUpInside)
    }

    @objc private func didTapLogoutButton() {
        print("🚪 Logout button tapped")
        
        // Очищаем токен
        let storage = OAuth2TokenStorage()
        storage.token = nil
        
        print("🗑️ Token cleared, returning to authentication")
        
        // Возвращаемся к экрану авторизации
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let splashViewController = storyboard.instantiateViewController(withIdentifier: "SplashViewController") as? SplashViewController {
                window.rootViewController = splashViewController
                print("🔄 Switched back to SplashViewController")
            }
        }
    }
} 