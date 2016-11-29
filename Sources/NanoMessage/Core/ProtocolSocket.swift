/*
    ProtocolSocket.swift

    Copyright (c) 2016 Stephen Whittle  All rights reserved.

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
import C7
import ISFLibrary

/// Socket protocol protocol.
public protocol ProtocolSocket {
    var _nanoSocket: NanoSocket { get }

    init(socketDomain: SocketDomain) throws
    init() throws
}

extension ProtocolSocket where Self: Sender {
/// Send a message.
///
/// - Parameters:
///   - message:      The message to send.
///   - blockingMode: Specifies that the send should be performed in non-blocking mode.
///                   If the message cannot be sent straight away, the function will throw
///                   `NanoMessageError.MessageNotSent`
///
/// - Throws:  `NanoMessageError.sendMessage` there was a problem sending the message.
///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
///            `NanoMessageError.SendTimedOut` the send timedout.
///
/// - Returns: The number of bytes sent.
    @discardableResult
    public func sendMessage(_ message: C7.Data, blockingMode: BlockingMode = .Blocking) throws -> Int {
        return try sendPayloadToSocket(self._nanoSocket.socketFd, message, blockingMode)
    }

/// Send a message.
///
/// - Parameters:
///   - message:      The message to send.
///   - blockingMode: Specifies that the send should be performed in non-blocking mode.
///                   If the message cannot be sent straight away, the function will throw
///                   `NanoMessageError.MessageNotSent`
///
/// - Throws:  `NanoMessageError.sendMessage` there was a problem sending the message.
///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
///            `NanoMessageError.SendTimedOut` the send timedout.
///
/// - Returns: the number of bytes sent.
    @discardableResult
    public func sendMessage(_ message: String, blockingMode: BlockingMode = .Blocking) throws -> Int {
        return try self.sendMessage(C7.Data(message), blockingMode: blockingMode)   // chain down the sendMessage signature stack
    }

/// Send a message.
///
/// - Parameters:
///   - message: The message to send.
///   - timeout: Specifies that the send should be performed in non-blocking mode for a timeinterval.
///              If the message cannot be sent straight away, the function will throw `NanoMessageError.MessageNotSent`
///
/// - Throws:  `NanoMessageError.InvalidSendTimeout`
///            `NanoMessageError.GetSocketOption`
///            `NanoMessageError.SetSocketOption`
///            `NanoMessageError.sendMessage` there was a problem sending the message.
///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
///            `NanoMessageError.SendTimedOut` the send timedout.
///
/// - Returns: the number of bytes sent.
///
/// - Note:    The timeout before the call send was performed will be restore after the function returns but this is not
///            guaranteed and no error will be thrown. 
    @discardableResult
    public func sendMessage(_ message: C7.Data, timeout: TimeInterval) throws -> Int {
        guard (timeout >= 0) else {
            throw NanoMessageError.InvalidSendTimeout(timeout: timeout)
        }

        let originalTimeout = try self.setSendTimeout(seconds: timeout)

        defer {
            if (originalTimeout != timeout) {
                do {
                    try self.setSendTimeout(seconds: originalTimeout)
                } catch {
                    print(error, to: &errorStream)
                }
            }
        }

        return try self.sendMessage(message, blockingMode: .Blocking)   // chain down the sendMessage signature stack
    }

/// Send a message.
///
/// - Parameters:
///   - message: The message to send.
///   - timeout: Specifies that the send should be performed in non-blocking mode for a timeinterval.
///              If the message cannot be sent straight away, the function will throw `NanoMessageError.MessageNotSent`
///
/// - Throws:  `NanoMessageError.InvalidSendTimeout`
///            `NanoMessageError.GetSocketOption`
///            `NanoMessageError.SetSocketOption`
///            `NanoMessageError.sendMessage` there was a problem sending the message.
///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
///            `NanoMessageError.SendTimedOut` the send timedout.
///
/// - Returns: the number of bytes sent.
///
/// - Note:    The timeout before the call send was performed will be restore after the function returns but this is not
///            guaranteed behaviour and no error will be thrown. 
    @discardableResult
    public func sendMessage(_ message: String, timeout: TimeInterval) throws -> Int {
        return try self.sendMessage(C7.Data(message), timeout: timeout)   // chain down the sendMessage signature stack
    }
}

extension ProtocolSocket where Self: Receiver {
/// Receive a message.
///
/// - Parameters:
///   - blockingMode: Specifies if the socket should operate in blocking or non-blocking mode.
///                   if in non-blocking mode and there is no message to receive the function
///                   will throw `NanoMessageError.MessageNotReceived`.
///
/// - Throws:  `NanoMessageError.receiveMessage` there was an issue when receiving the message.
///            `NanoMessageError.MessageNotAvailable` in non-blocking mode there was no message to receive.
///            `NanoMessageError.ReceiveTimedOut` the receive timedout.
///
/// - Returns: the number of bytes received and the received message
    public func receiveMessage(blockingMode: BlockingMode = .Blocking) throws -> ReceiveData {
        return try receivePayloadFromSocket(self._nanoSocket.socketFd, blockingMode)
    }

/// Receive a message.
///
/// - Parameters:
///   - blockingMode: Specifies if the socket should operate in blocking or non-blocking mode.
///                   if in non-blocking mode and there is no message to receive the function
///                   will throw `NanoMessageError.MessageNotReceived`.
///
/// - Throws:  `NanoMessageError.receiveMessage` there was an issue when receiving the message.
///            `NanoMessageError.MessageNotAvailable` in non-blocking mode there was no message to receive.
///            `NanoMessageError.ReceiveTimedOut` the receive timedout.
///
/// - Returns: the number of bytes received and the received message
    public func receiveMessage(blockingMode: BlockingMode = .Blocking) throws -> ReceiveString {
        let received: ReceiveData = try self.receiveMessage(blockingMode: blockingMode) // chain down the receiveMessage signature stock.

        return (received.bytes, try String(data: received.message))
    }

/// Receive a message.
///
/// - Parameters:
///   - timeout: Specifies if the socket should operate in non-blocking mode for a timeout interval.
///              If there is no message to receive the function will throw `NanoMessageError.MessageNotReceived`.
///
/// - Throws:  `NanoMessageError.InvalidReceiveTimeout`
///            `NanoMessageError.GetSocketOption`
///            `NanoMessageError.SetSocketOption`
///            `NanoMessageError.receiveMessage` there was an issue when receiving the message.
///            `NanoMessageError.MessageNotAvailable` there was no message to receive.
///            `NanoMessageError.ReceiveTimedOut` the receive timedout.
///
/// - Returns: the number of bytes received and the received message
///
/// - Note:    The timeout before the call received was performed will be restore after the function returns but this is not
///            guaranteed behaviour and no error will be thrown. 
    public func receiveMessage(timeout: TimeInterval) throws -> ReceiveData {
        guard (timeout >= 0) else {
            throw NanoMessageError.InvalidReceiveTimeout(timeout: timeout)
        }

        let originalTimeout = try self.setReceiveTimeout(seconds: timeout)

        defer {
            if (originalTimeout != timeout) {
                do {
                    try self.setReceiveTimeout(seconds: originalTimeout)
                } catch {
                    print(error, to: &errorStream)
                }
            }
        }

        return try self.receiveMessage(blockingMode: .Blocking)    // chain down the receiveMessage signature stock.
    }

/// Receive a message.
///
/// - Parameters:
///   - timeout: Specifies if the socket should operate in non-blocking mode for a timeout interval.
///              If there is no message to receive the function will throw `NanoMessageError.MessageNotReceived`.
///
/// - Throws:  `NanoMessageError.receiveMessage` there was an issue when receiving the message.
///            `NanoMessageError.GetSocketOption`
///            `NanoMessageError.SetSocketOption`
///            `NanoMessageError.MessageNotAvailable` there was no message to receive.
///            `NanoMessageError.ReceiveTimedOut` the receive timedout.
///
/// - Returns: the number of bytes received and the received message
///
/// - Note:    The timeout before the call received was performed will be restore after the function returns but this is not
///            guaranteed behaviour and no error will be thrown. 
    public func receiveMessage(timeout: TimeInterval) throws -> ReceiveString {
        let received: ReceiveData = try self.receiveMessage(timeout: timeout)  // chain down the receiveMessage signature stock.

        return (received.bytes, try String(data: received.message))
    }
}

extension ProtocolSocket where Self: Sender {
/// Size of the send buffer, in bytes. To prevent blocking for messages larger than the buffer,
/// exactly one message may be buffered in addition to the data in the send buffer.
///
/// Default value is 131072 bytes (128kB).
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///
/// - Returns: The sockets send buffer size.
    public func getSendBufferSize() throws -> UInt {
        return try getSocketOption(self._nanoSocket.socketFd, .SendBuffer)
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
        let originalValue = try self.getSendBufferSize()

        try setSocketOption(self._nanoSocket.socketFd, .SendBuffer, bytes)

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
        return try getSocketOption(self._nanoSocket.socketFd, .SendTimeout)
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
        let originalValue = try self.getSendTimeout()

        try setSocketOption(self._nanoSocket.socketFd, .SendTimeout, seconds)

        return originalValue
    }

/// The timeout for send operation on the socket, in milliseconds. If message cannot be sent within
/// the specified timeout, `NanoMessageError.TimedOut` is thrown. Negative value means infinite timeout.
///
/// - Parameters:
///   - seconds: The send timeout enum.
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///            `NanoMessageError.SetSocketOption`
///
/// - Returns: The sockets send timeout in timeinterval before being set.
    @discardableResult
    public func setSendTimeout(seconds: Timeout) throws -> TimeInterval {
        let originalValue = try self.getSendTimeout()

        try setSocketOption(self._nanoSocket.socketFd, .SendTimeout, seconds.rawValue)

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
        return try getSocketOption(self._nanoSocket.socketFd, .SendPriority)
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
        let originalValue = try self.getSendPriority()

        try setSocketOption(self._nanoSocket.socketFd, .SendPriority, priority)

        return originalValue
    }

/// Retrieves the underlying file descriptor for the messages that can be sent to the socket.
/// The descriptor should be used only for polling and never read from or written to.
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///
/// - Returns: The sockets underlying send file descriptor.
    public func getSendFd() throws -> Int {
        return try getSocketOption(self._nanoSocket.socketFd, .SendFd)
    }
}

extension ProtocolSocket where Self: Receiver {
/// Size of the receive buffer, in bytes. To prevent blocking for messages larger than the buffer,
/// exactly one message may be buffered in addition to the data in the receive buffer.
///
/// Default value is 131072 bytes (128kB).
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///
/// - Returns: The sockets receive buffer size.
    public func getReceiveBufferSize() throws -> UInt {
        return try getSocketOption(self._nanoSocket.socketFd, .ReceiveBuffer)
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
        let originalValue = try self.getReceiveBufferSize()

        try setSocketOption(self._nanoSocket.socketFd, .ReceiveBuffer, bytes)

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
        return try getSocketOption(self._nanoSocket.socketFd, .ReceiveMaximumMessageSize)
    }

/// Maximum message size that can be received, in bytes. Negative value means that the received size
/// is limited only by available addressable memory.
///
/// - Parameters:
///   - bytes: The size of the maximum receive message size.
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///            `NanoMessageError.SetSocketOption`
///            `NanoMessageError.FeatureNotSupported`
///
/// - Returns: The sockets receive buffer size before being set.
///
/// - Note:    The receive size is unlimited is not currently supported
    @discardableResult
    public func setMaximumMessageSize(bytes: Int) throws -> Int {
        if (bytes < 0) {
            throw NanoMessageError.FeatureNotSupported(function: #function, description: "unlimited message size is not currently supported")
        }

        let originalValue = try self.getMaximumMessageSize()

        try setSocketOption(self._nanoSocket.socketFd, .ReceiveMaximumMessageSize, bytes)

        return originalValue
    }

/// The timeout of receive operation on the socket, in milliseconds. If message cannot be received within
/// the specified timeout, `NanoMessageError.TimedOut` is thrown. Negative value means infinite timeout.
///
/// Default value is -1.
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///
/// - Returns: The sockets receive timeout in timeinterval (-1 seconds if there is no timeout).
    public func getReceiveTimeout() throws -> TimeInterval {
        return try getSocketOption(self._nanoSocket.socketFd, .ReceiveTimeout)
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
        let originalValue = try self.getReceiveTimeout()

        try setSocketOption(self._nanoSocket.socketFd, .ReceiveTimeout, seconds)

        return originalValue
    }

/// The timeout of receive operation on the socket, in milliseconds. If message cannot be received within
/// the specified timeout, `NanoMessageError.TimedOut` is thrown. Negative value means infinite timeout.
///
/// - Parameters:
///   - seconds: The receive timeout enum .Never.
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///            `NanoMessageError.SetSocketOption`
///
/// - Returns: The sockets receive timeout in timeinterval before being set.
    @discardableResult
    public func setReceiveTimeout(seconds: Timeout) throws -> TimeInterval {
        let originalValue = try self.getReceiveTimeout()

        try setSocketOption(self._nanoSocket.socketFd, .ReceiveTimeout, seconds.rawValue)

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
        return try getSocketOption(self._nanoSocket.socketFd, .ReceivePriority)
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
        let originalValue = try self.getReceivePriority()

        try setSocketOption(self._nanoSocket.socketFd, .ReceivePriority, priority)

        return originalValue
    }

/// Retrieves the underlying file descriptor for the messages that are received on the socket.
/// The descriptor should be used only for polling and never read from or written to.
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///
/// - Returns: The sockets underlying receiver file descriptor.
    public func getReceiveFd() throws -> Int {
        return try getSocketOption(self._nanoSocket.socketFd, .ReceiveFd)
    }
}

extension ProtocolSocket where Self: Sender {
/// The number messages sent by this socket.
///
/// - Throws:  `NanoMessageError.GetSocketStatistic`
///
/// - Returns: As per description.
    public func getMessagesSent() throws -> UInt64 {
        return try getSocketStatistic(self._nanoSocket.socketFd, .MessagesSent)
    }

/// The number of bytes sent by this socket.
///
/// - Throws:  `NanoMessageError.GetSocketStatistic`
///
/// - Returns: As per description.
    public func getBytesSent() throws -> UInt64 {
        return try getSocketStatistic(self._nanoSocket.socketFd, .BytesSent)
    }

/// The current send priority of the socket.
///
/// - Throws:  `NanoMessageError.GetSocketStatistic`
///
/// - Returns: As per description.
    public func getCurrentSendPriority() throws -> Priority {
        return try getSocketStatistic(self._nanoSocket.socketFd, .CurrentSendPriority)
    }
}

extension ProtocolSocket where Self: Receiver {
/// The number messages received by this socket.
///
/// - Throws:  `NanoMessageError.GetSocketStatistic`
///
/// - Returns: As per description.
    public func getMessagesReceived() throws -> UInt64 {
        return try getSocketStatistic(self._nanoSocket.socketFd, .MessagesReceived)
    }

/// The number of bytes received by this socket.
///
/// - Throws:  `NanoMessageError.GetSocketStatistic`
///
/// - Returns: As per description.
    public func getBytesReceived() throws -> UInt64 {
        return try getSocketStatistic(self._nanoSocket.socketFd, .BytesReceived)
    }
}
