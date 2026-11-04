import ColorCore
import ColorPlatform

/// One text or glyph role on one kind of surface, for one Theme (or one hue) and appearance: the contrast the system's
/// default colour reaches there (`before`) and the contrast the kit's colour reaches (`after`), against `threshold`:
/// 4.5:1 for text, 3:1 for glyphs, focus rings and outlines.
public struct LegibilityCase: Sendable, Equatable, CustomStringConvertible {
    public enum Role: String, Sendable, CaseIterable {
        /// Secondary text: `ColorRoles.secondaryText` instead of the system's secondary label.
        case secondaryText
        /// Text in the Theme's colour: `ColorRoles.tintText` instead of the raw primary hue.
        case tintedText
        /// Text in the label colour (titles, the switcher's name), which the kit leaves to the system.
        case primaryText
        /// A glyph in the Theme's colour (a banner's symbol): `ColorRoles.tintText` instead of the raw hue.
        case tintedGlyph
        /// Text on the opaque primary hue (a band, a glyph's initial): white, or black where white falls short.
        case textOnHue
        /// A symbol on an opaque hue (a tile, a glyph, a field pill's circle): white, or black where white falls short.
        case symbolOnHue
        /// The keyboard focus ring: `ColorRoles.focusRing` instead of the translucent system focus colour.
        case focusRing
        /// The outline of a selected or current row under Increase Contrast: `ColorRoles.outline` instead of the
        /// separator.
        case selectionOutline
    }

    public enum SurfaceKind: String, Sendable, CaseIterable {
        /// The frame's gradient, top to bottom.
        case frame
        /// A hovered row, a current row, a selected row: their fills over the gradient from `Frame.contentTop` down,
        /// free or on a panel.
        case hoveredRow
        case currentRow
        case selectedRow
        /// A badge or a tile fill over any of the above (tinted text only).
        case tintedFill
        /// The panel that groups an open folder's rows, over the gradient.
        case layerPanel
        /// Glass (a field pill, a banner), taken as anything between the plain window background (its Reduce
        /// Transparency fill) and the gradient under it.
        case glass
        /// The switcher's selected capsule: the hue at `Emphasis.glassTint` over glass, from `Emphasis.switcherTop` down.
        case switcherSelection
        /// The hue itself, opaque.
        case solidHue
    }

    /// The Theme's id, or the hue's name for a symbol on a hue.
    public let themeID: String
    public let appearance: Appearance
    public let role: Role
    public let surface: SurfaceKind
    public let before: Double
    public let after: Double
    public let threshold: Double

    /// The system's default fails here and the kit's colour does not.
    public var isFixed: Bool { before < threshold && after >= threshold }

    public var description: String {
        "\(themeID) \(appearance) \(role.rawValue) on \(surface.rawValue): \(before) → \(after) (≥ \(threshold))"
    }
}

