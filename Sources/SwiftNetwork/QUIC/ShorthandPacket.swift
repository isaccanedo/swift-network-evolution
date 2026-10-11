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

@available(Network 0.1.0, *)
struct ShorthandPacket: ShorthandLogEntry {
    let delta: NetworkDuration
    let keyState: PacketKeyState?
    let number: PacketNumber
    let longHeader: Bool
    let outgoing: Bool
    var retry: Bool = false
    var versionNegotiation: Bool = false

    init(packet: borrowing Packet, outgoing: Bool, delta: NetworkDuration) {
        keyState = packet.keyState
        longHeader = packet.longHeader
        number = packet.number
        self.outgoing = outgoing
        self.delta = delta
        self.retry = packet.retry
        self.versionNegotiation = packet.versionNegotiation
    }

    var description: String {
        let duration = Double(delta.milliseconds) / 1000.0
        var description = "\(outgoing ? "snd" : "rcv") \(duration)s "
        if longHeader {
            var type = ""
            if retry {
                type = "retry"
            } else if versionNegotiation {
                type = "vn"
            } else if let keyState = keyState {
                type = keyState.description
            }
            description += "LH<\(type), "
        } else {
            description += "SH<"
        }
        description += "\(number.value)>"

        return description
    }
}
#endif
