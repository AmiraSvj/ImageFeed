import UIKit

final class PhotoFeedController: UIViewController {
    
    @IBOutlet private var feedTable: UITableView!
    
    private let imageNames: [String] = (0..<20).map { String($0) }
    
    private lazy var localizedDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    private func setupUI() {
        view.backgroundColor = UIColor(named: "YP Black")
        
        feedTable.backgroundColor = UIColor(named: "YP Black")
        feedTable.rowHeight = 200
        feedTable.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        feedTable.dataSource = self
        feedTable.delegate = self
    }
}

// MARK: - UITableViewDataSource
extension PhotoFeedController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoFeedCell")
        guard let photoCell = cell as? PhotoFeedCell else { return UITableViewCell() }
        configure(cell: photoCell, at: indexPath)
        return photoCell
    }
}

// MARK: - UITableViewDelegate
extension PhotoFeedController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selected image at index: \(indexPath.row)")
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let img = UIImage(named: imageNames[indexPath.row]) else { return 200 }
        let insets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let width = tableView.bounds.width - insets.left - insets.right
        let scale = width / img.size.width
        return img.size.height * scale + insets.top + insets.bottom
    }
}

// MARK: - Private Methods
private extension PhotoFeedController {
    func configure(cell: PhotoFeedCell, at indexPath: IndexPath) {
        guard let img = UIImage(named: imageNames[indexPath.row]) else { return }
        let isLiked = indexPath.row.isMultiple(of: 2)
        let date = localizedDateFormatter.string(from: Date())
        cell.configure(with: img, date: date, isLiked: isLiked)
    }
}
