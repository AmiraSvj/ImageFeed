import UIKit

final class AnimatedGradientView: UIView {
    
    private var gradientLayer: CAGradientLayer?
    private var animationLayers = Set<CALayer>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bounds
    }
    
    private func setupGradient() {
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.locations = [0, 0.1, 0.3]
        gradient.colors = [
            UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.3).cgColor,
            UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 0.6).cgColor,
            UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.3).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.cornerRadius = 8 // Фиксированный радиус вместо bounds.height / 2
        gradient.masksToBounds = true
        
        layer.addSublayer(gradient)
        gradientLayer = gradient
        animationLayers.insert(gradient)
    }
    
    func startAnimation() {
        guard let gradient = gradientLayer else { return }
        
        // Анимация движения градиента слева направо
        let startPointAnimation = CABasicAnimation(keyPath: "startPoint")
        startPointAnimation.duration = 1.5
        startPointAnimation.repeatCount = .infinity
        startPointAnimation.autoreverses = true
        startPointAnimation.fromValue = CGPoint(x: -0.5, y: 0.5)
        startPointAnimation.toValue = CGPoint(x: 1.5, y: 0.5)
        
        let endPointAnimation = CABasicAnimation(keyPath: "endPoint")
        endPointAnimation.duration = 1.5
        endPointAnimation.repeatCount = .infinity
        endPointAnimation.autoreverses = true
        endPointAnimation.fromValue = CGPoint(x: 0.5, y: 0.5)
        endPointAnimation.toValue = CGPoint(x: 2.0, y: 0.5)
        
        gradient.add(startPointAnimation, forKey: "startPointAnimation")
        gradient.add(endPointAnimation, forKey: "endPointAnimation")
    }
    
    func stopAnimation() {
        animationLayers.forEach { layer in
            layer.removeAllAnimations()
            layer.removeFromSuperlayer()
        }
        animationLayers.removeAll()
        gradientLayer = nil
    }
    
    deinit {
        stopAnimation()
    }
}
