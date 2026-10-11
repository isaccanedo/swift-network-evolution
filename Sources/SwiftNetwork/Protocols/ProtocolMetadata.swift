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

#if canImport(Synchronization)
internal import Synchronization
#endif

@_spi(ProtocolProvider)
@available(Network 0.1.0, *)
public protocol PerProtocolMetadata: Equatable {
    func isEqual(to: Self, for: ProtocolCompareMode) -> Bool
    #if NETWORK_PRIVATE
    var cProtocolDefinition: nw_protocol_definition_t? { get }
    #endif
}

@_spi(ProtocolProvider)
@available(Network 0.1.0, *)
public class AbstractProtocolMetadata: PerProtocolMetadata {
    public static func == (lhs: AbstractProtocolMetadata, rhs: AbstractProtocolMetadata) -> Bool {
        lhs.isEqual(to: rhs, for: .equal)
    }

    public func isEqual(to: AbstractProtocolMetadata, for: ProtocolCompareMode) -> Bool {
        fatalError("Unimplemented")
    }

    public let messageIdentifier: SystemUUID
    public let protocolIdentifier: ProtocolIdentifier

    public func matches(protocolIdentifier: ProtocolIdentifier) -> Bool {
        self.protocolIdentifier == protocolIdentifier
    }

    final public func matches<T>(definition: ProtocolDefinition<T>) -> Bool {
        self.protocolIdentifier == definition.identifier
    }

    fileprivate init(protocolIdentifier: ProtocolIdentifier, messageIdentifier: SystemUUID) {
        self.protocolIdentifier = protocolIdentifier
        self.messageIdentifier = messageIdentifier
    }

    #if NETWORK_PRIVATE
    public var cProtocolDefinition: nw_protocol_definition_t? { nil }
    #endif
}

@_spi(Essentials)
@available(Network 0.1.0, *)
public final class ProtocolMetadata<P: NetworkProtocol>: AbstractProtocolMetadata, @unchecked Sendable {
    private let lock = NetworkMutex(())
    private var _perProtocolMetadata: P.Metadata? = nil
    public var perProtocolMetadata: P.Metadata? {
        get {
            lock.withLock { _ in
                _perProtocolMetadata
            }
        }
        set {
            lock.withLock { _ in
                _perProtocolMetadata = newValue
            }
        }
    }

    #if NETWORK_PRIVATE
    public override var cProtocolDefinition: nw_protocol_definition_t? { perProtocolMetadata?.cProtocolDefinition }
    #endif

    init(protocolIdentifier: ProtocolIdentifier, perProtocolMetadata: P.Metadata?, messageIdentifier: SystemUUID) {
        _perProtocolMetadata = perProtocolMetadata
        super.init(protocolIdentifier: protocolIdentifier, messageIdentifier: messageIdentifier)
    }

    public func isEqual(to other: ProtocolMetadata, for compareMode: ProtocolCompareMode) -> Bool {
        guard self.protocolIdentifier == other.protocolIdentifier else {
            return false
        }
        if let lh = self.perProtocolMetadata, let rh = other.perProtocolMetadata {
            return lh.isEqual(to: rh, for: compareMode)
        } else if self.perProtocolMetadata == nil, other.perProtocolMetadata == nil {
            return true
        }
        return false
    }

    public override func isEqual(to other: AbstractProtocolMetadata, for compareMode: ProtocolCompareMode) -> Bool {
        guard let other = other as? ProtocolMetadata else {
            return false
        }
        return isEqual(to: other, for: compareMode)
    }

    public static func == (lhs: ProtocolMetadata, rhs: ProtocolMetadata) -> Bool {
        lhs.isEqual(to: rhs, for: .equal)
    }

    public static func == (lhs: AbstractProtocolMetadata, rhs: ProtocolMetadata) -> Bool {
        guard let lhs = lhs as? ProtocolMetadata else {
            return false
        }
        return lhs == rhs
    }
}
