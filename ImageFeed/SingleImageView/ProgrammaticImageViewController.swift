import UIKit
import Kingfisher

final class ProgrammaticImageViewController: UIViewController, UIScrollViewDelegate {
    var image: UIImage?
    var fullImageURL: String?

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.minimumZoomScale = 0.1
        sv.maximumZoomScale = 3.0
        return sv
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setImage(UIImage(named: "nav_back_button_white"), for: .normal)
        btn.tintColor = .white
        return btn
    }()

    private let shareButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(named: "share_button")?.withRenderingMode(.alwaysOriginal)
        btn.setImage(image, for: .normal)
        btn.tintColor = .clear
        btn.adjustsImageWhenHighlighted = false
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "YP Black") ?? .black

        scrollView.delegate = self
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(closeButton)
        view.addSubview(shareButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),

            shareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shareButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -34),
            shareButton.widthAnchor.constraint(equalToConstant: 50),
            shareButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(didTapShare), for: .touchUpInside)

        loadImage()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let img = image {
            rescaleAndCenterImageInScrollView(image: img)
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    @objc private func didTapClose() {
        // Анимация нажатия на кнопку закрытия
        UIView.animate(withDuration: 0.1, animations: {
            self.closeButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: [.curveEaseOut], animations: {
                self.closeButton.transform = .identity
            }) { _ in
                self.dismiss(animated: true)
            }
        }
    }

    @objc private func didTapShare() {
        guard let img = imageView.image else { return }
        
        // Анимация нажатия на кнопку поделиться
        UIView.animate(withDuration: 0.1, animations: {
            self.shareButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: [.curveEaseOut], animations: {
                self.shareButton.transform = .identity
            }) { _ in
                let vc = UIActivityViewController(activityItems: [img], applicationActivities: nil)
                self.present(vc, animated: true)
            }
        }
    }
    
    private func loadImage() {
        if let image = image {
            imageView.image = image
            rescaleAndCenterImageInScrollView(image: image)
        } else if let urlString = fullImageURL {
            // Проверяем, является ли это мок-URL
            if urlString.hasPrefix("mock://") {
                let imageName = String(urlString.dropFirst(7)) // Убираем "mock://"
                if let image = UIImage(named: imageName) {
                    imageView.image = image
                    self.image = image
                    rescaleAndCenterImageInScrollView(image: image)
                } else {
                    print("⚠️ Изображение '\(imageName)' не найдено в Assets для полноэкранного просмотра")
                    showError()
                }
            } else if let url = URL(string: urlString) {
                // Обычный URL - загружаем через Kingfisher
                loadFullSizeImage(from: url)
            }
        }
    }
    
    private func loadFullSizeImage(from url: URL) {
        UIBlockingProgressHUD.show()
        
        // Начальное состояние - изображение прозрачное
        imageView.alpha = 0
        
        imageView.kf.setImage(with: url) { [weak self] result in
            DispatchQueue.main.async {
                UIBlockingProgressHUD.dismiss()
                
                guard let self = self else { return }
                switch result {
                case .success(let imageResult):
                    self.image = imageResult.image
                    self.rescaleAndCenterImageInScrollView(image: imageResult.image)
                    
                    // Анимация появления изображения
                    UIView.animate(withDuration: 0.5, delay: 0.1, options: [.curveEaseOut], animations: {
                        self.imageView.alpha = 1.0
                    })
                case .failure:
                    self.showError()
                }
            }
        }
    }
    
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        // Добавляем небольшую задержку для корректного центрирования
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let imageSize = image.size
            let visibleSize = self.scrollView.bounds.size
            
            // Рассчитываем масштаб для заполнения всего экрана
            let hScale = visibleSize.width / imageSize.width
            let vScale = visibleSize.height / imageSize.height
            let scale = max(hScale, vScale) // Используем max для заполнения всего экрана
            
            print("🔍 [ProgrammaticImageViewController] Масштабирование: imageSize=\(imageSize), visibleSize=\(visibleSize)")
            print("🔍 [ProgrammaticImageViewController] hScale=\(hScale), vScale=\(vScale), finalScale=\(scale)")
            
            // Устанавливаем размеры imageView равными размеру изображения
            self.imageView.frame = CGRect(origin: .zero, size: imageSize)
            
            // Устанавливаем contentSize равным размеру изображения
            self.scrollView.contentSize = imageSize
            
            // Устанавливаем масштаб
            let clamped = min(max(self.scrollView.minimumZoomScale, scale), self.scrollView.maximumZoomScale)
            self.scrollView.setZoomScale(clamped, animated: false)
            
            // Обновляем layout
            self.scrollView.layoutIfNeeded()
            
            // Центрируем изображение после масштабирования
            let scaledContentSize = CGSize(
                width: self.scrollView.contentSize.width * clamped,
                height: self.scrollView.contentSize.height * clamped
            )
            
            let x = max(0, (scaledContentSize.width - visibleSize.width) / 2)
            let y = max(0, (scaledContentSize.height - visibleSize.height) / 2)
            self.scrollView.setContentOffset(CGPoint(x: x, y: y), animated: false)
        }
    }
    
    private func showError() {
        let alert = UIAlertController(
            title: "Что-то пошло не так",
            message: "Попробовать ещё раз?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Не надо", style: .cancel))
        alert.addAction(UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            if let urlString = self?.fullImageURL, let url = URL(string: urlString) {
                self?.loadFullSizeImage(from: url)
            }
        })
        
        present(alert, animated: true)
    }
}


