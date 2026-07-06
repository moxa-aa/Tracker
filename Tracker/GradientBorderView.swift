import UIKit

final class GradientBorderView: UIView {
    private let borderLayer = CAGradientLayer()
    private let maskLayer = CAShapeLayer()
    
    var borderWidth: CGFloat = 1.0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    var cornerRadius: CGFloat = 16.0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    var gradientColors: [UIColor] = [
        UIColor(hex: "#FD4C34"),
        UIColor(hex: "#46CF69"),
        UIColor(hex: "#007BFA")
    ] {
        didSet {
            borderLayer.colors = gradientColors.map { $0.cgColor }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    private func setupLayer() {
        borderLayer.colors = gradientColors.map { $0.cgColor }
        borderLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        borderLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        layer.addSublayer(borderLayer)
        
        maskLayer.fillColor = UIColor.clear.cgColor
        maskLayer.strokeColor = UIColor.black.cgColor
        borderLayer.mask = maskLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        borderLayer.frame = bounds
        maskLayer.frame = bounds
        
        let path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2),
            cornerRadius: cornerRadius - borderWidth / 2
        )
        maskLayer.path = path.cgPath
        maskLayer.lineWidth = borderWidth
    }
}
