#if canImport(AppKit) || canImport(UIKit)
import ColorCore
import Synchronization

extension Legibility {
    /// Solved once per Theme, accent hues, surfaces and appearance: system colours do not change while the app runs (a
    /// new system does).
    public static func of(
        _ theme: Theme, accents: [Hue] = [], surfaces: Surfaces, in appearance: Appearance
    ) -> Legibility {
        cache.withLock { cache in
            let key = CacheKey(theme: theme, accents: accents, surfaces: surfaces, appearance: appearance)
            if let known = cache[key] { return known }
            let solved = solve(colors: ResolvedColors(theme, accents: accents, in: appearance), surfaces: surfaces)
            cache[key] = solved
            return solved
        }
    }

    private struct CacheKey: Hashable {
        let theme: Theme
        let accents: [Hue]
        let surfaces: Surfaces
        let appearance: Appearance
    }

    private static let cache = Mutex<[CacheKey: Legibility]>([:])
}
#endif
