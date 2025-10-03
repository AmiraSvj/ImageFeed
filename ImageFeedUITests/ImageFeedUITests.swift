import XCTest

class ImageFeedUITests: XCTestCase {
    private let app = XCUIApplication() // переменная приложения
    
    override func setUpWithError() throws {
        continueAfterFailure = false // настройка выполнения тестов, которая прекратит выполнения тестов, если в тесте что-то пошло не так
        
        app.launch() // запускаем приложение перед каждым тестом
    }
    
    // MARK: - Helper Methods
    
    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
    }
    
    private func tapButton(_ identifier: String) {
        let button = app.buttons[identifier]
        waitForElement(button)
        button.tap()
    }
    
    private func waitForTableCells() {
        let tablesQuery = app.tables
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        waitForElement(cell)
    }
    
    private func scrollUp() {
        let tablesQuery = app.tables
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        cell.swipeUp()
        sleep(2)
    }
    
    private func likeImage(at index: Int) {
        let tablesQuery = app.tables
        let cellToLike = tablesQuery.children(matching: .cell).element(boundBy: index)
        cellToLike.buttons["like button off"].tap()
        cellToLike.buttons["like button on"].tap()
        sleep(2)
    }
    
    private func openImage(at index: Int) {
        let tablesQuery = app.tables
        let cell = tablesQuery.children(matching: .cell).element(boundBy: index)
        cell.tap()
        sleep(2)
    }
    
    private func zoomImage() {
        let image = app.scrollViews.images.element(boundBy: 0)
        waitForElement(image)
        
        // Zoom in
        image.pinch(withScale: 3, velocity: 1)
        // Zoom out
        image.pinch(withScale: 0.5, velocity: -1)
    }
    
    private func goBack() {
        let navBackButton = app.buttons["nav back button white"]
        navBackButton.tap()
    }
    
    private func goToProfile() {
        app.tabBars.buttons.element(boundBy: 1).tap()
    }
    
    private func logout() {
        app.buttons["logout button"].tap()
        app.alerts["Bye bye!"].scrollViews.otherElements.buttons["Yes"].tap()
    }
    
    func testAuth() throws {
        // Нажать кнопку авторизации
        app.buttons["Authenticate"].tap()
        
        // Подождать, пока экран авторизации открывается и загружается
        let webView = app.webViews["UnsplashWebView"]
        XCTAssertTrue(webView.waitForExistence(timeout: 5))
        
        // Ввести данные в форму
        let loginTextField = webView.descendants(matching: .textField).element
        XCTAssertTrue(loginTextField.waitForExistence(timeout: 5))
        
        loginTextField.tap()
        loginTextField.typeText("") // Введите ваш email
        webView.swipeUp()
        
        let passwordTextField = webView.descendants(matching: .secureTextField).element
        XCTAssertTrue(passwordTextField.waitForExistence(timeout: 5))
        
        passwordTextField.tap()
        passwordTextField.typeText("") // Введите ваш пароль
        webView.swipeUp()
        
        // Нажать кнопку логина
        webView.buttons["Login"].tap()
        
        // Подождать, пока открывается экран ленты
        let tablesQuery = app.tables
        let cell = tablesQuery.children(matching: .cell).element(boundBy: 0)
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
    }
    
    func testFeed() throws {
        // Подождать, пока открывается и загружается экран ленты
        waitForTableCells()
        
        // Сделать жест «смахивания» вверх по экрану для его скролла
        scrollUp()
        
        // Поставить и отменить лайк в ячейке верхней картинки
        likeImage(at: 1)
        
        // Нажать на верхнюю ячейку и открыть на весь экран
        openImage(at: 1)
        
        // Увеличить и уменьшить картинку
        zoomImage()
        
        // Вернуться на экран ленты
        goBack()
    }
    
    func testProfile() throws {
        // Подождать, пока открывается и загружается экран ленты
        sleep(3)
        
        // Перейти на экран профиля
        goToProfile()
        
        // Проверить, что на нём отображаются ваши персональные данные
        XCTAssertTrue(app.staticTexts["Name Lastname"].exists)
        XCTAssertTrue(app.staticTexts["@username"].exists)
        
        // Нажать кнопку логаута и подтвердить
        logout()
    }
}