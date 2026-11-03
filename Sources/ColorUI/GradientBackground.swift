import ColorCore
import SwiftUI

/// A window background: the plain `.background`, then the Theme's gradient over it. A flat, static layer; only a change
/// of Theme animates it (not with Reduce Motion). Place it with `.background { … .ignoresSafeArea() }` to run under the
/// toolbar.
public struct GradientBackground: View {
    private let theme: Theme
    private let light: GradientSpec
    private let dark: GradientSpec
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(theme: Theme, light: GradientSpec = .light, dark: GradientSpec = .dark) {
        self.theme = theme
        self.light = light
        self.dark = dark
    }

    public var body: some View {
        let spec = scheme == .dark ? dark : light
        Rectangle()
            .fill(.background)
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: theme.primary.color.opacity(spec.top), location: 0),
                        .init(color: theme.secondary.color.opacity(spec.middle), location: 0.5),
                        .init(color: theme.primary.color.opacity(spec.bottom), location: 1),
                    ],
                    startPoint: .top, endPoint: .bottom)
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: theme)
    }
}
