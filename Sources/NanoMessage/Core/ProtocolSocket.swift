/*
    ProtocolSocket.swift

    Copyright (c) 2016, 2017 Stephen Whittle  All rights reserved.

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
import ISFLibrary
import Dispatch

/// Socket protocol protocol.
public protocol ProtocolSocket {
    var _nanoSocket: NanoSocket { get }

    init(socketDomain: SocketDomain) throws
    init(socketDomain: SocketDomain,
         urls:         Array<URL>,
         type:         ConnectionType) throws
    init(socketDomain: SocketDomain,
         url:          URL,
         type:         ConnectionType,
         name:         String) throws
}

extension ProtocolSocket {
    public init(socketDomain: SocketDomain = .StandardSocket,
                urls:         Array<URL>,
                type:         ConnectionType) throws {
        try self.init(socketDomain: socketDomain)

        for url in urls {
            let _: EndPoint = try _nanoSocket.createEndPoint(url: url, type: type)
        }
    }

    public init(socketDomain: SocketDomain = .StandardSocket,
                url:          URL,
                type:         ConnectionType,
                name:         String = "") throws {
        try self.init(socketDomain: socketDomain)

        let _: EndPoint = try _nanoSocket.createEndPoint(url: url, type: type, name: name)
    }
}

extension ProtocolSocket where Self: SenderSocket {
    /// Send a message.
    ///
    /// - Parameters:
    ///   - message:      The message to send.
    ///   - blockingMode: Specifies that the send should be performed in non-blocking mode.
    ///                   If the message cannot be sent straight away, the function will throw
    ///                   `NanoMessageError.MessageNotSent`
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.NoEndPoint`
    ///            `NanoMessageError.SendMessage` there was a problem sending the message.
    ///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
    ///            `NanoMessageError.SendTimedOut` the send timedout.
    ///
    /// - Returns: The payload sent.
    @discardableResult
    public func sendMessage(_ message:    Message,
                            blockingMode: BlockingMode = .Blocking) throws -> MessagePayload {
        let bytesSent = try sendToSocket(_nanoSocket, message.data, blockingMode)

        return MessagePayload(bytes: bytesSent, message: message)
    }

    /// Send a message.
    ///
    /// - Parameters:
    ///   - message: The message to send.
    ///   - timeout: Specifies that the send should be performed in non-blocking mode for a timeinterval.
    ///              If the message cannot be sent straight away, the function will throw `NanoMessageError.MessageNotSent`
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.NoEndPoint`
    ///            `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///            `NanoMessageError.SendMessage` there was a problem sending the message.
    ///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
    ///            `NanoMessageError.SendTimedOut` the send timedout.
    ///
    /// - Returns: The payload sent.
    ///
    /// - Note:    The timeout before the call send was performed will be restore after the function returns but this is not
    ///            guaranteed and no error will be thrown. 
    @discardableResult
    public func sendMessage(_ message: Message,
                            timeout:   TimeInterval) throws -> MessagePayload {
        let originalTimeout = try setSendTimeout(seconds: timeout)

        defer {
            if (originalTimeout != timeout) {
                wrapper(do: { () -> Void in
                            try self.setSendTimeout(seconds: originalTimeout)
                        },
                        catch: { failure in
                            nanoMessageErrorLogger(failure)
                        })
            }
        }

        return try sendMessage(message)   // chain down the sendMessage signature stack
    }

    /// Asynchrounous execute a passed sender closure.
    ///
    /// - Parameters:
    ///   - closure: The closure to use to perform the send
    ///   - success: The closure to use when `closure()` is succesful.
    ///   - capture: The closure to use to pass any objects required when an error occurs.
    private func _asyncSendMessage(closure: @escaping () throws -> MessagePayload,
                                   success: @escaping (MessagePayload) -> Void,
                                   capture: @escaping () -> Array<Any>) {
        _nanoSocket.aioQueue.async(group: _nanoSocket.aioGroup) {
            wrapper(do: {
                        try self._nanoSocket.mutex.lock {
                            try success(closure())
                        }
                    },
                    catch: { failure in
                        nanoMessageErrorLogger(failure)
                    },
                    capture: capture)
        }
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - message:      The message to send.
    ///   - blockingMode: Specifies that the send should be performed in non-blocking mode.
    ///                   If the message cannot be sent straight away, the closureHandler
    ///                   will be passed `NanoMessageError.MessageNotSent`
    ///   - success:      The closure to use when the async functionallity is succesful.
    public func sendMessage(_ message:    Message,
                            blockingMode: BlockingMode = .Blocking,
                            success:      @escaping (MessagePayload) -> Void) {
        _asyncSendMessage(closure: {
                              return try self.sendMessage(message, blockingMode: blockingMode)
                          },
                          success: success,
                          capture: {
                              return [self, message, blockingMode, self._nanoSocket.aioQueue, self._nanoSocket.aioGroup]
                          })
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - message: The message to send.
    ///   - timeout: Specifies that the send should be performed in non-blocking mode for a timeinterval.
    ///              If the message cannot be sent straight away, the closureHandler will be passed `NanoMessageError.MessageNotSent`
    ///   - success: The closure to use when the async functionallity is succesful.
    public func sendMessage(_ message: Message,
                            timeout:   TimeInterval,
                            success:   @escaping (MessagePayload) -> Void) {
        _asyncSendMessage(closure: {
                              return try self.sendMessage(message, timeout: timeout)
                          },
                          success: success,
                          capture: {
                              return [self, message, timeout, self._nanoSocket.aioQueue, self._nanoSocket.aioGroup]
                          })
    }
}

extension ProtocolSocket where Self: ReceiverSocket {
    /// Receive a message.
    ///
    /// - Parameters:
    ///   - blockingMode: Specifies if the socket should operate in blocking or non-blocking mode.
    ///                   if in non-blocking mode and there is no message to receive the function
    ///                   will throw `NanoMessageError.MessageNotReceived`.
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.NoEndPoint`
    ///            `NanoMessageError.ReceiveMessage` there was an issue when receiving the message.
    ///            `NanoMessageError.MessageNotAvailable` in non-blocking mode there was no message to receive.
    ///            `NanoMessageError.ReceiveTimedOut` the receive timedout.
    ///            `NanoMessageError.FreeMessage` deallocation of the message has failed.
    ///
    /// - Returns: The message payload received.
    public func receiveMessage(blockingMode: BlockingMode = .Blocking) throws -> MessagePayload {
        return try receiveFromSocket(_nanoSocket, blockingMode)
    }

    /// Receive a message.
    ///
    /// - Parameters:
    ///   - timeout: Specifies if the socket should operate in non-blocking mode for a timeout interval.
    ///              If there is no message to receive the function will throw `NanoMessageError.MessageNotReceived`.
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.NoEndPoint`
    ///            `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///            `NanoMessageError.ReceiveMessage` there was an issue when receiving the message.
    ///            `NanoMessageError.MessageNotAvailable` there was no message to receive.
    ///            `NanoMessageError.ReceiveTimedOut` the receive timedout.
    ///            `NanoMessageError.FreeMessage` deallocation of the message has failed.
    ///
    /// - Returns: The message payload received.
    ///
    /// - Note:    The timeout before the call received was performed will be restore after the function returns but this is not
    ///            guaranteed behaviour and no error will be thrown. 
    public func receiveMessage(timeout: TimeInterval) throws -> MessagePayload {
        let originalTimeout = try setReceiveTimeout(seconds: timeout)

        defer {
            if (originalTimeout != timeout) {
                wrapper(do: { () -> Void in
                            try self.setReceiveTimeout(seconds: originalTimeout)
                        },
                        catch: { failure in
                            nanoMessageErrorLogger(failure)
                        })
            }
        }

        return try receiveMessage()    // chain down the receiveMessage signature stock.
    }

    /// Asynchronous receive a message.
    ///
    /// - Parameters:
    ///   - blockingMode: Specifies if the socket should operate in blocking or non-blocking mode.
    ///                   if in non-blocking mode and there is no message to receive the closureHandler
    ///                   will be passed `NanoMessageError.MessageNotReceived`.
    ///   - success:      The closure to use when the async functionallity is succesful.
    public func receiveMessage(blockingMode: BlockingMode = .Blocking,
                               success:      @escaping (MessagePayload) -> Void) {
        asyncReceiveFromSocket(nanoSocket: self._nanoSocket,
                               closure: {
                                   return try self.receiveMessage(blockingMode: blockingMode)
                               },
                               success: success,
                               capture: {
                                   return [self, blockingMode, self._nanoSocket.aioQueue, self._nanoSocket.aioGroup]
                               })
    }

    /// Asynchronous receive a message.
    ///
    /// - Parameters:
    ///   - timeout: Specifies if the socket should operate in non-blocking mode for a timeout interval.
    ///              If there is no message to receive the closureHandler will be passed `NanoMessageError.MessageNotReceived`.
    ///   - success: The closure to use when the async functionallity is succesful.
    public func receiveMessage(timeout: TimeInterval,
                               success: @escaping (MessagePayload) -> Void) {
        asyncReceiveFromSocket(nanoSocket: self._nanoSocket,
                               closure: {
                                   return try self.receiveMessage(timeout: timeout)
                               },
                               success: success,
                               capture: {
                                   return [self, timeout, self._nanoSocket.aioQueue, self._nanoSocket.aioGroup]
                               })
    }
}

extension ProtocolSocket where Self: SenderSocketOptions {
    /// Size of the send buffer, in bytes. To prevent blocking for messages larger than the buffer,
    /// exactly one message may be buffered in addition to the data in the send buffer.
    ///
    /// Default value is 131072 bytes (128kB).
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets send buffer size.
    public func getSendBufferSize() throws -> UInt {
        return try getSocketOption(_nanoSocket, .SendBuffer)
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

        try setSocketOption(_nanoSocket, .SendBuffer, bytes)

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
        return try getSocketOption(_nanoSocket, .SendTimeout)
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

        try setSocketOption(_nanoSocket, .SendTimeout, seconds)

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
        return try getSocketOption(_nanoSocket, .SendPriority)
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

        try setSocketOption(_nanoSocket, .SendPriority, priority)

        return originalValue
    }

    @available(*, unavailable, renamed: "getSendFileDescriptor")
    public func getSendFd() throws -> Int { fatalError() }
    /// Retrieves the underlying file descriptor for the messages that can be sent to the socket.
    /// The descriptor should be used only for polling and never read from or written to.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets underlying send file descriptor.
    public func getSendFileDescriptor() throws -> Int {
        return try getSocketOption(_nanoSocket, .SendFileDescriptor)
    }
}

extension ProtocolSocket where Self: ReceiverSocketOptions {
    /// Size of the receive buffer, in bytes. To prevent blocking for messages larger than the buffer,
    /// exactly one message may be buffered in addition to the data in the receive buffer.
    ///
    /// Default value is 131072 bytes (128kB).
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets receive buffer size.
    public func getReceiveBufferSize() throws -> UInt {
        return try getSocketOption(_nanoSocket, .ReceiveBuffer)
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

        try setSocketOption(_nanoSocket, .ReceiveBuffer, bytes)

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
        return try getSocketOption(_nanoSocket, .ReceiveMaximumMessageSize)
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

        try setSocketOption(_nanoSocket, .ReceiveMaximumMessageSize, (bytes < 0) ? -1 : bytes)

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
        return try getSocketOption(_nanoSocket, .ReceiveTimeout)
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

        try setSocketOption(_nanoSocket, .ReceiveTimeout, seconds)

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
        return try getSocketOption(_nanoSocket, .ReceivePriority)
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

        try setSocketOption(_nanoSocket, .ReceivePriority, priority)

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
        return try getSocketOption(_nanoSocket, .ReceiveFileDescriptor)
    }
}

extension ProtocolSocket where Self: SenderSocketStatistics {
    @available(*, unavailable, renamed: "messagesSent")
    public func getMessagesSent() throws -> UInt64 { fatalError() }
    @available(*, unavailable, renamed: "bytesSent")
    public func getBytesSent() throws -> UInt64 { fatalError() }
    @available(*, unavailable, renamed: "currentSendPriority")
    public func getCurrentSendPriority() throws -> Priority { fatalError() }
}

extension ProtocolSocket where Self: SenderSocketStatistics {
    /// The number messages sent by this socket.
    public var messagesSent: UInt64? {
        return wrapper(do: {
                           return try getSocketStatistic(self._nanoSocket, .MessagesSent)
                       },
                       catch: { failure in
                           nanoMessageErrorLogger(failure)
                       },
                       capture: {
                           return [self]
                       })
    }

    /// The number of bytes sent by this socket.
    public var bytesSent: UInt64? {
        return wrapper(do: {
                           return try getSocketStatistic(self._nanoSocket, .BytesSent)
                       },
                       catch: { failure in
                           nanoMessageErrorLogger(failure)
                       },
                       capture: {
                           return [self]
                       })
    }

    /// The current send priority of the socket.
    public var currentSendPriority: Priority? {
        return wrapper(do: {
                           return try getSocketStatistic(self._nanoSocket, .CurrentSendPriority)
                       },
                       catch: { failure in
                           nanoMessageErrorLogger(failure)
                       },
                       capture: {
                           return [self]
                       })
    }
}

extension ProtocolSocket where Self: ReceiverSocketStatistics {
    @available(*, unavailable, renamed: "messagesReceived")
    public func getMessagesReceived() throws -> UInt64 { fatalError() }
    @available(*, unavailable, renamed: "bytesReceived")
    public func getBytesReceived() throws -> UInt64 { fatalError() }
}

extension ProtocolSocket where Self: ReceiverSocketStatistics {
    /// The number messages received by this socket.
    public var messagesReceived: UInt64? {
        return wrapper(do: {
                           return try getSocketStatistic(self._nanoSocket, .MessagesReceived)
                       },
                       catch: { failure in
                           nanoMessageErrorLogger(failure)
                       },
                       capture: {
                           return [self]
                       })
    }

    /// The number of bytes received by this socket.
    public var bytesReceived: UInt64? {
        return wrapper(do: {
                           return try getSocketStatistic(self._nanoSocket, .BytesReceived)
                       },
                       catch: { failure in
                           nanoMessageErrorLogger(failure)
                       },
                       capture: {
                           return [self]
                       })
    }
}
