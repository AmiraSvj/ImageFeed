import UIKit

extension UIImage {
    static var placeholder: UIImage {
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Серый цвет для заглушки
            UIColor.systemGray4.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Добавляем иконку изображения в центре
            let iconSize: CGFloat = 40
            let iconRect = CGRect(
                x: (size.width - iconSize) / 2,
                y: (size.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
            
            // Рисуем простую иконку изображения
            UIColor.systemGray2.setFill()
            context.fill(iconRect)
            
            // Добавляем рамку
            UIColor.systemGray3.setStroke()
            context.stroke(iconRect)
        }
    }
}
