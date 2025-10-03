import XCTest
@testable import ImageFeed

final class WebViewTests: XCTestCase {
    
    // MARK: - Test ViewController calls Presenter
    
    func testViewControllerCallsViewDidLoad() {
        //given
        let viewController = WebViewViewController()
        let presenter = WebViewPresenterSpy()
        viewController.presenter = presenter
        presenter.view = viewController
        
        //when
        viewController.viewDidLoad()
        
        //then
        XCTAssertTrue(presenter.viewDidLoadCalled) //behaviour verification
    }
    
    func testPresenterCallsLoadRequest() {
        //given
        let viewController = WebViewViewControllerSpy()
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        viewController.presenter = presenter
        presenter.view = viewController
        
        //when
        presenter.viewDidLoad()
        
        //then
        XCTAssertTrue(viewController.loadRequestCalled)
    }
    
    // MARK: - Test Progress Logic
    
    func testProgressVisibleWhenLessThenOne() {
        //given
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        let progress: Float = 0.6
        
        //when
        let shouldHideProgress = presenter.shouldHideProgress(for: progress)
        
        //then
        XCTAssertFalse(shouldHideProgress)
    }
    
    func testProgressHiddenWhenOne() {
        //given
        let authHelper = AuthHelper() //Dummy
        let presenter = WebViewPresenter(authHelper: authHelper)
        let progress: Float = 1.0
        
        //when
        let shouldHideProgress = presenter.shouldHideProgress(for: progress) // return value verification
        
        //then
        XCTAssertTrue(shouldHideProgress)
    }
    
    // MARK: - Test AuthHelper
    
    func testAuthHelperAuthURL() {
        //given
        let configuration = AuthConfiguration.standard
        let authHelper = AuthHelper(configuration: configuration)
        
        //when
        let url = authHelper.authURL()
        guard let url = url else {
            XCTFail("URL should not be nil")
            return
        }
        let urlString = url.absoluteString
        
        //then
        XCTAssertTrue(urlString.contains(configuration.authURLString))
        XCTAssertTrue(urlString.contains(configuration.accessKey))
        XCTAssertTrue(urlString.contains(configuration.redirectURI))
        XCTAssertTrue(urlString.contains("code"))
        XCTAssertTrue(urlString.contains(configuration.accessScope))
    }
    
    func testCodeFromURL() {
        //given
        var urlComponents = URLComponents(string: "https://unsplash.com/oauth/authorize/native")!
        urlComponents.queryItems = [URLQueryItem(name: "code", value: "test code")]
        let url = urlComponents.url!
        let authHelper = AuthHelper()
        
        //when
        let code = authHelper.code(from: url)
        
        //then
        XCTAssertEqual(code, "test code")
    }
    
    // MARK: - Additional Tests
    
    func testAuthHelperAuthRequest() {
        //given
        let authHelper = AuthHelper()
        
        //when
        let request = authHelper.authRequest()
        
        //then
        XCTAssertNotNil(request)
        XCTAssertNotNil(request?.url)
    }
    
    func testCodeFromURLWithInvalidPath() {
        //given
        let url = URL(string: "https://unsplash.com/oauth/authorize?code=test")!
        let authHelper = AuthHelper()
        
        //when
        let code = authHelper.code(from: url)
        
        //then
        XCTAssertNil(code)
    }
    
    func testCodeFromURLWithoutCode() {
        //given
        let url = URL(string: "https://unsplash.com/oauth/authorize/native")!
        let authHelper = AuthHelper()
        
        //when
        let code = authHelper.code(from: url)
        
        //then
        XCTAssertNil(code)
    }
    
    func testPresenterDidUpdateProgressValue() {
        //given
        let viewController = WebViewViewControllerSpy()
        let authHelper = AuthHelper()
        let presenter = WebViewPresenter(authHelper: authHelper)
        presenter.view = viewController
        
        //when
        presenter.didUpdateProgressValue(0.5)
        
        //then
        XCTAssertTrue(viewController.setProgressValueCalled)
        XCTAssertTrue(viewController.setProgressHiddenCalled)
        XCTAssertEqual(viewController.lastProgressValue, 0.5)
    }
}
