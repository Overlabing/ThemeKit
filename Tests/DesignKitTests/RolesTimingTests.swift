import ColorCore
import ColorUI
import DesignKit
import Foundation
import SwiftUI
import Testing

/// What 50 rows' backgrounds cost to evaluate, for the record (issue #38): each `ListRowBackground` builds its
/// `ColorRoles` in its body (`WithColorRoles`), so a hover that re-evaluates the visible rows builds 50. Opt in with
/// `THEMEKIT_TIMING=1 swift test --filter RolesTimingTests`; it prints and asserts nothing.
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.environment["THEMEKIT_TIMING"] != nil))
struct RolesTimingTests {
    static let rows = 50
    static let theme = Palette.standard.themes[0]

    static func state(_ index: Int) -> RowState {
        RowState(isSelected: index == 2, isCurrent: index == 5, isHovered: index == 1, isFocused: index == 3)
    }

    /// What one row's background reads of its roles: the fill of its state, the selected row's marker, and the focus
    /// ring's own roles (`FocusRing` builds a second `ColorRoles`).
    static func evaluate(_ appearance: Appearance) -> Double {
        var sink = 0.0
        for index in 0..<rows {
            let state = state(index)
            let roles = ColorRoles(theme: theme, tokens: .standard, appearance: appearance)
            sink += state.isSelected ? roles.selectionOpacity : state.isCurrent ? roles.currentOpacity
                : state.isHovered ? roles.hoverOpacity : 0
            if state.isSelected { sink += roles.selectionMarkerRGBA.red }
            if appearance.isIncreasedContrast && (state.isSelected || state.isCurrent) { sink += roles.secondaryTextRGBA.alpha }
            if state.isFocused {
                sink += ColorRoles(theme: theme, tokens: .standard, appearance: appearance).focusRingRGBA.red
            }
        }
        return sink
    }

    static func median(_ samples: [Duration]) -> Duration { samples.sorted()[samples.count / 2] }

    static func microseconds(_ duration: Duration) -> String {
        let (seconds, attoseconds) = duration.components
        return String(format: "%.1f µs", Double(seconds) * 1e6 + Double(attoseconds) / 1e12)
    }

    @Test func fiftyRowBackgrounds() throws {
        let clock = ContinuousClock()
        for appearance in [Appearance.light, .dark] {
            _ = Self.evaluate(appearance)
            var samples: [Duration] = []
            var sink = 0.0
            for _ in 0..<200 {
                samples.append(clock.measure { sink += Self.evaluate(appearance) })
            }
            print("TIMING roles \(appearance) 50 rows: median \(Self.microseconds(Self.median(samples))) (sink \(sink > 0))")
        }
        for scheme in [ColorScheme.light, .dark] {
            let view = VStack(spacing: 0) {
                ForEach(0..<Self.rows, id: \.self) { index in
                    ListRowBackground(state: Self.state(index)).frame(width: 300, height: 36)
                }
            }
            .theme(Self.theme)
            .environment(\.colorScheme, scheme)
            func render() {
                let renderer = ImageRenderer(content: view)
                renderer.scale = 1
                _ = renderer.cgImage
            }
            render()
            render()
            var samples: [Duration] = []
            for _ in 0..<30 { samples.append(clock.measure { render() }) }
            print("TIMING render \(scheme) 50 rows: median \(Self.microseconds(Self.median(samples)))")
        }
    }
}
