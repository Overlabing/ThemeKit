import ColorCore
import Foundation

extension Theme {
    /// The name read by VoiceOver and shown as help on the Theme's swatch, localized from this module's String
    /// Catalog. A Theme outside the standard Palette reads as a system colour.
    public var displayName: LocalizedStringResource {
        let bundle = LocalizedStringResource.BundleDescription.atURL(Bundle.module.bundleURL)
        switch id {
        case "orange-pink": return LocalizedStringResource("Orange and pink", table: "Themes", bundle: bundle)
        case "teal-green": return LocalizedStringResource("Teal and green", table: "Themes", bundle: bundle)
        case "indigo-blue": return LocalizedStringResource("Indigo and blue", table: "Themes", bundle: bundle)
        case "red-orange": return LocalizedStringResource("Red and orange", table: "Themes", bundle: bundle)
        case "purple-pink": return LocalizedStringResource("Purple and pink", table: "Themes", bundle: bundle)
        case "mint-cyan": return LocalizedStringResource("Mint and cyan", table: "Themes", bundle: bundle)
        case "brown-yellow": return LocalizedStringResource("Brown and yellow", table: "Themes", bundle: bundle)
        default: return LocalizedStringResource("System color", table: "Themes", bundle: bundle)
        }
    }
}
