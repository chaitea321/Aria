import SwiftUI
import UIKit

/// In-memory LRU cache for downloaded track artwork. Keys are the source
/// `URL`; values are the decoded `UIImage`. The cache is shared across all
/// `AsyncCachedImage` instances and survives view re-creation.
final class ImageMemoryCache {
    static let shared = ImageMemoryCache()

    private let cache = NSCache<NSURL, UIImage>()

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 64 * 1024 * 1024 // 64 MB
    }

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func store(_ image: UIImage, for url: URL) {
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
}

/// SwiftUI image view with a memory cache. Falls back to `placeholder` while
/// loading, then shows the cached or freshly fetched image.
struct AsyncCachedImage<Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var loadTask: Task<Void, Never>?

    init(
        url: URL?,
        @ViewBuilder placeholder: @escaping () -> Placeholder = { Rectangle().fill(Color.gray.opacity(0.2)) }
    ) {
        self.url = url
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable()
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await load()
        }
    }

    private func load() async {
        guard let url else { image = nil; return }
        if let cached = ImageMemoryCache.shared.image(for: url) {
            image = cached
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard !Task.isCancelled, let img = UIImage(data: data) else { return }
            ImageMemoryCache.shared.store(img, for: url)
            image = img
        } catch {
            // Silent: placeholder stays.
        }
    }
}
