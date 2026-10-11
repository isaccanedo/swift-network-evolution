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

#if (!os(Linux) && canImport(Darwin) && !NETWORK_STANDALONE) || NETWORK_DRIVERKIT
internal import os

#if !NETWORK_DRIVERKIT
import Darwin
#endif

/// A set of Darwin system APIs for interacting with the system interface.
@available(Network 0.1.0, *)
internal enum SystemInterface {

    enum Constants {
        static let SIOCGIFFLAGS: UInt32 = 0xc020_6911
        static let SIOCGIFMTU: UInt32 = 0xc020_6933
        static let IFF_LOOPBACK: UInt32 = 0x0000_0008
        static let IFXNAMSIZ: UInt32 = 0x0000_0018  // (IFNAMSIZ + 8)  IFNAMSIZ = 16
        static let SIOCGIFFUNCTIONALTYPE: UInt32 = 0xc020_69ad
        static let IFRTYPE_FUNCTIONAL_UNKNOWN: UInt32 = 0x0000_0000
        static let IFRTYPE_FUNCTIONAL_LOOPBACK: UInt32 = 0x0000_0001
        static let IFRTYPE_FUNCTIONAL_WIRED: UInt32 = 0x0000_0002
        static let IFRTYPE_FUNCTIONAL_WIFI_INFRA: UInt32 = 0x0000_0003
        static let IFRTYPE_FUNCTIONAL_WIFI_AWDL: UInt32 = 0x0000_0004
        static let IFRTYPE_FUNCTIONAL_CELLULAR: UInt32 = 0x0000_0005
        static let IFF_MULTICAST: UInt32 = 0x0000_8000
        static let IFF_UP: UInt32 = 0x0000_0001
        static let IFF_BROADCAST: UInt32 = 0x0000_0002
        static let IFF_RUNNING: UInt32 = 0x0000_0040
    }

    /// Gets the MTU from the interface.
    ///
    /// Uses `ioctl` to fetch the value.
    static func interfaceGetMTU(socket: Int32, name: String) throws -> Int {
        if name.isEmpty {
            return 65535
        }
        var ifr = ifreq()
        return try name.withCString { ptr in
            let bytes = UnsafeRawBufferPointer(start: ptr, count: name.count + 1)
            withUnsafeMutableBytes(of: &ifr.ifr_name) { dstPtr in
                dstPtr.copyMemory(from: bytes)
            }
            #if NETWORK_DRIVERKIT
            let result = ioctl_siocgifmtu(socket, &ifr)
            guard result != -1 else { throw NetworkError.posix(get_errno()) }
            #else
            try System.ioctl(fd: socket, request: CUnsignedLong(Constants.SIOCGIFMTU), ptr: &ifr)
            #endif
            return Int(ifr.ifr_ifru.ifru_mtu)
        }
    }

    /// Returns a Boolean value that indicates whether an interface has a specific flag.
    ///
    /// For example, `UP`, `RUNNING`, `BROADCAST`, or `MULTICAST`.
    static func interfaceHasFlag(socket: Int32, name: String, flag: Interface.Details.Flags) throws -> Bool {
        if name.isEmpty {
            return false
        }
        var comparisonFlag: UInt16 = 0
        if flag == .supportsMulticast {
            comparisonFlag = UInt16(Constants.IFF_MULTICAST)
        } else if flag == .hasBroadcast {
            comparisonFlag = UInt16(Constants.IFF_BROADCAST)
        } else {
            return false
        }

        var ifr = ifreq()
        return try name.withCString { ptr in
            let bytes = UnsafeRawBufferPointer(start: ptr, count: name.count + 1)
            withUnsafeMutableBytes(of: &ifr.ifr_name) { dstPtr in
                dstPtr.copyMemory(from: bytes)
            }
            #if NETWORK_DRIVERKIT
            let result = ioctl_siocgifflags(socket, &ifr)
            guard result != -1 else { throw NetworkError.posix(get_errno()) }
            #else
            try System.ioctl(fd: socket, request: CUnsignedLong(Constants.SIOCGIFFLAGS), ptr: &ifr)
            #endif
            if (UInt16(bitPattern: ifr.ifr_ifru.ifru_flags) & comparisonFlag) != 0 {
                return true
            }
            return false
        }
    }

