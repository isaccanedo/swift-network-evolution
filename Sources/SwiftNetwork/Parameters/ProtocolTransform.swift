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

@available(Network 0.1.0, *)
struct ProtocolTransform: Hashable {
    var transformStack: ProtocolStack?
    var trafficClass: UInt32?
    var multipathService: Parameters.MultipathServiceType?
    var dataMode: Parameters.DataMode = .unspecified
    var replaceEndpoint: Endpoint?

    enum FallbackMode: Hashable {
        case unspecified
        case failover  // Attempt the next transformation after this one fails
        case rttTimer  // Attempt the next transformation after a timeout based on current RTT stats
        case immediate  // Attempt the next transformation immediately after this one
    }
    var fallbackMode: FallbackMode = .unspecified

    var disabledProtocols: [ProtocolIdentifier] = [ProtocolIdentifier]()
    var matchURLSchemes: [String] = [String]()

    struct Flags: OptionSet, Hashable {
        init(rawValue: Self.RawValue) {
            self.rawValue = rawValue
        }
        let rawValue: UInt16
        static let clearApplication = Flags(rawValue: 1 << 0)
        static let clearTransport = Flags(rawValue: 1 << 1)
        static let clearInternet = Flags(rawValue: 1 << 2)
        static let noProxy = Flags(rawValue: 1 << 3)
        static let prohibitDirect = Flags(rawValue: 1 << 4)
        static let tfo = Flags(rawValue: 1 << 5)
        static let tfoNoCookie = Flags(rawValue: 1 << 6)
        static let noFallback = Flags(rawValue: 1 << 7)
        static let fastOpenForceEnable = Flags(rawValue: 1 << 8)
    }
    var flags: Flags = Flags(rawValue: 0)

    var clearApplication: Bool {
        get { flags.contains(.clearApplication) }
        set { if newValue { flags.insert(.clearApplication) } else { flags.remove(.clearApplication) } }
    }
    var clearTransport: Bool {
        get { flags.contains(.clearTransport) }
        set { if newValue { flags.insert(.clearTransport) } else { flags.remove(.clearTransport) } }
    }
    var clearInternet: Bool {
        get { flags.contains(.clearInternet) }
        set { if newValue { flags.insert(.clearInternet) } else { flags.remove(.clearInternet) } }
    }
    var noProxy: Bool {
        get { flags.contains(.noProxy) }
        set { if newValue { flags.insert(.noProxy) } else { flags.remove(.noProxy) } }
    }
    var prohibitDirect: Bool {
        get { flags.contains(.prohibitDirect) }
        set { if newValue { flags.insert(.prohibitDirect) } else { flags.remove(.prohibitDirect) } }
    }
    var tfo: Bool {
        get { flags.contains(.tfo) }
        set { if newValue { flags.insert(.tfo) } else { flags.remove(.tfo) } }
    }
    var tfoNoCookie: Bool {
        get { flags.contains(.tfoNoCookie) }
        set { if newValue { flags.insert(.tfoNoCookie) } else { flags.remove(.tfoNoCookie) } }
    }
    var noFallback: Bool {
        get { flags.contains(.noFallback) }
        set { if newValue { flags.insert(.noFallback) } else { flags.remove(.noFallback) } }
    }
    var fastOpenForceEnable: Bool {
        get { flags.contains(.fastOpenForceEnable) }
        set { if newValue { flags.insert(.fastOpenForceEnable) } else { flags.remove(.fastOpenForceEnable) } }
    }

    init() {}

    init(from original: ProtocolTransform) {
        self = original
        if let stack = original.transformStack {
            transformStack = ProtocolStack(deepCopy: stack)
        }
    }

    func isEqual(to other: ProtocolTransform, for compareMode: ProtocolCompareMode) -> Bool {
        switch (transformStack, other.transformStack) {
        case (.some(let lh), .some(let rh)):
            if !lh.isEqual(to: rh, for: compareMode) {
                return false
            }
        case (.none, .none):
            break
        default:
            return false
        }
        return
            (trafficClass == other.trafficClass && multipathService == other.multipathService
            && dataMode == other.dataMode && replaceEndpoint == other.replaceEndpoint
            && fallbackMode == other.fallbackMode && disabledProtocols == other.disabledProtocols
            && matchURLSchemes == other.matchURLSchemes && flags == other.flags)
    }

    static func == (lhs: ProtocolTransform, rhs: ProtocolTransform) -> Bool {
        lhs.isEqual(to: rhs, for: .equal)
    }

