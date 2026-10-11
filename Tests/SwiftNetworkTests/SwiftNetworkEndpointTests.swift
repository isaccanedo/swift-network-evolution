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

import XCTest

#if canImport(SwiftNetwork)
@_spi(Essentials) @_spi(ProtocolProvider) @testable import SwiftNetwork
#endif

#if !hasFeature(Embedded) && canImport(Foundation)
import Foundation
#endif

@available(Network 0.1.0, *)
final class SwiftNetworkEndpointTests: NetTestCase {

    func testApplicationServiceEndpointCreation() {
        let serviceID = SystemUUID.empty
        let applicationService = ApplicationServiceEndpoint("imessage", serviceID: serviceID)
        XCTAssertNotNil(applicationService)
        XCTAssertEqual(applicationService.serviceID.uuidString, "00000000-0000-0000-0000-000000000000")
        let uuid = SystemUUID()
        let applicationService2 = ApplicationServiceEndpoint("imessage", serviceID: uuid)
        XCTAssertNotNil(applicationService2)
        XCTAssertNotEqual(applicationService2.serviceID.uuidString, "00000000-0000-0000-0000-000000000000")
    }

    func testAddressEndpoint() {
        let v4Addr = IPv4Address([0x7F, 0x00, 0x00, 0x01])!
        let v4AddrEndpoint = AddressEndpoint(address: v4Addr, port: 8080)
        XCTAssertEqual(v4AddrEndpoint.port, 8080)
        XCTAssertEqual(v4AddrEndpoint.description, "127.0.0.1:8080")

        let v6Addr = IPv6Address([
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x01,
        ])!
        let v6AddrEndpoint = AddressEndpoint(address: v6Addr, port: 8080)
        XCTAssertEqual(v6AddrEndpoint.port, 8080)
        XCTAssertEqual(v6AddrEndpoint.description, "::1.8080")
    }

    func testURLEndpoint() {
        #if !hasFeature(Embedded) && canImport(Foundation)
        let urlEndpoint = URLEndpoint(url: URL(string: "https://www.apple.com")!)
        XCTAssertNotNil(urlEndpoint, "URL Endpoint should not be nil")
        XCTAssertNotNil(urlEndpoint?.name)
        XCTAssertEqual(urlEndpoint?.name, "www.apple.com")
        XCTAssertEqual(urlEndpoint?.port, 443)
        XCTAssertEqual(urlEndpoint?.schemeIsSecure, true)
        #endif
    }

    func testHostEndpoint() {
        let hostEndpoint = HostEndpoint(name: "www.apple.com", port: 443)
        XCTAssertNotNil(hostEndpoint)
        XCTAssertEqual(hostEndpoint.name, "www.apple.com")
        XCTAssertEqual(hostEndpoint.port, 443)
        XCTAssertEqual(hostEndpoint.weight, 0)
        XCTAssertEqual(hostEndpoint.priority, 0)
    }

    func testApplicationServiceEndpiont() {
        let service = "com.example.service_name"
        let serviceID = SystemUUID()
        let name = service + "/" + serviceID.uuidString
        let appSrvEndpoint = ApplicationServiceEndpoint(service, serviceID: serviceID)
        XCTAssertEqual(appSrvEndpoint.serviceID, serviceID)
        XCTAssertEqual(appSrvEndpoint.name, name)
        // Make a copy
        var appSrvEndpointCopy = appSrvEndpoint
        XCTAssertEqual(appSrvEndpointCopy.serviceID, serviceID)
        XCTAssertEqual(appSrvEndpointCopy.name, name)
        // Alter the copy
        let newServiceID = SystemUUID()
        appSrvEndpointCopy.serviceID = newServiceID
        XCTAssertEqual(appSrvEndpointCopy.serviceID, newServiceID)
        // Validate the original
        XCTAssertEqual(appSrvEndpoint.serviceID, serviceID)
        XCTAssertEqual(appSrvEndpoint.name, name)
    }
}
