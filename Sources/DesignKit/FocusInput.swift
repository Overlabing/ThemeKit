import Observation
import SwiftUI
#if os(macOS)
import AppKit
#endif

/// What last moved the keyboard focus, as far as the kit's focus ring is concerned.
public enum FocusInput: Sendable, Equatable {
    /// A navigation key: Tab or Shift-Tab, an arrow, Home, End, Page Up or Page Down.
    case keyboard
    /// A click or a tap of the pointer.
    case pointer
}

/// Decides whether the kit's focus ring shows: macOS draws one for keyboard navigation, never because a click put the
/// focus somewhere. Every `focusRing(_:in:)` asks it, so every row, the Space rail, its panel and the kit's controls
/// follow one rule without the app changing its code: a ring a view asks for shows unless the last focus-moving input
/// was the pointer. Before any input (a preview, an offscreen render) it shows, as in 0.2.10. While VoiceOver runs it
/// always shows, since VoiceOver moves the focus without a key the app sees.
///
/// `shared` watches the app's own events (a local monitor: a mouse button down is the pointer, a navigation key the
/// keyboard; a key with Command, a letter or Return changes nothing). A view reads the tracker from the environment
/// (`focusInputTracker(_:)`), `shared` when none is set; a test or a preview sets its own and records into it.
@MainActor
@Observable
public final class FocusInputTracker {
    /// The app's tracker. It starts watching the app's events the first time it is read; the kit's focus ring reads it
    /// when it first draws, before any click.
    public static let shared: FocusInputTracker = {
        let tracker = FocusInputTracker()
        tracker.watchesApp()
        return tracker
    }()

    /// The last focus-moving input; nil before any.
    public private(set) var last: FocusInput?
    /// Whether VoiceOver runs (`shared` follows it; a tracker of one's own is set with `record(voiceOver:)`).
    public private(set) var isVoiceOverRunning = false

    @ObservationIgnored private var monitor: Any?
    #if os(macOS)
    @ObservationIgnored private var voiceOverObservation: NSKeyValueObservation?
    #endif

    /// A tracker that watches nothing: input reaches it through `record(_:)` (and `handle(_:)` on macOS).
    public init() {}

    /// Whether a focus ring a view asks for shows now.
    public var showsFocusRing: Bool { isVoiceOverRunning || last != .pointer }

    /// Notes `input` as the last focus-moving input.
    public func record(_ input: FocusInput) {
        if last != input { last = input }
    }

    /// Notes whether VoiceOver runs.
    public func record(voiceOver running: Bool) {
        if isVoiceOverRunning != running { isVoiceOverRunning = running }
    }

    #if os(macOS)
    /// The focus-moving input `event` is: a mouse button down is the pointer, a navigation key without Command the
    /// keyboard, anything else nil.
    public nonisolated static func input(for event: NSEvent) -> FocusInput? {
        switch event.type {
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            return .pointer
        case .keyDown:
            guard !event.modifierFlags.contains(.command) else { return nil }
            return navigationKeyCodes.contains(event.keyCode) ? .keyboard : nil
        default:
            return nil
        }
    }

    /// Tab, Home, Page Up, End, Page Down, ←, →, ↓, ↑.
    nonisolated static let navigationKeyCodes: Set<UInt16> = [48, 115, 116, 119, 121, 123, 124, 125, 126]

    /// Records `event` when it moves the focus.
    public func handle(_ event: NSEvent) {
        if let input = Self.input(for: event) { record(input) }
    }

    private func watchesApp() {
        monitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown, .keyDown]
        ) { event in
            if let input = FocusInputTracker.input(for: event) {
                MainActor.assumeIsolated { FocusInputTracker.shared.record(input) }
            }
            return event
        }
        record(voiceOver: NSWorkspace.shared.isVoiceOverEnabled)
        voiceOverObservation = NSWorkspace.shared.observe(\.isVoiceOverEnabled, options: [.new]) { workspace, _ in
            let running = workspace.isVoiceOverEnabled
            DispatchQueue.main.async { FocusInputTracker.shared.record(voiceOver: running) }
        }
    }
    #else
    private func watchesApp() {}
    #endif
}

extension EnvironmentValues {
    /// The tracker the kit's focus rings ask; nil for `FocusInputTracker.shared`.
    @Entry public var focusInputTracker: FocusInputTracker? = nil
}

extension View {
    /// Has the focus rings below ask `tracker` instead of `FocusInputTracker.shared`: for tests, previews and renders
    /// that show the ring after a click (no ring) or after a navigation key (the ring). Never in shipping UI.
    public func focusInputTracker(_ tracker: FocusInputTracker) -> some View {
        environment(\.focusInputTracker, tracker)
    }
}
