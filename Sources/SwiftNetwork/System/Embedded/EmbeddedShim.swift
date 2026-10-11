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

#if NETWORK_EMBEDDED || NETWORK_DRIVERKIT

#if !NETWORK_DRIVERKIT
let ENOENT: Int32 = 2
let EFAULT: Int32 = 14
let EBUSY: Int32 = 16
let EINVAL: Int32 = 22
let EAGAIN: Int32 = 35
let EALREADY: Int32 = 37
let EMSGSIZE: Int32 = 40
let ENOTSUP: Int32 = 45
let ECONNABORTED: Int32 = 53
let ECONNRESET: Int32 = 54
let ENOBUFS: Int32 = 55
let ENOTCONN: Int32 = 57
let ETIMEDOUT: Int32 = 60
let ECANCELED: Int32 = 89
let EPROTO: Int32 = 100

typealias sa_family_t = UInt8

struct Logger {
    init(label: StaticString) {
        self.label = label
    }
    var label: StaticString

    func error(_ message: String) {
        print(message)
    }

    func info(_ message: String) {
        print(message)
    }

    func fault(_ message: String) {
        print(message)
    }

    func debug(_ message: String) {
        print(message)
    }

    func log(_ message: String) {
        print(message)
    }
}

public protocol CustomStringConvertible {
    var description: String { get }
}

public protocol CustomDebugStringConvertible {
    var debugDescription: String { get }
}

extension StaticString: @retroactive Hashable {
    public static func == (lhs: StaticString, rhs: StaticString) -> Bool {
        lhs.withUTF8Buffer { body1 in
            rhs.withUTF8Buffer { body2 in
                if body1.count != body2.count {
                    return false
                }
                for index in 0..<body1.count {
                    if body1[index] != body2[index] {
                        return false
                    }
                }
                return true
            }
        }
    }

    public func hash(into hasher: inout Hasher) {
        self.withUTF8Buffer { body in
            hasher.combine(body.count)
        }
    }
}

extension Array {
    mutating func prepend(_ newElement: Element) {
        self.insert(newElement, at: 0)
    }
    mutating func popFirst() -> Element? {
        if self.isEmpty {
            return nil
        } else {
            return self.removeFirst()
        }
    }
    init(minimumCapacity: Int) {
        self.init()
    }
}
public typealias Deque = Array
public typealias DispatchData = [UInt8]
#endif

// Stub for URL
public struct URL: Hashable {
    public var url: String
    public var scheme: String?
    public var port: Int?
    public var absoluteString: String

    public init(url: String) {
        self.url = url
        self.absoluteString = url
    }

    public init?(string: String) {
        self.url = string
        self.absoluteString = string
    }

    public func host(percentEncoded: Bool = true) -> String? {
        url
    }

    public var absoluteURL: URL {
        self
    }
}

internal enum SystemResources {
    static func getFDLimit() -> UInt64 {
        // No limit available on embedded
        0
    }
}

#if !NETWORK_NO_SWIFT_QUIC

extension Cubic {
    func cbrtPureSwift(_ x: Double) -> Double {
        if x == 0 {
            return 0
        }

        if x.isNaN {
            return Double.nan
        }

        if x.isInfinite {
            return x
        }

        let isNegative = x < 0
        let absX = abs(x)

        // Simple initial guess
        var guess = absX / 3.0
        if absX > 1 {
            guess = absX / 2.0
        }

        // Newton-Raphson iteration
        let epsilon = 1e-15
        let maxIterations = 100

        for _ in 0..<maxIterations {
            let guess2 = guess * guess
            let nextGuess = (2.0 * guess + absX / guess2) / 3.0

            if abs(nextGuess - guess) < epsilon * abs(nextGuess) {
                guess = nextGuess
                break
            }

            guess = nextGuess
        }

        return isNegative ? -guess : guess
    }
}

#endif

#endif
