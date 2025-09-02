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
    @IBOutlet private var webView: WKWebView!
    @IBOutlet private var progressView: UIProgressView!

    private var estimatedProgressObservation: NSKeyValueObservation?

    weak var delegate: WebViewViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        webView.navigationDelegate = self

        loadAuthView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        estimatedProgressObservation = webView.observe(
            \.estimatedProgress,
             options: [],
             changeHandler: { [weak self] _, _ in
                 guard let self = self else { return }
                 self.updateProgress()
             })
        updateProgress()
    }

    private func updateProgress() {
        progressView.progress = Float(webView.estimatedProgress)
        progressView.isHidden = fabs(webView.estimatedProgress - 1.0) <= 0.0001
    }
    
    private func loadAuthView() {
        guard var urlComponents = URLComponents(string: WebViewConstants.unsplashAuthorizeURLString) else {
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Constants.accessScope)
        ]
        
        guard let url = urlComponents.url else {
            return
        }
        
        // Добавляем логирование для отладки
        print("🔐 [WebViewViewController]: URL для авторизации: \(url.absoluteString)")
        print("🔐 [WebViewViewController]: client_id: \(Constants.accessKey)")
        print("🔐 [WebViewViewController]: redirect_uri: \(Constants.redirectURI)")
        print("🔐 [WebViewViewController]: scope: \(Constants.accessScope)")
        
        let request = URLRequest(url: url)
        webView.load(request)

        updateProgress()
    }
}

extension WebViewViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        print("🔐 [WebViewViewController]: Navigation action: \(navigationAction.request.url?.absoluteString ?? "nil")")
        
        if let code = code(from: navigationAction) {
            print("🔐 [WebViewViewController]: ✅ Code extracted successfully: \(code)")
            delegate?.webViewViewController(self, didAuthenticateWithCode: code)
            decisionHandler(.cancel)
        } else {
            print("🔐 [WebViewViewController]: ❌ No code found, allowing navigation")
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("🔐 [WebViewViewController]: Page loaded: \(webView.url?.absoluteString ?? "nil")")
    }

    private func code(from navigationAction: WKNavigationAction) -> String? {
        if let url = navigationAction.request.url {
            print("🔐 [WebViewViewController]: Navigation URL: \(url.absoluteString)")
            
            if let urlComponents = URLComponents(string: url.absoluteString) {
                print("🔐 [WebViewViewController]: Path: \(urlComponents.path)")
                print("🔐 [WebViewViewController]: Host: \(urlComponents.host ?? "nil")")
                print("🔐 [WebViewViewController]: Query items: \(urlComponents.queryItems ?? [])")
                
                // Проверяем разные возможные пути
                if urlComponents.path == "/oauth/authorize/native" ||
                   urlComponents.path == "/oauth/authorize" ||
                   urlComponents.host == "unsplash.com" {
                    
                    if let items = urlComponents.queryItems,
                       let codeItem = items.first(where: { $0.name == "code" }) {
                        print("🔐 [WebViewViewController]: Found code: \(codeItem.value)")
                        return codeItem.value
                    } else {
                        print("🔐 [WebViewViewController]: No code found in query items")
                    }
                } else {
                    print("🔐 [WebViewViewController]: Path not matched: \(urlComponents.path)")
                }
            }
        }
        return nil
    }
}

 