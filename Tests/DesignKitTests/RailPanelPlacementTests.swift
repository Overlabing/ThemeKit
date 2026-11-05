#if os(macOS)
import AppKit
#endif
import ColorCore
import ColorPlatform
import DesignKit
import SwiftUI
import Testing

/// The rail's panels no longer force `.column` (issue #21): they take the placement they inherit, `.frame` by default,
/// and their text still reaches 4.5:1 on the popover, their focus ring and marker 3:1.
///
/// The popover's material cannot be drawn without a window, so it is bounded: from the plain window background (the
/// material at its most opaque, and under Reduce Transparency) to that background at half opacity over the window's
/// gradient (the material letting the window behind it through; the deprecated column's fill, which the panels were
/// solved on before).
struct RailPanelPlacementTests {
    struct Measure {
        var text = 21.0, nonText = 21.0
    }

    /// The surfaces a panel's text sits on: each backdrop, and the hovered, current and selected rows' fills over it.
    func popover(_ roles: ColorRoles, _ colors: ResolvedColors, _ appearance: Appearance) -> [RGBA] {
        let tokens = roles.tokens
        let (top, content) = tokens.surfaces(in: appearance).scaled(by: roles.hueScale).samples(colors)
        let backdrops = [colors.background] + (top + content).map { colors.background.opacity(0.5).composited(over: $0) }
        let fills = [roles.hoverOpacity, roles.currentOpacity, roles.selectionOpacity]
        return backdrops + fills.flatMap { opacity in backdrops.map { colors.primary.opacity(opacity).composited(over: $0) } }
    }

    func measure(_ placement: SurfacePlacement, _ theme: Theme, _ appearance: Appearance) -> Measure {
        let roles = ColorRoles(theme: theme, tokens: .standard, appearance: appearance, placement: placement)
        let colors = ResolvedColors(theme, in: appearance)
        let surfaces = popover(roles, colors, appearance)
        var measure = Measure()
        // Row titles in the label colour; shortcuts, command symbols, section headers and the Increase Contrast
        // outline in the secondary ink.
        for ink in [colors.label, roles.secondaryTextRGBA] {
            measure.text = min(measure.text, Contrast.worst(foreground: ink, on: surfaces))
        }
        var marks = [roles.focusRingRGBA]
        if !appearance.isIncreasedContrast { marks.append(roles.selectionMarkerRGBA) }
        for mark in marks {
            measure.nonText = min(measure.nonText, Contrast.worst(foreground: mark, on: surfaces))
        }
        return measure
    }

    /// Worst text on the popover across the Themes, `.frame` (`.column` before): light 4.72 (4.62), dark 5.86 (4.81),
    /// light Increase Contrast 4.70 (4.61), dark Increase Contrast 5.51 (4.73). The focus ring and the marker: 3.36
    /// at worst (light Increase Contrast).
    @Test(arguments: Appearance.allCases)
    func thePanelsTextReachesItsContrastOnThePopover(_ appearance: Appearance) {
        for theme in Palette.standard.themes {
            let frame = measure(.frame, theme, appearance)
            #expect(frame.text >= 4.5, "\(theme.id) \(appearance): text \(frame.text)")
            #expect(frame.nonText >= 3, "\(theme.id) \(appearance): ring or marker \(frame.nonText)")
        }
    }

    /// What leaving `.column` changed in the panels: the secondary ink is a little more opaque in every Theme (alpha
    /// +0.01 to +0.03 in light, +0.10 to +0.14 in dark, +0.01 to +0.04 and +0.09 to +0.11 under Increase Contrast),
    /// and in light four bright Themes' selection is heavier (orange-pink 0.375 to 0.478, teal-green 0.381 to 0.5,
    /// mint-cyan 0.391 to 0.5, brown-yellow 0.300 to 0.317). Nothing got lighter, and no text on the popover got
    /// lower.
    @available(*, deprecated, message: "Compares with the deprecated column, kept until 0.3.")
    @Test(arguments: Appearance.allCases)
    func leavingTheColumnOnlyRaisedThePanelsInks(_ appearance: Appearance) {
        for theme in Palette.standard.themes {
            let frame = ColorRoles(theme: theme, tokens: .standard, appearance: appearance, placement: .frame)
            let column = ColorRoles(theme: theme, tokens: .standard, appearance: appearance, placement: .column)
            let moved = frame.secondaryTextRGBA.alpha - column.secondaryTextRGBA.alpha
            #expect(moved > 0 && moved < 0.15, "\(theme.id) \(appearance): secondary alpha \(moved)")
            #expect(frame.selectionOpacity >= column.selectionOpacity, "\(theme.id) \(appearance)")
            #expect(measure(.frame, theme, appearance).text >= measure(.column, theme, appearance).text,
                    "\(theme.id) \(appearance)")
        }
    }
}

#if os(macOS)
/// The panel drawn through AppKit, offscreen with no window: it takes the placement around it. Forced to `.column` as
/// in 0.2.5, the render with no placement set and the one inside a column were the same.
@MainActor
struct RailPanelPlacementRenderTests {
    /// teal-green in light: the selection is 0.5 on the frame, 0.381 in the column.
    static let theme = Palette.standard.themes.first { $0.id == "teal-green" }!

    func render(_ placement: SurfacePlacement?) throws -> [UInt8] {
        let model = SpaceRailModel(
            spaces: [SpaceRailSpace(id: "a", name: "Reading", theme: Self.theme),
                     SpaceRailSpace(id: "b", name: "Home", theme: Self.theme)],
            selection: "a")
        let panel = SpaceRailPanel(model: model, commands: [], showsFocusRing: false, selectSpace: { _ in }, perform: { _ in })
        let view = Group {
            if let placement { panel.environment(\.surfacePlacement, placement) } else { panel }
        }
        .theme(Self.theme)
        .environment(\.colorScheme, .light)
        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(origin: .zero, size: hosting.fittingSize)
        hosting.layoutSubtreeIfNeeded()
        let rep = try #require(hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds))
        hosting.cacheDisplay(in: hosting.bounds, to: rep)
        let image = try #require(rep.cgImage)
        var data = [UInt8](repeating: 0, count: image.width * image.height * 4)
        data.withUnsafeMutableBytes { buffer in
            let context = CGContext(
                data: buffer.baseAddress, width: image.width, height: image.height, bitsPerComponent: 8,
                bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return data
    }

    @available(*, deprecated, message: "Compares with the deprecated column, kept until 0.3.")
    @Test func thePanelTakesThePlacementAroundIt() throws {
        let inherited = try render(nil)
        #expect(inherited == (try render(.frame)), "with no placement set, the panel is in .frame")
        #expect(inherited != (try render(.column)), "the panel no longer forces .column")
    }
}
#endif
