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

#if !NETWORK_PRIVATE && canImport(Darwin) && !NETWORK_EMBEDDED
import Darwin
internal import os

public struct rt_metrics {
    init() {}
    public var rmx_locks: UInt32 = 0
    public var rmx_mtu: UInt32 = 0
    public var rmx_hopcount: UInt32 = 0
    public var rmx_expire: Int32 = 0
    public var rmx_recvpipe: UInt32 = 0
    public var rmx_sendpipe: UInt32 = 0
    public var rmx_ssthresh: UInt32 = 0
    public var rmx_rtt: UInt32 = 0
    public var rmx_rttvar: UInt32 = 0
    public var rmx_pksent: UInt32 = 0
    public var rmx_filler: (UInt32, UInt32, UInt32, UInt32) = (0, 0, 0, 0)
}

public struct rt_msghdr {
    init() {}
    public var rtm_msglen: u_short = 0
    public var rtm_version: u_char = 5
    public var rtm_type: u_char = 0
    public var rtm_index: u_short = 0
    public var rtm_flags: Int32 = 0
    public var rtm_addrs: Int32 = 0
    public var rtm_pid: pid_t = 0
    public var rtm_seq: Int32 = 0
    public var rtm_errno: Int32 = 0
    public var rtm_use: Int32 = 0
    public var rtm_inits: UInt32 = 0
    public var rtm_rmx: rt_metrics = rt_metrics()
}
public let RTM_VERSION: Int32 = 5
public let RTM_GET: Int32 = 0x4
public let RTF_GATEWAY: Int32 = 0x2
public let RTF_HOST: Int32 = 0x4
public let RTF_STATIC: Int32 = 0x800
public let RTF_UP: Int32 = 0x1
public let RTV_RTTVAR: Int32 = 0x80
public let RTA_IFP: Int32 = 0x10
public let RTA_DST: Int32 = 0x1
public let RTF_IFSCOPE: Int32 = 0x1000000

/// A set of Darwin system APIs for interacting with the system interface.
@available(Network 0.1.0, *)
internal enum SystemRoute {

    static func routeGetInterfaceIndex(dst: any IPAddress, scopedIndex: UInt32 = 0) throws -> UInt32 {

        var ifIndex: UInt32 = 0
        let pid = getpid()
        let seq: Int32 = 1
        var buffer = [UInt8]()
        let bufferLength = 512
        buffer.reserveCapacity(bufferLength)
        let rtMsgHeaderSize = MemoryLayout<rt_msghdr>.size
        var socketAddrSize = MemoryLayout<sockaddr_in>.size

        let protocolFamily = dst.addressFamily
        // Create a v4 or v6 sockaddr based on the passed in IPAddress
        var dstSockArr = sockaddr()

        // Assign the scoped index if passed in and the sockaddr is v6
        if protocolFamily == .ipv6, let v6Address = dst as? IPv6Address {
            var ipv6Addr = sockaddr_in6()
            ipv6Addr.sin6_len = UInt8(MemoryLayout<sockaddr_in6>.size)
            ipv6Addr.sin6_family = sa_family_t(AF_INET6)
            ipv6Addr.sin6_addr.__u6_addr.__u6_addr32 = v6Address.address
            ipv6Addr.sin6_scope_id = scopedIndex
            dstSockArr = withUnsafePointer(to: ipv6Addr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    $0.pointee
                }
            }
            precondition(dstSockArr.sa_len >= MemoryLayout<sockaddr_in6>.size, "Route: sockaddr_in6 size check failed")
            socketAddrSize = MemoryLayout<sockaddr_in6>.size
        } else if protocolFamily == .ipv4, let v4Address = dst as? IPv4Address {
            var ipv4Addr = sockaddr_in()
            ipv4Addr.sin_family = sa_family_t(AF_INET)
            ipv4Addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
            ipv4Addr.sin_addr = in_addr(s_addr: v4Address.address)
            dstSockArr = withUnsafePointer(to: ipv4Addr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    $0.pointee
                }
            }
            precondition(dstSockArr.sa_len >= MemoryLayout<sockaddr_in>.size, "Route: sockaddr_in size check failed")
        } else {
            // Something went wrong with IPAdress and could not be converted to a sockaddr
            Logger.interface.error("routeGetInterfaceIndex failed convert IPAddress to sockaddr")
            return ifIndex
        }
        let socket = try SystemSocket(
            protocolFamily: .route,
            sockType: .raw,
            protocolSubType: AF_UNSPEC,
            nonBlocking: true
        )

        // Create the route message
        var header = rt_msghdr()
        header.rtm_msglen = u_short(rtMsgHeaderSize) + u_short(socketAddrSize)
        header.rtm_version = UInt8(RTM_VERSION)
        header.rtm_type = UInt8(RTM_GET)
        header.rtm_flags = RTF_UP | RTF_GATEWAY | RTF_HOST | RTF_STATIC
        header.rtm_addrs = RTA_DST | RTA_IFP
        header.rtm_inits = UInt32(RTV_RTTVAR)
        header.rtm_pid = pid
        header.rtm_seq = seq
        if scopedIndex != 0 {
            header.rtm_flags |= RTF_IFSCOPE
            header.rtm_index = u_short(scopedIndex)
        }
        // Append the route message and the dst sockaddr to the buffer
        withUnsafeBytes(
            of: &header,
            {
                buffer.append(contentsOf: $0)
            }
        )
        withUnsafeBytes(
            of: &dstSockArr,
            {
                buffer.append(contentsOf: $0)
            }
        )
        let writeResult = try buffer.withUnsafeBytes { pointer in
            try socket.platformWrite(buffer: pointer.baseAddress!, size: Int(header.rtm_msglen))
        }
        // When scoping rtm_index to an index, ESRCH No such process is returned but the correct routing message is present still
        if writeResult < 0 && errno == EINVAL {
            Logger.interface.error("routeGetInterfaceIndex write result failed: \(writeResult) error: \(errno)")
            return ifIndex
        }
        return try withUnsafeTemporaryAllocation(of: UInt8.self, capacity: bufferLength) { pointer -> UInt32 in
            let bytesRead = try socket.platformRead(buffer: pointer.baseAddress!, size: bufferLength)
            let rtMessageHeaderSize = MemoryLayout<rt_msghdr>.size
            if bytesRead > rtMessageHeaderSize {
                guard
                    let readHeader = SafeAccess.loadCStructure(
                        buffer: UnsafeRawBufferPointer(pointer),
                        type: rt_msghdr.self
                    )
                else {
                    return ifIndex
                }
                if readHeader.rtm_index > 0 {
                    ifIndex = UInt32(readHeader.rtm_index)
                }
            }
            return ifIndex
        }
    }
}
#endif
