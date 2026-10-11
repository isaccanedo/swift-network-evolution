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
import Synchronization

#if canImport(SwiftNetwork)
@_spi(Essentials) @_spi(ProtocolProvider) @testable import SwiftNetwork
#endif

@available(Network 0.1.0, *)
extension Frame {
    fileprivate mutating func dropOwnership() {
        self.buffer = .empty
    }
}

@available(Network 0.1.0, *)
final class SwiftNetworkFrameCustomFinalizerTests: NetTestCase {

    private let bufferSize = 128

    func testCustomFinalizerCreation() {
        let buf = allocateAndFillBuffer(size: bufferSize)
        var frame = Frame(
            buffer: buf,
            finalizer: { $0.baseAddress?.deallocate() }
        )
        XCTAssertEqual(frame.bufferLength, bufferSize)
        XCTAssertEqual(frame.unclaimedLength, bufferSize)
        XCTAssertTrue(frame.isValid)
        frame.finalize(success: true)
    }

    func testCustomFinalizerFinalization() {
        let tracker = Mutex<Bool>(false)
        let buf = allocateAndFillBuffer(size: bufferSize)
        var frame = Frame(
            buffer: buf,
            finalizer: { ptr in
                tracker.withLock { $0 = true }
                ptr.baseAddress?.deallocate()
            }
        )
        XCTAssertFalse(tracker.withLock { $0 })
        frame.finalize(success: true)
        XCTAssertTrue(tracker.withLock { $0 })
    }

    func testCustomFinalizerDisarmedByReplacingWithEmpty() {
        let tracker = Mutex<Bool>(false)
        let buf = allocateAndFillBuffer(size: bufferSize)
        var frame = Frame(
            buffer: buf,
            finalizer: { ptr in
                tracker.withLock { $0 = true }
                ptr.baseAddress?.deallocate()
            }
        )
        frame.dropOwnership()
        frame.finalize(success: true)
        XCTAssertFalse(tracker.withLock { $0 })
        buf.baseAddress?.deallocate()
    }

    func testCustomFinalizerSpanAndClaim() {
        let buf = allocateAndFillBuffer(size: bufferSize)
        var frame = Frame(
            buffer: buf,
            finalizer: { $0.baseAddress?.deallocate() }
        )

        XCTAssertEqual(frame.unclaimedLength, bufferSize)
        XCTAssert(frame.span != nil)
        frame.span?.withUnsafeBufferPointer { ptr in
            XCTAssertEqual(ptr.count, bufferSize)
            XCTAssertEqual(ptr[0], 0)
            XCTAssertEqual(ptr[9], 9)
        }

        XCTAssertTrue(frame.claim(fromStart: 2))
        XCTAssertEqual(frame.unclaimedLength, bufferSize - 2)
        frame.span?.withUnsafeBufferPointer { ptr in
            XCTAssertEqual(ptr.count, bufferSize - 2)
            XCTAssertEqual(ptr[0], 2)
        }

        XCTAssertTrue(frame.claim(fromStart: 0, fromEnd: 3))
        XCTAssertEqual(frame.unclaimedLength, bufferSize - (2 + 3))
        frame.span?.withUnsafeBufferPointer { ptr in
            XCTAssertEqual(ptr.count, bufferSize - (2 + 3))
            XCTAssertEqual(ptr[0], 2)
            XCTAssertEqual(ptr[4], 6)
        }

        frame.finalize(success: true)
    }

    // MARK: Helper

    private func allocateAndFillBuffer(size: Int) -> UnsafeMutableRawBufferPointer {
        let ptr = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: MemoryLayout<UInt8>.alignment)
        let buf = UnsafeMutableRawBufferPointer(start: ptr, count: size)
        for i in 0..<size {
            buf[i] = UInt8(i)
        }
        return buf
    }
}
