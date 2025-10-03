import XCTest
import WebKit
@testable import ImageFeed

final class AuthHelperTests: XCTestCase {
    
    var authHelper: AuthHelper!
    
    override func setUp() {
        super.setUp()
        authHelper = AuthHelper()
    }
    
    override func tearDown() {
        authHelper = nil
        super.tearDown()
    }
    
    func testCodeFromURLWithValidCode() {
        // Given
        let testURL = URL(string: "https://unsplash.com/oauth/authorize/native?code=test_code")!
        
        // When
        let code = authHelper.code(from: testURL)
        
        // Then
        XCTAssertEqual(code, "test_code", "Should extract code from valid URL")
    }
    
    func testCodeFromURLWithInvalidPath() {
        // Given
        let testURL = URL(string: "https://unsplash.com/oauth/authorize?code=test_code")!
        
        // When
        let code = authHelper.code(from: testURL)
        
        // Then
        XCTAssertNil(code, "Should return nil for invalid path")
    }
    
    func testCodeFromURLWithoutCode() {
        // Given
        let testURL = URL(string: "https://unsplash.com/oauth/authorize/native")!
        
        // When
        let code = authHelper.code(from: testURL)
        
        // Then
        XCTAssertNil(code, "Should return nil when code is missing")
    }
    
    func testCodeFromURLWithEmptyCode() {
        // Given
        let testURL = URL(string: "https://unsplash.com/oauth/authorize/native?code=")!
        
        // When
        let code = authHelper.code(from: testURL)
        
        // Then
        XCTAssertEqual(code, "", "Should return empty string for empty code")
    }
    
    func testCodeFromURLWithMultipleQueryItems() {
        // Given
        let testURL = URL(string: "https://unsplash.com/oauth/authorize/native?state=test_state&code=test_code&other=value")!
        
        // When
        let code = authHelper.code(from: testURL)
        
        // Then
        XCTAssertEqual(code, "test_code", "Should extract code from URL with multiple query items")
    }
    
    func testCodeFromURLWithDifferentDomain() {
        // Given
        let testURL = URL(string: "https://example.com/oauth/authorize/native?code=test_code")!
        
        // When
        let code = authHelper.code(from: testURL)
        
        // Then
        XCTAssertEqual(code, "test_code", "Should extract code regardless of domain")
    }
}
