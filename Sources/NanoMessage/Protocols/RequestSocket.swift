/*
    RequestSocket.swift

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

/// Request socket.
public final class RequestSocket: NanoSocket, ProtocolSocket, Receiver, Sender, ASyncSender {
    public var _nanoSocket: NanoSocket {
        return self
    }

    public init(socketDomain: SocketDomain = .StandardSocket) throws {
        try super.init(socketDomain: socketDomain, socketProtocol: .RequestProtocol)
    }
}

extension RequestSocket {
    /// If reply is not received in specified amount of milliseconds, the request will be automatically resent.
    ///
    /// Default value is 60000 milliseconds (60 seconds).
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets resend interval.
    public func getResendInterval() throws -> TimeInterval {
        return try getSocketOption(self.socketFd, .ResendInterval, .RequestProtocol)
    }

    /// If reply is not received in specified amount of milliseconds, the request will be automatically resent.
    ///
    /// - Parameters:
    ///   - seconds: The sockets resend interval.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///            `NanoMessageError.SetSocketOption`
    ///
    /// - Returns: The sockets resend interval before being set.
    @discardableResult
    public func setResendInterval(seconds: TimeInterval) throws -> TimeInterval {
        let originalValue = try self.getResendInterval()

        try setSocketOption(self.socketFd, .ResendInterval, seconds, .RequestProtocol)

        return originalValue
    }
}
