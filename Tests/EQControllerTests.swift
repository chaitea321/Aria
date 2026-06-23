import XCTest
@testable import Aria___Music_Browser

@MainActor
final class EQControllerTests: XCTestCase {
    func test_InitialStateIsDisabled() {
        let eq = EQController()
        XCTAssertFalse(eq.isEnabled)
        XCTAssertEqual(eq.bands, [Float](repeating: 0, count: EQController.bandCount))
    }

    func test_AllZerosApplyReportsNoChange() {
        let eq = EQController()
        let outcome = eq.apply([Float](repeating: 0, count: 10))
        XCTAssertEqual(outcome, .noChange)
        XCTAssertFalse(eq.isEnabled)
    }

    func test_AnyNonZeroEnablesEQ() {
        let eq = EQController()
        let outcome = eq.apply([0, 0, 0, 0, 0, 1, 0, 0, 0, 0])
        XCTAssertEqual(outcome, .becameEnabled)
        XCTAssertTrue(eq.isEnabled)
    }

    func test_ClampingAtRange() {
        let eq = EQController()
        eq.apply([Float](repeating: 100, count: 10))
        XCTAssertEqual(eq.bands.first, 12)
        eq.apply([Float](repeating: -100, count: 10))
        XCTAssertEqual(eq.bands.first, -12)
    }

    func test_ResetZerosBandsAndDisables() {
        let eq = EQController()
        eq.apply([0, 0, 0, 0, 0, 5, 0, 0, 0, 0])
        XCTAssertTrue(eq.isEnabled)
        let wasEnabled = eq.reset()
        XCTAssertTrue(wasEnabled)
        XCTAssertFalse(eq.isEnabled)
        XCTAssertEqual(eq.bands, [Float](repeating: 0, count: 10))
    }

    func test_ResetOnAlreadyDisabledReturnsFalse() {
        let eq = EQController()
        let wasEnabled = eq.reset()
        XCTAssertFalse(wasEnabled)
    }

    func test_ApplyReportsNoChangeWhenUnchanged() {
        let eq = EQController()
        eq.apply([0, 0, 0, 0, 0, 5, 0, 0, 0, 0])
        let outcome = eq.apply([0, 0, 0, 0, 0, 5, 0, 0, 0, 0])
        XCTAssertEqual(outcome, .noChange)
    }

    func test_ApplyReportsStillEnabledWhenChangedButStillOn() {
        let eq = EQController()
        eq.apply([0, 0, 0, 0, 0, 5, 0, 0, 0, 0])
        let outcome = eq.apply([0, 0, 0, 0, 0, 6, 0, 0, 0, 0])
        XCTAssertEqual(outcome, .stillEnabled)
        XCTAssertTrue(eq.isEnabled)
    }

    func test_ApplyReportsBecameDisabledWhenAllZeroAfterEnabled() {
        let eq = EQController()
        eq.apply([0, 0, 0, 0, 0, 5, 0, 0, 0, 0])
        let outcome = eq.apply([Float](repeating: 0, count: 10))
        XCTAssertEqual(outcome, .becameDisabled)
        XCTAssertFalse(eq.isEnabled)
    }

    func test_WrongCountIsNoChange() {
        let eq = EQController()
        let outcome = eq.apply([1, 2, 3])
        XCTAssertEqual(outcome, .noChange)
        XCTAssertFalse(eq.isEnabled)
    }

    func test_SetBandByIndex() {
        let eq = EQController()
        let outcome = eq.setBand(4, gain: 7)
        XCTAssertEqual(outcome, .becameEnabled)
        XCTAssertEqual(eq.bands[4], 7)
    }

    func test_SetBandClamps() {
        let eq = EQController()
        eq.setBand(0, gain: 999)
        XCTAssertEqual(eq.bands[0], 12)
        eq.setBand(0, gain: -999)
        XCTAssertEqual(eq.bands[0], -12)
    }

    func test_SetBandOutOfRangeIsNoChange() {
        let eq = EQController()
        let outcome = eq.setBand(20, gain: 5)
        XCTAssertEqual(outcome, .noChange)
    }

    func test_PublisherEmitsChanges() {
        let eq = EQController()
        let exp = expectation(description: "bands published")
        var received: [[Float]] = []
        let cancellable = eq.$bands.sink { bands in
            received.append(bands)
            if received.count == 2 { exp.fulfill() }
        }
        eq.apply([0, 0, 0, 0, 0, 3, 0, 0, 0, 0])
        wait(for: [exp], timeout: 1.0)
        cancellable.cancel()
        XCTAssertEqual(received.count, 2)
    }
}
