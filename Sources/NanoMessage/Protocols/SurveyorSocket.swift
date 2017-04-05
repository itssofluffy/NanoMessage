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
public final class SurveyorSocket: NanoSocket, ProtocolSocket, SenderReceiverNoTimeoutSocket {
    public init(socketDomain: SocketDomain = .StandardSocket) throws {
        try super.init(socketDomain: socketDomain, socketProtocol: .SurveyorProtocol)
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
        do {
            return try receiveFromSocket(self, blockingMode)
        } catch let error as NanoMessageError {
            switch error {
                case .ReceiveTimedOut:
                    let deadline = wrapper(do: { () -> TimeInterval in
                                               return try self.getDeadline()
                                           },
                                           catch: { failure in
                                               nanoMessageErrorLogger(failure)
                                           })

                    throw NanoMessageError.DeadlineExpired(timeout: deadline!)
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

        try setSocketOption(self, .SurveyDeadline, seconds, .SurveyorProtocol)

        return originalValue
    }
}
