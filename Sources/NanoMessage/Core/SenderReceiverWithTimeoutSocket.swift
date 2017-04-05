/*
    SenderReceiverWithTimeoutSocket.swift

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

public protocol SenderReceiverWithTimeoutSocket: SenderReceiverSocketProtocol, SenderSocket, ReceiverWithTimeoutSocket {
    func sendMessage(_ message:      Message,
                     sendTimeout:    TimeInterval,
                     receiveTimeout: TimeInterval,
                     _ closure:      @escaping (MessagePayload) throws -> Void) throws -> MessagePayload
}

extension SenderReceiverWithTimeoutSocket {
    /// Send a message and pass that sent message to a closure, the receive a message.
    ///
    /// - Parameters:
    ///   - message:
    ///   - sendTimeout:
    ///   - receiveTimeout:
    ///   - closure:
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.NoEndPoint`
    ///            `NanoMessageError.SendMessage` there was a problem sending the message.
    ///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
    ///            `NanoMessageError.SendTimedOut` the send timedout.
    ///            `NanoMessageError.ReceiveMessage` there was an issue when receiving the message.
    ///            `NanoMessageError.MessageNotAvailable` in non-blocking mode there was no message to receive.
    ///            `NanoMessageError.ReceiveTimedOut` the receive timedout.
    ///            `NanoMessageError.FreeMessage` deallocation of the message has failed.
    ///
    /// - Returns: The received message.
    public func sendMessage(_ message:      Message,
                            sendTimeout:    TimeInterval,
                            receiveTimeout: TimeInterval,
                            _ closure:      @escaping (MessagePayload) throws -> Void) throws -> MessagePayload {
        try closure(sendMessage(message, timeout: sendTimeout))

        return try receiveMessage(timeout: receiveTimeout)
    }
}
