/*
    SenderSocketMethods.swift

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
import ISFLibrary

/// Sender socket methods protocol.
public protocol SenderSocketMethods: SenderSocketOptions {
    // Output functions.
    @discardableResult
    func sendMessage(_ message:    Message,
                     blockingMode: BlockingMode) throws -> MessagePayload
    @discardableResult
    func sendMessage(_ message:    Message,
                     timeout:      TimeInterval) throws -> MessagePayload
    // ASync Output functions.
    func sendMessage(_ message:    Message,
                     blockingMode: BlockingMode,
                     success:      @escaping (MessagePayload) -> Void)
    func sendMessage(_ message:    Message,
                     timeout:      TimeInterval,
                     success:      @escaping (MessagePayload) -> Void)
}

extension SenderSocketMethods {
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
        let sent = try sendToSocket(self as! NanoSocket, message.data, blockingMode)

        return MessagePayload(bytes:     sent.bytes,
                              message:   message,
                              direction: .Sent,
                              timestamp: sent.timestamp)
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
    /// - Returns: The message payload sent.
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

        return try sendMessage(message, blockingMode: .Blocking)   // chain down the sendMessage signature stack
    }

    /// Asynchrounous execute a passed sender closure.
    ///
    /// - Parameters:
    ///   - nanoSocket: The socket to perform the operation on.
    ///   - closure:    The closure to use to perform the send
    ///   - success:    The closure to use when `closure()` is succesful.
    ///   - capture:    The closure to use to pass any objects required when an error occurs.
    private func _asyncSendToSocket(nanoSocket: NanoSocket,
                                    closure:    @escaping () throws -> MessagePayload,
                                    success:    @escaping (MessagePayload) -> Void,
                                    capture:    @escaping () -> Array<Any>) {
        nanoSocket.aioQueue.async(group: nanoSocket.aioGroup) {
            wrapper(do: {
                        try nanoSocket.mutex.lock {
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
        _asyncSendToSocket(nanoSocket: self as! NanoSocket,
                           closure: {
                               return try self.sendMessage(message, blockingMode: blockingMode)
                           },
                           success: success,
                           capture: {
                               return [self, message, blockingMode]
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
        _asyncSendToSocket(nanoSocket: self as! NanoSocket,
                           closure: {
                               return try self.sendMessage(message, timeout: timeout)
                           },
                           success: success,
                           capture: {
                               return [self, message, timeout]
                           })
    }
}
