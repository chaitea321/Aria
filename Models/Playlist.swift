import Foundation

struct Playlist: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var tracks: [Track]
    var createdAt: Date = Date()
    var lastPlayedAt: Date?

    var previewThumbnailURL: URL? {
        tracks.last?.thumbnailURL
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id
    }
}
