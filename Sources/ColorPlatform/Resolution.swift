#if canImport(AppKit) || canImport(UIKit)
import ColorCore

extension RGBA {
    public var nativeColor: NativeColor { .sRGB(red: red, green: green, blue: blue, alpha: alpha) }
}
#endif
