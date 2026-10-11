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

struct TestDataGenerator: IteratorProtocol, Sequence {
    static func createBlock(size: Int, uniqueBits: UInt8? = nil) -> [UInt8] {
        let baseArray: [UInt8]
        let base = Array(0...UInt8.max)
        if let uniqueBits = uniqueBits {
            baseArray = base.map { $0 ^ uniqueBits }
        } else {
            baseArray = base
        }
        var array: [UInt8] = []
        for _ in 0..<size / baseArray.count {
            array = array + baseArray
        }
        if array.count < size {
            array = array + baseArray[0..<size - array.count]
        }
        return array
    }

    let numberOfBlocks: Int
    let block: [UInt8]
    let blockSize: Int
    var blocksDone: Int = 0
    let sendFIN: Bool

    init(blockSize: Int, numberOfBlocks: Int, uniqueBits: UInt8? = nil, sendFIN: Bool = false) {
        self.numberOfBlocks = numberOfBlocks
        self.blockSize = blockSize
        self.block = TestDataGenerator.createBlock(size: blockSize, uniqueBits: uniqueBits)
        self.sendFIN = sendFIN
    }

    init(singleDataBlock: [UInt8], sendFIN: Bool = false) {
        self.numberOfBlocks = 1
        self.blockSize = singleDataBlock.count
        self.block = singleDataBlock
        self.sendFIN = sendFIN
    }

    var totalSize: Int {
        numberOfBlocks * blockSize
    }

    enum ValidationError: Error {
        case invalidIndex
        case sizeBeyondEnd
        case byteMismatch(index: Int, expected: UInt8, actual: UInt8)
    }

    func validate(at dataStartIndex: Int, data: [UInt8]) throws {
        guard dataStartIndex < totalSize && dataStartIndex >= 0 else {
            throw ValidationError.invalidIndex
        }
        guard dataStartIndex + data.count <= totalSize else {
            throw ValidationError.sizeBeyondEnd
        }

        var indexWithinSequence = dataStartIndex
        var indexWithinData = 0
        while indexWithinSequence < dataStartIndex + data.count {
            while indexWithinSequence < dataStartIndex + data.count {
                let indexWithinBlock = indexWithinSequence % blockSize
                if block[indexWithinBlock] != data[indexWithinData] {
                    throw ValidationError.byteMismatch(
                        index: indexWithinSequence,
                        expected: block[indexWithinBlock],
                        actual: data[indexWithinData]
                    )
                }
                indexWithinData += 1
                indexWithinSequence += 1
            }
        }
    }

    mutating func next() -> [UInt8]? {
        guard blocksDone < numberOfBlocks && blockSize > 0 else {
            return nil
        }
        blocksDone += 1
        return block
    }
}

final class TestDataGeneratorTests: XCTestCase {
    func testSingleDataBlock() {
        let data = Array("Hello World!".utf8)
        let generator = TestDataGenerator(singleDataBlock: data)
        var blockCount = 0
        for block in generator {
            XCTAssertEqual(block.count, data.count)
            var byteCount = 0
            for byte in block {
                XCTAssert(byte == data[byteCount])
                byteCount += 1
            }
            blockCount += 1
        }
        XCTAssertEqual(blockCount, 1)
        XCTAssertEqual(generator.totalSize, data.count)
    }

    func test10BlocksOfSize257() {
        let generator = TestDataGenerator(blockSize: 257, numberOfBlocks: 10)
        var blockCount = 0
        for block in generator {
            XCTAssertEqual(block.count, 257)
            var byteCount = 0
            for byte in block {
                XCTAssert(byte == (byteCount <= UInt8.max ? byteCount : 0))
                byteCount += 1
            }
            blockCount += 1
        }
        XCTAssertEqual(blockCount, 10)
        XCTAssertEqual(generator.totalSize, 257 * 10)
    }

    func testUniqueBits() {
        let uniqueBits = UInt8(1)
        let generator = TestDataGenerator(blockSize: 257, numberOfBlocks: 10, uniqueBits: uniqueBits)
        var blockCount = 0
        for block in generator {
            XCTAssertEqual(block.count, 257)
            var byteCount = 0
            for byte in block {
                XCTAssertEqual(byte, (byteCount <= UInt8.max ? UInt8(byteCount) : 0) ^ uniqueBits)
                byteCount += 1
            }
            blockCount += 1
        }
        XCTAssertEqual(blockCount, 10)
        XCTAssertEqual(generator.totalSize, 257 * 10)

        let originalGenerator = TestDataGenerator(blockSize: 257, numberOfBlocks: 10)
        for block in generator {
            for originalBlock in originalGenerator {
                XCTAssertNotEqual(block, originalBlock)
            }
        }
    }

