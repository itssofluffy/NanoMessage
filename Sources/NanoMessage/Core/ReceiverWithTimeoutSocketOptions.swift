/*
    ReceiverWithTimeoutSocketOptions.swift

    Copyright (c) 2017 Stephen Whittle  All rights reserved.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom
    the Software is furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
*/

import Foundation

/// Receiver socket options protocol.
public protocol ReceiverWithTimeoutSocketOptions {
    // socket option functions.
    func getReceiveTimeout() throws -> TimeInterval
    @discardableResult
    func setReceiveTimeout(seconds: TimeInterval) throws -> TimeInterval
}

extension ReceiverWithTimeoutSocketOptions {
    /// The timeout of receive operation on the socket, in milliseconds. If message cannot be received within
    /// the specified timeout, `NanoMessageError.TimedOut` is thrown. Negative value means infinite timeout.
    ///
    /// Default value is -1.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets receive timeout in timeinterval (-1 seconds if there is no timeout).
    public func getReceiveTimeout() throws -> TimeInterval {
        return try getSocketOption(self as! NanoSocket, .ReceiveTimeout)
    }

    /// The timeout of receive operation on the socket, in milliseconds. If message cannot be received within
    /// the specified timeout, `NanoMessageError.TimedOut` is thrown. Negative value means infinite timeout.
    ///
    /// - Parameters:
    ///   - seconds: The receive timeout (-1 for no timeout).
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///
    /// - Returns: The sockets receive timeout in timeinterval before being set.
    @discardableResult
    public func setReceiveTimeout(seconds: TimeInterval) throws -> TimeInterval {
        let originalValue = try getReceiveTimeout()

        try setSocketOption(self as! NanoSocket, .ReceiveTimeout, seconds)

        return originalValue
    }
}
