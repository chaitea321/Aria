import XCTest
@testable import Aria___Music_Browser

@MainActor
final class FloatClampTests: XCTestCase {
    func test_ClampBelowLowerBound() {
        XCTAssertEqual(Float(-100).clamped(to: -12...12), -12)
        XCTAssertEqual(Float(-12.5).clamped(to: -12...12), -12)
    }

    func test_ClampAboveUpperBound() {
        XCTAssertEqual(Float(100).clamped(to: -12...12), 12)
        XCTAssertEqual(Float(12.5).clamped(to: -12...12), 12)
    }

    func test_ClampWithinRange() {
        XCTAssertEqual(Float(0).clamped(to: -12...12), 0)
        XCTAssertEqual(Float(5.5).clamped(to: -12...12), 5.5)
        XCTAssertEqual(Float(-5.5).clamped(to: -12...12), -5.5)
    }

    func test_ClampAtBoundaries() {
        XCTAssertEqual(Float(-12).clamped(to: -12...12), -12)
        XCTAssertEqual(Float(12).clamped(to: -12...12), 12)
    }
}
