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
import C7
import ISFLibrary
import Dispatch

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
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.SendMessage` there was a problem sending the message.
    ///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
    ///            `NanoMessageError.SendTimedOut` the send timedout.
    ///
    /// - Returns: The number of bytes sent.
    @discardableResult
    public func sendMessage(_ message: C7.Data, blockingMode: BlockingMode = .Blocking) throws -> Int {
        return try sendPayloadToSocket(self._nanoSocket, message, blockingMode)
    }

    /// Send a message.
    ///
    /// - Parameters:
    ///   - message:      The message to send.
    ///   - blockingMode: Specifies that the send should be performed in non-blocking mode.
    ///                   If the message cannot be sent straight away, the function will throw
    ///                   `NanoMessageError.MessageNotSent`
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.SendMessage` there was a problem sending the message.
    ///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
    ///            `NanoMessageError.SendTimedOut` the send timedout.
    ///
    /// - Returns: the number of bytes sent.
    @discardableResult
    public func sendMessage(_ message: String, blockingMode: BlockingMode = .Blocking) throws -> Int {
        return try self.sendMessage(C7.Data(message), blockingMode: blockingMode)   // chain down the sendMessage signature stack
    }

    /// Send a message setting the send timeout and attempt to restore to back to it's original value.
    ///
    /// - Parameters:
    ///   - message:      The message to send.
    ///   - timeout:      The timeout interval to set.
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///            `NanoMessageError.SendMessage` there was a problem sending the message.
    ///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
    ///            `NanoMessageError.SendTimedOut` the send timedout.
    ///
    /// - Returns: the number of bytes sent.
    @discardableResult
    private func _sendMessageWithTimeout(_ message: C7.Data, timeout: TimeInterval) throws -> Int {
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
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.InvalidSendTimeout`
    ///            `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///            `NanoMessageError.SendMessage` there was a problem sending the message.
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

        return try self._sendMessageWithTimeout(message, timeout: timeout)
    }

    /// Send a message.
    ///
    /// - Parameters:
    ///   - message: The message to send.
    ///   - timeout: Specifies that the send should be performed in non-blocking mode for a timeinterval.
    ///              If the message cannot be sent straight away, the function will throw `NanoMessageError.MessageNotSent`
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.InvalidSendTimeout`
    ///            `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///            `NanoMessageError.SendMessage` there was a problem sending the message.
    ///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
    ///            `NanoMessageError.SendTimedOut` the send timedout.
    ///
    /// - Returns: the number of bytes sent.
    ///
    /// - Note:    The timeout before the call send was performed will be restore after the function returns but this is not
    ///            guaranteed behaviour and no error will be thrown. 
    @discardableResult
    public func sendMessage(_ message: String, timeout: TimeInterval) throws -> Int {
        return try self.sendMessage(C7.Data(message), timeout: timeout)           // chain down the sendMessage signature stack
    }

    /// Send a message.
    ///
    /// - Parameters:
    ///   - message: The message to send.
    ///   - timeout: .Never
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///            `NanoMessageError.SendMessage` there was a problem sending the message.
    ///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
    ///
    /// - Returns: The number of bytes sent.
    @discardableResult
    public func sendMessage(_ message: C7.Data, timeout: Timeout) throws -> Int {
        return try self._sendMessageWithTimeout(message, timeout: TimeInterval(seconds: timeout.rawValue))
    }

    /// Send a message.
    ///
    /// - Parameters:
    ///   - message: The message to send.
    ///   - timeout: .Never
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///            `NanoMessageError.SendMessage` there was a problem sending the message.
    ///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
    ///
    /// - Returns: The number of bytes sent.
    ///
    /// - Note:    This is the same as sendMessage(..., blockingMode: .Blocking) and is included for symantics.
    @discardableResult
    public func sendMessage(_ message: String, timeout: Timeout) throws -> Int {
        return try self.sendMessage(C7.Data(message), timeout: timeout)           // chain down the sendMessage signature stack.
    }
}

