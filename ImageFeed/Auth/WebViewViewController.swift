import UIKit
@preconcurrency import WebKit

enum WebViewConstants {
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
}

protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
    func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}

final class WebViewViewController: UIViewController {
    
    private lazy var webView: WKWebView = {
        let webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.backgroundColor = .systemBackground
        return webView
    }()
    
    private lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = UIColor(named: "YP Black")
        progressView.trackTintColor = .clear
        progressView.progress = 0.0
        return progressView
    }()
    
    weak var delegate: WebViewViewControllerDelegate?
    private var estimatedProgress: Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🌐 WebViewViewController viewDidLoad")
        setupUI()
        setupNavigationBar()
        loadOAuthPage()
        observeProgress()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // Добавляем UI элементы
        view.addSubview(progressView)
        view.addSubview(webView)
        
        // Настраиваем констрейнты
        NSLayoutConstraint.activate([
            // Progress view
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            
            // WebView
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // Настраиваем WebView
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.backgroundColor = .systemBackground
        
        // Настраиваем ProgressView
        progressView.progress = 0.0
        progressView.isHidden = false
        progressView.alpha = 1.0
        progressView.progressTintColor = UIColor(named: "YP Black")
        progressView.trackTintColor = .clear
    }
    
    private func setupNavigationBar() {
        // Создаем кнопку "Назад"
        let backButton = UIBarButtonItem(
            image: UIImage(named: "nav_back_button"),
            style: .plain,
            target: self,
            action: #selector(didTapBackButton)
        )
        backButton.tintColor = UIColor(named: "YP Black")
        
        // Устанавливаем кнопку в навигационную панель
        navigationItem.leftBarButtonItem = backButton
        
        // Устанавливаем заголовок
        title = "Авторизация"
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor(named: "YP Black") ?? .black
        ]
    }
    
    @objc private func didTapBackButton() {
        print("🔙 Back button tapped")
        delegate?.webViewViewControllerDidCancel(self)
    }
    
    private func observeProgress() {
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        clearWebViewCache()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            estimatedProgress = Float(webView.estimatedProgress)
            updateProgress()
        }
    }
    
    private func updateProgress() {
        progressView.progress = estimatedProgress
        
        if estimatedProgress >= 1.0 {
            UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseOut, animations: { [weak self] in
                self?.progressView.alpha = 0.0
            }, completion: { [weak self] _ in
                self?.progressView.isHidden = true
            })
        } else {
            progressView.isHidden = false
            progressView.alpha = 1.0
        }
    }
    
    private func loadOAuthPage() {
        let urlString = "https://unsplash.com/oauth/authorize?client_id=\(Constants.accessKey)&redirect_uri=\(Constants.redirectURI)&response_type=code&scope=\(Constants.accessScope)"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid OAuth URL: \(urlString)")
            return
        }
        
        print("🔗 Loading OAuth page: \(url.absoluteString)")
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func clearWebViewCache() {
        print("🧹 Clearing WebView cache...")
        
        WKWebsiteDataStore.default().removeData(
            ofTypes: [
                WKWebsiteDataTypeDiskCache,
                WKWebsiteDataTypeMemoryCache,
                WKWebsiteDataTypeCookies,
                WKWebsiteDataTypeLocalStorage,
                WKWebsiteDataTypeSessionStorage
            ],
            modifiedSince: Date(timeIntervalSince1970: 0)
        ) { [weak self] in
            DispatchQueue.main.async {
                print("✅ WebView cache cleared successfully")
            }
        }
        
        URLCache.shared.removeAllCachedResponses()
        print("✅ URLSession cache cleared")
    }
}

extension WebViewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let code = code(from: navigationAction) {
            print("✅ Authorization successful! Received code: \(code)")
            clearWebViewCache()
            decisionHandler(.cancel)
            
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.webViewViewController(self!, didAuthenticateWithCode: code)
            }
        } else {
            print("✅ Allowing navigation to: \(navigationAction.request.url?.absoluteString ?? "unknown")")
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ WebView navigation failed: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("❌ WebView provisional navigation failed: \(error.localizedDescription)")
        
        if (error as NSError).code == 102 {
            print("Provisional navigation was cancelled or interrupted - this is normal after successful auth")
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("🌐 WebView finished loading: \(webView.url?.absoluteString ?? "unknown")")
    }
    
    private func code(from navigationAction: WKNavigationAction) -> String? {
        if let url = navigationAction.request.url {
            print("🔍 Checking URL for authorization code: \(url.absoluteString)")
            
            if url.absoluteString.contains("oauth/authorize") && !url.absoluteString.contains("code=") {
                print("📱 Loading authorization page - this is normal, no code yet")
                return nil
            }
            
            if let code = url.queryParameters["code"] {
                print("✅ Found authorization code in query parameters: \(code)")
                return code
            }
            
            if !url.absoluteString.contains("oauth/authorize") {
                print("🌐 Navigation to non-authorization URL: \(url.absoluteString)")
            }
        }
        return nil
    }
}

extension URL {
    var queryParameters: [String: String] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return [:] }
        
        var parameters = [String: String]()
        for queryItem in queryItems {
            parameters[queryItem.name] = queryItem.value
        }
        return parameters
    }
} 