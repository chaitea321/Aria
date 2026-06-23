import XCTest
@testable import Aria___Music_Browser

final class PlaylistsManagerTests: XCTestCase {
    private var manager: PlaylistsManager!

    override func setUp() {
        super.setUp()
        manager = PlaylistsManager()
    }

    override func tearDown() {
        manager = nil
        super.tearDown()
    }

    func testCreateReturnsPlaylist() {
        let playlist = manager.create(name: "Chill")
        XCTAssertEqual(playlist.name, "Chill")
        XCTAssertTrue(playlist.tracks.isEmpty)
        XCTAssertEqual(manager.playlists.count, 1)
    }

    func testRename() {
        let playlist = manager.create(name: "Old")
        manager.rename(playlist, to: "New")
        XCTAssertEqual(manager.playlists.first?.name, "New")
    }

    func testAddTrackIsIdempotent() {
        let playlist = manager.create(name: "P")
        let track = makeTrack(id: "1", title: "T")
        manager.addTrack(track, to: playlist)
        manager.addTrack(track, to: playlist)
        XCTAssertEqual(manager.playlists.first?.tracks.count, 1)
    }

    func testRemoveTrack() {
        let playlist = manager.create(name: "P")
        let track = makeTrack(id: "1", title: "T")
        manager.addTrack(track, to: playlist)
        manager.removeTrack(track, from: playlist)
        XCTAssertEqual(manager.playlists.first?.tracks.count, 0)
    }

    func testMarkPlayedUpdatesTimestamp() {
        let playlist = manager.create(name: "P")
        XCTAssertNil(playlist.lastPlayedAt)
        manager.markPlayed(playlist)
        XCTAssertNotNil(manager.playlists.first?.lastPlayedAt)
    }

    func testDelete() {
        let playlist = manager.create(name: "P")
        manager.delete(playlist)
        XCTAssertTrue(manager.playlists.isEmpty)
    }

    func testSortedPlaylistsRespectsOrder() {
        manager.deleteAll()
        manager.sortOrder = .alphabetical
        manager.create(name: "Charlie")
        manager.create(name: "Alpha")
        manager.create(name: "Bravo")
        XCTAssertEqual(manager.sortedPlaylists.map(\.name), ["Alpha", "Bravo", "Charlie"])
    }

    func testRecentlyPlayedPlaylistsExcludesUnplayed() {
        manager.deleteAll()
        let a = manager.create(name: "A")
        let _ = manager.create(name: "B")
        manager.markPlayed(a)
        XCTAssertEqual(manager.recentlyPlayedPlaylists.map(\.name), ["A"])
    }

    // MARK: - Helpers

    private func makeTrack(id: String, title: String) -> Track {
        Track(id: id, title: title, artist: "T", thumbnailURL: nil)
    }
}
