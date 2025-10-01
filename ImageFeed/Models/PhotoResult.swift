import Foundation

// MARK: - PhotoResult
struct PhotoResult: Codable {
    let id: String
    let createdAt: String?
    let updatedAt: String?
    let width: Int
    let height: Int
    let color: String?
    let blurHash: String?
    let likes: Int
    let likedByUser: Bool
    let description: String?
    let urls: UrlsResult
    let links: LinksResult
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case width, height, color
        case blurHash = "blur_hash"
        case likes
        case likedByUser = "liked_by_user"
        case description
        case urls, links
    }
}

// MARK: - UrlsResult
struct UrlsResult: Codable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

// MARK: - LinksResult
struct LinksResult: Codable {
    let selfLink: String
    let html: String
    let download: String
    let downloadLocation: String
    
    enum CodingKeys: String, CodingKey {
        case selfLink = "self"
        case html, download
        case downloadLocation = "download_location"
    }
}

// MARK: - LikeResponse
struct LikeResponse: Codable {
    let photo: PhotoResult
    let user: LikeUserResult
}

// MARK: - LikeUserResult
struct LikeUserResult: Codable {
    let id: String
    let username: String
    let name: String
}
