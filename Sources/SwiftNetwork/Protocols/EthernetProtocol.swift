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

@available(Network 0.1.0, *)
struct EthernetProtocol {
    struct Properties {
        let localEthernet: EthernetAddress
        let remoteEthernet: EthernetAddress
        let ethertype: UInt16

        init(localEthernet: EthernetAddress, remoteEthernet: EthernetAddress, ethertype: UInt16) {
            self.localEthernet = localEthernet
            self.remoteEthernet = remoteEthernet
            self.ethertype = ethertype
        }

        init(localEthernet: EthernetAddress, remoteEthernet: EthernetAddress, addressFamily: AddressFamily) {
            self.localEthernet = localEthernet
            self.remoteEthernet = remoteEthernet
            switch addressFamily {
            case .ipv4:
                self.ethertype = EtherType.ipv4.rawValue
            case .ipv6:
                self.ethertype = EtherType.ipv6.rawValue
            default:
                self.ethertype = 0
            }
        }

        func writeHeader(into frame: inout Frame, claim: Bool) -> SerializationResult {
            // Destination goes first, then source.
            // For sending, remote is the destination, and local is the source.
            Serializer.serialize(&frame, claim: claim) { write throws(SerializationError) in
                try write.span(remoteEthernet.span.bytes)
                try write.span(localEthernet.span.bytes)
                try write.uint16NetworkByteOrder(ethertype)
            }
        }

        func validateHeader(from frame: inout Frame, claim: Bool) -> DeserializationResult {
            // Destination goes first, then source.
            // For receiving, local is the destination, and remote is the source.
            Deserializer.deserialize(&frame, claim: claim) { read throws(DeserializationError) in
                try read.span(expect: localEthernet.span.bytes)
                try read.span(expect: remoteEthernet.span.bytes)
                try read.uint16NetworkByteOrder(expect: ethertype)
            }
        }
    }

    enum EtherType: UInt16 {
        case ipv4 = 0x0800
        case ipv6 = 0x86dd
    }

    // Ethernet Header
    // source: EthernetAddress
    // destination: EthernetAddress
    // type: UInt16
    static let headerLength: Int = EthernetAddress.length * 2 + MemoryLayout<UInt16>.size
}
