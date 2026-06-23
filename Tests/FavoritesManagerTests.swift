import XCTest
@testable import Aria___Music_Browser

final class FavoritesManagerTests: XCTestCase {
    private var manager: FavoritesManager!
    private var store: InMemoryKeyValueStore!

    override func setUp() {
        super.setUp()
        store = InMemoryKeyValueStore()
        manager = FavoritesManager(store: store)
    }

    override func tearDown() {
        manager = nil
        store = nil
        super.tearDown()
    }

    func testAddMakesFavorite() {
        let track = makeTrack(id: "1", title: "Alpha")
        manager.add(track)
        XCTAssertTrue(manager.isFavorite(track))
        XCTAssertEqual(manager.tracks.count, 1)
    }

    func testAddDuplicateIsNoOp() {
        let track = makeTrack(id: "1", title: "Alpha")
        manager.add(track)
        manager.add(track)
        XCTAssertEqual(manager.tracks.count, 1)
    }

    func testToggleAddsAndRemoves() {
        let track = makeTrack(id: "1", title: "Alpha")
        manager.toggle(track)
        XCTAssertTrue(manager.isFavorite(track))
        manager.toggle(track)
        XCTAssertFalse(manager.isFavorite(track))
    }

    func testRemoveByTrack() {
        let track = makeTrack(id: "1", title: "Alpha")
        manager.add(track)
        manager.remove(track)
        XCTAssertFalse(manager.isFavorite(track))
    }

    func testGroupedByLetterSortsAndBuckets() {
        manager.add(makeTrack(id: "1", title: "Banana"))
        manager.add(makeTrack(id: "2", title: "Apple"))
        manager.add(makeTrack(id: "3", title: "Apricot"))
        manager.add(makeTrack(id: "4", title: "Blueberry"))

        let grouped = manager.grouped
        XCTAssertEqual(grouped.count, 2)
        XCTAssertEqual(grouped[0].letter, "A")
        XCTAssertEqual(grouped[0].tracks.map(\.title), ["Apple", "Apricot"])
        XCTAssertEqual(grouped[1].letter, "B")
        XCTAssertEqual(grouped[1].tracks.map(\.title), ["Banana", "Blueberry"])
    }

    func testGroupedRecomputedOnMutation() {
        manager.add(makeTrack(id: "1", title: "A"))
        XCTAssertEqual(manager.grouped.count, 1)
        manager.add(makeTrack(id: "2", title: "B"))
        XCTAssertEqual(manager.grouped.count, 2)
    }

    func testRemoveAllClears() {
        manager.add(makeTrack(id: "1", title: "A"))
        manager.add(makeTrack(id: "2", title: "B"))
        manager.removeAll()
        XCTAssertTrue(manager.tracks.isEmpty)
    }

    func testPersistsAcrossInstances() {
        let track = makeTrack(id: "p1", title: "Persisted")
        manager.add(track)
        manager.flushPendingWrites()

        // A new manager pointed at the same store should see the saved track.
        let restored = FavoritesManager(store: store)
        XCTAssertEqual(restored.tracks.count, 1)
        XCTAssertEqual(restored.tracks.first?.id, "p1")
    }

    // MARK: - Helpers

    private func makeTrack(id: String, title: String) -> Track {
        Track(id: id, title: title, artist: "Test", thumbnailURL: nil)
    }
}
