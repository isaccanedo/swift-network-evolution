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

#if canImport(Synchronization) && !NETWORK_DRIVERKIT && !NETWORK_EMBEDDED

internal import Synchronization

// Availability due to `Synchronization`'s `Mutex`
@available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
typealias NetworkMutex = Mutex

#endif
