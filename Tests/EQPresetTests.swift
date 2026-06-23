import XCTest
@testable import Aria___Music_Browser

@MainActor
final class EQPresetTests: XCTestCase {
    func test_AllPresetsHaveTenBands() {
        for preset in EQPreset.allCases {
            XCTAssertEqual(preset.gains.count, 10, "Preset \(preset.rawValue) has wrong band count")
        }
    }

    func test_AllPresetsAreWithinRange() {
        for preset in EQPreset.allCases {
            for (i, gain) in preset.gains.enumerated() {
                XCTAssertGreaterThanOrEqual(gain, -12, "Preset \(preset.rawValue) band \(i) below range")
                XCTAssertLessThanOrEqual(gain, 12, "Preset \(preset.rawValue) band \(i) above range")
            }
        }
    }

    func test_FlatPresetIsAllZeros() {
        XCTAssertEqual(EQPreset.flat.gains, [Float](repeating: 0, count: 10))
    }

    func test_BassBoostShiftsEnergyToLowFrequencies() {
        let lowEnergy = EQPreset.bassBoost.gains.prefix(3).reduce(0, +)
        let highEnergy = EQPreset.bassBoost.gains.suffix(3).reduce(0, +)
        XCTAssertGreaterThan(lowEnergy, highEnergy, "Bass Boost should emphasize low frequencies")
    }

    func test_TrebleBoostShiftsEnergyToHighFrequencies() {
        let lowEnergy = EQPreset.trebleBoost.gains.prefix(3).reduce(0, +)
        let highEnergy = EQPreset.trebleBoost.gains.suffix(3).reduce(0, +)
        XCTAssertGreaterThan(highEnergy, lowEnergy, "Treble Boost should emphasize high frequencies")
    }

    func test_PresetsAreUnique() {
        let allGains = EQPreset.allCases.map { $0.gains }
        let unique = Set(allGains.map { "\($0)" })
        XCTAssertGreaterThan(unique.count, 1, "Presets should not all be identical")
    }

    func test_AllPresetsHaveIDs() {
        for preset in EQPreset.allCases {
            XCTAssertFalse(preset.id.isEmpty)
        }
    }
}
