import UIKit
import Kingfisher

final class PhotoFeedController: UIViewController {
    
    @IBOutlet private var feedTable: UITableView!
    
    private let imagesListService = ImagesListService.shared
    
    private var photos: [Photo] = []
    private var photosObserver: NSObjectProtocol?
    private var isLikeRequestInProgress = false
    private var isLoadingMorePhotos = false
    
    private lazy var localizedDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📱 [PhotoFeedController] viewDidLoad вызван")
        setupUI()
        setupNotificationObserver()
        // Запускаем загрузку фотографий
        imagesListService.fetchPhotosNextPage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("👁️ [PhotoFeedController] viewDidAppear вызван")
        
        // Убираем reloadData из viewDidAppear, так как он вызывает бесконечный цикл
        // Таблица уже обновляется в updatePhotos()
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
        photoCell.delegate = self
        configure(cell: photoCell, at: indexPath)
        
        // Анимация появления ячейки
        photoCell.alpha = 0
        photoCell.transform = CGAffineTransform(translationX: 0, y: 20)
        
        UIView.animate(withDuration: 0.5, delay: Double(indexPath.row) * 0.1, options: [.curveEaseOut], animations: {
            photoCell.alpha = 1.0
            photoCell.transform = .identity
        })
        
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
        
        // Минимальная высота для заглушки
        let minHeight: CGFloat = 200
        
        // Рассчитываем высоту на основе пропорций изображения
        let scale = width / photo.size.width
        let calculatedHeight = photo.size.height * scale + insets.top + insets.bottom
        
        return max(calculatedHeight, minHeight)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Загружаем следующую страницу только когда показываем последние 3 ячейки
        if indexPath.row + 3 >= photos.count && !isLoadingMorePhotos {
            print("📄 Загружаем следующую страницу фотографий...")
            isLoadingMorePhotos = true
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
            cell.configure(
                with: url,
                date: formatDate(photo.createdAt),
                isLiked: photo.isLiked,
                photoId: photo.id
            ) { [weak self] in
                // Обновляем высоту ячейки после загрузки изображения
                // Убираем reloadRows, так как это вызывает бесконечный цикл
                // self?.feedTable.reloadRows(at: [indexPath], with: .none)
            }
        }
    }
    
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        return localizedDateFormatter.string(from: date)
    }
    
    func setupNotificationObserver() {
        let notificationName = ImagesListService.didChangeNotification
        
        print("🔔 [PhotoFeedController] Настраиваем наблюдатель для уведомления: \(notificationName)")
        
        photosObserver = NotificationCenter.default.addObserver(
            forName: notificationName,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("🔔 [PhotoFeedController] Получено уведомление didChangeNotification")
            print("🔍 [PhotoFeedController] Источник уведомления: \(notification.object ?? "nil")")
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
        let newPhotos: [Photo] = imagesListService.photos
        let newCount = newPhotos.count
        
        print("🔄 [PhotoFeedController] updatePhotos: oldCount=\(oldCount), newCount=\(newCount)")
        
        // Проверяем, что view уже загружен
        guard isViewLoaded else {
            print("⚠️ [PhotoFeedController] View еще не загружен, откладываем обновление UI")
            // Обновляем данные, но не UI
            photos = newPhotos
            return
        }
        
        // Проверяем, действительно ли есть изменения
        if photos == newPhotos {
            print("⚠️ [PhotoFeedController] Данные не изменились, пропускаем обновление")
            return
        }
        
        if newCount > oldCount {
            photos = newPhotos
            
            print("🔄 Обновление таблицы: добавлено \(newCount - oldCount) новых фотографий")
            
            // Простое обновление таблицы без анимации
            print("🔄 [PhotoFeedController] Вызываем reloadData для \(newCount) фотографий")
            feedTable.reloadData()
            print("✅ Обновление таблицы завершено. Всего фотографий: \(newCount)")
            
            // Сбрасываем флаг загрузки
            isLoadingMorePhotos = false
        } else if newCount == oldCount {
            // Обновляем существующие фотографии (например, при изменении лайков)
            photos = newPhotos
            feedTable.reloadData()
            print("🔄 [PhotoFeedController] Обновлены существующие фотографии")
            
            // Сбрасываем флаг загрузки
            isLoadingMorePhotos = false
        } else {
            print("⚠️ [PhotoFeedController] Неожиданное изменение количества фотографий: \(oldCount) -> \(newCount)")
            
            // Сбрасываем флаг загрузки
            isLoadingMorePhotos = false
        }
    }
}

// MARK: - PhotoFeedCellDelegate
extension PhotoFeedController: PhotoFeedCellDelegate {
    func photoFeedCellDidTapLike(_ cell: PhotoFeedCell, photoId: String, isLiked: Bool) {
        print("❤️ [PhotoFeedController] Пользователь нажал на лайк для photoId: \(photoId), isLiked: \(isLiked)")
        
        // Защита от множественных нажатий
        guard !isLikeRequestInProgress else {
            print("⏳ [PhotoFeedController] Запрос лайка уже выполняется, игнорируем нажатие")
            return
        }
        
        guard let indexPath = feedTable.indexPath(for: cell) else { return }
        let photo = photos[indexPath.row]
        
        // Устанавливаем флаг выполнения запроса
        isLikeRequestInProgress = true
        
        // Показываем индикатор загрузки
        UIBlockingProgressHUD.show()
        
        // Вызываем метод изменения лайка
        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            DispatchQueue.main.async {
                // Сбрасываем флаг выполнения запроса
                self?.isLikeRequestInProgress = false
                UIBlockingProgressHUD.dismiss()
                
                switch result {
                case .success:
                    print("✅ [PhotoFeedController] Лайк успешно изменен")
                    // Синхронизируем массив картинок с сервисом
                    self?.photos = self?.imagesListService.photos ?? []
                    // Изменим индикацию лайка картинки
                    cell.setIsLiked(self?.photos[indexPath.row].isLiked ?? false)
                case .failure(let error):
                    print("❌ [PhotoFeedController] Ошибка изменения лайка: \(error)")
                    
                    // Показываем уведомление об ошибке
                    let alert = UIAlertController(
                        title: "Ошибка",
                        message: "Не удалось изменить лайк. Попробуйте еще раз.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
}
