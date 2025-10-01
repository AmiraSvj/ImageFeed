import UIKit
import Kingfisher

final class PhotoFeedController: UIViewController {
    
    @IBOutlet private var feedTable: UITableView!
    
    private let imagesListService = ImagesListService.shared
    private var photos: [Photo] = []
    private var photosObserver: NSObjectProtocol?
    
    private lazy var localizedDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotificationObserver()
        imagesListService.fetchPhotosNextPage()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeNotificationObserver()
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
        return photos.count
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
        tableView.deselectRow(at: indexPath, animated: true)
        let photo = photos[indexPath.row]
        let vc = ProgrammaticImageViewController()
        vc.fullImageURL = photo.largeImageURL
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = photos[indexPath.row]
        let insets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let width = tableView.bounds.width - insets.left - insets.right
        let scale = width / photo.size.width
        return photo.size.height * scale + insets.top + insets.bottom
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == photos.count {
            imagesListService.fetchPhotosNextPage()
        }
    }
}

// MARK: - Private Methods
private extension PhotoFeedController {
    func configure(cell: PhotoFeedCell, at indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        
        // Загружаем изображение через Kingfisher
        if let url = URL(string: photo.thumbImageURL) {
            cell.configure(with: url, date: formatDate(photo.createdAt), isLiked: photo.isLiked)
        }
    }
    
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        return localizedDateFormatter.string(from: date)
    }
    
    func setupNotificationObserver() {
        photosObserver = NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updatePhotos()
        }
    }
    
    func removeNotificationObserver() {
        if let observer = photosObserver {
            NotificationCenter.default.removeObserver(observer)
            photosObserver = nil
        }
    }
    
    func updatePhotos() {
        let oldCount = photos.count
        photos = imagesListService.photos
        let newCount = photos.count
        
        if newCount > oldCount {
            let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
            feedTable.insertRows(at: indexPaths, with: .automatic)
        }
    }
}