extension ProtocolSocket where Self: Sender & ASyncSender {
    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - message:        The message to send.
    ///   - blockingMode:   Specifies that the send should be performed in non-blocking mode.
    ///                     If the message cannot be sent straight away, the closureHandler
    ///                     will be passed `NanoMessageError.MessageNotSent`
    ///   - closureHandler: The closure to use when the async functionallity completes.
    public func sendMessage(_ message: C7.Data, blockingMode: BlockingMode, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self._nanoSocket.aioQueue.async(group: self._nanoSocket.aioGroup) {
            do {
                try self._nanoSocket.mutex.lock {
                    let bytesSent = try self.sendMessage(message, blockingMode: blockingMode)

                    closureHandler(bytesSent, nil)
                }
            } catch {
                closureHandler(nil, error)
            }
        }
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - message:        The message to send.
    ///   - blockingMode:   Specifies that the send should be performed in non-blocking mode.
    ///                     If the message cannot be sent straight away, the closureHandler
    ///                     will be passed `NanoMessageError.MessageNotSent`
    ///   - closureHandler: The closure to use when the async functionallity completes.
    public func sendMessage(_ message: String, blockingMode: BlockingMode, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.sendMessage(C7.Data(message), blockingMode: blockingMode, closureHandler)
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - message:        The message to send.
    ///   - closureHandler: The closure to use when the async functionallity completes.
    ///
    /// - Note:             'sendMessage()' is called with blocking mode.
    public func sendMessage(_ message: C7.Data, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.sendMessage(message, blockingMode: .Blocking, closureHandler)
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - message:        The message to send.
    ///   - closureHandler: The closure to use when the async functionallity completes.
    ///
    /// - Note:             'sendMessage()' is called with blocking mode.
    public func sendMessage(_ message: String, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.sendMessage(C7.Data(message), blockingMode: .Blocking, closureHandler)
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - message:        The message to send.
    ///   - timeout:        Specifies that the send should be performed in non-blocking mode for a timeinterval.
    ///                     If the message cannot be sent straight away, the closureHandler will be passed `NanoMessageError.MessageNotSent`
    ///   - closureHandler: The closure to use when the async functionallity completes.
    public func sendMessage(_ message: C7.Data, timeout: TimeInterval, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self._nanoSocket.aioQueue.async(group: self._nanoSocket.aioGroup) {
            do {
                try self._nanoSocket.mutex.lock {
                    let bytesSent = try self.sendMessage(message, timeout: timeout)

                    closureHandler(bytesSent, nil)
                }
            } catch {
                closureHandler(nil, error)
            }
        }
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - message:        The message to send.
    ///   - timeout:        Specifies that the send should be performed in non-blocking mode for a timeinterval.
    ///                     If the message cannot be sent straight away, the closureHandler will be passed `NanoMessageError.MessageNotSent`
    ///   - closureHandler: The closure to use when the async functionallity completes.
    public func sendMessage(_ message: String, timeout: TimeInterval, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.sendMessage(C7.Data(message), timeout: timeout, closureHandler)
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - message:        The message to send.
    ///   - timeout:        .Never
    ///   - closureHandler: The closure to use when the async functionallity completes.
    public func sendMessage(_ message: C7.Data, timeout: Timeout, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self._nanoSocket.aioQueue.async(group: self._nanoSocket.aioGroup) {
            do {
                try self._nanoSocket.mutex.lock {
                    let bytesSent = try self.sendMessage(message, timeout: timeout)

                    closureHandler(bytesSent, nil)
                }
            } catch {
                closureHandler(nil, error)
            }
        }
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - message:        The message to send.
    ///   - timeout:        .Never
    ///   - closureHandler: The closure to use when the async functionallity completes.
    public func sendMessage(_ message: String, timeout: Timeout, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.sendMessage(C7.Data(message), timeout: timeout, closureHandler)
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
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.ReceiveMessage` there was an issue when receiving the message.
    ///            `NanoMessageError.MessageNotAvailable` in non-blocking mode there was no message to receive.
    ///            `NanoMessageError.ReceiveTimedOut` the receive timedout.
    ///
    /// - Returns: the number of bytes received and the received message
    public func receiveMessage(blockingMode: BlockingMode = .Blocking) throws -> ReceiveData {
        return try receivePayloadFromSocket(self._nanoSocket, blockingMode)
    }

    /// Receive a message.
    ///
    /// - Parameters:
    ///   - blockingMode: Specifies if the socket should operate in blocking or non-blocking mode.
    ///                   if in non-blocking mode and there is no message to receive the function
    ///                   will throw `NanoMessageError.MessageNotReceived`.
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.ReceiveMessage` there was an issue when receiving the message.
    ///            `NanoMessageError.MessageNotAvailable` in non-blocking mode there was no message to receive.
    ///            `NanoMessageError.ReceiveTimedOut` the receive timedout.
    ///
    /// - Returns: the number of bytes received and the received message
    public func receiveMessage(blockingMode: BlockingMode = .Blocking) throws -> ReceiveString {
        let received: ReceiveData = try self.receiveMessage(blockingMode: blockingMode) // chain down the receiveMessage signature stock.

        return ReceiveString(received.bytes, try String(data: received.message))
    }

    /// Receive a message setting the receive timeout and attempt to restore to back to it's original value.
    ///
    /// - Parameters:
    ///   - timeout: The timeout interval to set.
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///            `NanoMessageError.ReceiveMessage` there was a problem sending the message.
    ///            `NanoMessageError.MessageNotAvailable` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
    ///            `NanoMessageError.ReceiveTimedOut` the send timedout.
    ///
    /// - Returns: the number of bytes received and the received message
    private func _receiveMessageWith(timeout: TimeInterval) throws -> ReceiveData {
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
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.InvalidReceiveTimeout`
    ///            `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///            `NanoMessageError.ReceiveMessage` there was an issue when receiving the message.
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

        return try self._receiveMessageWith(timeout: timeout)
    }

    /// Receive a message.
    ///
    /// - Parameters:
    ///   - timeout: Specifies if the socket should operate in non-blocking mode for a timeout interval.
    ///              If there is no message to receive the function will throw `NanoMessageError.MessageNotReceived`.
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.ReceiveMessage` there was an issue when receiving the message.
    ///            `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///            `NanoMessageError.MessageNotAvailable` there was no message to receive.
    ///            `NanoMessageError.ReceiveTimedOut` the receive timedout.
    ///
    /// - Returns: the number of bytes received and the received message as a string.
    ///
    /// - Note:    The timeout before the call received was performed will be restore after the function returns but this is not
    ///            guaranteed behaviour and no error will be thrown. 
    public func receiveMessage(timeout: TimeInterval) throws -> ReceiveString {
        let received: ReceiveData = try self.receiveMessage(timeout: timeout)  // chain down the receiveMessage signature stock.

        return ReceiveString(received.bytes, try String(data: received.message))
    }

    /// Receive a message.
    ///
    /// - Parameters:
    ///   - timeout: .Never
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///            `NanoMessageError.ReceiveMessage` there was an issue when receiving the message.
    ///            `NanoMessageError.MessageNotAvailable` there was no message to receive.
    ///            `NanoMessageError.ReceiveTimedOut` the receive timedout.
    ///
    /// - Returns: the number of bytes received and the received message
    ///
    /// - Note:    The timeout before the call received was performed will be restore after the function returns but this is not
    ///            guaranteed behaviour and no error will be thrown. 
    public func receiveMessage(timeout: Timeout) throws -> ReceiveData {
        return try self._receiveMessageWith(timeout: TimeInterval(seconds: timeout.rawValue))
    }

    /// Receive a message.
    ///
    /// - Parameters:
    ///   - timeout: .Never
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///            `NanoMessageError.ReceiveMessage` there was an issue when receiving the message.
    ///            `NanoMessageError.MessageNotAvailable` there was no message to receive.
    ///            `NanoMessageError.ReceiveTimedOut` the receive timedout.
    ///
    /// - Returns: the number of bytes received and the received message as a string.
    ///
    /// - Note:    The timeout before the call received was performed will be restore after the function returns but this is not
    ///            guaranteed behaviour and no error will be thrown. 
    public func receiveMessage(timeout: Timeout) throws -> ReceiveString {
        let received: ReceiveData = try self.receiveMessage(timeout: timeout)  // chain down the receiveMessage signature stock.

        return ReceiveString(received.bytes, try String(data: received.message))
    }
}

extension ProtocolSocket where Self: Receiver & ASyncReceiver {
    /// Asynchronous receive a message.
    ///
    /// - Parameters:
    ///   - blockingMode:   Specifies if the socket should operate in blocking or non-blocking mode.
    ///                     if in non-blocking mode and there is no message to receive the closureHandler
    ///                     will be passed `NanoMessageError.MessageNotReceived`.
    ///   - closureHandler: The closure to use when the async functionallity completes.
    public func receiveMessage(blockingMode: BlockingMode, _ closureHandler: @escaping (ReceiveData?, Error?) -> Void) {
        self._nanoSocket.aioQueue.async(group: self._nanoSocket.aioGroup) {
            do {
                try self._nanoSocket.mutex.lock {
                    let received: ReceiveData = try self.receiveMessage(blockingMode: blockingMode)

                    closureHandler(received, nil)
                }
            } catch {
                closureHandler(nil, error)
            }
        }
    }

    /// Asynchronous receive a message.
    ///
    /// - Parameters:
    ///   - closureHandler: The closure to use when the async functionallity completes.
    ///
    /// - Note:             'receiveMessage()' will be called with blocking mode.
    public func receiveMessage(_ closureHandler: @escaping (ReceiveData?, Error?) -> Void) {
        self.receiveMessage(blockingMode: .Blocking, closureHandler)
    }

    /// Asynchronous receive a message.
    ///
    /// - Parameters:
    ///   - blockingMode:   Specifies if the socket should operate in blocking or non-blocking mode.
    ///                     if in non-blocking mode and there is no message to receive the closureHandler
    ///                     will be passed `NanoMessageError.MessageNotReceived`.
    ///   - closureHandler: The closure to use when the async functionallity completes.
    public func receiveMessage(blockingMode: BlockingMode, _ closureHandler: @escaping (ReceiveString?, Error?) -> Void) {
        self._nanoSocket.aioQueue.async(group: self._nanoSocket.aioGroup) {
            do {
                try self._nanoSocket.mutex.lock {
                    let received: ReceiveString = try self.receiveMessage(blockingMode: blockingMode)

                    closureHandler(received, nil)
                }
            } catch {
                closureHandler(nil, error)
            }
        }
    }

    /// Asynchronous receive a message.
    ///
    /// - Parameters:
    ///   - closureHandler: The closure to use when the async functionallity completes.
    ///
    /// - Note:             'receiveMessage()' will be called with blocking mode.
    public func receiveMessage(_ closureHandler: @escaping (ReceiveString?, Error?) -> Void) {
        self.receiveMessage(blockingMode: .Blocking, closureHandler)
    }

    /// Asynchronous receive a message.
    ///
    /// - Parameters:
    ///   - timeout:        Specifies if the socket should operate in non-blocking mode for a timeout interval.
    ///                     If there is no message to receive the closureHandler will be passed `NanoMessageError.MessageNotReceived`.
    ///   - closureHandler: The closure to use when the async functionallity completes.
    public func receiveMessage(timeout: TimeInterval, _ closureHandler: @escaping (ReceiveData?, Error?) -> Void) {
        self._nanoSocket.aioQueue.async(group: self._nanoSocket.aioGroup) {
            do {
                try self._nanoSocket.mutex.lock {
                    let received: ReceiveData = try self.receiveMessage(timeout: timeout)

                    closureHandler(received, nil)
                }
            } catch {
                closureHandler(nil, error)
            }
        }
    }

    /// Asynchronous receive a message.
    ///
    /// - Parameters:
    ///   - timeout:        Specifies if the socket should operate in non-blocking mode for a timeout interval.
    ///                     If there is no message to receive the closureHandler will be passed `NanoMessageError.MessageNotReceived`.
    ///   - closureHandler: The closure to use when the async functionallity completes.
    public func receiveMessage(timeout: TimeInterval, _ closureHandler: @escaping (ReceiveString?, Error?) -> Void) {
        self._nanoSocket.aioQueue.async(group: self._nanoSocket.aioGroup) {
            do {
                try self._nanoSocket.mutex.lock {
                    let received: ReceiveString = try self.receiveMessage(timeout: timeout)

                    closureHandler(received, nil)
                }
            } catch {
                closureHandler(nil, error)
            }
        }
    }

    /// Asynchronous receive a message.
    ///
    /// - Parameters:
    ///   - timeout:        .Never
    ///   - closureHandler: The closure to use when the async functionallity completes.
    public func receiveMessage(timeout: Timeout, _ closureHandler: @escaping (ReceiveData?, Error?) -> Void) {
        self._nanoSocket.aioQueue.async(group: self._nanoSocket.aioGroup) {
            do {
                try self._nanoSocket.mutex.lock {
                    let received: ReceiveData = try self.receiveMessage(timeout: timeout)

                    closureHandler(received, nil)
                }
            } catch {
                closureHandler(nil, error)
            }
        }
    }

    /// Asynchronous receive a message.
    ///
    /// - Parameters:
    ///   - timeout:        .Never
    ///   - closureHandler: The closure to use when the async functionallity completes.
    public func receiveMessage(timeout: Timeout, _ closureHandler: @escaping (ReceiveString?, Error?) -> Void) {
        self._nanoSocket.aioQueue.async(group: self._nanoSocket.aioGroup) {
            do {
                try self._nanoSocket.mutex.lock {
                    let received: ReceiveString = try self.receiveMessage(timeout: timeout)

                    closureHandler(received, nil)
                }
            } catch {
                closureHandler(nil, error)
            }
        }
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
    ///
    /// - Returns: The sockets receive buffer size before being set.
    @discardableResult
    public func setMaximumMessageSize(bytes: Int) throws -> Int {
        let originalValue = try self.getMaximumMessageSize()

        try setSocketOption(self._nanoSocket.socketFd, .ReceiveMaximumMessageSize, (bytes < 0) ? -1 : bytes)

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
