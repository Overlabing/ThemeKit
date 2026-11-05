import SwiftUI

extension Text {
    /// The text in a type role: its font, tracking and case.
    public func role(_ role: TextRole) -> some View {
        font(role.font).tracking(role.tracking).textCase(role.uppercased ? .uppercase : nil)
    }
}

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

extension TextRole {
    /// The system's point size for this role's text style, at `dynamicTypeSize` where the platform has Dynamic Type.
    func pointSize(_ dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        #if canImport(AppKit)
        let style: NSFont.TextStyle = switch self.style {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: .body
        }
        return NSFont.preferredFont(forTextStyle: style).pointSize
        #elseif canImport(UIKit)
        let style: UIFont.TextStyle = switch self.style {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: .body
        }
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        return UIFont.preferredFont(forTextStyle: style, compatibleWith: traits).pointSize
        #endif
    }
}