extension DesignTokens {
    /// Every text and glyph role on every surface the kit draws them on, for one Theme in one appearance, with resolved
    /// colours (pure: runs without a window). The focus ring cases need the system's focus colour, the outline cases
    /// (Increase Contrast only) the separator's; without them those cases are left out.
    public func legibilityCases(
        themeID: String, colors: ResolvedColors, focus: RGBA? = nil, separator: RGBA? = nil, in appearance: Appearance
    ) -> [LegibilityCase] {
        let solved = Legibility.fit(colors: colors, surfaces: surfaces(in: appearance))
        let described = surfaces(in: appearance).scaled(by: solved.hueScale)
        let spec = described.gradient
        func gradient(at t: Double) -> RGBA {
            spec.color(at: t, primary: colors.primary, secondary: colors.secondary, over: colors.background)
        }
        let ink = colors.ink
        let top = stride(from: 0.0, to: described.contentTop, by: 0.02).map(gradient(at:))
        let content = stride(from: described.contentTop, through: 1.0, by: 0.05).map(gradient(at:))
        let panels = described.neutralFills.flatMap { opacity in content.map { ink.opacity(opacity).composited(over: $0) } }
        func filled(_ opacity: Double) -> [RGBA] {
            (content + panels).map { colors.primary.opacity(opacity).composited(over: $0) }
        }
        let fills = described.fills
        let rows: [(LegibilityCase.SurfaceKind, [RGBA])] = [
            (.frame, top + content),
            (.hoveredRow, filled(fills[0])),
            (.currentRow, filled(fills.count > 1 ? fills[1] : fills[0])),
            (.selectedRow, filled(solved.selected)),
            (.layerPanel, panels),
        ]
        let everyRow = rows.flatMap(\.1)
        let tinted = described.tintFills.flatMap { opacity in
            everyRow.map { colors.primary.opacity(opacity).composited(over: $0) }
        }
        let glass = [colors.background] + stride(from: 0.0, through: 1.0, by: 0.05).map(gradient(at:))
        let switcher = ([colors.background] + stride(from: emphasis.switcherTop, through: 1.0, by: 0.05).map(gradient(at:)))
            .map { colors.primary.opacity(emphasis.glassTint).composited(over: $0) }

        let secondaryInk = colors.label.opacity(solved.secondaryAlpha / colors.label.alpha)
        let tintInk = colors.primary.mixed(with: ink, by: solved.tintMix)
        var cases: [LegibilityCase] = []
        func add(_ role: LegibilityCase.Role, _ kind: LegibilityCase.SurfaceKind, _ before: Double, _ after: Double,
                 _ threshold: Double) {
            cases.append(LegibilityCase(
                themeID: themeID, appearance: appearance, role: role, surface: kind, before: before, after: after,
                threshold: threshold))
        }
        let text = emphasis.textContrast
        let nonText = emphasis.nonTextContrast
        for (kind, surfaces) in rows + [(.glass, glass), (.switcherSelection, switcher)] {
            let label = Contrast.worst(foreground: colors.label, on: surfaces)
            add(.primaryText, kind, label, label, text)
        }
        for (kind, surfaces) in rows + [(.glass, glass)] {
            add(.secondaryText, kind, Contrast.worst(foreground: colors.secondaryLabel, on: surfaces),
                Contrast.worst(foreground: secondaryInk, on: surfaces), text)
        }
        for (kind, surfaces) in rows + [(.tintedFill, tinted)] {
            let range = Contrast.luminances(surfaces)
            add(.tintedText, kind, Contrast.worst(opaque: colors.primary, onLuminances: range),
                Contrast.worst(opaque: tintInk, onLuminances: range), text)
        }
        let glassRange = Contrast.luminances(glass)
        add(.tintedGlyph, .glass, Contrast.worst(opaque: colors.primary, onLuminances: glassRange),
            Contrast.worst(opaque: tintInk, onLuminances: glassRange), nonText)
        let hue = RGBA(red: colors.primary.red, green: colors.primary.green, blue: colors.primary.blue)
        add(.textOnHue, .solidHue, Contrast.ratio(.white, hue),
            Contrast.ratio(Contrast.ink(on: hue, minimum: text), hue), text)
        if let focus {
            let ring = solved.focusRing(focus, ink: ink, minimum: nonText)
            for (kind, surfaces) in rows {
                add(.focusRing, kind, Contrast.worst(foreground: focus, on: surfaces),
                    Contrast.worst(opaque: ring, onLuminances: Contrast.luminances(surfaces)), nonText)
            }
        }
        if let separator, appearance.isIncreasedContrast {
            for (kind, surfaces) in rows where kind == .selectedRow || kind == .currentRow {
                let around = surfaces + top + content
                add(.selectionOutline, kind, Contrast.worst(foreground: separator, on: around),
                    Contrast.worst(foreground: secondaryInk, on: around), nonText)
            }
        }
        return cases
    }

    /// The same with the system's colours for `theme` in `appearance`.
    public func legibilityCases(for theme: Theme, in appearance: Appearance) -> [LegibilityCase] {
        legibilityCases(
            themeID: theme.id, colors: ResolvedColors(theme, in: appearance), focus: .keyboardFocus(in: appearance),
            separator: .separator(in: appearance), in: appearance)
    }

    /// A symbol on each system hue (a tile's colour), white before, the kit's ink after, against 3:1.
    public func symbolCases(in appearance: Appearance) -> [LegibilityCase] {
        Hue.allCases.map { hue in
            let color = RGBA(hue.systemColor, in: appearance)
            return LegibilityCase(
                themeID: hue.rawValue, appearance: appearance, role: .symbolOnHue, surface: .solidHue,
                before: Contrast.ratio(.white, color),
                after: Contrast.ratio(Contrast.ink(on: color, minimum: emphasis.nonTextContrast), color),
                threshold: emphasis.nonTextContrast)
        }
    }
}
