//
//  ImageFeedTests.swift
//  ImageFeedTests
//
//  Created by ameera on 02.07.2025.
//

import XCTest
import Foundation
@testable import ImageFeed

final class ImageFeedTests: XCTestCase {

    func testExample() {
        // Write your test here and use APIs like XCTAssert to check expected conditions.
    }
    
    func testFetchPhotos() {
        let service = ImagesListService.shared
        
        let expectation = XCTestExpectation(description: "Photos loaded")
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
        wait(for: [expectation], timeout: 10.0)
        
        XCTAssertTrue(notificationReceived, "Ожидалось получение уведомления о загрузке фотографий")
        XCTAssertEqual(service.photos.count, 10, "Ожидалось загрузка 10 фотографий, получено: \(service.photos.count)")
    }

}
