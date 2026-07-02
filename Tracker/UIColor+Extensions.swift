import UIKit

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }

    static var ypBlue: UIColor {
        return UIColor(hex: "#3772E7")
    }

    static var ypBlack: UIColor {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor(hex: "#1A1B22")
        }
    }

    static var ypWhite: UIColor {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#1A1B22") : UIColor.white
        }
    }

    static var ypGray: UIColor {
        return UIColor(hex: "#AEAFB4")
    }

    static var ypBackground: UIColor {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#414141").withAlphaComponent(0.85) : UIColor(hex: "#E6E8EB").withAlphaComponent(0.3)
        }
    }

    static var ypLightGray: UIColor {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#2F3035") : UIColor(hex: "#E6E8EB")
        }
    }

    static var ypRed: UIColor {
        return UIColor(hex: "#F56B6C")
    }

    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
