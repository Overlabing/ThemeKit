/// The opacities of a Theme's window gradient: primary hue at the top, secondary hue in the middle, primary hue again
/// at the bottom. Drawn over the window background.
public struct GradientSpec: Sendable, Hashable {
    public var top: Double
    public var middle: Double
    public var bottom: Double

    public init(top: Double, middle: Double, bottom: Double) {
        self.top = top
        self.middle = middle
        self.bottom = bottom
    }

    /// Defaults tuned on screen: light keeps the same character as dark, the gradient showing as clearly on white as
    /// on near-black (1.4 to 1.8:1 against the background).
    public static let light = GradientSpec(top: 0.38, middle: 0.16, bottom: 0.05)
    public static let dark = GradientSpec(top: 0.42, middle: 0.18, bottom: 0.06)

    public static func standard(isDark: Bool) -> GradientSpec { isDark ? .dark : .light }

    /// The colour of the gradient at `t` (0 top, 1 bottom) as drawn over `background`.
    public func color(at t: Double, primary: RGBA, secondary: RGBA, over background: RGBA) -> RGBA {
        let first = primary.opacity(top)
        let second = secondary.opacity(middle)
        let last = primary.opacity(bottom)
        let (a, b, local) = t < 0.5 ? (first, second, t / 0.5) : (second, last, (t - 0.5) / 0.5)
        return a.interpolatedPremultiplied(to: b, by: local).composited(over: background)
    }
}
