import SwiftUI

/// Shared thumbnail view for a track. Uses `AsyncCachedImage` so the
/// same artwork URL is only downloaded once across the whole app.
struct TrackThumbnail: View {
    let url: URL?
    let size: CGFloat
    var cornerRadius: CGFloat = 6

    var body: some View {
        AsyncCachedImage(url: url) {
            Rectangle().fill(Color.gray.opacity(0.2))
        }
        .frame(width: size, height: size)
        .cornerRadius(cornerRadius)
        .clipped()
    }
}
