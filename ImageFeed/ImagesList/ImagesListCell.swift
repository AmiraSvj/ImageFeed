import UIKit

final class PhotoFeedCell: UITableViewCell {
    
    @IBOutlet private var previewImage: UIImageView!
    @IBOutlet private var likeBtn: UIButton!
    @IBOutlet private var dateText: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
    }
    
    func configure(with image: UIImage, date: String, isLiked: Bool) {
        previewImage.image = image
        dateText.text = date
        let likeIcon = isLiked ? UIImage(named: "like_button_on") : UIImage(named: "like_button_off")
        likeBtn.setImage(likeIcon, for: .normal)
    }
}
