/*
    ReceiverSocketTimeoutMethods.swift

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

/// Receiver socket methods protocol.
public protocol ReceiverSocketTimeoutMethods: ReceiverSocketMethods, ReceiverSocketTimeoutOptions {
    // Input functions.
    func receiveMessage(timeout: TimeInterval) throws -> MessagePayload
    // ASync Input functions.
    func receiveMessage(timeout: TimeInterval,
                        success: @escaping (MessagePayload) -> Void)
}

extension ReceiverSocketTimeoutMethods {
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

        return try receiveMessage(blockingMode: .Blocking)    // chain down the receiveMessage signature stock.
    }

    /// Asynchronous receive a message.
    ///
    /// - Parameters:
    ///   - timeout: Specifies if the socket should operate in non-blocking mode for a timeout interval.
    ///              If there is no message to receive the closureHandler will be passed `NanoMessageError.MessageNotReceived`.
    ///   - success: The closure to use when the async functionallity is succesful.
    public func receiveMessage(timeout: TimeInterval,
                               success: @escaping (MessagePayload) -> Void) {
        asyncReceiveFromSocket(nanoSocket: self as! NanoSocket,
                               closure: {
                                   return try self.receiveMessage(timeout: timeout)
                               },
                               success: success,
                               capture: {
                                   return [self, timeout]
                               })
    }
}
