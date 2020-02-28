/*
The MIT License (MIT)

Copyright (c) 2020 Daniel Illescas Romero

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import class Dispatch.DispatchQueue

public struct StreamHistory<T> {
	
	let maxSize: UInt32
	var values: [T]
	
	mutating func addValue(_ value: T) {
		guard maxSize > 0 else { return }
		if values.count == maxSize {
			values.removeFirst()
		}
		values.append(value)
	}
}

public class Stream<T> {
	
	private var handler: ((T) -> Void)?
	private let queue: DispatchQueue?
	private var _history: StreamHistory<T>
	
	public init(queue: DispatchQueue? = nil, historySize: UInt32 = 0) {
		self.queue = queue
		self._history = .init(maxSize: historySize, values: [])
	}
	
	public func emitValue(_ newValue: T) {
		queue.asyncIfNotNil { [weak self] in
			guard let self = self else { return }
			self.handler?(newValue)
			if self.handler != nil {
				self._history.addValue(newValue)
			}
		}
	}
	
	public func listen(_ handler: @escaping (T) -> Void) {
		queue.asyncIfNotNil { [weak self] in
			self?.handler = handler
		}
	}
	
	public func removeListener() {
		queue.asyncIfNotNil { [weak self] in
			self?.handler = nil
		}
	}
	
	public func history(_ completionHandler: @escaping ([T]) -> Void) {
		queue.asyncIfNotNil { [weak self] in
			guard let self = self else { return }
			completionHandler(self._history.values)
		}
	}
	
	deinit {
		self.handler = nil
	}
}
