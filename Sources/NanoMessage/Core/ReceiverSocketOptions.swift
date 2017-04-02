/*
    ReceiverSocketOptions.swift

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
public protocol ReceiverSocketOptions {
    // socket option functions.
    func getReceiveBufferSize() throws -> UInt
    @discardableResult
    func setReceiveBufferSize(bytes: UInt) throws -> UInt
    func getMaximumMessageSize() throws -> Int
    @discardableResult
    func setMaximumMessageSize(bytes: Int) throws -> Int
    func getReceivePriority() throws -> Priority
    @discardableResult
    func setReceivePriority(_ priority: Priority) throws -> Priority
    func getReceiveFd() throws -> Int
}

extension ReceiverSocketOptions {
    /// Size of the receive buffer, in bytes. To prevent blocking for messages larger than the buffer,
    /// exactly one message may be buffered in addition to the data in the receive buffer.
    ///
    /// Default value is 131072 bytes (128kB).
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets receive buffer size.
    public func getReceiveBufferSize() throws -> UInt {
        return try getSocketOption(self as! NanoSocket, .ReceiveBuffer)
    }

    /// Size of the receive buffer, in bytes. To prevent blocking for messages larger than the buffer,
    /// exactly one message may be buffered in addition to the data in the receive buffer.
    ///
    /// - Parameters:
    ///   - bytes: The size of the receive buffer.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///
    /// - Returns: The sockets receive buffer size before being set.
    @discardableResult
    public func setReceiveBufferSize(bytes: UInt) throws -> UInt {
        let originalValue = try getReceiveBufferSize()

        try setSocketOption(self as! NanoSocket, .ReceiveBuffer, bytes)

        return originalValue
    }

    /// Maximum message size that can be received, in bytes. Negative value means that the received size
    /// is limited only by available addressable memory.
    ///
    /// Default value is 1048576 bytes (1024kB).
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets receive buffer size.
    ///
    /// - Note:    The receive size is unlimited is not currently supported
    public func getMaximumMessageSize() throws -> Int {
        return try getSocketOption(self as! NanoSocket, .ReceiveMaximumMessageSize)
    }

    /// Maximum message size that can be received, in bytes. Negative value means that the received size
    /// is limited only by available addressable memory.
    ///
    /// - Parameters:
    ///   - bytes: The size of the maximum receive message size.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///
    /// - Returns: The sockets receive buffer size before being set.
    @discardableResult
    public func setMaximumMessageSize(bytes: Int) throws -> Int {
        let originalValue = try getMaximumMessageSize()

        try setSocketOption(self as! NanoSocket, .ReceiveMaximumMessageSize, (bytes < 0) ? -1 : bytes)

        return originalValue
    }

    /// The inbound priority for endpoints subsequently added to the socket. When receiving a message, messages
    /// from peer with higher priority are received before messages from peer with lower priority.
    /// Highest priority is 1, lowest priority is 16.
    ///
    /// Default value is 8.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets receive timeout.
    public func getReceivePriority() throws -> Priority {
        return try getSocketOption(self as! NanoSocket, .ReceivePriority)
    }

    /// The inbound priority for endpoints subsequently added to the socket. When receiving a message, messages
    /// from peer with higher priority are received before messages from peer with lower priority.
    /// Highest priority is 1, lowest priority is 16.
    ///
    /// - Parameters:
    ///   - priority: The receive priority.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///
    /// - Returns: The sockets receive timeout before being set.
    @discardableResult
    public func setReceivePriority(_ priority: Priority) throws -> Priority {
        let originalValue = try getReceivePriority()

        try setSocketOption(self as! NanoSocket, .ReceivePriority, priority)

        return originalValue
    }

    @available(*, unavailable, renamed: "getReceiveFileDescriptor")
    public func getReceiveFd() throws -> Int { fatalError() }
    /// Retrieves the underlying file descriptor for the messages that are received on the socket.
    /// The descriptor should be used only for polling and never read from or written to.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets underlying receiver file descriptor.
    public func getReceiveFileDescriptor() throws -> Int {
        return try getSocketOption(self as! NanoSocket, .ReceiveFileDescriptor)
    }
}
