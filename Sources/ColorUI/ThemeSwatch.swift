import ColorCore
import SwiftUI

/// A round swatch of a Theme's two hues, for a picker. Reads its localized name aloud and shows it as help.
public struct ThemeSwatch: View {
    private let theme: Theme
    private let isSelected: Bool
    private let size: CGFloat

    public init(_ theme: Theme, isSelected: Bool = false, size: CGFloat = 22) {
        self.theme = theme
        self.isSelected = isSelected
        self.size = size
    }

    public var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [theme.primary.color, theme.secondary.color], startPoint: .topLeading,
                    endPoint: .bottomTrailing)
            )
            .frame(width: size, height: size)
            .overlay {
                if isSelected {
                    Circle().strokeBorder(.primary, lineWidth: 2).padding(-4)
                }
            }
            .help(Text(theme.displayName))
            .accessibilityElement()
            .accessibilityLabel(Text(theme.displayName))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
