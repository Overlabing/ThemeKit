import AppKit
import ColorCore
import ColorUI
import DesignKit
import SwiftUI

// Renders the gallery offscreen with ImageRenderer: no window, nothing on screen. ImageRenderer does not draw Liquid
// Glass reliably (shapes vanish), so glass surfaces are drawn with `.material`; the live look needs a window on screen.
// `DesignKitGallery <output directory> [Theme id…]`: the sample Themes, or the ones named. `DesignKitGallery rail
// <output directory>`: the Space rail's windows and states (RailGallery.swift). `DesignKitGallery client <output
// directory>`: the 0.2.4 controls and a real List of rows (ClientGallery.swift). `DesignKitGallery 0.2.8 <output
// directory>`: the 0.2.8 additions (Gallery028.swift). `DesignKitGallery 0.2.9 <output directory>`: the 0.2.9 additions
// (Gallery029.swift). `DesignKitGallery 0.2.10 <output directory>`: the 0.2.10 changes (Gallery0210.swift).

enum Kind: String, CaseIterable {
    case components
    case componentsAccessibility = "components-contrast-transparency"
    case columnLeft = "column-left"
    case columnRight = "column-right"
    case browserLeft = "browser-main-window-left"
    case browserRight = "browser-main-window-right"
    case browserAccessibility = "browser-main-window-left-contrast-transparency"
}

struct Shot {
    let kind: Kind
    let theme: Theme
    let isDark: Bool

    var file: String { "\(kind.rawValue)-\(theme.id)-\(isDark ? "dark" : "light").png" }
    var size: CGSize {
        switch kind {
        case .components, .componentsAccessibility: CGSize(width: 840, height: 860)
        default: CGSize(width: 1200, height: 800)
        }
    }

    @MainActor @ViewBuilder var view: some View {
        Group {
            switch kind {
            case .components: ComponentSheet()
            case .componentsAccessibility: ComponentSheet().accessibilityOverrides(increaseContrast: true, reduceTransparency: true)
            case .columnLeft: CompositionSheet(side: .left)
            case .columnRight: CompositionSheet(side: .right)
            case .browserLeft: BrowserSample(side: .left)
            case .browserRight: BrowserSample(side: .right)
            case .browserAccessibility:
                BrowserSample(side: .left).accessibilityOverrides(increaseContrast: true, reduceTransparency: true)
            }
        }
        .designTokens(.standard)
        .theme(theme)
        .environment(\.glassRendering, .material)
        .environment(\.colorScheme, isDark ? .dark : .light)
        .frame(width: size.width, height: size.height)
    }
}

@MainActor
func render(_ shot: Shot, to url: URL) throws {
    let renderer = ImageRenderer(content: shot.view)
    renderer.scale = 2
    guard let image = renderer.cgImage,
          let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    else { throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: url.path]) }
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url)
}

