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

public protocol ProtocolSocket {
    var _nanoSocket: NanoSocket { get }

    init(socketDomain: SocketDomain) throws
    init() throws
}

extension ProtocolSocket where Self: Sender {
    @discardableResult
    public func sendMessage(message: Data, blockingMode: BlockingMode = .Blocking) throws -> Int {
        return try sendPayloadToSocket(self._nanoSocket.socketFd, message, blockingMode)
    }

    @discardableResult
    public func sendMessage(message: String, blockingMode: BlockingMode = .Blocking) throws -> Int {
        return try self.sendMessage(message: Data(message), blockingMode: blockingMode)
    }
}

extension ProtocolSocket where Self: Receiver {
    public func receiveMessage(blockingMode: BlockingMode = .Blocking) throws -> (bytes: Int, message: Data) {
        return try receivePayloadFromSocket(self._nanoSocket.socketFd, blockingMode)
    }

    public func receiveMessage(blockingMode: BlockingMode = .Blocking) throws -> (bytes: Int, message: String) {
        let received: (bytes: Int, message: Data) = try self.receiveMessage(blockingMode: blockingMode)

        return (received.bytes, try String(data: received.message))
    }
}

extension ProtocolSocket where Self: Sender {
    public func getSendBufferSize() throws -> UInt {
        return try getSocketOption(self._nanoSocket.socketFd, NN_SNDBUF)
    }

    public func setSendBufferSize(bytes: UInt) throws {
        try setSocketOption(self._nanoSocket.socketFd, NN_SNDBUF, bytes)
    }

    public func getSendTimeout() throws -> Int {
        return try getSocketOption(self._nanoSocket.socketFd, NN_SNDTIMEO)
    }

    public func setSendTimeout(milliseconds: Int) throws {
        try setSocketOption(self._nanoSocket.socketFd, NN_SNDTIMEO, milliseconds)
    }

    public func getSendPriority() throws -> Int {
        return try getSocketOption(self._nanoSocket.socketFd, NN_SNDPRIO)
    }

    public func setSendPriority(priority: Int) throws {
        try setSocketOption(self._nanoSocket.socketFd, NN_SNDPRIO, priority)
    }

    public func getSenderFd() throws -> Int {
        return try getSocketOption(self._nanoSocket.socketFd, NN_SNDFD)
    }
}

extension ProtocolSocket where Self: Receiver {
    public func getReceiverBufferSize() throws -> UInt {
        return try getSocketOption(self._nanoSocket.socketFd, NN_RCVBUF)
    }

    public func setReceiverBufferSize(bytes: UInt) throws {
        try setSocketOption(self._nanoSocket.socketFd, NN_RCVBUF, bytes)
    }

    public func getMaximumMessageSize() throws -> Int {
        return try getSocketOption(self._nanoSocket.socketFd, NN_RCVMAXSIZE)
    }

    public func setMaximumMessageSize(bytes: Int) throws {
        try setSocketOption(self._nanoSocket.socketFd, NN_RCVMAXSIZE, bytes)
    }

    public func getReceiverTimeout() throws -> Int {
        return try getSocketOption(self._nanoSocket.socketFd, NN_RCVTIMEO)
    }

    public func setReceiverTimeout(milliseconds: Int) throws {
        try setSocketOption(self._nanoSocket.socketFd, NN_RCVTIMEO, milliseconds)
    }

    public func getReceiverPriority() throws -> Int {
        return try getSocketOption(self._nanoSocket.socketFd, NN_RCVPRIO)
    }

    public func setReceiverPriority(priority: Int) throws {
        try setSocketOption(self._nanoSocket.socketFd, NN_RCVPRIO, priority)
    }

    public func getReceiverFd() throws -> Int {
        return try getSocketOption(self._nanoSocket.socketFd, NN_RCVFD)
    }
}

extension ProtocolSocket where Self: Sender {
    public func getMessagesSent() throws -> UInt64 {
        return try getStatistic(self._nanoSocket.socketFd, NN_STAT_MESSAGES_SENT)
    }

    public func getBytesSent() throws -> UInt64 {
        return try getStatistic(self._nanoSocket.socketFd, NN_STAT_BYTES_SENT)
    }

    public func getCurrentSendPriority() throws -> UInt64 {
        return try getStatistic(self._nanoSocket.socketFd, NN_STAT_CURRENT_SND_PRIORITY)
    }
}

extension ProtocolSocket where Self: Receiver {
    public func getMessagesReceived() throws -> UInt64 {
        return try getStatistic(self._nanoSocket.socketFd, NN_STAT_MESSAGES_RECEIVED)
    }

    public func getBytesReceived() throws -> UInt64 {
        return try getStatistic(self._nanoSocket.socketFd, NN_STAT_BYTES_RECEIVED)
    }
}
