//
//  ImageFeedTests.swift
//  ImageFeedTests
//
//  Created by ameera on 02.07.2025.
//

import Testing
@testable import ImageFeed

struct ImageFeedTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func testFetchPhotos() async throws {
        let service = ImagesListService.shared
        
        let expectation = Expectation()
        var notificationReceived = false
        
        NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            notificationReceived = true
            expectation.fulfill()
        }
        
        service.fetchPhotosNextPage()
        
        // Ждем уведомление в течение 10 секунд
        try await expectation.wait(for: .seconds(10))
        
        #expect(notificationReceived, "Ожидалось получение уведомления о загрузке фотографий")
        #expect(service.photos.count == 10, "Ожидалось загрузка 10 фотографий, получено: \(service.photos.count)")
    }

}
