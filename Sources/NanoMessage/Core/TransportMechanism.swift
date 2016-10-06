/*
    TransportMechanism.swift

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

import Foundation
import CNanoMessage

public enum TransportMechanism: CInt {
    case TCP            // Transmission Control Protocol transport.
    case InProcess      // In-process transport.
    case InterProcess   // Inter-process communication transport.
    case WebSocket      // Web socket transport.
    case Unsupported    // Unsupported transport.

    public var rawValue: CInt {
        switch self {
            case .TCP:
                return NN_TCP
            case .InProcess:
                return NN_INPROC
            case .InterProcess:
                return NN_IPC
            case .WebSocket:
                return NN_WS
            case .Unsupported:
                return 0
        }
    }

    public init(rawValue: CInt) {
        switch rawValue {
            case NN_TCP:
                self = .TCP
            case NN_INPROC:
                self = .InProcess
            case NN_IPC:
                self = .InterProcess
            case NN_WS:
                self = .WebSocket
            default:
                self = .Unsupported
        }
    }

    public init(rawValue: String) {
        if (rawValue.hasPrefix("tcp:")) {
            self = .TCP
        } else if (rawValue.hasPrefix("inproc:")) {
            self = .InProcess
        } else if (rawValue.hasPrefix("ipc:")) {
            self = .InterProcess
        } else if (rawValue.hasPrefix("ws:")) {
            self = .WebSocket
        } else {
            self = .Unsupported
        }
    }
}

extension TransportMechanism: CustomStringConvertible {
    public var description: String {
        switch self {
            case .TCP:
                return "tcp"
            case .InProcess:
                return "inter-process"
            case .InterProcess:
                return "ipc"
            case .WebSocket:
                return "web socket"
            case .Unsupported:
                return "unsupported"
        }
    }
}
