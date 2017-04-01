/*
    SurveyorSocket.swift

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

/// Surveyor socket.
public final class SurveyorSocket: NanoSocket, ProtocolSocket, SenderReceiverSurveyorSocket {
    public var _nanoSocket: NanoSocket {
        return self
    }

    fileprivate var _sentTimestamp = TimeInterval()

    public init(socketDomain: SocketDomain = .StandardSocket) throws {
        try super.init(socketDomain: socketDomain, socketProtocol: .SurveyorProtocol)
    }
}

extension SurveyorSocket {
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
    ///            `NanoMessageError.NoTopic` if there was no topic defined to send.
    ///            `NanoMessageError.TopicLength` if the topic length too large.
    ///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
    ///            `NanoMessageError.TimedOut` the send timedout.
    ///
    /// - Returns: The message payload sent.
    @discardableResult
    public func sendMessage(_ message:    Message,
                            blockingMode: BlockingMode = .Blocking) throws -> MessagePayload {
        let sent = try sendToSocket(self, message.data, blockingMode)

        _sentTimestamp = sent.timestamp

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
        asyncSendToSocket(nanoSocket: self,
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
        asyncSendToSocket(nanoSocket: self,
                          closure: {
                              return try self.sendMessage(message, timeout: timeout)
                          },
                          success: success,
                          capture: {
                              return [self, message, timeout]
                          })
    }
}

extension SurveyorSocket {
    /// Receive a message.
    ///
    /// - Parameters:
    ///   - blockingMode: Specifies if the socket should operate in blocking or non-blocking mode.
    ///                   if in non-blocking mode and there is no message to receive the function
    ///                   will throw `NanoMessageError.MessageNotReceived`.
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.NoEndPoint`
    ///            `NanoMessageError.receiveMessage` there was an issue when receiving the message.
    ///            `NanoMessageError.MessageNotReceived` in non-blocking mode there was no message to receive.
    ///            `NanoMessageError.TimedOut` the receive timedout.
    ///            `NanoMessageError.ReachedDeadline` The surveyor has received a message after the deadline has expired.
    ///            `NanoMessageError.FreeMessage` deallocation of the message has failed.
    ///
    /// - Returns: The message payload received.
    public func receiveMessage(blockingMode: BlockingMode = .Blocking) throws -> MessagePayload {
        var deadline = TimeInterval()
        var deadlineTimeout = TimeInterval()

        do {
            deadline = try getDeadline()
            deadlineTimeout = _sentTimestamp + deadline

            return try receiveFromSocket(self, blockingMode)
        } catch let error as NanoMessageError {
            let now = Date().timeIntervalSinceReferenceDate

            switch error {
                case .ReceiveTimedOut:
                    guard (now <= deadlineTimeout) else {
                        throw NanoMessageError.DeadlineExpired(timeout: deadline)
                    }

                    fallthrough
                default:
                    throw error
            }
        } catch {
            throw error
        }
    }
}

extension SurveyorSocket {
    /// Specifies how long to wait for responses to the survey. Once the deadline expires,
    /// receive function will throw `NanoMessageError.ReachedDeadline` and all subsequent responses
    /// to the survey will be silently dropped. The deadline is measured in timeinterval.
    ///
    /// Default value is 1000 milliseconds (1 second).
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets deadline timeout.
    public func getDeadline() throws -> TimeInterval {
        return try getSocketOption(self, .SurveyDeadline, .SurveyorProtocol)
    }

    /// Specifies how long to wait for responses to the survey. Once the deadline expires,
    /// receive function will throw `NanoMessageError.ReachedDeadline` and all subsequent responses
    /// to the survey will be silently dropped. The deadline is measured in timeinterval.
    ///
    /// - Parameters:
    ///   - seconds: The deadline timeout in timeinterval.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///
    /// - Returns: The sockets deadline timeout before being set.
    @discardableResult
    public func setDeadline(seconds: TimeInterval) throws -> TimeInterval {
        let originalValue = try getDeadline()

        var timeout = try getReceiveTimeout()

        if (timeout < 0) {          // account for inifinte timeout of -1
            timeout = seconds + 1
        }

        guard (timeout > seconds) else {
            throw NanoMessageError.DeadlineNotLessThanTimeout(timeout: timeout)
        }

        try setSocketOption(self, .SurveyDeadline, seconds, .SurveyorProtocol)

        return originalValue
    }
}
