import XCTest
@testable import Streams

final class StreamsTests: XCTestCase {
	
	func testStream() {
		streamT(withQueue: nil)
	}
	
	func testStreamWithCustomQueue() {
		let queue = DispatchQueue(label: "customQueue1")
		streamT(withQueue: queue)
	}
	
	private func streamT(withQueue queue: DispatchQueue?) {
		
		let streamsExpectation = expectation(description: "streams1-\(queue?.label ?? "noQueue")")
		streamsExpectation.assertForOverFulfill = true
		streamsExpectation.expectedFulfillmentCount = 4
		
		let stream = Streams.Stream<Int>(queue: queue, historySize: 3)
		var expectedValues = [11, 13, 16, 17].makeIterator()
		stream.listen { newValue in
			XCTAssertEqual(expectedValues.next(), newValue)
			streamsExpectation.fulfill()
		}
		stream.emitValue(11)
		stream.emitValue(13)
		
		stream.history { values in
			XCTAssertEqual(values[0], 11)
			XCTAssertEqual(values[1], 13)
		}
		
		DispatchQueue.global().async {
			stream.emitValue(16)
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
			stream.emitValue(17)
			stream.removeListener()
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
			stream.emitValue(99) // wont't be received, since there is no listener listen to this event
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
			stream.history { values in
				XCTAssertEqual(values[0], 13)
				XCTAssertEqual(values[1], 16)
				XCTAssertEqual(values[2], 17)
			}
		}
		
		wait(for: [streamsExpectation], timeout: 4)
	}
	
	//
	
	func testBroadcastStream() {
		broadcastStreamT(withQueue: nil)
	}
	
	func testBroadcastStreamWithCustomQueue() {
		let queue = DispatchQueue(label: "customQueue2")
		broadcastStreamT(withQueue: queue)
	}
	
	private func broadcastStreamT(withQueue queue: DispatchQueue?) {
		
		let streamsExpectation = expectation(description: "streams2-\(queue?.label ?? "noQueue")")
		streamsExpectation.assertForOverFulfill = true
		streamsExpectation.expectedFulfillmentCount = 4
		
		let streamsExpectation2 = expectation(description: "streams2_2\(queue?.label ?? "noQueue")")
		streamsExpectation2.assertForOverFulfill = true
		streamsExpectation2.expectedFulfillmentCount = 4
		
		let stream = BroadcastStream<String>(queue: queue, historySize: 4)
		var expectedValues1 = ["Daniel", "Pepe", "John", "Stark"].makeIterator()
		stream.addListener(identifiedBy: 0) { newValue in
			XCTAssertEqual(expectedValues1.next(), newValue)
			streamsExpectation.fulfill()
		}
		stream.emitValue("Daniel")
		
		var expectedValues2 = ["Pepe", "John", "Stark", "last"].makeIterator()
		stream.addListener(identifiedBy: 1) { newValue in
			XCTAssertEqual(expectedValues2.next(), newValue)
			streamsExpectation2.fulfill()
		}
		
		stream.emitValue("Pepe")
		
		stream.history { values in
			XCTAssertEqual(["Daniel", "Pepe"], values)
		}
		
		DispatchQueue.global().async {
			stream.emitValue("John")
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
			stream.emitValue("Stark")
			stream.removeListener(withId: 0)
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
			stream.emitValue("last") // wont't be received on listener 0
			stream.removeAllListeners()
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
			stream.emitValue("last-") // wont't be received on any listener
			
			stream.history { values in
				XCTAssertEqual(["Pepe", "John", "Stark", "last"], values)
			}
		}
		
		wait(for: [streamsExpectation, streamsExpectation2], timeout: 4)
	}
	
	static var allTests = [
		("testSingleStream", testStream),
		("testSingleStreamWithCustomQueue", testStreamWithCustomQueue),
		("testBroadcastStream", testBroadcastStream),
		("testBroadcastStreamWithCustomQueue", testBroadcastStreamWithCustomQueue)
	]
}
