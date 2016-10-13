/*
    NanoMessageError.swift

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

import CNanoMessage

public enum NanoMessageError: Error {
    case NanoSocket(code: CInt)
    case Close(code: CInt)
    case Interrupted
    case BindToAddress(code: CInt)
    case ConnectToAddress(code: CInt)
    case RemoveEndPoint(code: CInt)
    case BindToSocket(code: CInt)
    case LoopBack(code: CInt)
    case GetSocketOption(code: CInt, option: SocketOption)
    case SetSocketOption(code: CInt, option: SocketOption)
    case GetSocketStatistic(code: CInt, option: SocketStatistic)
    case PollSocket(code: CInt)
    case SendMessage(code: CInt)
    case MessageNotSent
    case ReceiveMessage(code: CInt)
    case MessageNotAvailable
    case TimedOut
    case NoTopic
    case InvalidTopic
    case FeatureNotSupported(str: String)
}

extension NanoMessageError: CustomStringConvertible {
    public var description: String {
        func errorString(_ code: CInt) -> String {
            var errorMessage = String(cString: nn_strerror(code))

            if let posixError = nanomsgError[Int(code)] {
                errorMessage += " (#\(code) '\(posixError)')"
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
            case .BindToAddress(let code):
                return "bindToAddress() failed: " + errorString(code)
            case .ConnectToAddress(let code):
                return "connectToAddress() failed: " + errorString(code)
            case .RemoveEndPoint(let code):
                return "removeEndPoint() failed: " + errorString(code)
            case .BindToSocket(let code):
                return "bindToSocket() failed: " + errorString(code)
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
            case .SendMessage(let code):
                return "sendMessage() failed: " + errorString(code)
            case .MessageNotSent:
                return "message not sent"
            case .ReceiveMessage(let code):
                return "receiveMessage() failed: " + errorString(code)
            case .MessageNotAvailable:
                return "no message received"
            case .TimedOut:
                return "operation has timed out"
            case .NoTopic:
                return "topic undefined"
            case .InvalidTopic:
                return "topics of unequal length"
            case .FeatureNotSupported(let str):
                return "unsupported feature: " + str
        }
    }
}
