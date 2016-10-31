/*
    SurveyorSocket.swift

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

/// Surveyor socket.
public final class SurveyorSocket: NanoSocket, ProtocolSocket, Receiver, Sender {
    public var _nanoSocket: NanoSocket {
        return self
    }

    public init(socketDomain: SocketDomain) throws {
        try super.init(socketDomain: socketDomain, socketProtocol: .SurveyorProtocol)
    }

    public convenience init() throws {
        try self.init(socketDomain: .StandardSocket)
    }
}

extension SurveyorSocket {
/// Specifies how long to wait for responses to the survey. Once the deadline expires,
/// receive function will throw `NanoMessageError.TimedOut` and all subsequent responses
/// to the survey will be silently dropped. The deadline is measured in milliseconds.
///
/// Default value is 1000 milliseconds (1 second).
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///
/// - Returns: The sockets deadline timeout.
    public func getDeadline() throws -> Int {
        return try getSocketOption(self.socketFd, .SurveyDeadline, .SurveyorProtocol)
    }

/// Specifies how long to wait for responses to the survey. Once the deadline expires,
/// receive function will throw `NanoMessageError.TimedOut` and all subsequent responses
/// to the survey will be silently dropped. The deadline is measured in milliseconds.
///
/// - Parameters:
///   - milliseconds: The deadline timeout in milliseconds.
///
/// - Throws:  `NanoMessageError.SetSocketOption`
    public func setDeadline(milliseconds: Int) throws {
        try setSocketOption(self.socketFd, .SurveyDeadline, milliseconds, .SurveyorProtocol)
    }
}
