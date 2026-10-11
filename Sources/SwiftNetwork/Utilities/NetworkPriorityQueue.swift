//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if canImport(BasicContainers)
import BasicContainers
internal import DequeModule
#endif

protocol NetworkComparable: ~Copyable {
    static func < (lhs: borrowing Self, rhs: borrowing Self) -> Bool

    static func == (lhs: borrowing Self, rhs: borrowing Self) -> Bool
}

@available(Network 0.1.0, *)
struct NetworkPriorityQueue<Element: NetworkComparable & ~Copyable>: ~Copyable {
    internal var _heap: NetworkHeap<Element>

    init(_ heap: consuming NetworkHeap<Element>) {
        self._heap = heap
    }

    init() {
        self._heap = NetworkHeap()
    }

    mutating func remove(_ key: borrowing Element) {
        self._heap.remove(value: key)
    }

    @discardableResult
    mutating func removeFirst(where shouldBeRemoved: (borrowing Element) throws -> Bool) rethrows -> Element? {
        try self._heap.removeFirst(where: shouldBeRemoved)
    }

    mutating func push(_ key: consuming Element) {
        self._heap.append(key)
    }

    @inlinable
    var first: Element {
        _modify {
            yield &_heap.storage[0]
        }
        _read {
            yield _heap.storage[0]
        }
    }

    func peek<ReturnValue, ErrorType: Error>(
        _ body: (borrowing Element) throws(ErrorType) -> ReturnValue
    ) throws(ErrorType) -> ReturnValue? {
        if self.isEmpty {
            return nil
        } else {
            return try body(self._heap.storage[0])
        }
    }

    var isEmpty: Bool {
        self._heap.storage.isEmpty
    }

    @discardableResult
    mutating func pop() -> Element? {
        self._heap.removeRoot()
    }

    mutating func clear() {
        self._heap = NetworkHeap()
    }
}

@available(Network 0.1.0, *)
extension NetworkPriorityQueue where Element: ~Copyable {
    var count: Int {
        self._heap.count
    }
}

@available(Network 0.1.0, *)
extension NetworkPriorityQueue where Element: Copyable {

    func peek() -> Element? {
        self.peek { $0 }
    }

    func copy() -> Self {
        Self(_heap.copy())
    }
}

@available(Network 0.1.0, *)
extension NetworkPriorityQueue: Sendable where Element: Sendable {}
