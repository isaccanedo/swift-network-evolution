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

@_spi(ProtocolProvider)
@available(Network 0.1.0, *)
public enum RequestedNetworkMetrics {
    case protocolEstablishmentReports
    case dataTransferSnapshot
}

@_spi(ProtocolProvider)
@available(Network 0.1.0, *)
public enum NetworkMetrics {
    case protocolEstablishmentReports([ProtocolEstablishmentReport])
    case dataTransferSnapshot(DataTransferSnapshot)
}
