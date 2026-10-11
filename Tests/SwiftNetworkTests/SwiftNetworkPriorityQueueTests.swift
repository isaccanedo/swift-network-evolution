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
extension String: NetworkComparable {}

@available(Network 0.1.0, *)
final class SwiftNetworkPriorityQueueTests: XCTestCase {

    func testSomeStringsAsc() throws {
        var pq = NetworkPriorityQueue<String>()
        pq.push("foo")
        pq.push("bar")
        pq.push("buz")
        pq.push("qux")

        pq.remove("buz")

        XCTAssertTrue("bar" == pq.peek()!)
        XCTAssertTrue("bar" == pq.pop()!)

        pq.push("bar")

        XCTAssertTrue("bar" == pq.peek()!)
        XCTAssertTrue("bar" == pq.pop()!)

        XCTAssertTrue("foo" == pq.pop()!)
        XCTAssertTrue("qux" == pq.pop()!)

        let isEmpty = pq.isEmpty
        XCTAssertTrue(isEmpty)
    }

    func testRemoveNonExisting() throws {
        var pq = NetworkPriorityQueue<String>()
        pq.push("foo")
        pq.remove("bar")
        pq.remove("foo")
        XCTAssertTrue(pq.pop() == nil)
        XCTAssertTrue(pq.peek() == nil)
    }

    func testRemoveFromEmpty() throws {
        var pq = NetworkPriorityQueue<Int>()
        pq.remove(234)

        let isEmpty = pq.isEmpty
        XCTAssertTrue(isEmpty)
    }

    func testBuildAndRemoveFromRandomPriorityQueues() {
        for size in 0...33 {
            var pq = NetworkPriorityQueue<UInt8>()
            let randoms = SwiftNetworkHeapTests.getRandomNumbers(count: size)
            for number in randoms {
                pq.push(number)
            }

            // remove one random member, add it back and assert we're still the same
            for random in randoms {
                var pq2 = pq.copy()
                pq2.remove(random)
                XCTAssertTrue(pq.count - 1 == pq2.count)

                let areNotEqual = pq != pq2
                XCTAssertTrue(areNotEqual)
                pq2.push(random)

                let areEqual = pq == pq2
                XCTAssertTrue(areEqual)
            }

            // remove up to `n` members and add them back at the end and check that the priority queues are still the same
            for n in 1...5 where n <= size {
                var pq2 = pq.copy()
                let deleted = randoms.prefix(n).map { (random: UInt8) -> UInt8 in
                    pq2.remove(random)
                    return random
                }
                XCTAssertTrue(pq.count - n == pq2.count)

                let areNotEqual = pq != pq2
                XCTAssertTrue(areNotEqual)
                for number in deleted.reversed() {
                    pq2.push(number)
                }

                let areEqual = pq == pq2
                XCTAssertTrue(areEqual)
            }
        }
    }

    func testPartialOrder() {
        let clearlyTheSmallest = SomePartiallyOrderedDataType(width: 0, height: 0)
        let clearlyTheLargest = SomePartiallyOrderedDataType(width: 100, height: 100)
        let inTheMiddles = zip(1...99, (1...99).reversed()).map { SomePartiallyOrderedDataType(width: $0, height: $1) }

        // the four values are only partially ordered (from small (top) to large (bottom)):

        //                   clearlyTheSmallest
        //                  /         |        \
        //           inTheMiddle[0]   |    inTheMiddle[1...]
        //                  \         |        /
        //                    clearlyTheLargest

        var pq = NetworkPriorityQueue<SomePartiallyOrderedDataType>()
        pq.push(clearlyTheLargest)
        pq.push(inTheMiddles[0])
        pq.push(clearlyTheSmallest)
        for number in inTheMiddles[1...] {
            pq.push(number)
        }
        let pop1 = pq.pop()
        XCTAssertTrue(clearlyTheSmallest == pop1)
        for _ in inTheMiddles {
            let popN = pq.pop()!
            let containsPopN = inTheMiddles.contains(popN)
            XCTAssertTrue(containsPopN)
        }
        XCTAssertTrue(clearlyTheLargest == pq.pop()!)

        let isEmpty = pq.isEmpty
        XCTAssertTrue(isEmpty)
    }
}

/// This data type is only partially ordered. Ie. from `a < b` and `a != b` we can't imply `a > b`.
@available(Network 0.1.0, *)
struct SomePartiallyOrderedDataType: NetworkComparable, Equatable, CustomStringConvertible {
    public static func < (lhs: SomePartiallyOrderedDataType, rhs: SomePartiallyOrderedDataType) -> Bool {
        lhs.width < rhs.width && lhs.height < rhs.height
    }

    public static func == (lhs: SomePartiallyOrderedDataType, rhs: SomePartiallyOrderedDataType) -> Bool {
        lhs.width == rhs.width && lhs.height == rhs.height
    }

    private let width: Int
    private let height: Int
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    public var description: String {
        "(w: \(self.width), h: \(self.height))"
    }
}

@available(Network 0.1.0, *)
extension NetworkPriorityQueue where Element: Equatable {
    public static func == (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
        let arr = Array(lhs._heap)
        let arr2 = Array(rhs._heap)
        return arr == arr2
    }

    public static func != (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
        !(lhs == rhs)
    }
}
