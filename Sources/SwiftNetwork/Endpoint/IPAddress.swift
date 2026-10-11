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

/// A stub protocol that represents an IP address.
protocol IPAddress: Sendable {

    /// Creates an IP address from raw bytes.
    init?(_ bytes: [UInt8])

    /// The address family used by this IP address.
    var addressFamily: AddressFamily { get }

    /// A Boolean value that indicates whether this address is a loopback address.
    var isLoopback: Bool { get }

    /// A Boolean value that indicates whether this address is a multicast address.
    var isMulticast: Bool { get }
}
