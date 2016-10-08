/*
    SocketDomain.swift

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

/// Socket domain.
public enum SocketDomain: CInt {
    case StandardSocket // Standard full-blown SP socket.
    case RawSocket      // Raw SP socket.

    public var rawValue: CInt {
        switch self {
            case .StandardSocket:
                return AF_SP
            case .RawSocket:
                return AF_SP_RAW
        }
    }

    public init?(rawValue: CInt) {
        switch rawValue {
            case AF_SP:
                self = .StandardSocket
            case AF_SP_RAW:
                self = .RawSocket
            default:
                return nil
        }
    }
}

extension SocketDomain: CustomStringConvertible {
    public var description: String {
        switch self {
            case .StandardSocket:
                return "standard"
            case .RawSocket:
                return "raw"
        }
    }
}
