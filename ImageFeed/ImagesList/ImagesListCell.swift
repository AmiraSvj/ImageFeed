import UIKit
import Kingfisher

final class PhotoFeedCell: UITableViewCell {
    
    @IBOutlet private var previewImage: UIImageView!
    @IBOutlet private var likeBtn: UIButton!
    @IBOutlet private var dateText: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        previewImage.kf.cancelDownloadTask()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
    }
    
    func configure(with url: URL, date: String, isLiked: Bool) {
        previewImage.kf.setImage(with: url)
        dateText.text = date
        let likeIcon = isLiked ? UIImage(named: "like_button_on") : UIImage(named: "like_button_off")
        likeBtn.setImage(likeIcon, for: .normal)
    }
}
