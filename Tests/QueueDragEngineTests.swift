import XCTest
@testable import Aria___Music_Browser

final class QueueDragEngineTests: XCTestCase {

    func test_update_pointerInFirstRowMidpoint_returnsFirstIndex() {
        let frames = makeFrames(count: 4, rowHeight: 50, originY: 0)
        let result = QueueDragEngine.update(
            currentOrder: ["a", "b", "c", "d"],
            rowFrames: frames,
            pointerY: 25
        )
        XCTAssertEqual(result?.rowID, "a")
        XCTAssertEqual(result?.newIndex, 0)
    }

    func test_update_pointerBelowFirstRowMidpoint_returnsSecondIndex() {
        let frames = makeFrames(count: 4, rowHeight: 50, originY: 0)
        let result = QueueDragEngine.update(
            currentOrder: ["a", "b", "c", "d"],
            rowFrames: frames,
            pointerY: 75
        )
        XCTAssertEqual(result?.newIndex, 1)
    }

    func test_update_pointerAtBottom_returnsLastIndex() {
        let frames = makeFrames(count: 4, rowHeight: 50, originY: 0)
        let result = QueueDragEngine.update(
            currentOrder: ["a", "b", "c", "d"],
            rowFrames: frames,
            pointerY: 1000
        )
        XCTAssertEqual(result?.newIndex, 3)
    }

    func test_update_pointerInGap_returnsNil() {
        let frames = makeFrames(count: 4, rowHeight: 50, originY: 0)
        // No gap in the test frames; this case shouldn't arise in production.
        let result = QueueDragEngine.update(
            currentOrder: ["a", "b", "c", "d"],
            rowFrames: frames,
            pointerY: -100
        )
        XCTAssertNil(result)
    }

    private func makeFrames(count: Int, rowHeight: CGFloat, originY: CGFloat) -> [CGRect] {
        (0..<count).map { i in
            CGRect(x: 0, y: originY + CGFloat(i) * rowHeight, width: 320, height: rowHeight)
        }
    }
}
