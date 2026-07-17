import SwiftUI

/// A small three-bar "now playing" indicator that animates while audio is
/// playing. Used in lists to mark the currently playing track.
struct NowPlayingIndicator: View {
    let isPlaying: Bool
    let accent: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Full (tallest) height per bar; each pulses on its own staggered timeline.
    private let fullHeights: [CGFloat] = [8, 14, 10]
    private let delays: [Double] = [0, 0.2, 0.4]

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<fullHeights.count, id: \.self) { i in
                Bar(fullHeight: fullHeights[i], delay: delays[i], accent: accent,
                    animating: isPlaying && !reduceMotion)
            }
        }
        .frame(width: 14, height: 14)
        // Purely decorative — the now-playing state is announced on the row
        // label instead, so keep this out of the VoiceOver tree.
        .accessibilityHidden(true)
    }

    /// One bar. Pulses its vertical scale between two DISTINCT values so SwiftUI
    /// interpolates it over time — a function whose animated endpoints coincide
    /// (e.g. abs(sin(phase·π))) renders as a static bar and never moves.
    private struct Bar: View {
        let fullHeight: CGFloat
        let delay: Double
        let accent: Color
        let animating: Bool

        @State private var scaleY: CGFloat = 0.45

        var body: some View {
            Capsule()
                .fill(accent)
                .frame(width: 2.5, height: fullHeight)
                .scaleEffect(y: scaleY, anchor: .center)
                .onAppear { apply(animating) }
                .onChange(of: animating) { apply($0) }
        }

        private func apply(_ on: Bool) {
            if on {
                scaleY = 0.45
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(delay)) {
                    scaleY = 1.0
                }
            } else {
                // Reduce Motion / not playing: hold at a fixed mid-height.
                withAnimation(.easeInOut(duration: 0.2)) { scaleY = 0.7 }
            }
        }
    }
}

/// A leading "now playing" indicator on a track row.
struct NowPlayingLeadingBar: View {
    let isCurrent: Bool
    let accent: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(isCurrent ? accent : Color.clear)
            .frame(width: 3, height: 28)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: isCurrent)
            .accessibilityHidden(true)
    }
}

extension View {
    /// Gives a track row a single, clear VoiceOver announcement that folds in
    /// the now-playing state (the animated indicator is hidden from a11y, so
    /// without this the state would be invisible to VoiceOver). Apply to the
    /// row's `Button` — it replaces the auto-generated label and adds a hint.
    func trackRowAccessibility(
        title: String, artist: String,
        isCurrent: Bool, isPlaying: Bool
    ) -> some View {
        let state = isCurrent ? (isPlaying ? "Now playing. " : "Paused. ") : ""
        return self
            .accessibilityLabel("\(state)\(title), \(artist)")
            .accessibilityHint("Plays the track")
    }
}

/// Section header used in lists (Apple-style small caps).
struct SectionLabel: View {
    let title: String
    let tokens: DesignTokens

    var body: some View {
        Text(title)
            .font(DS.Typography.sectionHeader)
            .foregroundColor(tokens.textSecondary)
            .textCase(nil)
    }
}
