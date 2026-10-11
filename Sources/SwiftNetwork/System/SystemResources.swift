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

/// An extension that adds system-resource APIs.
///
/// Extends `System` with system-resource functions.
@available(Network 0.1.0, *)
extension System {

    /// Returns the file-descriptor limit, if available.
    ///
    /// Returns `nil` if no limit was obtained.
    static func getFDLimit() -> UInt64? {
        let fdLimit = SystemResources.getFDLimit()
        return fdLimit > 0 ? fdLimit : nil
    }
}
