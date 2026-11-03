#if canImport(AppKit)
import AppKit

/// The colour type of the platform, under a name of this module's own: `NSColor` on macOS, `UIColor` elsewhere.
public typealias NativeColor = NSColor

extension NativeColor {
    /// A colour from sRGB components.
    public static func sRGB(red: Double, green: Double, blue: Double, alpha: Double = 1) -> NativeColor {
        NSColor(srgbRed: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
}
#elseif canImport(UIKit)
import UIKit

public typealias NativeColor = UIColor

extension NativeColor {
    /// A colour from sRGB components (UIKit's initializer takes extended sRGB, the same inside 0…1).
    public static func sRGB(red: Double, green: Double, blue: Double, alpha: Double = 1) -> NativeColor {
        UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
}
#endif
