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

public class BroadcastStream<T> {
	
	private var handlers: [AnyHashable: (T) -> Void] = [:]
	private let queue: DispatchQueue?
	private var _history: StreamHistory<T>
	
	public init(queue: DispatchQueue? = nil, historySize: UInt32 = 0) {
		self.queue = queue
		self._history = .init(maxSize: historySize, values: [])
	}
	
	public func emitValue(_ newValue: T) {
		queue.asyncIfNotNil { [weak self] in
			guard let self = self else { return }
			self.handlers.forEach { $0.value(newValue) }
			if !self.handlers.isEmpty {
				self._history.addValue(newValue)
			}
		}
	}
	
	public func addListener(identifiedBy id: AnyHashable, _ handler: @escaping (T) -> Void) {
		queue.asyncIfNotNil { [weak self] in
			self?.handlers[id] = handler
		}
	}
	
	public func history(_ completionHandler: @escaping ([T]) -> Void) {
		queue.asyncIfNotNil { [weak self] in
			guard let self = self else { return }
			completionHandler(self._history.values)
		}
	}
	
	public func removeListener(withId id: AnyHashable) {
		queue.asyncIfNotNil { [weak self] in
			self?.handlers.removeValue(forKey: id)
		}
	}
	
	public func removeAllListeners() {
		queue.asyncIfNotNil { [weak self] in
			self?.handlers.removeAll()
		}
	}
	
	deinit {
		self.handlers.removeAll()
	}
}
