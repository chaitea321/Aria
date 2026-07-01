import Foundation

extension Array {
    /// Reorders elements the same way SwiftUI's `move(fromOffsets:toOffset:)`
    /// does, but without importing SwiftUI — so model/manager types can stay
    /// UI-framework-free. `destination` is the pre-removal index to insert
    /// before (matching SwiftUI's `onMove` semantics).
    mutating func moveElements(fromOffsets source: IndexSet, toOffset destination: Int) {
        let moving = source.sorted().map { self[$0] }
        for index in source.sorted(by: >) { remove(at: index) }
        let removedBefore = source.filter { $0 < destination }.count
        insert(contentsOf: moving, at: destination - removedBefore)
    }
}
