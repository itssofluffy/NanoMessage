/*
    Library.swift

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

import C7
import CNanoMessage

internal func sendPayloadToSocket(_ socketFd: CInt, _ payload: Data, _ blockingMode: BlockingMode) throws -> Int {
    let bytesSent = nn_send(socketFd, payload.bytes, payload.count, blockingMode.rawValue)

    guard (bytesSent >= 0) else {
        let errno = nn_errno()

        if (blockingMode == .NonBlocking && errno == EAGAIN) {
            throw NanoMessageError.MessageNotSent
        } else if (errno == ETIMEDOUT) {
            throw NanoMessageError.TimedOut
        }

        throw NanoMessageError.SendMessage(code: errno)
    }

    return Int(bytesSent)
}

// Zero copy message size. NN_MSG = ((size_t)-1) this cannot be reproduced using the clang compiler see:
// https://github.com/apple/swift/blob/master/docs/StdlibRationales.rst#size_t-is-unsigned-but-it-is-imported-as-int
private func _maxBufferSize(_ socketFd: CInt) -> Int {
    let defaultReceiveMaximumMessageSize: CInt = 1048576 // 1024 * 1024 bytes = 1 MiB

    if var bufferSize: CInt = try? getSocketOption(socketFd, NN_RCVMAXSIZE) {
        if (bufferSize <= 0) {
            bufferSize = defaultReceiveMaximumMessageSize
        }

        return Int(bufferSize)
    } else {
        return Int(defaultReceiveMaximumMessageSize)
    }
}

internal func receivePayloadFromSocket(_ socketFd: CInt, _ blockingMode: BlockingMode) throws -> (Int, Data) {
    let bufferSize = _maxBufferSize(socketFd)
    var buffer = Data.buffer(with: bufferSize)

    let bytesReceived = Int(nn_recv(socketFd, &buffer.bytes, bufferSize, blockingMode.rawValue))

    guard (bytesReceived >= 0) else {
        let errno = nn_errno()

        if (blockingMode == .NonBlocking && errno == EAGAIN) {
            throw NanoMessageError.MessageNotAvailable
        } else if (errno == ETIMEDOUT) {
            throw NanoMessageError.TimedOut
        }

        throw NanoMessageError.ReceiveMessage(code: errno)
    }

    return (bytesReceived, Data(buffer[0 ..< min(bytesReceived, bufferSize)]))
}
