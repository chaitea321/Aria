import CoreGraphics
import Foundation

enum QueueDragEngine {
    static func update(
        currentOrder: [String],
        rowFrames: [CGRect],
        pointerY: CGFloat
    ) -> (rowID: String, newIndex: Int)? {
        guard !rowFrames.isEmpty, !currentOrder.isEmpty else { return nil }
        guard pointerY >= 0 else { return nil }
        for (i, frame) in rowFrames.enumerated() {
            let midpoint = frame.midY
            if pointerY <= midpoint {
                guard i < currentOrder.count else { return nil }
                return (currentOrder[i], i)
            }
        }
        let lastIndex = currentOrder.count - 1
        guard lastIndex >= 0 else { return nil }
        return (currentOrder[lastIndex], lastIndex)
    }
}
