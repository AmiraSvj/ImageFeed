import XCTest
@testable import ImageFeed

// MARK: - WebViewPresenter Spy
final class WebViewPresenterSpy: WebViewPresenterProtocol {
    var viewDidLoadCalled: Bool = false
    var didUpdateProgressValueCalled: Bool = false
    var codeFromURLCalled: Bool = false
    
    var view: WebViewViewControllerProtocol?
    var lastProgressValue: Double?
    var lastURL: URL?
    
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
        return nil
    }
}

// MARK: - WebViewViewController Spy
final class WebViewViewControllerSpy: WebViewViewControllerProtocol {
    var presenter: WebViewPresenterProtocol?
    
    var loadRequestCalled: Bool = false
    var setProgressValueCalled: Bool = false
    var setProgressHiddenCalled: Bool = false
    
    var lastRequest: URLRequest?
    var lastProgressValue: Float?
    var lastProgressHidden: Bool?
    
    func load(request: URLRequest) {
        loadRequestCalled = true
        lastRequest = request
    }
    
    func setProgressValue(_ newValue: Float) {
        setProgressValueCalled = true
        lastProgressValue = newValue
    }
    
    func setProgressHidden(_ isHidden: Bool) {
        setProgressHiddenCalled = true
        lastProgressHidden = isHidden
    }
}
