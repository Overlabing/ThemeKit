#if canImport(AppKit)
import ColorCore

/// Recorded from the original implementation on macOS 27.0.1: the window background, the labels and the twelve system
/// hues, resolved in each appearance. Increase Contrast resolves like its base there (AppKit answers plain Aqua).
struct NativeGolden: Sendable {
    let appearance: Appearance
    let background, label, secondaryLabel: RGBA
    let hues: [Hue: RGBA]

    static let all: [NativeGolden] = [
    NativeGolden(appearance: .light, background: RGBA(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), label: RGBA(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.8470588235294118), secondaryLabel: RGBA(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.4980392156862745), hues: [
        .indigo: RGBA(red: 0.3803921568627451, green: 0.3333333333333333, blue: 0.9607843137254902, alpha: 1.0),
        .blue: RGBA(red: 0.0, green: 0.5333333333333333, blue: 1.0, alpha: 1.0),
        .orange: RGBA(red: 1.0, green: 0.5529411764705883, blue: 0.1568627450980392, alpha: 1.0),
        .pink: RGBA(red: 1.0, green: 0.17647058823529413, blue: 0.3333333333333333, alpha: 1.0),
        .teal: RGBA(red: 0.0, green: 0.7647058823529411, blue: 0.8156862745098039, alpha: 1.0),
        .green: RGBA(red: 0.20392156862745098, green: 0.7803921568627451, blue: 0.34901960784313724, alpha: 1.0),
        .red: RGBA(red: 1.0, green: 0.2196078431372549, blue: 0.23529411764705882, alpha: 1.0),
        .purple: RGBA(red: 0.796078431372549, green: 0.18823529411764706, blue: 0.8784313725490196, alpha: 1.0),
        .mint: RGBA(red: 0.0, green: 0.7843137254901961, blue: 0.7019607843137254, alpha: 1.0),
        .cyan: RGBA(red: 0.0, green: 0.7529411764705882, blue: 0.9098039215686274, alpha: 1.0),
        .brown: RGBA(red: 0.6745098039215687, green: 0.4980392156862745, blue: 0.3686274509803922, alpha: 1.0),
        .yellow: RGBA(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0),
    ]),
    NativeGolden(appearance: .dark, background: RGBA(red: 0.11764705882352941, green: 0.11764705882352941, blue: 0.11764705882352941, alpha: 1.0), label: RGBA(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8470588235294118), secondaryLabel: RGBA(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5490196078431373), hues: [
        .indigo: RGBA(red: 0.42745098039215684, green: 0.48627450980392156, blue: 1.0, alpha: 1.0),
        .blue: RGBA(red: 0.0, green: 0.5686274509803921, blue: 1.0, alpha: 1.0),
        .orange: RGBA(red: 1.0, green: 0.5725490196078431, blue: 0.18823529411764706, alpha: 1.0),
        .pink: RGBA(red: 1.0, green: 0.21568627450980393, blue: 0.37254901960784315, alpha: 1.0),
        .teal: RGBA(red: 0.0, green: 0.8235294117647058, blue: 0.8784313725490196, alpha: 1.0),
        .green: RGBA(red: 0.18823529411764706, green: 0.8196078431372549, blue: 0.34509803921568627, alpha: 1.0),
        .red: RGBA(red: 1.0, green: 0.25882352941176473, blue: 0.27058823529411763, alpha: 1.0),
        .purple: RGBA(red: 0.8588235294117647, green: 0.20392156862745098, blue: 0.9490196078431372, alpha: 1.0),
        .mint: RGBA(red: 0.0, green: 0.8549019607843137, blue: 0.7647058823529411, alpha: 1.0),
        .cyan: RGBA(red: 0.23529411764705882, green: 0.8274509803921568, blue: 0.996078431372549, alpha: 1.0),
        .brown: RGBA(red: 0.7176470588235294, green: 0.5411764705882353, blue: 0.4, alpha: 1.0),
        .yellow: RGBA(red: 1.0, green: 0.8392156862745098, blue: 0.0, alpha: 1.0),
    ]),
    NativeGolden(appearance: .lightIncreasedContrast, background: RGBA(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), label: RGBA(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.8470588235294118), secondaryLabel: RGBA(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.4980392156862745), hues: [
        .indigo: RGBA(red: 0.3803921568627451, green: 0.3333333333333333, blue: 0.9607843137254902, alpha: 1.0),
        .blue: RGBA(red: 0.0, green: 0.5333333333333333, blue: 1.0, alpha: 1.0),
        .orange: RGBA(red: 1.0, green: 0.5529411764705883, blue: 0.1568627450980392, alpha: 1.0),
        .pink: RGBA(red: 1.0, green: 0.17647058823529413, blue: 0.3333333333333333, alpha: 1.0),
        .teal: RGBA(red: 0.0, green: 0.7647058823529411, blue: 0.8156862745098039, alpha: 1.0),
        .green: RGBA(red: 0.20392156862745098, green: 0.7803921568627451, blue: 0.34901960784313724, alpha: 1.0),
        .red: RGBA(red: 1.0, green: 0.2196078431372549, blue: 0.23529411764705882, alpha: 1.0),
        .purple: RGBA(red: 0.796078431372549, green: 0.18823529411764706, blue: 0.8784313725490196, alpha: 1.0),
        .mint: RGBA(red: 0.0, green: 0.7843137254901961, blue: 0.7019607843137254, alpha: 1.0),
        .cyan: RGBA(red: 0.0, green: 0.7529411764705882, blue: 0.9098039215686274, alpha: 1.0),
        .brown: RGBA(red: 0.6745098039215687, green: 0.4980392156862745, blue: 0.3686274509803922, alpha: 1.0),
        .yellow: RGBA(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0),
    ]),
    NativeGolden(appearance: .darkIncreasedContrast, background: RGBA(red: 0.11764705882352941, green: 0.11764705882352941, blue: 0.11764705882352941, alpha: 1.0), label: RGBA(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8470588235294118), secondaryLabel: RGBA(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5490196078431373), hues: [
        .indigo: RGBA(red: 0.42745098039215684, green: 0.48627450980392156, blue: 1.0, alpha: 1.0),
        .blue: RGBA(red: 0.0, green: 0.5686274509803921, blue: 1.0, alpha: 1.0),
        .orange: RGBA(red: 1.0, green: 0.5725490196078431, blue: 0.18823529411764706, alpha: 1.0),
        .pink: RGBA(red: 1.0, green: 0.21568627450980393, blue: 0.37254901960784315, alpha: 1.0),
        .teal: RGBA(red: 0.0, green: 0.8235294117647058, blue: 0.8784313725490196, alpha: 1.0),
        .green: RGBA(red: 0.18823529411764706, green: 0.8196078431372549, blue: 0.34509803921568627, alpha: 1.0),
        .red: RGBA(red: 1.0, green: 0.25882352941176473, blue: 0.27058823529411763, alpha: 1.0),
        .purple: RGBA(red: 0.8588235294117647, green: 0.20392156862745098, blue: 0.9490196078431372, alpha: 1.0),
        .mint: RGBA(red: 0.0, green: 0.8549019607843137, blue: 0.7647058823529411, alpha: 1.0),
        .cyan: RGBA(red: 0.23529411764705882, green: 0.8274509803921568, blue: 0.996078431372549, alpha: 1.0),
        .brown: RGBA(red: 0.7176470588235294, green: 0.5411764705882353, blue: 0.4, alpha: 1.0),
        .yellow: RGBA(red: 1.0, green: 0.8392156862745098, blue: 0.0, alpha: 1.0),
    ]),
    ]
}
#endif
