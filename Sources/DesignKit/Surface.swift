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
    /// Increase Contrast forced by `accessibilityOverrides`, which a `List` cell does not lose as it does the system's key.
    @Entry var forcedContrast: ColorSchemeContrast? = nil
    /// The contrast the kit's views draw for: the override if there is one, else the system's.
    var kitContrast: ColorSchemeContrast { forcedContrast ?? colorSchemeContrast }
}

extension View {
    /// Draws `surface` behind the view in `shape`. Glass becomes an opaque background fill with a separator line under
    /// Reduce Transparency; Increase Contrast outlines every surface in `.secondary`.
    public func surface(_ surface: Surface, in shape: some InsettableShape) -> some View {
        modifier(SurfaceModifier(surface: surface, shape: shape))
    }

    /// Simulates Increase Contrast, Reduce Transparency and Reduce Motion for previews and renders, without touching
    /// the system's settings; `fullMotion` does the opposite and lifts a Reduce Motion the system has on, to see the
    /// full animations. When both are set, Reduce Motion wins. Increase Contrast reaches the kit's views inside a
    /// `List`'s cells too (AppKit hands a cell the system's own value, which this cannot change; the kit's views read
    /// the override as well). Never use it in shipping UI: the app follows the system.
    public func accessibilityOverrides(
        increaseContrast: Bool = false, reduceTransparency: Bool = false, reduceMotion: Bool = false,
        fullMotion: Bool = false
    ) -> some View {
        transformEnvironment(\._colorSchemeContrast) { if increaseContrast { $0 = .increased } }
            .transformEnvironment(\.forcedContrast) { if increaseContrast { $0 = .increased } }
            .transformEnvironment(\._accessibilityReduceTransparency) { if reduceTransparency { $0 = true } }
            .transformEnvironment(\._accessibilityReduceMotion) {
                if reduceMotion { $0 = true } else if fullMotion { $0 = false }
            }
    }
}

private struct SurfaceModifier<S: InsettableShape>: ViewModifier {
    let surface: Surface
    let shape: S
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.kitContrast) private var contrast
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
    /// A keyboard focus ring on `shape` while `isVisible`: a `Size.focusRing` line (1.5 pt) inside the shape's edge, so
    /// no container clips it, in `ColorRoles.focusRing` (the Theme's hue at 3:1 at least on the Theme's surfaces, never
    /// the system's blue). For custom controls whose own focus effect is disabled. It shows only when the focus came
    /// from the keyboard (or while VoiceOver runs), never after a click (`FocusInputTracker`): pass the view's focus as
    /// it is, the kit hides the ring a click would otherwise draw.
    public func focusRing(_ isVisible: Bool, in shape: some InsettableShape) -> some View {
        modifier(FocusRing(isVisible: isVisible, isSelected: false, shape: shape))
    }

    /// The same for a row of a list, where the arrow keys move the selection: a selected row shows no ring, since its
    /// selection already shows where the focus is (`FocusInputTracker.showsFocusRing(isSelected:)`). A focused row
    /// that is not selected shows the ring, and so does a selected one under `selectionFollowsFocus(false)`. `ListRowBackground` and the kit's sidebar cells pass `RowState.isSelected`
    /// themselves.
    public func focusRing(_ isVisible: Bool, isSelected: Bool, in shape: some InsettableShape) -> some View {
        modifier(FocusRing(isVisible: isVisible, isSelected: isSelected, shape: shape))
    }
}

extension EnvironmentValues {
    /// Whether the arrow keys move the selection of the rows below with their focus, as in a `List` (the default): a
    /// selected row then shows no focus ring, its selection is the focus. False for rows whose focus moves on its own,
    /// over a selection that stays put (the Space rail's panel, a menu-like list): a focused selected row shows the ring.
    @Entry public var selectionFollowsFocus: Bool = true
}

extension View {
    /// Sets `selectionFollowsFocus` for the rows below.
    public func selectionFollowsFocus(_ follows: Bool) -> some View {
        environment(\.selectionFollowsFocus, follows)
    }
}

private struct FocusRing<S: InsettableShape>: ViewModifier {
    let isVisible: Bool
    let isSelected: Bool
    let shape: S
    @Environment(\.designTokens) private var tokens
    @Environment(\.focusInputTracker) private var tracker
    @Environment(\.selectionFollowsFocus) private var selectionFollowsFocus

    func body(content: Content) -> some View {
        // Read even when no ring is asked for, so that the shared tracker watches the app's events before any click.
        let tracker = tracker ?? .shared
        return content.overlay {
            if isVisible && tracker.showsFocusRing(isSelected: isSelected && selectionFollowsFocus) {
                WithColorRoles { roles in
                    shape.strokeBorder(roles.focusRing, lineWidth: tokens.size.focusRing)
                }
                .accessibilityHidden(true)
                .allowsHitTesting(false)
            }
        }
    }
}

extension EnvironmentValues {
    /// Draws the kit's controls (`IconButton`, `SegmentedPill`, a banner's buttons) as if focused, for previews and
    /// offscreen renders: `ImageRenderer` has no focus.
    @Entry public var controlFocusPreview: Bool = false
}

extension View {
    /// Draws the controls below with the keyboard focus ring, for previews and renders. Never in shipping UI.
    public func controlFocusPreview(_ isFocused: Bool = true) -> some View {
        environment(\.controlFocusPreview, isFocused)
    }

    /// The kit's focus ring around `shape` while the nearest focusable ancestor (the control's button) has keyboard
    /// focus. Put it inside the button's label, and disable the button's own focus effect.
    func controlFocusRing(in shape: some InsettableShape) -> some View {
        modifier(ControlFocusRing(shape: shape))
    }
}

private struct ControlFocusRing<S: InsettableShape>: ViewModifier {
    @Environment(\.isFocused) private var isFocused
    @Environment(\.controlFocusPreview) private var preview
    let shape: S

    func body(content: Content) -> some View {
        content.focusRing(isFocused || preview, in: shape)
    }
}
