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

@available(Network 0.1.0, *)
typealias NetworkUniqueArray = BasicContainers.UniqueArray
@available(Network 0.1.0, *)
typealias NetworkRigidArray = BasicContainers.RigidArray

@available(Network 0.1.0, *)
typealias NetworkUniqueDeque = DequeModule.UniqueDeque

#endif
