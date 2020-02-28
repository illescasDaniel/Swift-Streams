//
//  File.swift
//  
//
//  Created by Daniel Illescas Romero on 28/02/2020.
//

import Foundation
import Streams

let myQueue = DispatchQueue(label: "streamQueue1")

let stream = Streams.Stream<Int>(queue: myQueue, historySize: 2)

stream.listen { newValue in
	print(newValue)
}

stream.emitValue(72)


stream.emitValue(73)
DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
	stream.emitValue(75)
}
stream.removeListener()
stream.emitValue(74)

stream.history { values in
	print(values)
}

//

enum State {
	case idle
	case doingSomething
	case finished
}

let stream2 = BroadcastStream<State>(queue: myQueue, historySize: 5) // or other queue

stream2.addListener(identifiedBy: 0) { newValue in
	print(newValue)
}

stream2.emitValue(.idle)

stream2.addListener(identifiedBy: 1) { newValue in
	print(newValue)
}

stream2.emitValue(.doingSomething)
myQueue.asyncAfter(deadline: .now() + .seconds(1)) {
	stream2.emitValue(.finished)
}

DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
	stream2.history { values in
		print(values)
		exit(EXIT_SUCCESS)
	}
}

RunLoop.main.run()