    /// Returns the functional type flags for the interface.
    static func getFunctionalType(socket: Int32, name: String) throws -> UInt32 {
        if name.isEmpty {
            return 0
        }
        var ifr = ifreq()
        return try name.withCString { ptr in
            let bytes = UnsafeRawBufferPointer(start: ptr, count: name.count + 1)
            withUnsafeMutableBytes(of: &ifr.ifr_name) { dstPtr in
                dstPtr.copyMemory(from: bytes)
            }
            #if NETWORK_DRIVERKIT
            let result = ioctl_siocgiffunctionaltype(socket, &ifr)
            guard result != -1 else { throw NetworkError.posix(get_errno()) }
            #else
            try System.ioctl(fd: socket, request: CUnsignedLong(Constants.SIOCGIFFUNCTIONALTYPE), ptr: &ifr)
            #endif
            return UInt32(ifr.ifr_ifru.ifru_functional_type)
        }
    }

    /// Returns all of the interface flags for the specified interface.
    static func interfaceGetInterfaceFlags(socket: Int32, name: String) throws -> UInt32 {
        if name.isEmpty {
            return 0
        }
        var ifr = ifreq()
        return try name.withCString { ptr in
            let bytes = UnsafeRawBufferPointer(start: ptr, count: name.count + 1)
            withUnsafeMutableBytes(of: &ifr.ifr_name) { dstPtr in
                dstPtr.copyMemory(from: bytes)
            }
            #if NETWORK_DRIVERKIT
            let result = ioctl_siocgifflags(socket, &ifr)
            guard result != -1 else { throw NetworkError.posix(get_errno()) }
            #else
            try System.ioctl(fd: socket, request: CUnsignedLong(Constants.SIOCGIFFLAGS), ptr: &ifr)
            #endif
            let interfaceFlags = UInt16(bitPattern: ifr.ifr_ifru.ifru_flags)
            return UInt32(interfaceFlags)
        }
    }
    /// Returns the interface type for the specified interface.
    static func interfaceGetInterfaceType(socket: Int32, name: String) throws -> InterfaceType {
        var interfaceType = InterfaceType.other
        // Check for interface type using SIOCGIFFUNCTIONALTYPE
        let functionalType = try SystemInterface.getFunctionalType(socket: socket, name: name)
        if functionalType == 2 {
            interfaceType = .loopback
        } else if functionalType == 3 {
            interfaceType = .wifi
        } else if functionalType == 5 {
            interfaceType = .cellular
        } else if functionalType == 1 {
            interfaceType = .loopback
        }
        return interfaceType
    }

    /// Returns the interface subtype.
    static func interfaceGetInterfaceSubType(socket: Int32, name: String) throws -> InterfaceSubtype {
        var interfaceSubtype = InterfaceSubtype.other
        if socket == 0 {
            return interfaceSubtype
        }
        let functionalType = try SystemInterface.getFunctionalType(socket: socket, name: name)
        if functionalType == 7 {
            interfaceSubtype = .companion
        } else if functionalType == 6 {
            interfaceSubtype = .coprocessor
        } else if functionalType == 4 {
            interfaceSubtype = .wifiAWDL
        } else if functionalType == 3 {
            interfaceSubtype = .wifiInfrastructure
        }
        return interfaceSubtype
    }

    /// Returns the interface name from the index.
    static func interfaceGetNameFromIndex(index: UInt32) throws -> String? {
        guard index > 0 else {
            Logger.interface.error("Invalid index for interface: 0")
            throw NetworkError.posix(EIO)
        }
        let name = try String(unsafeUninitializedCapacity: Int(Constants.IFXNAMSIZ) + 1) { buffer in
            guard let name = if_indextoname(UInt32(index), buffer.baseAddress) else {
                #if NETWORK_DRIVERKIT
                let error = get_errno()
                Logger.interface.error("if_indextoname failed for interface index \(index): \(error)")
                throw NetworkError.posix(error)
                #else
                let error = errno
                Logger.interface.error("if_indextoname failed for interface index \(index): \(error)")
                if let errorCode = POSIXErrorCode(rawValue: error) {
                    throw NetworkError.posix(errorCode.rawValue)
                } else {
                    throw NetworkError.posix(EINVAL)
                }
                #endif
            }
            return strlen(name)
        }
        return name
    }
}
#endif
