import XCTest
import WebKit
@testable import ImageFeed

final class WebViewPresenterTests: XCTestCase {
    
    var presenter: WebViewPresenter!
    var viewControllerSpy: WebViewViewControllerSpy!
    var authHelperStub: AuthHelperStub!
    
    override func setUp() {
        super.setUp()
        authHelperStub = AuthHelperStub()
        presenter = WebViewPresenter(authHelper: authHelperStub)
        viewControllerSpy = WebViewViewControllerSpy()
        presenter.view = viewControllerSpy
    }
    
    override func tearDown() {
        presenter = nil
        viewControllerSpy = nil
        authHelperStub = nil
        super.tearDown()
    }
    
    // MARK: - viewDidLoad Tests
    
    func testViewDidLoadCallsLoadRequest() {
        // Given
        let testURL = URL(string: "https://test.com")!
        let testRequest = URLRequest(url: testURL)
        authHelperStub.authRequestToReturn = testRequest
        
        // When
        presenter.viewDidLoad()
        
        // Then
        XCTAssertTrue(viewControllerSpy.loadRequestCalled, "viewDidLoad should call load request")
        XCTAssertEqual(viewControllerSpy.lastRequest?.url, testURL, "Should load correct URL")
    }
    
    func testViewDidLoadDoesNotCallLoadRequestWhenURLIsNil() {
        // Given
        authHelperStub.authRequestToReturn = nil
        
        // When
        presenter.viewDidLoad()
        
        // Then
        XCTAssertFalse(viewControllerSpy.loadRequestCalled, "Should not call load request when URL is nil")
    }
    
    // MARK: - code(from url) Tests
    
    func testCodeFromURLWithValidCode() {
        // Given
        let testURL = URL(string: "https://unsplash.com/oauth/authorize/native?code=test_code")!
        authHelperStub.codeToReturn = "test_code"
        
        // When
        let code = presenter.code(from: testURL)
        
        // Then
        XCTAssertEqual(code, "test_code", "Should return code from auth helper")
    }
    
    func testCodeFromURLReturnsNil() {
        // Given
        let testURL = URL(string: "https://unsplash.com/oauth/authorize?code=test_code")!
        authHelperStub.codeToReturn = nil
        
        // When
        let code = presenter.code(from: testURL)
        
        // Then
        XCTAssertNil(code, "Should return nil when auth helper returns nil")
    }
    
    // MARK: - didUpdateProgressValue Tests
    
    func testDidUpdateProgressValue() {
        // Given
        let progressValue: Double = 0.5
        
        // When
        presenter.didUpdateProgressValue(progressValue)
        
        // Then
        XCTAssertTrue(viewControllerSpy.setProgressValueCalled, "Should call setProgressValue")
        XCTAssertTrue(viewControllerSpy.setProgressHiddenCalled, "Should call setProgressHidden")
        XCTAssertEqual(viewControllerSpy.lastProgressValue, Float(progressValue), "Should pass correct progress value")
    }
}
