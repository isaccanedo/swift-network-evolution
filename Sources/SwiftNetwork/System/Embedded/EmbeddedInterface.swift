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

#if (NETWORK_EMBEDDED || NETWORK_STANDALONE) && !NETWORK_DRIVERKIT

/// A set of embedded system APIs for interacting with the system interface.
internal enum SystemInterface {

    /// Gets the MTU from the interface.
    ///
    /// Uses `ioctl` to fetch the value.
    static func interfaceGetMTU(socket: Int32, name: String) throws -> Int {
        1500
    }

    /// Returns a Boolean value that indicates whether an interface has a specific flag.
    ///
    /// For example, `UP`, `RUNNING`, `BROADCAST`, or `MULTICAST`.
    static func interfaceHasFlag(socket: Int32, name: String, flag: Interface.Details.Flags) throws -> Bool {
        false
    }

    /// Returns the functional type flags for the interface.
    static func getFunctionalType(socket: Int32, name: String) throws -> UInt32 {
        0
    }

    /// Returns all of the interface flags for the specified interface.
    static func interfaceGetInterfaceFlags(socket: Int32, name: String) throws -> UInt32 {
        0
    }

    /// Returns the interface type for the specified interface.
    static func interfaceGetInterfaceType(socket: Int32, name: String) throws -> InterfaceType {
        .loopback
    }

    /// Returns the interface subtype.
    static func interfaceGetInterfaceSubType(socket: Int32, name: String) throws -> InterfaceSubtype {
        .wifiInfrastructure
    }

    /// Returns the interface name from the index.
    static func interfaceGetNameFromIndex(index: UInt32) throws -> String? {
        String("BogusInterface")
    }
}

internal enum SystemRoute {
    static func routeGetInterfaceIndex(dst: any IPAddress, scopedIndex: UInt32 = 0) throws -> UInt32 {
        // No route lookups on embedded
        0
    }
}
#endif
