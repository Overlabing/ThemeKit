import Foundation
import Testing
import ColorCore
import DesignKit

// The legibility cases of `DesignTokens.standard`, recorded on macOS 27 with the system's own colours, the contrast of
// the system default (before) and of the kit's colour (after), against its threshold. They live in JSON resources, not
// Swift literals: a 1,600-element array literal took the compiler several gigabytes to type-check (0.2.11).
// Regenerate all four files with `swift run --package-path Gallery DesignKitGallery audit Tests/DesignKitTests/Resources`.
//
// - `RecordedCases.json` (`all`): each text and glyph role on each surface the kit draws it on, on the window's gradient
//   and inside a list column. CHANGELOG.md (0.2.1) lists the frame cases against what 0.2.0 drew, 0.2.3 the column's.
// - `RecordedRailCases.json` (`rail`, CHANGELOG 0.2.4): the Space rail's cases, the roles that start with `rail`: a quiet
//   glyph, the selected Space's marker, a folded Profile's dots (every system hue, the worst counted) and the divider,
//   inside a list column, for every standard Theme in the four appearances.
// - `RecordedAccentCases.json` (`accent`, CHANGELOG 0.2.4): the accent text inks (role `accentText`), text in an accent
//   hue by index, the worst of the twelve counted, on the bare surface, a hovered, a current and a selected row and the
//   panel that groups rows, on the window's gradient and inside a list column.
// - `RecordedThemeAccentCases.json` (`themeFirstAccent`, CHANGELOG 0.2.5): the same surfaces with the Theme's own hues
//   first, `[.primary, .secondary, .hue(.mint), .hue(.yellow)]` (issue #17), the worst of the four counted; the audit
//   suffixes their Theme id with the list.

struct RecordedCase: Sendable, Decodable, CustomTestStringConvertible {
    let theme: String
    let appearance: Appearance
    let placement: SurfacePlacement
    let role: LegibilityCase.Role
    let surface: LegibilityCase.SurfaceKind
    let before: Double
    let after: Double
    let threshold: Double

    var key: String { "\(theme) \(appearance) \(placement) \(role) \(surface)" }
    var testDescription: String {
        "\(theme) \(appearance) \(role.rawValue) on \(surface.rawValue)\(placement == .frame ? "" : " in the column")"
    }

    private enum CodingKeys: String, CodingKey {
        case theme, appearance, placement, role, surface, before, after, threshold
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        func value<T>(_ key: CodingKeys, _ make: (String) -> T?) throws -> T {
            let name = try container.decode(String.self, forKey: key)
            guard let made = make(name) else {
                throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "unknown \(name)")
            }
            return made
        }
        theme = try container.decode(String.self, forKey: .theme)
        appearance = try value(.appearance) { name in Appearance.allCases.first { "\($0)" == name } }
        placement = try value(.placement, SurfacePlacement.init(rawValue:))
        role = try value(.role, LegibilityCase.Role.init(rawValue:))
        surface = try value(.surface, LegibilityCase.SurfaceKind.init(rawValue:))
        before = try container.decode(Double.self, forKey: .before)
        after = try container.decode(Double.self, forKey: .after)
        threshold = try container.decode(Double.self, forKey: .threshold)
    }

    /// Decodes a recording; a missing or malformed file stops the run, since every check depends on it.
    private static func load(_ name: String) -> [RecordedCase] {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json") else {
            fatalError("missing test resource \(name).json")
        }
        do {
            return try JSONDecoder().decode([RecordedCase].self, from: Data(contentsOf: url))
        } catch {
            fatalError("\(name).json: \(error)")
        }
    }

    static let all = load("RecordedCases")
    static let rail = load("RecordedRailCases")
    static let accent = load("RecordedAccentCases")
    static let themeFirstAccent = load("RecordedThemeAccentCases")
}
