import UIKit

final class PhotoFeedCell: UITableViewCell {
    static let cellID = "PhotoFeedCell"
    
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var likeBtn: UIButton!
    @IBOutlet weak var dateText: UILabel!
}
