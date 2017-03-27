/*
    ReceiverSenderSocket.swift

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

public protocol ReceiverSenderSocket: ReceiverSocket, SenderSocket {
    func receiveMessage(receiveMode:    BlockingMode,
                        sendMode:       BlockingMode,
                        _ closure:      @escaping (MessagePayload) throws -> Message) throws -> MessagePayload
    func receiveMessage(receiveTimeout: TimeInterval,
                        sendTimeout:    TimeInterval,
                        _ closure:      @escaping (MessagePayload) throws -> Message) throws -> MessagePayload
}

extension ReceiverSenderSocket {
    /// Receive a message and pass that received message to a closure that produces a message that is sent.
    ///
    /// - Parameters:
    ///   - receiveMode:
    ///   - sendMode:
    ///   - closure:
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.NoEndPoint`
    ///            `NanoMessageError.ReceiveMessage` there was an issue when receiving the message.
    ///            `NanoMessageError.MessageNotAvailable` in non-blocking mode there was no message to receive.
    ///            `NanoMessageError.ReceiveTimedOut` the receive timedout.
    ///            `NanoMessageError.FreeMessage` deallocation of the message has failed.
    ///            `NanoMessageError.SendMessage` there was a problem sending the message.
    ///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
    ///            `NanoMessageError.SendTimedOut` the send timedout.
    @discardableResult
    public func receiveMessage(receiveMode: BlockingMode = .Blocking,
                               sendMode:    BlockingMode = .Blocking,
                               _ closure:   @escaping (MessagePayload) throws -> Message) throws -> MessagePayload {
        let message = try closure(receiveMessage(blockingMode: receiveMode))
        let sent = try sendMessage(message, blockingMode: sendMode)

        return MessagePayload(bytes: sent.bytes, message: sent.message)
    }

    /// Receive a message and pass that received message to a closure that produces a message that is sent.
    ///
    /// - Parameters:
    ///   - receiveTimeout:
    ///   - sendTimeout:
    ///   - closure:
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.NoEndPoint`
    ///            `NanoMessageError.ReceiveMessage` there was an issue when receiving the message.
    ///            `NanoMessageError.MessageNotAvailable` in non-blocking mode there was no message to receive.
    ///            `NanoMessageError.ReceiveTimedOut` the receive timedout.
    ///            `NanoMessageError.FreeMessage` deallocation of the message has failed.
    ///            `NanoMessageError.SendMessage` there was a problem sending the message.
    ///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
    ///            `NanoMessageError.SendTimedOut` the send timedout.
    @discardableResult
    public func receiveMessage(receiveTimeout: TimeInterval,
                               sendTimeout:    TimeInterval,
                               _ closure:      @escaping (MessagePayload) throws -> Message) throws -> MessagePayload {
        let message = try closure(receiveMessage(timeout: receiveTimeout))
        let sent = try sendMessage(message, timeout: sendTimeout)

        return MessagePayload(bytes: sent.bytes, message: sent.message)
    }
}
