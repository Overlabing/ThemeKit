import SwiftUI

/// The duration scale, in seconds. For a spring it is the perceptual duration (SwiftUI's `duration:`).
public enum MotionDuration: Double, Sendable, CaseIterable {
    /// Feedback under the pointer: a hover fill, an overlay fading.
    case instant = 0.12
    /// A small change in place: a chevron, a row's state, the reduced fade.
    case quick = 0.2
    /// A surface changing: a panel, the Theme, the switcher.
    case calm = 0.35
    /// A long travel.
    case deliberate = 0.5
    /// The period of a looping activity indicator.
    case cycle = 1.2
}

/// The curves. Springs never bounce visibly.
public enum MotionCurve: Sendable, CaseIterable {
    /// Critically damped spring, no overshoot.
    case smooth
    /// Slightly underdamped spring, for a state change.
    case snappy
    /// A panel's entrance, a little livelier than `smooth`.
    case spring
    case easeOut
    /// Loops only.
    case easeInOut

    /// The spring's bounce as `Animation.spring(duration:bounce:)` takes it; nil for a timing curve.
    public var bounce: Double? {
        switch self {
        case .smooth: 0
        case .snappy: 0.15
        case .spring: 0.1
        case .easeOut, .easeInOut: nil
        }
    }

    /// A spring keeps moving after its perceptual duration: it is within 0.1 % of its target only after
    /// `duration × settlingFactor`. 1 for a timing curve.
    public var settlingFactor: Double {
        switch self {
        case .smooth: 1.47
        case .snappy: 1.39
        case .spring: 1.33
        case .easeOut, .easeInOut: 1
        }
    }
}

/// What a role becomes under Reduce Motion.
public enum ReducedMotion: Sendable, Equatable {
    /// The shared fade: no movement, no change of size.
    case fade
    /// The change happens at once.
    case none
}

/// The named motions. A view never writes a duration or a curve; it asks a role for its animation or transition. A new
/// motion becomes a role first. A looping role (`loadingPulse`) is repeated by the caller.
public enum MotionRole: String, Sendable, CaseIterable {
    case panelAppear
    case panelContent
    case panelDisappear
    case rowState
    case rowDeparture
    case indicatorRotation
    case hoverFill
    /// A Theme changing, a change of space included: the window background, the switcher, the column's edge. There is
    /// no separate space role; a space's change is the change of its Theme (Oisillon's `spaceChange` has this spec).
    case themeChange
    /// The Space rail changing Profile: the old Profile's glyphs fold into its dots while the new one's open, one
    /// glyph after the other.
    case profileSwap
    case pullToOpen
    case contentReveal
    case scrollFollow
    case overlayFade
    case placeholderFade
    case loadingPulse

    public struct Spec: Sendable, Equatable {
        public var duration: MotionDuration
        public var curve: MotionCurve
        public var delay: Double
        /// Delay added per item when several items move together (groups arriving one after the other).
        public var stagger: Double
        public var reduced: ReducedMotion

        public init(
            duration: MotionDuration, curve: MotionCurve, delay: Double = 0, stagger: Double = 0, reduced: ReducedMotion
        ) {
            self.duration = duration
            self.curve = curve
            self.delay = delay
            self.stagger = stagger
            self.reduced = reduced
        }

        /// When the motion is really over: its delay plus its duration times the curve's settling factor.
        public var settlingSeconds: Double { delay + duration.rawValue * curve.settlingFactor }
    }

    public var spec: Spec {
        switch self {
        case .panelAppear: Spec(duration: .calm, curve: .spring, reduced: .fade)
        case .panelContent: Spec(duration: .quick, curve: .easeOut, delay: 0.08, reduced: .none)
        case .panelDisappear: Spec(duration: .calm, curve: .easeOut, reduced: .fade)
        case .rowState: Spec(duration: .quick, curve: .snappy, reduced: .none)
        case .rowDeparture: Spec(duration: .calm, curve: .easeOut, reduced: .none)
        case .indicatorRotation: Spec(duration: .quick, curve: .smooth, reduced: .none)
        case .hoverFill: Spec(duration: .instant, curve: .easeOut, reduced: .none)
        case .themeChange: Spec(duration: .calm, curve: .smooth, reduced: .none)
        case .profileSwap: Spec(duration: .calm, curve: .smooth, stagger: 0.04, reduced: .fade)
        case .pullToOpen: Spec(duration: .calm, curve: .spring, stagger: 0.04, reduced: .fade)
        case .contentReveal: Spec(duration: .calm, curve: .smooth, reduced: .none)
        case .scrollFollow: Spec(duration: .deliberate, curve: .smooth, reduced: .none)
        case .overlayFade: Spec(duration: .instant, curve: .easeOut, reduced: .none)
        case .placeholderFade: Spec(duration: .instant, curve: .easeOut, delay: 0.1, reduced: .none)
        case .loadingPulse: Spec(duration: .cycle, curve: .easeInOut, reduced: .none)
        }
    }

    /// The fade every `.fade` role becomes under Reduce Motion.
    public static let reducedFade = Spec(duration: .quick, curve: .easeOut, reduced: .fade)

    /// The spec to run, or nil when Reduce Motion makes the change immediate.
    public func resolved(reduceMotion: Bool) -> Spec? {
        guard reduceMotion else { return spec }
        return spec.reduced == .fade ? Self.reducedFade : nil
    }

    public func animation(reduceMotion: Bool) -> Animation? {
        guard let spec = resolved(reduceMotion: reduceMotion) else { return nil }
        let seconds = spec.duration.rawValue
        let base: Animation = switch spec.curve {
        case .easeOut: .easeOut(duration: seconds)
        case .easeInOut: .easeInOut(duration: seconds)
        case .smooth, .snappy, .spring: .spring(duration: seconds, bounce: spec.curve.bounce ?? 0)
        }
        return spec.delay > 0 ? base.delay(spec.delay) : base
    }

    /// `transition`, or under Reduce Motion a plain fade (a role that fades) or nothing.
    public func transition(_ transition: AnyTransition, reduceMotion: Bool) -> AnyTransition {
        guard reduceMotion else { return transition }
        return spec.reduced == .fade ? .opacity : .identity
    }
}
