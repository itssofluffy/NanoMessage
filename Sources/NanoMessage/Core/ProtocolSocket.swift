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

import C7
import CNanoMessage

/// Socket protocol protocol.
public protocol ProtocolSocket {
    var _nanoSocket: NanoSocket { get }

    init(socketDomain: SocketDomain) throws
    init() throws
}

extension ProtocolSocket {
/// Function to check a socket and reports whether it’s possible to send a message to the socket and/or receive a message from the socket.
///
/// - Parameters:
///   - timeout milliseconds: The maximum number of milliseconds to poll the socket for an event to occur,
///                           default is 1000 milliseconds (1 second).
///
/// - Throws: `NanoMessageError.PollSocket` if polling the socket fails.
///
/// - Returns: Message waiting and send queue blocked as a tuple of bools.
    public func pollSocket(timeout milliseconds: Int = 1000) throws -> (messageIsWaiting: Bool, sendIsBlocked: Bool) {
        // define our nano sockets file descriptor locally instead of calling the code chain multiple times
        let socketFd = self._nanoSocket.socketFd

        let pollinMask = CShort(NN_POLLIN)                                  // define nn_poll event masks as short's so we only
        let polloutMask = CShort(NN_POLLOUT)                                // cast once in the function

        var eventMask = CShort.allZeros                                     //
        if let _: Int = try? getSocketOption(socketFd, NN_RCVFD) {          // rely on the fact that getting the for example receive
            eventMask = pollinMask                                          // file descriptor for a socket type that does not support
        }                                                                   // receiving will throw a nil return value to determine
        if let _: Int = try? getSocketOption(socketFd, NN_SNDFD) {          // what our polling event mask will be.
            eventMask = eventMask | polloutMask                             //
        }                                                                   //

        var pfd = nn_pollfd(fd: socketFd, events: eventMask, revents: 0)    // define the pollfd struct for this socket

        let rc = nn_poll(&pfd, 1, CInt(milliseconds))                       // poll the nano socket

        guard (rc >= 0) else {
            throw NanoMessageError.PollSocket(code: nn_errno())
        }

        let messageIsWaiting = ((pfd.revents & pollinMask) != 0) ? true : false // using the event masks determine our return values
        let sendIsBlocked = ((pfd.revents & polloutMask) != 0) ? true : false   //

        return (messageIsWaiting, sendIsBlocked)
    }
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
///            `NanoMessageError.TimedOut` the send timedout.
///
/// - Returns: The number of bytes sent.
    @discardableResult
    public func sendMessage(_ message: Data, blockingMode: BlockingMode = .Blocking) throws -> Int {
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
///            `NanoMessageError.TimedOut` the send timedout.
///
/// - Returns: the number of bytes sent.
    @discardableResult
    public func sendMessage(_ message: String, blockingMode: BlockingMode = .Blocking) throws -> Int {
        return try self.sendMessage(Data(message), blockingMode: blockingMode)
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
///            `NanoMessageError.MessageNotReceived` in non-blocking mode there was no message to receive.
///            `NanoMessageError.TimedOut` the receive timedout.
///
/// - Returns: the number of bytes received and the received message
    public func receiveMessage(blockingMode: BlockingMode = .Blocking) throws -> (bytes: Int, message: Data) {
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
///            `NanoMessageError.MessageNotReceived` in non-blocking mode there was no message to receive.
///            `NanoMessageError.TimedOut` the receive timedout.
///
/// - Returns: the number of bytes received and the received message
    public func receiveMessage(blockingMode: BlockingMode = .Blocking) throws -> (bytes: Int, message: String) {
        let received: (bytes: Int, message: Data) = try self.receiveMessage(blockingMode: blockingMode)

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
        return try getSocketOption(self._nanoSocket.socketFd, NN_SNDBUF)
    }

/// Size of the send buffer, in bytes. To prevent blocking for messages larger than the buffer,
/// exactly one message may be buffered in addition to the data in the send buffer.
///
/// - Parameters:
///   - bytes: The size of the send buffer.
///
/// - Throws:  `NanoMessageError.SetSocketOption`
    public func setSendBufferSize(bytes: UInt) throws {
        try setSocketOption(self._nanoSocket.socketFd, NN_SNDBUF, bytes)
    }

/// The timeout for send operation on the socket, in milliseconds. If message cannot be sent within
/// the specified timeout, `NanoMessageError.TimedOut` is thrown. Negative value means infinite timeout.
///
/// Default value is -1.
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///
/// - Returns: The sockets send timeout in milliseconds.
    public func getSendTimeout() throws -> Int {
        return try getSocketOption(self._nanoSocket.socketFd, NN_SNDTIMEO)
    }

/// The timeout for send operation on the socket, in milliseconds. If message cannot be sent within
/// the specified timeout, `NanoMessageError.TimedOut` is thrown. Negative value means infinite timeout.
///
/// - Parameters:
///   - milliseconds: The send timeout.
///
/// - Throws:  `NanoMessageError.SetSocketOption`
    public func setSendTimeout(milliseconds: Int) throws {
        try setSocketOption(self._nanoSocket.socketFd, NN_SNDTIMEO, milliseconds)
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
    public func getSendPriority() throws -> Int {
        return try getSocketOption(self._nanoSocket.socketFd, NN_SNDPRIO)
    }

/// Retrieves outbound priority currently set on the socket. This option has no effect on socket types that
/// send messages to all the peers. However, if the socket type sends each message to a single peer
/// (or a limited set of peers), peers with high priority take precedence over peers with low priority.
/// Highest priority is 1, lowest priority is 16.
///
/// - Parameters:
///   - priority: The sockets send priority.
///
/// - Throws:  `NanoMessageError.SetSocketOption`
    public func setSendPriority(_ priority: Int) throws {
        try setSocketOption(self._nanoSocket.socketFd, NN_SNDPRIO, clamp(value: priority, lower: 1, upper: 16))
    }

/// Retrieves the underlying file descriptor for the messages that can be sent to the socket.
/// The descriptor should be used only for polling and never read from or written to.
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///
/// - Returns: The sockets underlying send file descriptor.
    public func getSenderFd() throws -> Int {
        return try getSocketOption(self._nanoSocket.socketFd, NN_SNDFD)
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
    public func getReceiverBufferSize() throws -> UInt {
        return try getSocketOption(self._nanoSocket.socketFd, NN_RCVBUF)
    }

/// Size of the receive buffer, in bytes. To prevent blocking for messages larger than the buffer,
/// exactly one message may be buffered in addition to the data in the receive buffer.
///
/// - Parameters:
///   - bytes: The size of the receive buffer.
///
/// - Throws:  `NanoMessageError.SetSocketOption`
    public func setReceiverBufferSize(bytes: UInt) throws {
        try setSocketOption(self._nanoSocket.socketFd, NN_RCVBUF, bytes)
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
        return try getSocketOption(self._nanoSocket.socketFd, NN_RCVMAXSIZE)
    }

/// Maximum message size that can be received, in bytes. Negative value means that the received size
/// is limited only by available addressable memory.
///
/// - Parameters:
///   - bytes: The size of the maximum receive message size.
///
/// - Throws:  `NanoMessageError.SetSocketOption`
///            `NanoMessageError.FeatureNotSupported`
///
/// - Note:    The receive size is unlimited is not currently supported
    public func setMaximumMessageSize(bytes: Int) throws {
        if (bytes < 0) {
            throw NanoMessageError.FeatureNotSupported(str: "unlimited buffersize is not currently supported")
        }

        try setSocketOption(self._nanoSocket.socketFd, NN_RCVMAXSIZE, bytes)
    }

/// The timeout of receive operation on the socket, in milliseconds. If message cannot be received within
/// the specified timeout, `NanoMessageError.TimedOut` is thrown. Negative value means infinite timeout.
///
/// Default value is -1.
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///
/// - Returns: The sockets receive timeout.
    public func getReceiverTimeout() throws -> Int {
        return try getSocketOption(self._nanoSocket.socketFd, NN_RCVTIMEO)
    }

/// The timeout of receive operation on the socket, in milliseconds. If message cannot be received within
/// the specified timeout, `NanoMessageError.TimedOut` is thrown. Negative value means infinite timeout.
///
/// - Parameters:
///   - milliseconds: The receive timeout.
///
/// - Throws:  `NanoMessageError.SetSocketOption`
    public func setReceiverTimeout(milliseconds: Int) throws {
        try setSocketOption(self._nanoSocket.socketFd, NN_RCVTIMEO, milliseconds)
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
    public func getReceiverPriority() throws -> Int {
        return try getSocketOption(self._nanoSocket.socketFd, NN_RCVPRIO)
    }

/// The inbound priority for endpoints subsequently added to the socket. When receiving a message, messages
/// from peer with higher priority are received before messages from peer with lower priority.
/// Highest priority is 1, lowest priority is 16.
///
/// - Parameters:
///   - priority: The receive priority.
///
/// - Throws:  `NanoMessageError.SetSocketOption`
    public func setReceiverPriority(_ priority: Int) throws {
        try setSocketOption(self._nanoSocket.socketFd, NN_RCVPRIO, clamp(value: priority, lower: 1, upper: 16))
    }

/// Retrieves the underlying file descriptor for the messages that are received on the socket.
/// The descriptor should be used only for polling and never read from or written to.
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///
/// - Returns: The sockets underlying receiver file descriptor.
    public func getReceiverFd() throws -> Int {
        return try getSocketOption(self._nanoSocket.socketFd, NN_RCVFD)
    }
}

extension ProtocolSocket where Self: Sender {
/// The number messages sent by this socket.
///
/// - Returns: As per description.
///
/// - Throws:  `NanoMessageError.GetSocketStatistic`
    public func getMessagesSent() throws -> UInt64 {
        return try getSocketStatistic(self._nanoSocket.socketFd, NN_STAT_MESSAGES_SENT)
    }

/// The number of bytes sent by this socket.
///
/// - Returns: As per description.
///
/// - Throws:  `NanoMessageError.GetSocketStatistic`
    public func getBytesSent() throws -> UInt64 {
        return try getSocketStatistic(self._nanoSocket.socketFd, NN_STAT_BYTES_SENT)
    }

/// The current send priority of the socket.
///
/// - Returns: As per description.
///
/// - Throws:  `NanoMessageError.GetSocketStatistic`
    public func getCurrentSendPriority() throws -> UInt64 {
        return try getSocketStatistic(self._nanoSocket.socketFd, NN_STAT_CURRENT_SND_PRIORITY)
    }
}

extension ProtocolSocket where Self: Receiver {
/// The number messages received by this socket.
///
/// - Returns: As per description.
///
/// - Throws:  `NanoMessageError.GetSocketStatistic`
    public func getMessagesReceived() throws -> UInt64 {
        return try getSocketStatistic(self._nanoSocket.socketFd, NN_STAT_MESSAGES_RECEIVED)
    }

/// The number of bytes received by this socket.
///
/// - Returns: As per description.
///
/// - Throws:  `NanoMessageError.GetSocketStatistic`
    public func getBytesReceived() throws -> UInt64 {
        return try getSocketStatistic(self._nanoSocket.socketFd, NN_STAT_BYTES_RECEIVED)
    }
}

/// Clamp a value between an lower and upper boundary.
///
/// - Parameters:
///   - value: The value to be clamped.
///   - lower: The lower boundry.
///   - upper: The upper boundary.
///
/// - Returns: The clamped value.
private func clamp<T: Comparable>(value: T, lower: T, upper: T) -> T {
    return min(max(value, lower), upper)
}
