import UIKit

final class StarWithRingView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let center = CGPoint(x: rect.midX, y: rect.midY)

        // 1. Draw the back/full ring (tilted ellipse)
        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: -CGFloat.pi / 8) // Tilted ring

        let ringWidth = rect.width * 0.95
        let ringHeight = rect.height * 0.40
        let ringRect = CGRect(x: -ringWidth / 2, y: -ringHeight / 2, width: ringWidth, height: ringHeight)

        let ringPath = UIBezierPath(ovalIn: ringRect)
        UIColor.ypBlack.withAlphaComponent(0.25).setStroke()
        ringPath.lineWidth = 2.5
        ringPath.stroke()
        context.restoreGState()

        // 2. Draw the star at the center (slightly tilted counter-clockwise)
        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: -CGFloat.pi / 12) // Slightly tilt the star counter-clockwise

        let starSize = rect.width * 0.45
        let starRect = CGRect(x: -starSize / 2, y: -starSize / 2, width: starSize, height: starSize)
        let path = starPath(in: starRect)

        // Fill with ypWhite to hide the back ring segment under the star
        UIColor.ypWhite.setFill()
        path.fill()

        UIColor.ypBlack.setStroke()
        path.lineWidth = 2.5
        path.lineJoinStyle = .round
        path.stroke()
        context.restoreGState()

        // 3. Draw the front part of the ring on top of the star to create 3D overlap
        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: -CGFloat.pi / 8) // Same tilt as full ring

        let frontRingPath = UIBezierPath()
        // Draw the bottom-right arc of the ellipse (from -pi/8 to 7pi/8)
        frontRingPath.addArc(withCenter: .zero, radius: 1.0, startAngle: -CGFloat.pi / 8, endAngle: 7 * CGFloat.pi / 8, clockwise: true)
        frontRingPath.apply(CGAffineTransform(scaleX: ringWidth / 2, y: ringHeight / 2))

        UIColor.ypBlack.withAlphaComponent(0.25).setStroke()
        frontRingPath.lineWidth = 2.5
        frontRingPath.stroke()
        context.restoreGState()
    }

    private func starPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let center = CGPoint.zero // Centered at origin because of CGContext translation
        let numberOfPoints = 5
        let r = rect.width / 2.0
        let rInner = r * 0.45

        var angle = -CGFloat.pi / 2.0
        let angleIncrement = CGFloat.pi * 2.0 / CGFloat(numberOfPoints * 2)

        for i in 0..<(numberOfPoints * 2) {
            let radius = i % 2 == 0 ? r : rInner
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
            angle += angleIncrement
        }
        path.close()
        return path
    }
}

final class EmptyStateView: UIView {

    private let starView = StarWithRingView()

    private let label: UILabel = {
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .ypBlack
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        
        let illustration: UIView
        if UIImage(named: "emptyStateStar") != nil {
            let imageView = UIImageView(image: UIImage(named: "emptyStateStar"))
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            illustration = imageView
        } else {
            starView.translatesAutoresizingMaskIntoConstraints = false
            illustration = starView
        }
        
        addSubview(illustration)
        addSubview(label)

        NSLayoutConstraint.activate([
            illustration.centerXAnchor.constraint(equalTo: centerXAnchor),
            illustration.topAnchor.constraint(equalTo: topAnchor),
            illustration.widthAnchor.constraint(equalToConstant: 80),
            illustration.heightAnchor.constraint(equalToConstant: 80),

            label.topAnchor.constraint(equalTo: illustration.bottomAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
