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

#if canImport(BasicContainers)
import BasicContainers
internal import DequeModule
#endif

@_spi(Essentials)
@available(Network 0.1.0, *)
public struct PathFlow: CustomDebugStringConvertible, Equatable {

    public var nexusKey: [UInt8]? = nil
    var interface: Interface? = nil
    var localEndpoint: Endpoint? = nil
    var remoteEndpoint: Endpoint? = nil
    var assignedProtocol: AbstractProtocolOptions? = nil
    public var flowID = SystemUUID.empty
    var tfoCookie: [UInt8]? = nil

    var discoveredEndpoints: Deque<Endpoint>? = nil
    var resolvedEndpoints: Deque<Endpoint>? = nil

    var interfaceGeneration: UInt32 = 0
    var interfaceIndex: UInt32 = 0

    #if NETWORK_PRIVATE || NETWORK_DRIVERKIT
    var privateFlow = PathFlow.PathFlowPrivate()
    #endif

    var ctlCommandCode: UInt32?
    var ctlCommandValue: UInt32 = 0
    var ctlCommandTCPSeqNum: UInt32 = 0
    var uniqueFlowTag: UInt32 = 0
    var flowStatsIndex: UInt32 = 0

    struct Flags: OptionSet {
        public var rawValue: UInt16

        static public let viable = Flags(rawValue: 1 << 0)
        static public let assigned = Flags(rawValue: 1 << 1)
        static public let ecnEnabled = Flags(rawValue: 1 << 2)
        static public let fastOpenBlocked = Flags(rawValue: 1 << 3)
        static public let isLocal = Flags(rawValue: 1 << 4)
        static public let isDirect = Flags(rawValue: 1 << 5)
        static public let hasIPv4 = Flags(rawValue: 1 << 6)
        static public let hasIPv6 = Flags(rawValue: 1 << 7)
        static public let hasNAT64 = Flags(rawValue: 1 << 8)
        static public let ctlCommandValid = Flags(rawValue: 1 << 9)
        static public let defunct = Flags(rawValue: 1 << 10)
        static public let isCustomIP = Flags(rawValue: 1 << 11)
    }
    var flags: Flags = Flags()

    public init() {}

    public static func == (lhs: PathFlow, rhs: PathFlow) -> Bool {
        // Note: This will not match if the generation for the nexus differ. We may want to reevaluate this.
        if lhs.flag(.viable) != rhs.flag(.viable) || lhs.flag(.assigned) != rhs.flag(.assigned)
            || lhs.flag(.ecnEnabled) != rhs.flag(.ecnEnabled)
            || lhs.flag(.fastOpenBlocked) != rhs.flag(.fastOpenBlocked) || lhs.flag(.isLocal) != rhs.flag(.isLocal)
            || lhs.flag(.isDirect) != rhs.flag(.isDirect) || lhs.flag(.hasIPv4) != rhs.flag(.hasIPv4)
            || lhs.flag(.hasIPv6) != rhs.flag(.hasIPv6) || lhs.tfoCookie != rhs.tfoCookie
            || lhs.interfaceGeneration != rhs.interfaceGeneration || lhs.interfaceIndex != rhs.interfaceIndex
            || lhs.localEndpoint != rhs.localEndpoint || lhs.remoteEndpoint != rhs.remoteEndpoint
            || lhs.nexusKey != rhs.nexusKey
        {
            return false
        }
        #if NETWORK_PRIVATE || NETWORK_DRIVERKIT
        if lhs.privateFlow != rhs.privateFlow {
            return false
        }
        #endif
        return true
    }

    public var debugDescription: String {

        var desc = flowID.uuidString + " interface: "
        if let interface {
            desc += interface.name
        }
        if flag(.viable) {
            desc += ", viable"
        }
        if flag(.assigned) {
            desc += ", assigned"
        }
        return desc
    }

    func flag(_ flag: Flags) -> Bool {
        if flags.contains(flag) { return true }
        return false
    }
    mutating func setFlag(flag: Flags, value: Bool) {
        if value {
            flags.insert(flag)
        } else {
            flags.remove(flag)
        }
    }
    var viable: Bool {
        get { flags.contains(.viable) }
        set { setFlag(flag: .viable, value: newValue) }
    }
    var assigned: Bool {
        get { flags.contains(.assigned) }
        set { setFlag(flag: .assigned, value: newValue) }
    }
    var ecnEnabled: Bool {
        get { flags.contains(.ecnEnabled) }
        set { setFlag(flag: .ecnEnabled, value: newValue) }
    }
    var fastOpenBlocked: Bool {
        get { flags.contains(.fastOpenBlocked) }
        set { setFlag(flag: .fastOpenBlocked, value: newValue) }
    }
    var isLocal: Bool {
        get { flags.contains(.isLocal) }
        set { setFlag(flag: .isLocal, value: newValue) }
    }
    var isDirect: Bool {
        get { flags.contains(.isDirect) }
        set { setFlag(flag: .isDirect, value: newValue) }
    }
    var hasIPv4: Bool {
        get { flags.contains(.hasIPv4) }
        set { setFlag(flag: .hasIPv4, value: newValue) }
    }
    var hasIPv6: Bool {
        get { flags.contains(.hasIPv6) }
        set { setFlag(flag: .hasIPv6, value: newValue) }
    }
    var hasNAT64: Bool {
        get { flags.contains(.hasNAT64) }
        set { setFlag(flag: .hasNAT64, value: newValue) }
    }
    var defunct: Bool {
        get { flags.contains(.defunct) }
        set { setFlag(flag: .defunct, value: newValue) }
    }
}