/// Several renders in a grid, one row per entry of `rows`, on a neutral background.
func overview(_ rows: [[URL]], to url: URL) throws {
    let images = try rows.map { row in
        try row.map { file -> CGImage in
            guard let image = NSImage(contentsOf: file)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: file.path])
            }
            return image
        }
    }
    let gap = 48
    let cell = (width: images[0][0].width, height: images[0][0].height)
    let columns = images.map(\.count).max() ?? 1
    let width = columns * cell.width + (columns + 1) * gap
    let height = images.count * cell.height + (images.count + 1) * gap
    guard let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { throw CocoaError(.fileWriteUnknown) }
    context.setFillColor(CGColor(gray: 0.5, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    for (row, line) in images.enumerated() {
        for (column, image) in line.enumerated() {
            let x = gap + column * (cell.width + gap)
            let y = height - (row + 1) * (cell.height + gap)
            context.draw(image, in: CGRect(x: x, y: y, width: image.width, height: image.height))
        }
    }
    guard let image = context.makeImage(),
          let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    else { throw CocoaError(.fileWriteUnknown) }
    try data.write(to: url)
}

@MainActor
func run(output: URL, themes: [Theme]) {
    do {
        for theme in themes {
            for isDark in [false, true] {
                for kind in Kind.allCases {
                    let shot = Shot(kind: kind, theme: theme, isDark: isDark)
                    try render(shot, to: output.appending(path: shot.file))
                    print("OK: \(shot.file)")
                }
            }
        }
        for kind in Kind.allCases {
            let rows = themes.map { theme in
                [false, true].map { output.appending(path: Shot(kind: kind, theme: theme, isDark: $0).file) }
            }
            try overview(rows, to: output.appending(path: "overview-\(kind.rawValue).png"))
            print("OK: overview-\(kind.rawValue).png")
        }
    } catch {
        print("FAILED: \(error)")
        exit(1)
    }
}

/// Prints every legibility case of the standard tokens, one tab-separated row each: Theme (or hue), appearance,
/// placement, role, surface, the system default's ratio, the kit's ratio, the threshold. Then the accent cases with the
/// Theme's own hues first, their Theme id suffixed with the list.
func audit() {
    let tokens = DesignTokens.standard
    var cases: [LegibilityCase] = []
    for placement in SurfacePlacement.allCases {
        for theme in Palette.standard.themes {
            for appearance in Appearance.allCases {
                cases += tokens.legibilityCases(for: theme, in: appearance, placement: placement)
            }
        }
        if placement == .frame {
            for appearance in Appearance.allCases {
                cases += tokens.symbolCases(in: appearance)
            }
        }
    }
    for theme in Palette.standard.themes {
        for appearance in Appearance.allCases {
            cases += tokens.railCases(for: theme, in: appearance)
        }
    }
    for theme in Palette.standard.themes {
        for appearance in Appearance.allCases {
            for placement in SurfacePlacement.allCases {
                cases += tokens.accentCases(for: theme, in: appearance, placement: placement)
            }
        }
    }
    // The Theme's own hues first (Oisillon's account order, issue #17): the same accent cases, the list resolved
    // against each Theme. Their Theme id carries the list, so they do not collide with the default order's.
    var themeFirst = tokens
    themeFirst.accents = [.primary, .secondary, .hue(.mint), .hue(.yellow)]
    var themeFirstCases: [LegibilityCase] = []
    for theme in Palette.standard.themes {
        for appearance in Appearance.allCases {
            for placement in SurfacePlacement.allCases {
                themeFirstCases += themeFirst.accentCases(for: theme, in: appearance, placement: placement)
            }
        }
    }
    func emit(_ item: LegibilityCase, themeID: String) {
        print([themeID, "\(item.appearance)", item.placement.rawValue, item.role.rawValue, item.surface.rawValue,
               "\(item.before)", "\(item.after)",
               String(format: "%.1f", item.threshold)].joined(separator: "\t"))
    }
    for item in cases { emit(item, themeID: item.themeID) }
    for item in themeFirstCases { emit(item, themeID: "\(item.themeID)[primary,secondary,mint,yellow]") }
}

if CommandLine.arguments.count == 2 && CommandLine.arguments[1] == "audit" {
    audit()
    exit(0)
}
if CommandLine.arguments.count == 3 && CommandLine.arguments[1] == "client" {
    MainActor.assumeIsolated { runClient(output: URL(filePath: CommandLine.arguments[2], directoryHint: .isDirectory)) }
    exit(0)
}
if CommandLine.arguments.count == 3 && CommandLine.arguments[1] == "0.2.8" {
    MainActor.assumeIsolated { run028(output: URL(filePath: CommandLine.arguments[2], directoryHint: .isDirectory)) }
    exit(0)
}
if CommandLine.arguments.count == 3 && CommandLine.arguments[1] == "0.2.9" {
    MainActor.assumeIsolated { run029(output: URL(filePath: CommandLine.arguments[2], directoryHint: .isDirectory)) }
    exit(0)
}
if CommandLine.arguments.count == 3 && CommandLine.arguments[1] == "0.2.10" {
    MainActor.assumeIsolated { run0210(output: URL(filePath: CommandLine.arguments[2], directoryHint: .isDirectory)) }
    exit(0)
}
if CommandLine.arguments.count == 3 && CommandLine.arguments[1] == "rail" {
    MainActor.assumeIsolated { runRail(output: URL(filePath: CommandLine.arguments[2], directoryHint: .isDirectory)) }
    exit(0)
}
guard CommandLine.arguments.count >= 2 else {
    print("usage: DesignKitGallery <output directory> [Theme id…] | rail <output directory> | client <output directory> | 0.2.8 <output directory> | 0.2.9 <output directory> | 0.2.10 <output directory> | audit")
    exit(2)
}
let named = CommandLine.arguments.dropFirst(2).map { id in
    guard let theme = Palette.standard.theme(id: id) else {
        print("FAILED: no standard Theme \(id)")
        exit(2)
    }
    return theme
}
MainActor.assumeIsolated {
    run(output: URL(filePath: CommandLine.arguments[1], directoryHint: .isDirectory),
        themes: named.isEmpty ? Sample.themes : named)
}
