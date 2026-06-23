import Foundation

/// Debounces a side-effect to fire at most once per `delay` seconds after the
/// last call to `call()`. If a new call arrives before the delay elapses, the
/// pending work item is cancelled and replaced.
///
/// This is intended to coalesce bursts of mutations (e.g., adding 20 tracks to
/// a playlist in a loop) into a single disk write.
final class Debouncer {
    private let delay: TimeInterval
    private let queue: DispatchQueue
    private let action: () -> Void

    private var workItem: DispatchWorkItem?

    init(delay: TimeInterval, queue: DispatchQueue = .main, action: @escaping () -> Void) {
        self.delay = delay
        self.queue = queue
        self.action = action
    }

    func call() {
        workItem?.cancel()
        let item = DispatchWorkItem(block: action)
        workItem = item
        queue.asyncAfter(deadline: .now() + delay, execute: item)
    }

    /// Cancels any pending invocation without firing.
    func cancel() {
        workItem?.cancel()
        workItem = nil
    }

    /// Runs the pending action immediately, if any, then clears it.
    func flush() {
        guard let item = workItem, !item.isCancelled else {
            workItem = nil
            return
        }
        item.cancel()
        workItem = nil
        action()
    }
}
