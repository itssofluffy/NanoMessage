/*
    NanoSocketIO.swift

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

/// The low-level send a message function.
///
/// - Parameters:
///   - nanoSocket:   The nano socket to use.
///   - message:      The message to send.
///   - blockingMode: Specifies that the send should be performed in non-blocking mode.
///                   If the message cannot be sent straight away, the function will throw
///                   `NanoMessageError.MessageNotSent`
///
/// - Throws:  `NanoMessageError.SocketIsADevice`
///            `NanoMessageError.sendMessage` there was a problem sending the message.
///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
///            `NanoMessageError.SendTimedOut` the send timedout.
///
/// - Returns: The number of bytes sent.
internal func sendPayloadToSocket(_ nanoSocket: NanoSocket, _ payload: Data, _ blockingMode: BlockingMode) throws -> Int {
    guard (!nanoSocket.socketIsADevice) else {
        throw NanoMessageError.SocketIsADevice
    }

    let bytesSent = nn_send(nanoSocket.socketFd, payload.bytes, payload.count, blockingMode.rawValue)

    guard (bytesSent >= 0) else {
        let errno = nn_errno()

        if (blockingMode == .NonBlocking && errno == EAGAIN) {
            throw NanoMessageError.MessageNotSent
        } else if (errno == ETIMEDOUT) {
            throw NanoMessageError.SendTimedOut(timeout: try! getSocketOption(nanoSocket.socketFd, .SendTimeout))
        }

        throw NanoMessageError.SendMessage(code: errno)
    }

    return Int(bytesSent)
}

/// The low-level receive a message function.
///
/// - Parameters:
///   - nanoSocket:   The nano socket to use.
///   - blockingMode: Specifies if the socket should operate in blocking or non-blocking mode.
///                   if in non-blocking mode and there is no message to receive the function
///                   will throw `NanoMessageError.MessageNotReceived`.
///
/// - Throws:  `NanoMessageError.SocketIsADevice`
///            `NanoMessageError.receiveMessage` there was an issue when receiving the message.
///            `NanoMessageError.MessageNotAvailable` in non-blocking mode there was no message to receive.
///            `NanoMessageError.ReceiveTimedOut` the receive timedout.
///
/// - Returns: The number of bytes received and the received message
internal func receivePayloadFromSocket(_ nanoSocket: NanoSocket, _ blockingMode: BlockingMode) throws -> ReceiveData {
    // The underlying nanomsg library zero copy message size NN_MSG = ((size_t)-1) cannot be reproduced using the clang compiler see:
    // https://github.com/apple/swift/blob/master/docs/StdlibRationales.rst#size_t-is-unsigned-but-it-is-imported-as-int
    func _maxBufferSize(_ socketFd: CInt) -> Int {
        var maxBufferSize = 1048576                      // 1024 * 1024 bytes = 1 MiB

        if let bufferSize: Int = try? getSocketOption(socketFd, .ReceiveMaximumMessageSize) {
            if (bufferSize > 0) {                        // cater for unlimited message size.
                maxBufferSize = bufferSize
            }
        }

        return maxBufferSize
    }

    guard (!nanoSocket.socketIsADevice) else {
        throw NanoMessageError.SocketIsADevice
    }

    let bufferSize = _maxBufferSize(nanoSocket.socketFd)
    var buffer = Data.buffer(with: bufferSize)

    let bytesReceived = Int(nn_recv(nanoSocket.socketFd, &buffer.bytes, bufferSize, blockingMode.rawValue))

    guard (bytesReceived >= 0) else {
        let errno = nn_errno()

        if (blockingMode == .NonBlocking && errno == EAGAIN) {
            throw NanoMessageError.MessageNotAvailable
        } else if (errno == ETIMEDOUT) {
            throw NanoMessageError.ReceiveTimedOut(timeout: try! getSocketOption(nanoSocket.socketFd, .ReceiveTimeout))
        }

        throw NanoMessageError.ReceiveMessage(code: errno)
    }

    return ReceiveData(bytesReceived, Data(buffer[0 ..< min(bytesReceived, bufferSize)]))
}
