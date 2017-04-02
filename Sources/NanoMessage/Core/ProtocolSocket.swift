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
        let sent = try sendToSocket(_nanoSocket, message.data, blockingMode)

        return MessagePayload(bytes:     sent.bytes,
                              message:   message,
                              direction: .Sent,
                              timestamp: sent.timestamp)
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
        asyncSendToSocket(nanoSocket: self._nanoSocket,
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
        asyncSendToSocket(nanoSocket: self._nanoSocket,
                          closure: {
                              return try self.sendMessage(message, timeout: timeout)
                          },
                          success: success,
                          capture: {
                              return [self, message, timeout]
                          })
    }
}
