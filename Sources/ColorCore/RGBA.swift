import Foundation

/// An sRGB colour, components in 0…1, straight (not premultiplied) alpha. Platform colours resolve into it per
/// appearance (`ColorPlatform`); everything measured here is plain arithmetic, testable without a window.
public struct RGBA: Sendable, Equatable, Hashable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public static let black = RGBA(red: 0, green: 0, blue: 0)
    public static let white = RGBA(red: 1, green: 1, blue: 1)

    /// The same colour at `opacity` times its own alpha, as `Color.opacity(_:)` draws it.
    public func opacity(_ opacity: Double) -> RGBA {
        RGBA(red: red, green: green, blue: blue, alpha: alpha * opacity)
    }

    /// Source-over compositing on `background`, the way a fill or a text is drawn on what lies under it. The result
    /// keeps the background's alpha when it is opaque (the only case measured: every surface ends on the window).
    public func composited(over background: RGBA) -> RGBA {
        let a = alpha + background.alpha * (1 - alpha)
        guard a > 0 else { return RGBA(red: 0, green: 0, blue: 0, alpha: 0) }
        func channel(_ top: Double, _ bottom: Double) -> Double {
            (top * alpha + bottom * background.alpha * (1 - alpha)) / a
        }
        return RGBA(
            red: channel(red, background.red), green: channel(green, background.green),
            blue: channel(blue, background.blue), alpha: a)
    }

    /// Straight interpolation of the opaque channels toward `other` (`fraction` 0: self, 1: other), alpha toward its
    /// alpha: how a hue is mixed with the ink for a tinted text (`Legibility`).
    public func mixed(with other: RGBA, by fraction: Double) -> RGBA {
        let t = min(max(fraction, 0), 1)
        return RGBA(
            red: red + (other.red - red) * t, green: green + (other.green - green) * t,
            blue: blue + (other.blue - blue) * t, alpha: alpha + (other.alpha - alpha) * t)
    }

    /// Interpolation of premultiplied colours, how a gradient blends its stops: a stop at low opacity does not drag
    /// the hue toward black.
    public func interpolatedPremultiplied(to other: RGBA, by t: Double) -> RGBA {
        let alpha = self.alpha + (other.alpha - self.alpha) * t
        guard alpha > 0 else { return RGBA(red: 0, green: 0, blue: 0, alpha: 0) }
        func channel(_ x: Double, _ y: Double) -> Double {
            (x * self.alpha + (y * other.alpha - x * self.alpha) * t) / alpha
        }
        return RGBA(
            red: channel(red, other.red), green: channel(green, other.green), blue: channel(blue, other.blue),
            alpha: alpha)
    }

    /// WCAG 2.x relative luminance of the opaque colour.
    public var relativeLuminance: Double {
        func linear(_ v: Double) -> Double { v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
}
