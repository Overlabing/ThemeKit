import Foundation

/// WCAG 2.x contrast ratios (1…21).
public enum Contrast {
    /// Body text at any size: 4.5:1.
    public static let text: Double = 4.5
    /// Non-text indicators (glyphs, status dots): 3:1.
    public static let nonText: Double = 3

    /// Ratio between two opaque colours.
    public static func ratio(_ a: RGBA, _ b: RGBA) -> Double {
        let la = a.relativeLuminance
        let lb = b.relativeLuminance
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    /// Ratio of a foreground, possibly translucent (a secondary label is black at 50 %), drawn on an opaque surface.
    public static func ratio(foreground: RGBA, on surface: RGBA) -> Double {
        ratio(foreground.composited(over: surface), surface)
    }

    /// The lowest ratio of `foreground` over every surface: the one the eye meets last.
    public static func worst(foreground: RGBA, on surfaces: [RGBA]) -> Double {
        surfaces.map { ratio(foreground: foreground, on: $0) }.min() ?? 21
    }

    /// The same for an opaque foreground, from the surfaces' luminance range only: the ratio falls as a surface's
    /// luminance nears the foreground's, so the worst surface is the nearer extreme (1 inside the range). What makes
    /// solving a palette cheap.
    public static func worst(opaque foreground: RGBA, onLuminances range: ClosedRange<Double>) -> Double {
        let l = foreground.relativeLuminance
        if range.contains(l) { return 1 }
        let nearest = l < range.lowerBound ? range.lowerBound : range.upperBound
        return (max(l, nearest) + 0.05) / (min(l, nearest) + 0.05)
    }

    /// The luminance range of opaque surfaces.
    public static func luminances(_ surfaces: [RGBA]) -> ClosedRange<Double> {
        let values = surfaces.map(\.relativeLuminance)
        return (values.min() ?? 0)...(values.max() ?? 1)
    }
}
