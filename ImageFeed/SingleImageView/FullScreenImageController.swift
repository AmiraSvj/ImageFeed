import UIKit

final class FullScreenImageController: UIViewController {
    var selectedImage: UIImage? {
        didSet {
            guard isViewLoaded, let selectedImage else { return }
            
            fullScreenImageView.image = selectedImage
            fullScreenImageView.frame.size = selectedImage.size
            rescaleAndCenterImageInScrollView(image: selectedImage)
        }
    }

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var fullScreenImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25

        guard let selectedImage else { return }
        fullScreenImageView.image = selectedImage
        fullScreenImageView.frame.size = selectedImage.size
        rescaleAndCenterImageInScrollView(image: selectedImage)
    }

    @IBAction private func handleBackButtonTap() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func handleShareButtonTap(_ sender: UIButton) {
        guard let selectedImage else { return }
        let shareVC = UIActivityViewController(
            activityItems: [selectedImage],
            applicationActivities: nil
        )
        present(shareVC, animated: true, completion: nil)
    }
    
    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        let minZoomScale = scrollView.minimumZoomScale
        let maxZoomScale = scrollView.maximumZoomScale
        view.layoutIfNeeded()
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        let hScale = visibleRectSize.width / imageSize.width
        let vScale = visibleRectSize.height / imageSize.height
        let scale = min(maxZoomScale, max(minZoomScale, min(hScale, vScale)))
        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()
        let newContentSize = scrollView.contentSize
        let x = (newContentSize.width - visibleRectSize.width) / 2
        let y = (newContentSize.height - visibleRectSize.height) / 2
        scrollView.setContentOffset(CGPoint(x: x, y: y), animated: false)
    }
}

extension FullScreenImageController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        fullScreenImageView
    }
} 