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

// Availability due to Swift's `Span` type
@available(anyAppleOS 26, *)
extension Array {
    init(copying span: Span<Element>, maxCount: Int) {
        let copyCount = Swift.min(span.count, maxCount)
        self.init(unsafeUninitializedCapacity: copyCount) { (buffer, count) in
            for i in 0..<copyCount {
                buffer.initializeElement(at: i, to: span[i])
            }
            count = copyCount
        }
    }
}
