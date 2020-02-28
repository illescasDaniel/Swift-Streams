import XCTest
@testable import Streams

final class StreamsTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Streams().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
