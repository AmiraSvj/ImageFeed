import UIKit

final class ProgrammaticImageViewController: UIViewController, UIScrollViewDelegate {
    var image: UIImage?

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

        if let image {
            imageView.image = image
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        rescaleAndCenter()
    }

    private func rescaleAndCenter() {
        guard let img = image else { return }
        let imageSize = img.size
        let visibleSize = scrollView.bounds.size
        let hScale = visibleSize.width / imageSize.width
        let vScale = visibleSize.height / imageSize.height
        let scale = max(hScale, vScale)
        let clamped = min(max(scrollView.minimumZoomScale, scale), scrollView.maximumZoomScale)
        scrollView.setZoomScale(clamped, animated: false)
        scrollView.layoutIfNeeded()
        let x = max(0, (scrollView.contentSize.width - visibleSize.width) / 2)
        let y = max(0, (scrollView.contentSize.height - visibleSize.height) / 2)
        scrollView.setContentOffset(CGPoint(x: x, y: y), animated: false)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    @objc private func didTapClose() {
        dismiss(animated: true)
    }

    @objc private func didTapShare() {
        guard let img = image else { return }
        let vc = UIActivityViewController(activityItems: [img], applicationActivities: nil)
        present(vc, animated: true)
    }
}


