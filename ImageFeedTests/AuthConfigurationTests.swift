import XCTest
@testable import ImageFeed

final class AuthConfigurationTests: XCTestCase {
    
    func testStandardConfiguration() {
        //given
        let configuration = AuthConfiguration.standard
        
        //when & then
        XCTAssertEqual(configuration.accessKey, Constants.accessKey)
        XCTAssertEqual(configuration.secretKey, Constants.secretKey)
        XCTAssertEqual(configuration.redirectURI, Constants.redirectURI)
        XCTAssertEqual(configuration.accessScope, Constants.accessScope)
        XCTAssertEqual(configuration.authURLString, Constants.unsplashAuthorizeURLString)
        XCTAssertEqual(configuration.defaultBaseURL, Constants.defaultBaseURL)
    }
    
    func testCustomConfiguration() {
        //given
        let customAccessKey = "custom_access_key"
        let customSecretKey = "custom_secret_key"
        let customRedirectURI = "custom://redirect"
        let customAccessScope = "custom_scope"
        let customAuthURLString = "https://custom.com/oauth/authorize"
        let customDefaultBaseURL = URL(string: "https://custom.com")!
        
        //when
        let configuration = AuthConfiguration(
            accessKey: customAccessKey,
            secretKey: customSecretKey,
            redirectURI: customRedirectURI,
            accessScope: customAccessScope,
            authURLString: customAuthURLString,
            defaultBaseURL: customDefaultBaseURL
        )
        
        //then
        XCTAssertEqual(configuration.accessKey, customAccessKey)
        XCTAssertEqual(configuration.secretKey, customSecretKey)
        XCTAssertEqual(configuration.redirectURI, customRedirectURI)
        XCTAssertEqual(configuration.accessScope, customAccessScope)
        XCTAssertEqual(configuration.authURLString, customAuthURLString)
        XCTAssertEqual(configuration.defaultBaseURL, customDefaultBaseURL)
    }
}
