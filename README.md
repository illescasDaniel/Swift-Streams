# Streams

[![Swift version](https://img.shields.io/badge/Swift-5-orange.svg)](https://swift.org/download)
[![Version](https://img.shields.io/badge/version-1.0-green.svg)](https://github.com/illescasDaniel/Swift-Streams/releases)
[![license](https://img.shields.io/github/license/mashape/apistatus.svg)](https://github.com/illescasDaniel/Swift-Streams/blob/master/LICENSE)

`Stream<T>` and `BroadcastStream<T>` classes to emit a flow of values and subscribe to them.

- It offers a single subscriber option (`Stream`) or a multiple subscriber one (`BroadcastStream`).
- A history of the emitted values is stored if you wish (just pass a `historySize` value bigger than 0)

## Example

```swift
import Streams

let myQueue = DispatchQueue(label: "streamQueue1")

let stream = Streams.Stream<Int>(queue: myQueue, historySize: 2)

stream.listen { newValue in
    print(newValue) // 72 ... 73 ... 12
}

stream.emitValue(72)
stream.emitValue(73)
stream.emitValue(12)

stream.history { values in
    print(values) // [73, 12]
}
```
```swift
enum State {
    case idle
    case doingSomething
    case finished
}

let stream2 = BroadcastStream<State>(queue: myQueue, historySize: 5) // or other queue

stream2.addListener(identifiedBy: 0) { newValue in
    print(newValue)  // .idle ... .doingSomething ... .finished
}

stream2.emitValue(.idle)

stream2.addListener(identifiedBy: "my other listener") { newValue in
    print(newValue) // .doingSomething ... .finished
}

stream2.emitValue(.doingSomething)

myQueue.asyncAfter(deadline: .now() + .seconds(1)) {
    stream2.emitValue(.finished)
}

DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
    stream2.history { values in
    print(values) // [.idle, .doingSomething, .finished]
    }
}
```
