import ColorCore
import DesignKit
import Foundation
import SwiftUI
import Testing

/// Every value `ColorRoles` hands out, for every Theme, appearance, placement and two sets of tokens, one per line,
/// written to `THEMEKIT_ROLES_DUMP`: run before and after a change to the roles and diff the two files. Opt in.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["THEMEKIT_ROLES_DUMP"] != nil))
struct RolesDumpTests {
    @available(*, deprecated, message: "Reads the deprecated column's roles too, kept until 0.3.")
    @Test func dump() throws {
        var custom = DesignTokens.standard
        custom.accents = [.primary, .secondary, .hue(.mint)]
        custom.emphasis.hover = 0.2
        var lines: [String] = []
        for (tokensName, tokens) in [("standard", DesignTokens.standard), ("custom", custom)] {
            for theme in Palette.standard.themes {
                for appearance in Appearance.allCases {
                    for placement in SurfacePlacement.allCases {
                        let roles = ColorRoles(theme: theme, tokens: tokens, appearance: appearance, placement: placement)
                        let prefix = "\(tokensName) \(theme.id) \(appearance) \(placement)"
                        func add(_ name: String, _ value: Any) { lines.append("\(prefix) \(name) \(value)") }
                        add("legibility", roles.legibility)
                        add("hueScale", roles.hueScale)
                        add("selectionOpacity", roles.selectionOpacity)
                        add("hoverOpacity", roles.hoverOpacity)
                        add("currentOpacity", roles.currentOpacity)
                        add("tileOpacity", roles.tileOpacity)
                        add("badgeOpacity", roles.badgeOpacity)
                        add("layerOpacity", roles.layerOpacity)
                        add("secondaryText", roles.secondaryTextRGBA)
                        add("tintText", roles.tintTextRGBA)
                        add("selectionMarker", roles.selectionMarkerRGBA)
                        add("focusRing", roles.focusRingRGBA)
                        add("columnEdge", roles.columnEdgeRGBA)
                        add("columnFill", roles.columnFillOpacity)
                        add("bandText", roles.bandText)
                        add("primaryGlyph", roles.primaryGlyph)
                        add("frameStops", roles.frameStops)
                        add("tint", roles.tint)
                        for index in -1..<13 {
                            add("accentHue[\(index)]", roles.accentHue(at: index))
                            add("accentInk[\(index)]", roles.accentInkRGBA(at: index))
                        }
                        for hue in Hue.allCases { add("railDot[\(hue)]", roles.railDotRGBA(hue)) }
                    }
                }
            }
        }
        let path = try #require(ProcessInfo.processInfo.environment["THEMEKIT_ROLES_DUMP"])
        try (lines.joined(separator: "\n") + "\n").write(toFile: path, atomically: true, encoding: .utf8)
        print("DUMP \(lines.count) lines to \(path)")
    }
}