    func testValidation() {
        // Generator with three blocks, that each have byte values from 0 to 255
        let generator = TestDataGenerator(blockSize: 256, numberOfBlocks: 3)
        let subArrayEmpty: [UInt8] = []
        let subArrayFirstByte: [UInt8] = [0]
        let subArrayStart: [UInt8] = [0, 1]
        let subArrayMiddle: [UInt8] = [42]
        let subArrayEnd: [UInt8] = [254, 255]
        let subArrayLastByte: [UInt8] = [255]

        let subArrayEndAndNextByte: [UInt8] = [255, 0]
        let subArrayExactlySame: [UInt8] = Array(0...UInt8.max)
        let subArrayOneBadByte: [UInt8] = Array(0...9) + [255] + Array(11...UInt8.max)
        let subArrayExactlySamePlusOne: [UInt8] = subArrayExactlySame + [0]
        let subArrayExactlySameTwoBlocks: [UInt8] = subArrayExactlySame + subArrayExactlySame
        let subArrayExactlySameThreeBlocks: [UInt8] = subArrayExactlySameTwoBlocks + subArrayExactlySame
        let subArrayExactlySameExceptOneByte: [UInt8] = subArrayExactlySame + subArrayOneBadByte + subArrayExactlySame

        XCTAssertNoThrow(try generator.validate(at: 0, data: subArrayEmpty))
        XCTAssertNoThrow(try generator.validate(at: 0, data: subArrayFirstByte))
        XCTAssertThrowsError(try generator.validate(at: 0, data: [1]))
        XCTAssertNoThrow(try generator.validate(at: 0, data: subArrayStart))
        XCTAssertNoThrow(try generator.validate(at: 42, data: subArrayMiddle))
        // off by one index
        XCTAssertThrowsError(try generator.validate(at: 41, data: subArrayMiddle))
        XCTAssertNoThrow(try generator.validate(at: 254, data: subArrayEnd))
        XCTAssertNoThrow(try generator.validate(at: 255, data: subArrayLastByte))
        XCTAssertNoThrow(try generator.validate(at: 0, data: subArrayExactlySame))
        XCTAssertThrowsError(try generator.validate(at: 0, data: subArrayOneBadByte))
        // off by one index
        XCTAssertThrowsError(try generator.validate(at: 1, data: subArrayExactlySame))
        // into second block
        XCTAssertNoThrow(try generator.validate(at: 0, data: subArrayExactlySamePlusOne))
        XCTAssertNoThrow(try generator.validate(at: 255, data: subArrayEndAndNextByte))
        // second block
        XCTAssertNoThrow(try generator.validate(at: 256, data: subArrayStart))
        XCTAssertNoThrow(try generator.validate(at: 256, data: subArrayFirstByte))
        XCTAssertNoThrow(try generator.validate(at: 256 + 42, data: subArrayMiddle))
        XCTAssertNoThrow(try generator.validate(at: 256, data: subArrayExactlySame))
        // into third block
        XCTAssertNoThrow(try generator.validate(at: 256 + 255, data: subArrayEndAndNextByte))
        // third block
        XCTAssertNoThrow(try generator.validate(at: 256 + 256, data: subArrayFirstByte))
        XCTAssertNoThrow(try generator.validate(at: 256 + 256 + 42, data: subArrayMiddle))
        // Last valid index of whole sequence and last block
        XCTAssertNoThrow(try generator.validate(at: 256 + 256 + 255, data: subArrayLastByte))
        // multiple blocks
        XCTAssertNoThrow(try generator.validate(at: 256, data: subArrayExactlySameTwoBlocks))
        XCTAssertNoThrow(try generator.validate(at: 0, data: subArrayExactlySameThreeBlocks))
        XCTAssertThrowsError(try generator.validate(at: 0, data: subArrayExactlySameExceptOneByte))
        // beyond the end
        XCTAssertThrowsError(try generator.validate(at: 256, data: subArrayExactlySameThreeBlocks))
        XCTAssertThrowsError(try generator.validate(at: 256 + 256 + 255, data: subArrayEndAndNextByte))
    }
}
