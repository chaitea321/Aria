import XCTest
@testable import Aria___Music_Browser

final class FavoritesManagerTests: XCTestCase {
    private var manager: FavoritesManager!
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FavoritesManagerTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        manager = FavoritesManager()
    }

    override func tearDown() {
        manager = nil
        try? FileManager.default.removeItem(at: tempDir)
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

    // MARK: - Helpers

    private func makeTrack(id: String, title: String) -> Track {
        Track(id: id, title: title, artist: "Test", thumbnailURL: nil)
    }
}
