import ColorCore
import ColorPlatform

/// One text role on one kind of surface, for one Theme and appearance: the contrast the system's default colour reaches
/// there (`before`: the secondary label, or the raw hue for tinted text) and the contrast the kit's solved ink reaches
/// (`after`), against `threshold`.
public struct LegibilityCase: Sendable, Equatable, CustomStringConvertible {
    public enum Role: String, Sendable, CaseIterable {
        /// Secondary text: `ColorRoles.secondaryText` instead of the system's secondary label.
        case secondaryText
        /// Text in the Theme's colour: `ColorRoles.tintText` instead of the raw primary hue.
        case tintedText
    }

    public enum SurfaceKind: String, Sendable, CaseIterable {
        /// The frame's gradient, top to bottom.
        case frame
        /// A hovered row, a current row, a selected row: their fills over the gradient from `Frame.contentTop` down.
        case hoveredRow
        case currentRow
        case selectedRow
        /// A badge or a tile fill over any of the above (tinted text only).
        case tintedFill
    }

    public let themeID: String
    public let appearance: Appearance
    public let role: Role
    public let surface: SurfaceKind
    public let before: Double
    public let after: Double
    public let threshold: Double

    /// The system's default fails here and the kit's ink does not.
    public var isFixed: Bool { before < threshold && after >= threshold }

    public var description: String {
        "\(themeID) \(appearance) \(role.rawValue) on \(surface.rawValue): \(before) → \(after) (≥ \(threshold))"
    }
}

extension DesignTokens {
    /// Every text role on every surface the kit draws text on, for one Theme in one appearance, with resolved colours
    /// (pure: runs without a window).
    public func legibilityCases(themeID: String, colors: ResolvedColors, in appearance: Appearance) -> [LegibilityCase] {
        let described = surfaces(in: appearance)
        let solved = Legibility.solve(colors: colors, surfaces: described)
        let spec = described.gradient
        func gradient(at t: Double) -> RGBA {
            spec.color(at: t, primary: colors.primary, secondary: colors.secondary, over: colors.background)
        }
        let top = stride(from: 0.0, to: described.contentTop, by: 0.02).map(gradient(at:))
        let content = stride(from: described.contentTop, through: 1.0, by: 0.05).map(gradient(at:))
        func filled(_ opacity: Double) -> [RGBA] { content.map { colors.primary.opacity(opacity).composited(over: $0) } }
        let fills = described.fills
        let kinds: [(LegibilityCase.SurfaceKind, [RGBA])] = [
            (.frame, top + content),
            (.hoveredRow, filled(fills[0])),
            (.currentRow, filled(fills.count > 1 ? fills[1] : fills[0])),
            (.selectedRow, filled(solved.selected)),
        ]
        let everything = kinds.flatMap(\.1)
        let tinted = described.tintFills.flatMap { opacity in
            everything.map { colors.primary.opacity(opacity).composited(over: $0) }
        }

        let secondaryInk = colors.label.opacity(solved.secondaryAlpha / colors.label.alpha)
        let tintInk = colors.primary.mixed(with: colors.ink, by: solved.tintMix)
        var cases: [LegibilityCase] = []
        for (kind, surfaces) in kinds + [(.tintedFill, tinted)] {
            if kind != .tintedFill {
                cases.append(LegibilityCase(
                    themeID: themeID, appearance: appearance, role: .secondaryText, surface: kind,
                    before: Contrast.worst(foreground: colors.secondaryLabel, on: surfaces),
                    after: Contrast.worst(foreground: secondaryInk, on: surfaces), threshold: emphasis.textContrast))
            }
            let range = Contrast.luminances(surfaces)
            cases.append(LegibilityCase(
                themeID: themeID, appearance: appearance, role: .tintedText, surface: kind,
                before: Contrast.worst(opaque: colors.primary, onLuminances: range),
                after: Contrast.worst(opaque: tintInk, onLuminances: range), threshold: emphasis.textContrast))
        }
        return cases
    }

    /// The same with the system's colours for `theme` in `appearance`.
    public func legibilityCases(for theme: Theme, in appearance: Appearance) -> [LegibilityCase] {
        legibilityCases(themeID: theme.id, colors: ResolvedColors(theme, in: appearance), in: appearance)
    }
}
