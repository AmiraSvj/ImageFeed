import UIKit
import Kingfisher

final class PhotoFeedCell: UITableViewCell {
    
    @IBOutlet private var previewImage: UIImageView!
    @IBOutlet private var likeBtn: UIButton!
    @IBOutlet private var dateText: UILabel!
    
    weak var delegate: PhotoFeedCellDelegate?
    private var photoId: String?
    private var isLiked: Bool = false
    private var gradientView: AnimatedGradientView?
    private var animationTimer: Timer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        print("🔄 [PhotoFeedCell] prepareForReuse вызван для photoId: \(photoId ?? "nil")")
        
        // Отменяем загрузку изображения
        previewImage.kf.cancelDownloadTask()
        previewImage.image = nil
        
        // Отменяем таймер
        animationTimer?.invalidate()
        animationTimer = nil
        
        // Останавливаем анимацию
        stopGradientAnimation()
        
        // Сбрасываем состояние
        photoId = nil
        isLiked = false
        
        // Сбрасываем UI элементы
        dateText.text = nil
        likeBtn.setImage(UIImage(named: "like_button_off"), for: .normal)
        
        print("✅ [PhotoFeedCell] prepareForReuse завершен")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // Настраиваем кнопку лайка
        likeBtn.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
    }
    
    @objc private func likeButtonTapped() {
        guard let photoId = photoId else { return }
        
        // Анимация нажатия на кнопку лайка
        UIView.animate(withDuration: 0.1, animations: {
            self.likeBtn.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: [.curveEaseOut], animations: {
                self.likeBtn.transform = .identity
            })
        }
        
        delegate?.photoFeedCellDidTapLike(self, photoId: photoId, isLiked: isLiked)
    }
    
    func configure(with url: URL, date: String, isLiked: Bool, photoId: String, completion: (() -> Void)? = nil) {
        print("🔧 [PhotoFeedCell] Настраиваем ячейку для photoId: \(photoId)")
        print("🔍 [PhotoFeedCell] Текущий photoId: \(self.photoId ?? "nil"), gradientView: \(gradientView != nil ? "есть" : "нет")")
        
        // Проверяем, не настраиваем ли мы ту же ячейку повторно для того же photoId
        if self.photoId == photoId && gradientView != nil {
            print("⚠️ [PhotoFeedCell] Ячейка уже настроена для этого photoId, пропускаем")
            return
        }
        
        // Останавливаем предыдущую анимацию, если есть
        if gradientView != nil {
            print("🔄 [PhotoFeedCell] Останавливаем предыдущую анимацию перед настройкой")
            stopGradientAnimation()
        }
        
        self.photoId = photoId
        self.isLiked = isLiked
        
        // Запускаем градиентную анимацию
        startGradientAnimation()
        
        // Настраиваем индикатор загрузки
        previewImage.kf.indicatorType = .activity
        
        // Проверяем, является ли это мок-URL
        if url.scheme == "mock" {
            let imageName = url.host ?? "0"
            if let image = UIImage(named: imageName) {
                previewImage.image = image
                // Добавляем задержку для анимации через таймер
                animationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                    self.stopGradientAnimation()
                }
                completion?()
            } else {
                previewImage.image = UIImage.placeholder
                print("⚠️ Изображение '\(imageName)' не найдено в Assets")
            }
        } else {
            // Загружаем изображение с заглушкой для обычных URL
            previewImage.kf.setImage(
                with: url,
                placeholder: UIImage.placeholder,
                options: [.transition(.fade(0.2))]
            ) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        // Добавляем задержку для анимации через таймер
                        self.animationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                            self.stopGradientAnimation()
                        }
                        // Обновляем высоту ячейки после загрузки изображения
                        completion?()
                    case .failure(let error):
                        print("Ошибка загрузки изображения: \(error)")
                        self.stopGradientAnimation()
                    }
                }
            }
        }
        
        dateText.text = date
        let likeIcon = isLiked ? UIImage(named: "like_button_on") : UIImage(named: "like_button_off")
        likeBtn.setImage(likeIcon, for: .normal)
    }
    
    func setIsLiked(_ isLiked: Bool) {
        print("❤️ [PhotoFeedCell] setIsLiked вызван: \(isLiked) для photoId: \(photoId ?? "nil")")
        self.isLiked = isLiked
        
        // Анимация изменения состояния лайка
        UIView.transition(with: likeBtn, duration: 0.3, options: [.transitionCrossDissolve], animations: {
            let likeIcon = isLiked ? UIImage(named: "like_button_on") : UIImage(named: "like_button_off")
            self.likeBtn.setImage(likeIcon, for: .normal)
        })
        
        // Дополнительная анимация масштабирования для красного сердечка
        if isLiked {
            UIView.animate(withDuration: 0.2, delay: 0.1, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: [.curveEaseOut], animations: {
                self.likeBtn.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }) { _ in
                UIView.animate(withDuration: 0.2, animations: {
                    self.likeBtn.transform = .identity
                })
            }
        }
        
        print("✅ [PhotoFeedCell] UI лайка обновлен")
    }
    
    private func startGradientAnimation() {
        print("🎬 [PhotoFeedCell] Запускаем градиентную анимацию")
        
        // Останавливаем предыдущую анимацию, если есть
        if gradientView != nil {
            gradientView?.stopAnimation()
            gradientView?.removeFromSuperview()
            gradientView = nil
        }
        
        let gradientView = AnimatedGradientView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        gradientView.isUserInteractionEnabled = false
        gradientView.backgroundColor = UIColor.clear
        
        // Добавляем поверх previewImage
        previewImage.superview?.addSubview(gradientView)
        self.gradientView = gradientView
        
        NSLayoutConstraint.activate([
            gradientView.leadingAnchor.constraint(equalTo: previewImage.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: previewImage.trailingAnchor),
            gradientView.topAnchor.constraint(equalTo: previewImage.topAnchor),
            gradientView.bottomAnchor.constraint(equalTo: previewImage.bottomAnchor)
        ])
        
        gradientView.startAnimation()
        print("✅ [PhotoFeedCell] Градиентная анимация запущена")
    }
    
    private func stopGradientAnimation() {
        print("🛑 [PhotoFeedCell] Останавливаем градиентную анимацию")
        print("🔍 [PhotoFeedCell] gradientView перед остановкой: \(gradientView != nil ? "есть" : "нет")")
        
        // Отменяем таймер
        animationTimer?.invalidate()
        animationTimer = nil
        
        // Останавливаем и удаляем анимацию
        if let gradientView = gradientView {
            gradientView.stopAnimation()
            gradientView.removeFromSuperview()
            print("✅ [PhotoFeedCell] gradientView удален из superview")
        }
        gradientView = nil
        print("✅ [PhotoFeedCell] gradientView установлен в nil")
    }
    
}

// MARK: - PhotoFeedCellDelegate
protocol PhotoFeedCellDelegate: AnyObject {
    func photoFeedCellDidTapLike(_ cell: PhotoFeedCell, photoId: String, isLiked: Bool)
}
