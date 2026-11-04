import ColorCore
import ColorUI
import SwiftUI

/// How a surface is drawn.
public enum Surface: Sendable, Equatable {
    /// Liquid Glass, optionally tinted with the Theme's primary hue at this opacity.
    case glass(tint: Double)
    /// A recessed fill of `.primary` at `Emphasis.layer`.
    case layer
}

/// How the kit draws its glass surfaces.
public enum GlassRendering: Sendable, Equatable {
    /// Liquid Glass, the default.
    case liquidGlass
    /// A system material in the same shapes, with the same tints and outlines. For renders made without a window
    /// (`ImageRenderer` does not draw Liquid Glass), snapshot tests and previews.
    case material
}

extension EnvironmentValues {
    @Entry public var glassRendering: GlassRendering = .liquidGlass
}

extension View {
    /// Draws `surface` behind the view in `shape`. Glass becomes an opaque background fill with a separator line under
    /// Reduce Transparency; Increase Contrast outlines every surface in `.secondary`.
    public func surface(_ surface: Surface, in shape: some InsettableShape) -> some View {
        modifier(SurfaceModifier(surface: surface, shape: shape))
    }

    /// Simulates Increase Contrast, Reduce Transparency and Reduce Motion for previews and renders, without touching
    /// the system's settings. Never use it in shipping UI: the app follows the system.
    public func accessibilityOverrides(
        increaseContrast: Bool = false, reduceTransparency: Bool = false, reduceMotion: Bool = false
    ) -> some View {
        transformEnvironment(\._colorSchemeContrast) { if increaseContrast { $0 = .increased } }
            .transformEnvironment(\._accessibilityReduceTransparency) { if reduceTransparency { $0 = true } }
            .transformEnvironment(\._accessibilityReduceMotion) { if reduceMotion { $0 = true } }
    }
}

private struct SurfaceModifier<S: InsettableShape>: ViewModifier {
    let surface: Surface
    let shape: S
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.designTokens) private var tokens
    @Environment(\.theme) private var theme
    @Environment(\.glassRendering) private var glassRendering

    func body(content: Content) -> some View {
        switch surface {
        case .layer:
            content
                .background {
                    shape.fill(Color.primary.opacity(tokens.emphasis.layer))
                }
                .overlay { outline }
        case .glass(let opacity):
            let tint = opacity > 0 ? (theme?.primary.color ?? .accentColor).opacity(opacity) : nil
            if reduceTransparency {
                content
                    .background {
                        shape.fill(.background)
                            .overlay { if let tint { shape.fill(tint) } }
                    }
                    .overlay { outline }
            } else if glassRendering == .material {
                content
                    .background {
                        shape.fill(.regularMaterial)
                            .overlay { if let tint { shape.fill(tint) } }
                    }
                    .overlay { outline }
            } else {
                // The outline belongs to the glass's content: drawn after the glass, a container composites it under.
                content
                    .overlay { outline }
                    .glassEffect(tint.map { Glass.regular.tint($0) } ?? .regular, in: shape)
            }
        }
    }

    @ViewBuilder private var outline: some View {
        if contrast == .increased {
            shape.strokeBorder(.secondary, lineWidth: tokens.size.stroke).accessibilityHidden(true)
        } else if reduceTransparency {
            shape.strokeBorder(.separator, lineWidth: tokens.size.stroke).accessibilityHidden(true)
        }
    }
}

extension View {
    /// A keyboard focus ring around `shape` while `isVisible`, outside it by `Spacing.focusRingOffset`, in
    /// `ColorRoles.focusRing`: the system's focus colour, opaque, at 3:1 at least on the Theme's surfaces. For custom
    /// controls whose own focus effect is disabled.
    public func focusRing(_ isVisible: Bool, in shape: some InsettableShape) -> some View {
        modifier(FocusRing(isVisible: isVisible, shape: shape))
    }
}

private struct FocusRing<S: InsettableShape>: ViewModifier {
    let isVisible: Bool
    let shape: S
    @Environment(\.designTokens) private var tokens

    func body(content: Content) -> some View {
        content.overlay {
            if isVisible {
                WithColorRoles { roles in
                    shape.inset(by: -(tokens.spacing.focusRingOffset + tokens.size.focusRing))
                        .strokeBorder(roles.focusRing, lineWidth: tokens.size.focusRing)
                }
                .accessibilityHidden(true)
                .allowsHitTesting(false)
            }
        }
    }
}
