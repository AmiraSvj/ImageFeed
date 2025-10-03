import Foundation
import WebKit
@testable import ImageFeed

// MARK: - WebViewPresenter Stub
final class WebViewPresenterStub: WebViewPresenterProtocol {
    weak var view: WebViewViewControllerProtocol?
    
    var viewDidLoadCalled = false
    var didUpdateProgressValueCalled = false
    var codeFromURLCalled = false
    
    var lastProgressValue: Double?
    var lastURL: URL?
    var codeToReturn: String?
    
    func viewDidLoad() {
        viewDidLoadCalled = true
    }
    
    func didUpdateProgressValue(_ newValue: Double) {
        didUpdateProgressValueCalled = true
        lastProgressValue = newValue
    }
    
    func code(from url: URL) -> String? {
        codeFromURLCalled = true
        lastURL = url
        return codeToReturn
    }
}

// MARK: - AuthHelper Stub
final class AuthHelperStub: AuthHelperProtocol {
    var codeToReturn: String?
    var authRequestToReturn: URLRequest?
    
    func authRequest() -> URLRequest? {
        return authRequestToReturn
    }
    
    func code(from url: URL) -> String? {
        return codeToReturn
    }
}

// MARK: - Test Navigation Action Helper
final class TestNavigationAction: WKNavigationAction {
    private let testURL: URL
    
    init(url: URL) {
        self.testURL = url
        super.init()
    }
    
    override var request: URLRequest {
        return URLRequest(url: testURL)
    }
}
