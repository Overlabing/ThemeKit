import ColorCore
import ColorPlatform

/// One text or glyph role on one kind of surface, for one Theme (or one hue) and appearance, on the window's gradient
/// or inside a list column (`placement`): the contrast the system's default colour reaches there (`before`) and the
/// contrast the kit's colour reaches (`after`), against `threshold`: 4.5:1 for text, 3:1 for glyphs, focus rings,
/// outlines and the column's edge.
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
        /// The bar at the leading edge of a selected row outside Increase Contrast: `ColorRoles.selectionMarker`. The
        /// system default is no marker, so `before` is how far the fill alone sets the row apart from what is under it.
        case selectionMarker
        /// The edge of a list column's surface: `ColorRoles.columnEdge` instead of the separator, against the gradient
        /// outside the column (surface `frame`) and against the column's fill inside (surface `columnFill`).
        case columnEdge
        /// A quiet Space of the Space rail: its symbol or initial in `ColorRoles.secondaryText`, on the column's fill
        /// and on its hover disc. Held to the text threshold, since an initial is a letter.
        case railGlyph
        /// The marker under the rail's selected Space: `ColorRoles.selectionMarker` instead of nothing (`before` is
        /// the raw hue the glyph's circle is drawn in), on the column's fill.
        case railMarker
        /// A folded Profile's dots: every system hue through `ColorRoles.railDot` instead of the raw hue, the worst
        /// hue counted, on the column's fill and on the folded Profile's hover fill.
        case railDot
        /// The hairline between the rail's groups: `ColorRoles.railDivider` instead of the separator, on the column's
        /// fill.
        case railDivider
        /// Text in an accent hue by index (`ColorRoles.accentInk(at:)`, an account's name): the hue mixed with ink
        /// instead of the raw hue, the worst of `DesignTokens.accents` (resolved against the Theme) counted, held to the
        /// text threshold.
        case accentText
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
        /// A list column's own fill: the plain background at `Emphasis.column(isDark:)` over the gradient, top to
        /// bottom, and the plain background alone (Reduce Transparency). Inside a column it takes the place of `frame`.
        case columnFill
    }

    /// The Theme's id, or the hue's name for a symbol on a hue.
    public let themeID: String
    public let appearance: Appearance
    /// On the window's gradient or inside a list column.
    public let placement: SurfacePlacement
    public let role: Role
    public let surface: SurfaceKind
    public let before: Double
    public let after: Double
    public let threshold: Double

    /// The system's default fails here and the kit's colour does not.
    public var isFixed: Bool { before < threshold && after >= threshold }

    public var description: String {
        let place = placement == .frame ? "" : " in the \(placement.rawValue)"
        return "\(themeID) \(appearance) \(role.rawValue) on \(surface.rawValue)\(place): \(before) → \(after) (≥ \(threshold))"
    }
}

