import ColorCore
import SwiftUI

extension EnvironmentValues {
    /// The Theme set by `View.theme(_:)` on a root view; nil when none was.
    @Entry public var theme: Theme?
}

extension View {
    /// Tints the view with the Theme's primary hue and makes the Theme available to the views below it through the
    /// environment. Set it at each root (a window, a sheet that does not inherit).
    public func theme(_ theme: Theme) -> some View {
        tint(theme.primary.color).environment(\.theme, theme)
    }
}
