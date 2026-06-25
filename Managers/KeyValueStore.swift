import Foundation

/// A minimal key-value persistence seam for the user-data stores
/// (FavoritesManager, PlaylistsManager, RecentlyPlayedManager).
///
/// Each store previously hardcoded its own `documentDirectory/<file>.json`
/// path and its own atomic-write + JSON-decode dance. Three near-identical
/// implementations; one place to change behavior. The protocol makes the
/// disk-vs-memory choice an init-time decision so tests can use an
/// `InMemoryKeyValueStore` and production gets the file-backed default.
protocol KeyValueStore: AnyObject {
    /// Returns the persisted bytes, or `nil` if nothing has been stored.
    func load() -> Data?
    /// Writes the bytes atomically. Throws on failure (caller decides how
    /// to surface this — the production stores currently swallow the error
    /// because user data is recoverable from `@Published` state on next
    /// launch).
    func save(_ data: Data) throws
}

/// File-backed implementation. Writes are atomic; reads are best-effort
/// and return `nil` on any I/O or decoding error (matching the prior
/// `try? Data(contentsOf:)` behavior).
final class JSONFileStore: KeyValueStore {
    let url: URL

    init(url: URL) {
        self.url = url
    }

    convenience init(
        filename: String,
        in directory: FileManager.SearchPathDirectory = .documentDirectory
    ) {
        let dir = FileManager.default.urls(for: directory, in: .userDomainMask)[0]
        self.init(url: dir.appendingPathComponent(filename))
    }

    func load() -> Data? {
        try? Data(contentsOf: url)
    }

    func save(_ data: Data) throws {
        try AtomicFileWriter.writeAtomically(data, to: url)
    }
}

/// In-memory implementation for tests. Behaves like a tiny key-value
/// store; never touches the file system, so tests run in any directory
/// and don't need cleanup.
final class InMemoryKeyValueStore: KeyValueStore {
    private var data: Data?
    /// Counts how many times `save(_:)` was called. Useful for asserting
    /// that the debouncer actually coalesced bursts of writes.
    private(set) var saveCount: Int = 0

    init(seed: Data? = nil) {
        self.data = seed
    }

    func load() -> Data? { data }

    func save(_ data: Data) throws {
        self.data = data
        saveCount += 1
    }
}
