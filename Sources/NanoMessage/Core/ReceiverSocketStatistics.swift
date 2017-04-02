/*
    ReceiverSocketStatistics.swift

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

import ISFLibrary

/// Receiver socket statistics protocol._.
public protocol ReceiverSocketStatistics {
    // socket statistics functions.
    var messagesReceived: UInt64? { get }
    var bytesReceived: UInt64? { get }
}

extension ReceiverSocketStatistics {
    /// The number messages received by this socket.
    public var messagesReceived: UInt64? {
        return wrapper(do: {
                           return try getSocketStatistic(self as! NanoSocket, .MessagesReceived)
                       },
                       catch: { failure in
                           nanoMessageErrorLogger(failure)
                       },
                       capture: {
                           return [self]
                       })
    }

    /// The number of bytes received by this socket.
    public var bytesReceived: UInt64? {
        return wrapper(do: {
                           return try getSocketStatistic(self as! NanoSocket, .BytesReceived)
                       },
                       catch: { failure in
                           nanoMessageErrorLogger(failure)
                       },
                       capture: {
                           return [self]
                       })
    }
}
