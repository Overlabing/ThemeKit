/// The four appearances a window is drawn in: light or dark, each with or without Increase Contrast.
public enum Appearance: Sendable, CaseIterable, Hashable {
    case light, dark, lightIncreasedContrast, darkIncreasedContrast

    public var isDark: Bool { self == .dark || self == .darkIncreasedContrast }
    public var isIncreasedContrast: Bool { self == .lightIncreasedContrast || self == .darkIncreasedContrast }

    public init(isDark: Bool, isIncreasedContrast: Bool) {
        switch (isDark, isIncreasedContrast) {
        case (false, false): self = .light
        case (true, false): self = .dark
        case (false, true): self = .lightIncreasedContrast
        case (true, true): self = .darkIncreasedContrast
        }
    }
}
