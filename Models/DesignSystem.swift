import SwiftUI

/// Centralised design tokens. All visual constants should flow from here so
/// the app feels coherent and tweaking the look is a one-file change.
enum DS {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 16
    }

    /// Text-style-based so every token scales with the user's Dynamic Type
    /// setting. The point sizes already matched Apple's type scale
    /// (28/22/17/15/13/12 = title/title2/headline/subheadline/footnote/caption),
    /// so this preserves the look at the default size while adding scaling.
    /// (`micro` shifts 10→11 via caption2, the smallest available style.)
    enum Typography {
        static let display = Font.system(.title, weight: .bold)
        static let titleLarge = Font.system(.title2, weight: .bold)
        static let titleMedium = Font.system(.headline)  // .headline is 17 semibold
        static let body = Font.system(.subheadline)
        static let bodyEm = Font.system(.subheadline, weight: .semibold)
        static let caption = Font.system(.caption)
        static let captionStrong = Font.system(.caption, weight: .semibold)
        static let micro = Font.system(.caption2)
        static let sectionHeader = Font.system(.footnote, weight: .semibold)
            .smallCaps()
    }
}

/// Scales a fixed-point system font with Dynamic Type, relative to a text style.
/// Use for *text* whose size isn't one of the `DS.Typography` tokens. Decorative
/// SF Symbol icons should keep a plain `.font(.system(size:))` — they scale via
/// `.imageScale`, not text metrics, and shouldn't grow with the text setting.
private struct ScaledSystemFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight

    init(size: CGFloat, weight: Font.Weight, relativeTo textStyle: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
        self.weight = weight
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight))
    }
}

extension View {
    /// A fixed-point system font that scales with Dynamic Type.
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular,
                    relativeTo textStyle: Font.TextStyle = .body) -> some View {
        modifier(ScaledSystemFont(size: size, weight: weight, relativeTo: textStyle))
    }
}

/// Shadow modifier used by cards and popovers.
extension View {
    func softShadow() -> some View {
        shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 2)
    }
}
