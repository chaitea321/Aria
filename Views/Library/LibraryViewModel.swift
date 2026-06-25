import Foundation
import Combine

enum LibrarySortOrder: String, CaseIterable, Identifiable {
    case recentlyAdded
    case title
    case artist
    case duration
    case fileSize

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .recentlyAdded: return "Recently Added"
        case .title: return "Title"
        case .artist: return "Artist"
        case .duration: return "Duration"
        case .fileSize: return "File Size"
        }
    }
}

enum LibraryGroupBy: String, CaseIterable, Identifiable {
    case none
    case album
    case artist

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .album: return "Album"
        case .artist: return "Artist"
        }
    }
}

struct LibrarySection: Identifiable, Hashable {
    let id: String
    let title: String
    let tracks: [LocalTrack]
}

@MainActor
final class LibraryViewModel: ObservableObject {

    @Published var searchText: String = ""
    @Published var sortOrder: LibrarySortOrder
    @Published var groupBy: LibraryGroupBy

    @Published private(set) var tracks: [LocalTrack] = []

    private let library: LocalLibraryManager

    init(
        library: LocalLibraryManager,
        initialSortOrder: LibrarySortOrder = .recentlyAdded,
        initialGroupBy: LibraryGroupBy = .none
    ) {
        self.library = library
        self.sortOrder = initialSortOrder
        self.groupBy = initialGroupBy
        library.$tracks.assign(to: &$tracks)
    }

    var filteredAndSortedTracks: [LocalTrack] { tracks }

    var sections: [LibrarySection] { [] }
}
