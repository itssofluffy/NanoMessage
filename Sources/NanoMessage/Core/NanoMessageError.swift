/*
    NanoMessageError.swift

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

import CNanoMessage
import Foundation

/// Obtain the underlying libraries error message as a string.
///
/// - Parameters:
///   - code:  Error code.
///
/// - Returns: The error string.
public func nanoMessageError(_ code: CInt) -> String {
    return String(cString: nn_strerror(code))
}

private var _nanomsgError = Dictionary<CInt, String>()
/// A dictionary of nanomsg error codes and their POSIX codes as strings.
public var nanomsgError: Dictionary<CInt, String> {
    if (_nanomsgError.isEmpty) {
        for symbol in symbolProperty.filter({ $0.namespace == .Error }) {
            _nanomsgError[symbol.value] = symbol.name
        }
    }

    return _nanomsgError
}

/// NanoMessage Error Domain.
public enum NanoMessageError: Error {
    case NanoSocket(code: CInt)
    case Close(code: CInt)
    case Interrupted
    case BindToURL(code: CInt, url: URL)
    case ConnectToURL(code: CInt, url: URL)
    case RemoveEndPoint(code: CInt, url: URL, endPointId: Int)
    case BindToSocket(code: CInt, nanoSocketName: String)
    case LoopBack(code: CInt)
    case GetSocketOption(code: CInt, option: SocketOption)
    case SetSocketOption(code: CInt, option: SocketOption)
    case GetSocketStatistic(code: CInt, option: SocketStatistic)
    case PollSocket(code: CInt)
    case SocketIsADevice
    case SendMessage(code: CInt)
    case MessageNotSent
    case SendTimedOut(timeout: TimeInterval)
    case InvalidSendTimeout(timeout: TimeInterval)
    case ReceiveMessage(code: CInt)
    case MessageNotAvailable
    case ReceiveTimedOut(timeout: TimeInterval)
    case InvalidReceiveTimeout(timeout: TimeInterval)
    case NoTopic
    case TopicLength
    case InvalidTopic
}

extension NanoMessageError: CustomStringConvertible {
    public var description: String {
        func errorString(_ code: CInt) -> String {
            var errorMessage = nanoMessageError(code)

            if let errorCode = nanomsgError[code] {
                errorMessage += " (#\(code) '\(errorCode)')"
            } else {
                errorMessage += " (#\(code))"
            }

            return errorMessage
        }

        switch self {
            case .NanoSocket(let code):
                return "nn_socket() failed: " + errorString(code)
            case .Close(let code):
                return "nn_close() failed: " + errorString(code)
            case .Interrupted:
                return "operation was interrupted"
            case .BindToURL(let code, let url):
                return "bindToURL('\(url.absoluteString)') failed: " + errorString(code)
            case .ConnectToURL(let code, let url):
                return "connectToURL('\(url.absoluteString)') failed: " + errorString(code)
            case .RemoveEndPoint(let code, let url, let endPointId):
                return "removeEndPoint('\(url.absoluteString)' #(\(endPointId))) failed: " + errorString(code)
            case .BindToSocket(let code, let nanoSocketName):
                return "bindToSocket('\(nanoSocketName)') failed: " + errorString(code)
            case .LoopBack(let code):
                return "loopBack() failed: " + errorString(code)
            case .GetSocketOption(let code, let option):
                return "getSocketOption('\(option)') failed: " + errorString(code)
            case .SetSocketOption(let code, let option):
                return "setSocketOption('\(option)') failed: " + errorString(code)
            case .GetSocketStatistic(let code, let option):
                return "getSocketStatistic('\(option)') failed: " + errorString(code)
            case .PollSocket(let code):
                return "pollSocket() failed: " + errorString(code)
            case .SocketIsADevice:
                return "Socket Is A Device"
            case .SendMessage(let code):
                return "sendMessage() failed: " + errorString(code)
            case .MessageNotSent:
                return "message not sent"
            case .ReceiveMessage(let code):
                return "receiveMessage() failed: " + errorString(code)
            case .MessageNotAvailable:
                return "no message received"
            case .SendTimedOut(let timeout), .ReceiveTimedOut(let timeout):
                return "operation has timed out " + ((timeout == .Never) ? "with an infinite timeout!" : "in \(timeout) second(s)")
            case .InvalidSendTimeout(let timeout), .InvalidReceiveTimeout(let timeout):
                return "timeout of \(timeout) second(s) is invalid"
            case .NoTopic:
                return "topic undefined"
            case .TopicLength:
                return "topic size > \(maximumTopicLength) bytes"
            case .InvalidTopic:
                return "topics of unequal length"
        }
    }
}
