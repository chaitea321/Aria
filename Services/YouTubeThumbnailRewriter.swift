import Foundation

/// Rewrites YouTube thumbnail URLs to higher-quality versions.
///
/// YouTube thumbnail URLs follow the pattern:
///   `https://i.ytimg.com/vi/{video_id}/default.jpg`        (120×90)
///   `https://i.ytimg.com/vi/{video_id}/mqdefault.jpg`       (320×180)
///   `https://i.ytimg.com/vi/{video_id}/hqdefault.jpg`       (480×360)
///   `https://i.ytimg.com/vi/{video_id}/sddefault.jpg`       (640×480)
///   `https://i.ytimg.com/vi/{video_id}/maxresdefault.jpg`   (1280×720)
///
/// For the full-screen player (290pt × 3x = 870px), `maxresdefault.jpg`
/// provides enough resolution to look sharp. However, `maxresdefault.jpg`
/// returns 404 for some older videos (pre-2014), so we always include
/// `hqdefault.jpg` as a guaranteed fallback (480×360, ~270px @3x — still
/// much sharper than `default.jpg` at 120×90).
///
/// The iOS app receives these URLs from the backend (`backend/app.py`)
/// which uses `default.jpg` as a fallback. This rewriter upgrades the
/// URL on the client side so every consumer (list rows, mini player,
/// full-screen player) benefits.
enum YouTubeThumbnailRewriter {
    private static let pattern = #"https?://i\.ytimg\.com/vi/([^/]+)/"#

    /// Returns candidate YouTube thumbnail URLs ordered by quality
    /// (highest first), or `[url]` if the URL doesn't match the YouTube
    /// CDN pattern. The caller should try them in order and fall back
    /// on failure.
    static func upgradedURLs(for url: URL) -> [URL] {
        let absolute = url.absoluteString
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return [url]
        }
        let range = NSRange(absolute.startIndex..., in: absolute)
        guard let match = regex.firstMatch(in: absolute, range: range),
              match.numberOfRanges > 1,
              let videoIDRange = Range(match.range(at: 1), in: absolute)
        else {
            return [url]
        }
        let videoID = String(absolute[videoIDRange])
        let maxres = URL(string: "https://i.ytimg.com/vi/\(videoID)/maxresdefault.jpg")
        let hq = URL(string: "https://i.ytimg.com/vi/\(videoID)/hqdefault.jpg")
        var result: [URL] = []
        if let maxres, maxres != url { result.append(maxres) }
        if let hq, hq != url { result.append(hq) }
        if result.isEmpty { return [url] }
        return result
    }
}
