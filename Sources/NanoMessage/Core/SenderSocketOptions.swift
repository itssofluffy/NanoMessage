/*
    SenderSocketOptions.swift

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

/// Sender socket options protocol.
public protocol SenderSocketOptions {
    // socket option functions.
    func getSendBufferSize() throws -> UInt
    @discardableResult
    func setSendBufferSize(bytes: UInt) throws -> UInt
    func getSendTimeout() throws -> TimeInterval
    @discardableResult
    func setSendTimeout(seconds: TimeInterval) throws -> TimeInterval
    func getSendPriority() throws -> Priority
    @discardableResult
    func setSendPriority(_ priority: Priority) throws -> Priority
    func getSendFileDescriptor() throws -> Int
}

extension SenderSocketOptions {
    /// Size of the send buffer, in bytes. To prevent blocking for messages larger than the buffer,
    /// exactly one message may be buffered in addition to the data in the send buffer.
    ///
    /// Default value is 131072 bytes (128kB).
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets send buffer size.
    public func getSendBufferSize() throws -> UInt {
        return try getSocketOption(self as! NanoSocket, .SendBuffer)
    }

    /// Size of the send buffer, in bytes. To prevent blocking for messages larger than the buffer,
    /// exactly one message may be buffered in addition to the data in the send buffer.
    ///
    /// - Parameters:
    ///   - bytes: The size of the send buffer.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///
    /// - Returns: The sockets send buffer size before being set.
    @discardableResult
    public func setSendBufferSize(bytes: UInt) throws -> UInt {
        let originalValue = try getSendBufferSize()

        try setSocketOption(self as! NanoSocket, .SendBuffer, bytes)

        return originalValue
    }

    /// The timeout for send operation on the socket, in milliseconds. If message cannot be sent within
    /// the specified timeout, `NanoMessageError.TimedOut` is thrown. Negative value means infinite timeout.
    ///
    /// Default value is -1.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets send timeout in timeinterval (-1 seconds if there is no timeout).
    public func getSendTimeout() throws -> TimeInterval {
        return try getSocketOption(self as! NanoSocket, .SendTimeout)
    }

    /// The timeout for send operation on the socket, in milliseconds. If message cannot be sent within
    /// the specified timeout, `NanoMessageError.TimedOut` is thrown. Negative value means infinite timeout.
    ///
    /// - Parameters:
    ///   - seconds: The send timeout (-1 for no timeout).
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///
    /// - Returns: The sockets send timeout in timeinterval before being set.
    @discardableResult
    public func setSendTimeout(seconds: TimeInterval) throws -> TimeInterval {
        let originalValue = try getSendTimeout()

        try setSocketOption(self as! NanoSocket, .SendTimeout, seconds)

        return originalValue
    }

    /// Retrieves outbound priority currently set on the socket. This option has no effect on socket types that
    /// send messages to all the peers. However, if the socket type sends each message to a single peer
    /// (or a limited set of peers), peers with high priority take precedence over peers with low priority.
    /// Highest priority is 1, lowest priority is 16.
    ///
    /// Default value is 8.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets send priority.
    public func getSendPriority() throws -> Priority {
        return try getSocketOption(self as! NanoSocket, .SendPriority)
    }

    /// Retrieves outbound priority currently set on the socket. This option has no effect on socket types that
    /// send messages to all the peers. However, if the socket type sends each message to a single peer
    /// (or a limited set of peers), peers with high priority take precedence over peers with low priority.
    /// Highest priority is 1, lowest priority is 16.
    ///
    /// - Parameters:
    ///   - priority: The sockets send priority.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///
    /// - Returns: The sockets send priority before being set.
    @discardableResult
    public func setSendPriority(_ priority: Priority) throws -> Priority {
        let originalValue = try getSendPriority()

        try setSocketOption(self as! NanoSocket, .SendPriority, priority)

        return originalValue
    }

    /// Retrieves the underlying file descriptor for the messages that can be sent to the socket.
    /// The descriptor should be used only for polling and never read from or written to.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets underlying send file descriptor.
    public func getSendFileDescriptor() throws -> Int {
        return try getSocketOption(self as! NanoSocket, .SendFileDescriptor)
    }
}