extension DesignTokens {
    /// Every text and glyph role on every surface the kit draws them on, for one Theme in one appearance, on the
    /// window's gradient or inside a list column, with resolved colours (pure: runs without a window). The focus ring
    /// cases need the system's focus colour, the outline cases (Increase Contrast only) the separator's; without them
    /// those cases are left out. Inside a column the surfaces sit on its fill (`columnSurfaces(in:)`), the hue keeps
    /// the frame's share, a symbol or a text on the opaque hue is left to the frame's cases (nothing under it changes),
    /// and the column's edge has its two cases.
    public func legibilityCases(
        themeID: String, colors: ResolvedColors, focus: RGBA? = nil, separator: RGBA? = nil, in appearance: Appearance,
        placement: SurfacePlacement = .frame
    ) -> [LegibilityCase] {
        let frameSolved = Legibility.fit(colors: colors, surfaces: surfaces(in: appearance))
        let solved = placement == .frame
            ? frameSolved
            : Legibility.solve(colors: colors, surfaces: columnSurfaces(in: appearance), hueScale: frameSolved.hueScale)
        let described = surfaces(in: appearance, placement: placement).scaled(by: solved.hueScale)
        let spec = described.gradient
        func place(at t: Double) -> RGBA {
            let bare = spec.color(at: t, primary: colors.primary, secondary: colors.secondary, over: colors.background)
            return described.backdrop > 0 ? colors.background.opacity(described.backdrop).composited(over: bare) : bare
        }
        let ink = colors.ink
        let (top, content) = described.samples(colors)
        let panels = described.neutralFills.flatMap { opacity in content.map { ink.opacity(opacity).composited(over: $0) } }
        func filled(_ opacity: Double) -> [RGBA] {
            (content + panels).map { colors.primary.opacity(opacity).composited(over: $0) }
        }
        let fills = described.fills
        let rows: [(LegibilityCase.SurfaceKind, [RGBA])] = [
            (placement == .frame ? .frame : .columnFill, top + content),
            (.hoveredRow, filled(fills[0])),
            (.currentRow, filled(fills.count > 1 ? fills[1] : fills[0])),
            (.selectedRow, filled(solved.selected)),
            (.layerPanel, panels),
        ]
        let everyRow = rows.flatMap(\.1)
        let tinted = described.tintFills.flatMap { opacity in
            everyRow.map { colors.primary.opacity(opacity).composited(over: $0) }
        }
        let glass = [colors.background] + stride(from: 0.0, through: 1.0, by: 0.05).map(place(at:))
        let switcher = ([colors.background] + stride(from: emphasis.switcherTop, through: 1.0, by: 0.05).map(place(at:)))
            .map { colors.primary.opacity(emphasis.glassTint).composited(over: $0) }

        let secondaryInk = colors.label.opacity(solved.secondaryAlpha / colors.label.alpha)
        let tintInk = colors.primary.mixed(with: ink, by: solved.tintMix)
        var cases: [LegibilityCase] = []
        func add(_ role: LegibilityCase.Role, _ kind: LegibilityCase.SurfaceKind, _ before: Double, _ after: Double,
                 _ threshold: Double) {
            cases.append(LegibilityCase(
                themeID: themeID, appearance: appearance, placement: placement, role: role, surface: kind,
                before: before, after: after, threshold: threshold))
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
        if placement == .frame {
            let hue = RGBA(red: colors.primary.red, green: colors.primary.green, blue: colors.primary.blue)
            add(.textOnHue, .solidHue, Contrast.ratio(.white, hue),
                Contrast.ratio(Contrast.ink(on: hue, minimum: text), hue), text)
        }
        if let focus {
            let ring = solved.focusRing(focus, ink: ink, minimum: nonText)
            for (kind, surfaces) in rows {
                add(.focusRing, kind, Contrast.worst(foreground: focus, on: surfaces),
                    Contrast.worst(opaque: ring, onLuminances: Contrast.luminances(surfaces)), nonText)
            }
        }
        if !appearance.isIncreasedContrast {
            let marker = colors.primary.mixed(
                with: ink, by: solved.mix(of: colors.primary, toward: ink, reaching: nonText))
            let selected = filled(solved.selected)
            let base = content + panels
            let fillAlone = zip(base, base.map { colors.primary.opacity(solved.selected).composited(over: $0) })
                .map { Contrast.ratio($0, $1) }.min() ?? 1
            add(.selectionMarker, .selectedRow, fillAlone,
                Contrast.worst(opaque: marker, onLuminances: Contrast.luminances(selected)), nonText)
        }
        if let separator, appearance.isIncreasedContrast {
            for (kind, surfaces) in rows where kind == .selectedRow || kind == .currentRow {
                let around = surfaces + top + content
                add(.selectionOutline, kind, Contrast.worst(foreground: separator, on: around),
                    Contrast.worst(foreground: secondaryInk, on: around), nonText)
            }
        }
        if placement == .column {
            let neighbours = ColorRoles.columnEdgeNeighbours(
                colors: colors, frame: surfaces(in: appearance), column: columnSurfaces(in: appearance),
                hueScale: solved.hueScale)
            let alpha = ColorRoles.columnEdgeAlpha(
                colors: colors, frame: surfaces(in: appearance), column: columnSurfaces(in: appearance),
                hueScale: solved.hueScale, minimum: nonText)
            func worst(_ line: RGBA?, against side: (RGBA, RGBA) -> RGBA) -> Double {
                neighbours.map { fill, outside in
                    Contrast.ratio(line.map { $0.composited(over: fill) } ?? fill, side(fill, outside))
                }.min() ?? 1
            }
            let edge = ink.opacity(alpha)
            add(.columnEdge, .frame, worst(separator, against: { $1 }), worst(edge, against: { $1 }), nonText)
            add(.columnEdge, .columnFill, worst(separator, against: { fill, _ in fill }),
                worst(edge, against: { fill, _ in fill }), nonText)
        }
        return cases
    }

    /// The same with the system's colours for `theme` in `appearance`.
    public func legibilityCases(
        for theme: Theme, in appearance: Appearance, placement: SurfacePlacement = .frame
    ) -> [LegibilityCase] {
        legibilityCases(
            themeID: theme.id, colors: ResolvedColors(theme, in: appearance), focus: .keyboardFocus(in: appearance),
            separator: .separator(in: appearance), in: appearance, placement: placement)
    }

    /// The Space rail's marks inside a list column, for one Theme in one appearance: a quiet glyph (on the column's
    /// fill and on its hover disc), the selected Space's marker, a folded Profile's dots (`dotHues`, the worst counted,
    /// on the fill and on the hover fill) and the divider. The rail's caption is plain and secondary text on the
    /// column's fill, which `legibilityCases(…, placement: .column)` already holds; a selected glyph's symbol or
    /// initial on its hue is `textOnHue` / `symbolCases`.
    public func railCases(
        themeID: String, colors: ResolvedColors, dotHues: [RGBA], separator: RGBA?, in appearance: Appearance
    ) -> [LegibilityCase] {
        let frameSolved = Legibility.fit(colors: colors, surfaces: surfaces(in: appearance))
        let solved = Legibility.solve(
            colors: colors, surfaces: columnSurfaces(in: appearance), hueScale: frameSolved.hueScale)
        let described = columnSurfaces(in: appearance).scaled(by: solved.hueScale)
        let (top, content) = described.samples(colors)
        let fill = top + content
        let hovered = fill.map { colors.primary.opacity(described.fills[0]).composited(over: $0) }
        let ink = colors.ink
        let secondaryInk = colors.label.opacity(solved.secondaryAlpha / colors.label.alpha)
        let nonText = emphasis.nonTextContrast
        func opaque(_ color: RGBA) -> RGBA { RGBA(red: color.red, green: color.green, blue: color.blue) }
        func solvedMark(_ hue: RGBA) -> RGBA {
            opaque(hue).mixed(with: ink, by: solved.mix(of: opaque(hue), toward: ink, reaching: nonText))
        }
        func worst(_ marks: [RGBA], on surfaces: [RGBA]) -> Double {
            let range = Contrast.luminances(surfaces)
            return marks.map { Contrast.worst(opaque: $0, onLuminances: range) }.min() ?? 21
        }
        var cases: [LegibilityCase] = []
        func add(_ role: LegibilityCase.Role, _ kind: LegibilityCase.SurfaceKind, _ before: Double, _ after: Double,
                 _ threshold: Double) {
            cases.append(LegibilityCase(
                themeID: themeID, appearance: appearance, placement: .column, role: role, surface: kind,
                before: before, after: after, threshold: threshold))
        }
        for (kind, surfaces) in [(LegibilityCase.SurfaceKind.columnFill, fill), (.hoveredRow, hovered)] {
            add(.railGlyph, kind, Contrast.worst(foreground: colors.secondaryLabel, on: surfaces),
                Contrast.worst(foreground: secondaryInk, on: surfaces), emphasis.textContrast)
        }
        add(.railMarker, .columnFill, worst([opaque(colors.primary)], on: fill), worst([solvedMark(colors.primary)], on: fill),
            nonText)
        for (kind, surfaces) in [(LegibilityCase.SurfaceKind.columnFill, fill), (.hoveredRow, hovered)] {
            add(.railDot, kind, worst(dotHues.map(opaque), on: surfaces), worst(dotHues.map(solvedMark), on: surfaces),
                nonText)
        }
        let edge = ink.opacity(ColorRoles.columnEdgeAlpha(
            colors: colors, frame: surfaces(in: appearance), column: columnSurfaces(in: appearance),
            hueScale: solved.hueScale, minimum: nonText))
        add(.railDivider, .columnFill,
            fill.map { place in Contrast.ratio(separator.map { $0.composited(over: place) } ?? place, place) }.min() ?? 1,
            fill.map { place in Contrast.ratio(edge.composited(over: place), place) }.min() ?? 1, nonText)
        return cases
    }

    /// The same with the system's colours for `theme` in `appearance`, every system hue as a dot.
    public func railCases(for theme: Theme, in appearance: Appearance) -> [LegibilityCase] {
        railCases(
            themeID: theme.id, colors: ResolvedColors(theme, in: appearance),
            dotHues: Hue.allCases.map { RGBA($0.systemColor, in: appearance) }, separator: .separator(in: appearance),
            in: appearance)
    }

    /// Text in each of `accentHues` by index (`ColorRoles.accentInk(at:)`) for one Theme in one appearance, on the
    /// window's gradient or inside a list column: on the bare surface (the gradient, or the column's fill), on a hovered,
    /// a current and a selected row, and on the panel that groups rows. Each case counts the worst accent: `before` is
    /// the raw hue, `after` its ink, against 4.5:1.
    public func accentCases(
        themeID: String, colors: ResolvedColors, accentHues: [RGBA], in appearance: Appearance,
        placement: SurfacePlacement = .frame
    ) -> [LegibilityCase] {
        var withAccents = colors
        withAccents.accents = accentHues
        let frameSolved = Legibility.fit(colors: withAccents, surfaces: surfaces(in: appearance))
        let solved = placement == .frame
            ? frameSolved
            : Legibility.solve(
                colors: withAccents, surfaces: columnSurfaces(in: appearance), hueScale: frameSolved.hueScale)
        let described = surfaces(in: appearance, placement: placement).scaled(by: solved.hueScale)
        let (top, content) = described.samples(colors)
        let panels = described.neutralFills.flatMap { opacity in
            content.map { colors.ink.opacity(opacity).composited(over: $0) }
        }
        func filled(_ opacity: Double) -> [RGBA] {
            (content + panels).map { colors.primary.opacity(opacity).composited(over: $0) }
        }
        let rows: [(LegibilityCase.SurfaceKind, [RGBA])] = [
            (placement == .frame ? .frame : .columnFill, top + content),
            (.hoveredRow, filled(described.fills[0])),
            (.currentRow, filled(described.fills.count > 1 ? described.fills[1] : described.fills[0])),
            (.selectedRow, filled(solved.selected)),
            (.layerPanel, panels),
        ]
        let inks = zip(accentHues, solved.accentMix).map { $0.mixed(with: colors.ink, by: $1) }
        func worst(_ marks: [RGBA], on surfaces: [RGBA]) -> Double {
            let range = Contrast.luminances(surfaces)
            return marks.map { Contrast.worst(opaque: $0, onLuminances: range) }.min() ?? 21
        }
        return rows.map { kind, surfaces in
            LegibilityCase(
                themeID: themeID, appearance: appearance, placement: placement, role: .accentText, surface: kind,
                before: worst(accentHues.map { RGBA(red: $0.red, green: $0.green, blue: $0.blue) }, on: surfaces),
                after: worst(inks, on: surfaces), threshold: emphasis.textContrast)
        }
    }

    /// The same with the system's colours for `theme` in `appearance`, every accent of `accents` resolved against
    /// `theme` (`accentHues(in:)`).
    public func accentCases(
        for theme: Theme, in appearance: Appearance, placement: SurfacePlacement = .frame
    ) -> [LegibilityCase] {
        accentCases(
            themeID: theme.id, colors: ResolvedColors(theme, in: appearance),
            accentHues: accentHues(in: theme).map { RGBA($0.systemColor, in: appearance) }, in: appearance,
            placement: placement)
    }

    /// A symbol on each system hue (a tile's colour), white before, the kit's ink after, against 3:1.
    public func symbolCases(in appearance: Appearance) -> [LegibilityCase] {
        Hue.allCases.map { hue in
            let color = RGBA(hue.systemColor, in: appearance)
            return LegibilityCase(
                themeID: hue.rawValue, appearance: appearance, placement: .frame, role: .symbolOnHue, surface: .solidHue,
                before: Contrast.ratio(.white, color),
                after: Contrast.ratio(Contrast.ink(on: color, minimum: emphasis.nonTextContrast), color),
                threshold: emphasis.nonTextContrast)
        }
    }
}
