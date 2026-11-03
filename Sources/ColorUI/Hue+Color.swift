import ColorCore
import SwiftUI

extension Hue {
    /// The SwiftUI system colour of the hue.
    public var color: Color {
        switch self {
        case .indigo: .indigo
        case .blue: .blue
        case .orange: .orange
        case .pink: .pink
        case .teal: .teal
        case .green: .green
        case .red: .red
        case .purple: .purple
        case .mint: .mint
        case .cyan: .cyan
        case .brown: .brown
        case .yellow: .yellow
        }
    }
}
