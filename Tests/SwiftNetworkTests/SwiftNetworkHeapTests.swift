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

import XCTest

#if canImport(SwiftNetwork)
@testable import SwiftNetwork
#endif

@available(Network 0.1.0, *)
extension Int: NetworkComparable {}

@available(Network 0.1.0, *)
extension UInt8: NetworkComparable {}

@available(Network 0.1.0, *)
final class SwiftNetworkHeapTests: XCTestCase {

    func testSimple() throws {
        var h = NetworkHeap<Int>()
        h.append(3)
        h.append(1)
        h.append(2)

        XCTAssertTrue(1 == h.removeRoot())
        let prop = h.checkHeapProperty()
        XCTAssertTrue(prop)
    }

    func testSortedDesc() throws {
        var minHeap = NetworkHeap<Int>()

        let inputs = [16, 14, 10, 9, 8, 7, 4, 3, 2, 1]
        for input in inputs {
            minHeap.append(input)
            let prop = minHeap.checkHeapProperty()
            XCTAssertTrue(prop)
        }
        var minHeapInputPtr = inputs.count - 1
        while let minE = minHeap.removeRoot() {
            XCTAssertTrue(minE == inputs[minHeapInputPtr])
            minHeapInputPtr -= 1
            let prop = minHeap.checkHeapProperty()
            XCTAssertTrue(prop)
        }
        XCTAssertTrue(-1 == minHeapInputPtr)
    }

    func testSortedAsc() throws {
        var minHeap = NetworkHeap<Int>()

        let inputs = Array([16, 14, 10, 9, 8, 7, 4, 3, 2, 1].reversed())
        for input in inputs {
            minHeap.append(input)
        }
        var minHeapInputPtr = 0
        while let minE = minHeap.removeRoot() {
            XCTAssertTrue(minE == inputs[minHeapInputPtr])
            minHeapInputPtr += 1
        }
        XCTAssertTrue(inputs.count == minHeapInputPtr)
    }

    func testAddAndRemoveRandomNumbers() throws {
        var minHeap = NetworkHeap<UInt8>()
        var minHeapLast = UInt8.min

        let N = 10

        for n in SwiftNetworkHeapTests.getRandomNumbers(count: N) {
            minHeap.append(n)
            let prop = minHeap.checkHeapProperty()
            XCTAssertTrue(prop)

            XCTAssertTrue(Array(minHeap.sorted()) == Array(minHeap))
        }

        for _ in 0..<N / 2 {
            let value = minHeap.removeRoot()!
            XCTAssertTrue(value >= minHeapLast)
            minHeapLast = value

            let prop = minHeap.checkHeapProperty()
            XCTAssertTrue(prop)

            XCTAssertTrue(Array(minHeap.sorted()) == Array(minHeap))
        }

        minHeapLast = UInt8.min

        for n in SwiftNetworkHeapTests.getRandomNumbers(count: N) {
            minHeap.append(n)
            let prop = minHeap.checkHeapProperty()
            XCTAssertTrue(prop)
        }

        for _ in 0..<N / 2 + N {
            let value = minHeap.removeRoot()!
            XCTAssertTrue(value >= minHeapLast)
            minHeapLast = value

            let prop = minHeap.checkHeapProperty()
            XCTAssertTrue(prop)
        }

        XCTAssertTrue(0 == minHeap.underestimatedCount)
    }

    func testRemoveElement() throws {
        var h = NetworkHeap<Int>()
        for f in [84, 22, 19, 21, 3, 10, 6, 5, 20] {
            h.append(f)
        }
        _ = h.remove(value: 10)
        let prop = h.checkHeapProperty()
        XCTAssertTrue(prop)
    }

    func testFailingExample() throws {
        var h = NetworkHeap<Int>()
        for f in [169, 236, 25] {
            h.append(f)
        }

        h.remove(value: 236)
        var arr = Array(h)
        XCTAssertTrue(arr == [25, 169])

        h.append(236)
        arr = Array(h)
        XCTAssertTrue(arr == [25, 169, 236])
    }

    public static func getRandomNumbers(count: Int) -> [UInt8] {
        (0..<count).map { _ in
            UInt8.random(in: .min ... .max)
        }
    }

}

@available(Network 0.1.0, *)
extension NetworkHeap {
    internal func checkHeapProperty() -> Bool {
        func checkHeapProperty(index: Int) -> Bool {
            let li = self.leftIndex(index)
            let ri = self.rightIndex(index)
            if index >= self.storage.count {
                return true
            } else {
                let me = self.storage[index]
                var lCond = true
                var rCond = true
                if li < self.storage.count {
                    let l = self.storage[li]
                    lCond = !self.comparator(l, me)
                }
                if ri < self.storage.count {
                    let r = self.storage[ri]
                    rCond = !self.comparator(r, me)
                }
                return lCond && rCond && checkHeapProperty(index: li) && checkHeapProperty(index: ri)
            }
        }
        return checkHeapProperty(index: 0)
    }
}

@available(Network 0.1.0, *)
extension Array where Element: NetworkComparable & Copyable {
    init(_ heap: borrowing NetworkHeap<Element>) {
        self = []
        var heap = heap.copy()

        while let element = heap.removeRoot() {
            self.append(element)
        }
    }
}

@available(Network 0.1.0, *)
extension NetworkHeap {
    func sorted() -> [Element] {
        Array(self).sorted(by: { $0 < $1 })
    }
}
