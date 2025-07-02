import UIKit

final class PhotoFeedController: UIViewController {
    @IBOutlet private weak var feedTable: UITableView!
    
    private let imageNames: [String] = (0..<20).map { String($0) }
    
    private lazy var localizedDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black")
        feedTable.rowHeight = 200
        feedTable.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
    }
}

// MARK: - UITableViewDataSource
extension PhotoFeedController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        imageNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PhotoFeedCell.cellID, for: indexPath)
        guard let photoCell = cell as? PhotoFeedCell else { return UITableViewCell() }
        configure(cell: photoCell, at: indexPath)
        return photoCell
    }
}

// MARK: - Cell Configuration
private extension PhotoFeedController {
    func configure(cell: PhotoFeedCell, at indexPath: IndexPath) {
        guard let img = UIImage(named: imageNames[indexPath.row]) else { return }
        cell.previewImage.image = img
        cell.dateText.text = localizedDateFormatter.string(from: Date())
        let liked = indexPath.row.isMultiple(of: 2)
        let likeIcon = liked ? UIImage(named: "like_button_on") : UIImage(named: "like_button_off")
        cell.likeBtn.setImage(likeIcon, for: .normal)
    }
}

// MARK: - UITableViewDelegate
extension PhotoFeedController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let img = UIImage(named: imageNames[indexPath.row]) else { return 0 }
        let insets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let width = tableView.bounds.width - insets.left - insets.right
        let scale = width / img.size.width
        return img.size.height * scale + insets.top + insets.bottom
    }
}