    func modify(parameters: inout Parameters) {
        parameters.transforms = nil
        if dataMode != .unspecified {
            parameters.dataMode = dataMode
        }
        if noProxy {
            parameters.noProxy = true
        }
        if let multipathService = multipathService {
            parameters.multipathService = multipathService
        }
        if tfo {
            parameters.tfo = true
        }
        if tfoNoCookie {
            parameters.noFastOpenCookie = true
        }
        if fastOpenForceEnable {
            parameters.fastOpenForceEnable = true
        }
        if noFallback {
            parameters.noFallback = true
        }
        if let trafficClass = trafficClass {
            parameters.trafficClass = trafficClass
        }
        if clearApplication {
            parameters.defaultStack.clearApplicationProtocols()
        }
        if clearTransport {
            parameters.defaultStack.clearTransportProtocols()
        }
        if clearInternet {
            parameters.defaultStack.internet = nil
        }
        for disabledProtocol in disabledProtocols {
            parameters.defaultStack.remove(protocolIdentifier: disabledProtocol)
        }
        if let transformStack = transformStack {
            #if !NETWORK_EMBEDDED
            for application in transformStack.applicationProtocols {
                parameters.defaultStack.append(applicationProtocol: application)
            }
            #endif
            if let transport = transformStack.transport {
                parameters.defaultStack.transport = transport
            }
            if let internet = transformStack.internet {
                parameters.defaultStack.internet = internet
            }
        }
    }

    func contains(protocol identifier: ProtocolIdentifier) -> Bool {
        guard let stack = transformStack else {
            return false
        }
        let isQUIC = (identifier == QUICStreamProtocol.identifier || identifier == QUICConnectionProtocol.identifier)
        for proto in stack.persistentApplication {
            if isQUIC {
                return proto.matches(identifier: QUICStreamProtocol.identifier)
                    || proto.matches(identifier: QUICConnectionProtocol.identifier)
            } else if proto.matches(identifier: identifier) {
                return true
            }
        }
        for proto in stack.application {
            if isQUIC {
                return proto.matches(identifier: QUICStreamProtocol.identifier)
                    || proto.matches(identifier: QUICConnectionProtocol.identifier)
            } else if proto.matches(identifier: identifier) {
                return true
            }
        }
        if let transport = stack.transport {
            if isQUIC {
                return transport.matches(identifier: QUICStreamProtocol.identifier)
                    || transport.matches(identifier: QUICConnectionProtocol.identifier)
            } else if transport.matches(identifier: identifier) {
                return true
            }
        }
        if let secondaryTransport = stack.secondaryTransport {
            if isQUIC {
                return secondaryTransport.matches(identifier: QUICStreamProtocol.identifier)
                    || secondaryTransport.matches(identifier: QUICConnectionProtocol.identifier)
            } else if secondaryTransport.matches(identifier: identifier) {
                return true
            }
        }
        if let internet = stack.internet {
            if isQUIC {
                return internet.matches(identifier: QUICStreamProtocol.identifier)
                    || internet.matches(identifier: QUICConnectionProtocol.identifier)
            } else if internet.matches(identifier: identifier) {
                return true
            }
        }
        return false
    }

    mutating func disable(protocol identifier: ProtocolIdentifier) {
        if !disabledProtocols.contains(identifier) {
            disabledProtocols.append(identifier)
        }
    }

    mutating func addMatchURLScheme(_ urlScheme: String) {
        if !matchURLSchemes.contains(urlScheme) {
            matchURLSchemes.append(urlScheme)
        }
    }

    mutating func clearMatchURLSchemes() {
        matchURLSchemes.removeAll()
    }

    // Causes all existing protocols at a level to be cleared before applying
    mutating func clear(at level: ProtocolLevel) {
        switch level {
        case .application:
            clearApplication = true
        case .transport:
            clearTransport = true
        case .internet:
            clearInternet = true
        default:
            break
        }
    }

    #if !NETWORK_EMBEDDED
    mutating func append(protocol protocolOptions: AbstractProtocolOptions, at level: ProtocolLevel) {
        if transformStack == nil {
            transformStack = ProtocolStack()
        }
        guard let transformStack else {
            return
        }
        switch level {
        case .application:
            transformStack.append(applicationProtocol: protocolOptions)
        case .transport:
            transformStack.transport = ProtocolStack.TransportProtocol(options: protocolOptions)
        case .internet:
            transformStack.internet = ProtocolStack.InternetProtocol(options: protocolOptions)
        default:
            break
        }
    }
    #endif
}
