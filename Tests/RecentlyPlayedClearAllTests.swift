import XCTest
@testable import Aria___Music_Browser

@MainActor
final class RecentlyPlayedClearAllTests: XCTestCase {

    private func makeTrack(id: String) -> Track {
        Track(id: id, title: "Title \(id)", artist: "Artist", thumbnailURL: nil)
    }

    func test_clearAll_emptiesBothListsAndPersists() {
        let playedStore = InMemoryKeyValueStore()
        let addedStore = InMemoryKeyValueStore()
        let manager = RecentlyPlayedManager(playedStore: playedStore, addedStore: addedStore)
        manager.trackPlayed(makeTrack(id: "a"))
        manager.trackPlayed(makeTrack(id: "b"))
        manager.trackAdded(makeTrack(id: "c"))

        manager.clearAll()

        XCTAssertTrue(manager.recentlyPlayed.isEmpty)
        XCTAssertTrue(manager.recentlyAdded.isEmpty)

        // The empty state must be what a relaunch loads (debounced save → flush).
        manager.flushPendingWrites()
        let reloaded = RecentlyPlayedManager(playedStore: playedStore, addedStore: addedStore)
        XCTAssertTrue(reloaded.recentlyPlayed.isEmpty)
        XCTAssertTrue(reloaded.recentlyAdded.isEmpty)
    }
}
