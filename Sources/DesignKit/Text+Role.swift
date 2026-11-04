import SwiftUI

extension Text {
    /// The text in a type role: its font, tracking and case.
    public func role(_ role: TextRole) -> some View {
        font(role.font).tracking(role.tracking).textCase(role.uppercased ? .uppercase : nil)
    }
}
