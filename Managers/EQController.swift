import Foundation
import Combine

final class EQController: ObservableObject {
    static let bandCount = 10
    static let gainRange: ClosedRange<Float> = -12...12

    @Published private(set) var bands: [Float]
    @Published private(set) var isEnabled: Bool = false

    init() {
        self.bands = Array(repeating: 0, count: EQController.bandCount)
    }

    @discardableResult
    func apply(_ gains: [Float]) -> EQApplyOutcome {
        guard gains.count == EQController.bandCount else { return .noChange }
        let wasEnabled = isEnabled
        let clamped = gains.map { $0.clamped(to: EQController.gainRange) }
        let nowEnabled = clamped.contains(where: { $0 != 0 })

        if bands == clamped {
            return .noChange
        }

        bands = clamped
        isEnabled = nowEnabled

        if !wasEnabled && nowEnabled { return .becameEnabled }
        if wasEnabled && !nowEnabled { return .becameDisabled }
        return .stillEnabled
    }

    @discardableResult
    func reset() -> Bool {
        let wasEnabled = isEnabled
        bands = Array(repeating: 0, count: EQController.bandCount)
        isEnabled = false
        return wasEnabled
    }

    @discardableResult
    func setBand(_ index: Int, gain: Float) -> EQApplyOutcome {
        guard index >= 0, index < EQController.bandCount else { return .noChange }
        var newBands = bands
        newBands[index] = gain.clamped(to: EQController.gainRange)
        return apply(newBands)
    }
}

enum EQApplyOutcome: Equatable {
    case noChange
    case becameEnabled
    case stillEnabled
    case becameDisabled
}

extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        max(range.lowerBound, min(range.upperBound, self))
    }
}
