import XCTest
@testable import Aria___Music_Browser

final class PlayerManagerQueueReorderTests: XCTestCase {

    private var manager: PlayerManager!

    override func setUp() {
        super.setUp()
        manager = PlayerManager()
    }

    func test_moveQueueItem_movesToPosition() {
        let a = makeTrack(id: "a", title: "A")
        let b = makeTrack(id: "b", title: "B")
        let c = makeTrack(id: "c", title: "C")
        manager.addToQueue(a)
        manager.addToQueue(b)
        manager.addToQueue(c)
        manager.moveQueueItem(from: IndexSet(integer: 0), to: 3)
        XCTAssertEqual(manager.queue.map(\.id), ["b", "c", "a"])
    }

    func test_moveQueueItem_toBeginning() {
        let a = makeTrack(id: "a", title: "A")
        let b = makeTrack(id: "b", title: "B")
        let c = makeTrack(id: "c", title: "C")
        manager.addToQueue(a)
        manager.addToQueue(b)
        manager.addToQueue(c)
        manager.moveQueueItem(from: IndexSet(integer: 2), to: 0)
        XCTAssertEqual(manager.queue.map(\.id), ["c", "a", "b"])
    }

    func test_moveQueueItem_preservesAllTracks() {
        let a = makeTrack(id: "a", title: "A")
        let b = makeTrack(id: "b", title: "B")
        let c = makeTrack(id: "c", title: "C")
        manager.addToQueue(a)
        manager.addToQueue(b)
        manager.addToQueue(c)
        manager.moveQueueItem(from: IndexSet(integer: 1), to: 0)
        let ids = Set(manager.queue.map(\.id))
        XCTAssertEqual(ids, Set(["a", "b", "c"]))
        XCTAssertEqual(manager.queue.count, 3)
    }

    private func makeTrack(id: String, title: String) -> Track {
        Track(id: id, title: title, artist: "Test", thumbnailURL: nil, localFileURL: nil)
    }
}
