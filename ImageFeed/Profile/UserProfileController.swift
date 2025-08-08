import UIKit

final class UserProfileController: UIViewController {
    private lazy var profilePictureView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "avatar")
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 35
        return imageView
    }()
    
    private lazy var fullNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Екатерина Новикова"
        label.font = UIFont.systemFont(ofSize: 23, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "@ekaterina_nov"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1.0)
        return label
    }()
    
    private lazy var bioLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Hello, World!"
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "logout_button"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleSignOutTap), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black")
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        view.addSubview(profilePictureView)
        view.addSubview(fullNameLabel)
        view.addSubview(usernameLabel)
        view.addSubview(bioLabel)
        view.addSubview(signOutButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            profilePictureView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            profilePictureView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            profilePictureView.widthAnchor.constraint(equalToConstant: 70),
            profilePictureView.heightAnchor.constraint(equalToConstant: 70),
            
            fullNameLabel.leadingAnchor.constraint(equalTo: profilePictureView.leadingAnchor),
            fullNameLabel.topAnchor.constraint(equalTo: profilePictureView.bottomAnchor, constant: 8),
            fullNameLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            
            usernameLabel.leadingAnchor.constraint(equalTo: fullNameLabel.leadingAnchor),
            usernameLabel.topAnchor.constraint(equalTo: fullNameLabel.bottomAnchor, constant: 8),
            usernameLabel.trailingAnchor.constraint(equalTo: fullNameLabel.trailingAnchor),
            
            bioLabel.leadingAnchor.constraint(equalTo: fullNameLabel.leadingAnchor),
            bioLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 8),
            bioLabel.trailingAnchor.constraint(equalTo: fullNameLabel.trailingAnchor),
            
            signOutButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            signOutButton.centerYAnchor.constraint(equalTo: profilePictureView.centerYAnchor),
            signOutButton.widthAnchor.constraint(equalToConstant: 44),
            signOutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func handleSignOutTap() {
    }
} 