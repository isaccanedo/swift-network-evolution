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

#if !NETWORK_NO_SWIFT_QUIC

@_spi(ProtocolProvider)
@available(Network 0.1.0, *)
public struct PreferredAddress: Equatable {
    let connectionID: QUICConnectionID
    let statelessResetToken: QUICStatelessResetToken
    let ipv4Port: Int
    let ipv4Address: UInt32
    let ipv6Port: Int
    let ipv6Address: [UInt8]

    var length: Int {
        MemoryLayout<UInt32>.size  // ipv4Address
            + MemoryLayout<UInt16>.size  // ipv4Port
            + MemoryLayout<UInt128>.size  // ipv6Address
            + MemoryLayout<UInt16>.size  // ipv6Port +
            + MemoryLayout<UInt8>.size  // connectionID length
            + connectionID.length
            + QUICStatelessResetToken.size
    }
    static let minimumSize =
        MemoryLayout<UInt32>.size  // ipv4Address
        + MemoryLayout<UInt16>.size  // ipv4Port
        + MemoryLayout<UInt128>.size  // ipv6Address
        + MemoryLayout<UInt16>.size  // ipv6Port +
        + MemoryLayout<UInt8>.size  // connectionID length == 0
        + QUICStatelessResetToken.size

    static let maximumSize =
        MemoryLayout<UInt32>.size  // ipv4Address
        + MemoryLayout<UInt16>.size  // ipv4Port
        + MemoryLayout<UInt128>.size  // ipv6Address
        + MemoryLayout<UInt16>.size  // ipv6Port +
        + MemoryLayout<UInt8>.size  // connectionID length
        + QUICConnectionID.maximumSize
        + QUICStatelessResetToken.size

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.connectionID == rhs.connectionID
            && lhs.statelessResetToken == rhs.statelessResetToken && lhs.ipv4Port == rhs.ipv4Port
            && lhs.ipv4Address == rhs.ipv4Address && lhs.ipv6Port == rhs.ipv6Port
            && lhs.ipv6Address == rhs.ipv6Address
    }
}
#endif
