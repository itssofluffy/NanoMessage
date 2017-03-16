/*
    NanoSocketIO.swift

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
import ISFLibrary
import Foundation

private let NN_MSG: size_t = -1

/// Is it valid to send or receive on the socket.
///
/// - Parameters:
///   - nanoSocket:   The nano socket to use.
///
/// - Throws:  `NanoMessageError.SocketIsADevice`
///            `NanoMessageError.NoEndPoint`
internal func validateNanoSocket(_ nanoSocket: NanoSocket) throws {
    guard (!nanoSocket.socketIsADevice) else {
        throw NanoMessageError.SocketIsADevice(socket: nanoSocket)
    }

    guard (nanoSocket.endPoints.count > 0) else {
        throw NanoMessageError.NoEndPoint(socket: nanoSocket)
    }
}

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
///            `NanoMessageError.NoEndPoint`
///            `NanoMessageError.sendMessage` there was a problem sending the message.
///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
///            `NanoMessageError.SendTimedOut` the send timedout.
///
/// - Returns: The number of bytes sent.
internal func sendPayloadToSocket(_ nanoSocket:   NanoSocket,
                                  _ payload:      Data,
                                  _ blockingMode: BlockingMode) throws -> Int {
    try validateNanoSocket(nanoSocket)

    let bytesSent = Int(nn_send(nanoSocket.fileDescriptor, payload.bytes, payload.count, blockingMode.rawValue))

    guard (bytesSent >= 0) else {
        let errno = nn_errno()

        if (blockingMode == .NonBlocking && errno == EAGAIN) {
            throw NanoMessageError.MessageNotSent
        } else if (errno == ETIMEDOUT) {
            let timeout = wrapper(do: { () -> TimeInterval in
                                      try getSocketOption(nanoSocket, .SendTimeout)
                                  },
                                  catch: { failure in
                                      nanoMessageLogger(failure)
                                  })

            throw NanoMessageError.SendTimedOut(timeout: timeout!)
        }

        throw NanoMessageError.SendMessage(code: errno)
    }

    return bytesSent
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
///            `NanoMessageError.NoEndPoint`
///            `NanoMessageError.receiveMessage` there was an issue when receiving the message.
///            `NanoMessageError.MessageNotAvailable` in non-blocking mode there was no message to receive.
///            `NanoMessageError.ReceiveTimedOut` the receive timedout.
///
/// - Returns: The number of bytes received and the received message
internal func receivePayloadFromSocket(_ nanoSocket:   NanoSocket,
                                       _ blockingMode: BlockingMode) throws -> ReceiveMessage {
    try validateNanoSocket(nanoSocket)

    var buffer = UnsafeMutablePointer<Byte>.allocate(capacity: 0)

    let bytesReceived = Int(nn_recv(nanoSocket.fileDescriptor, &buffer, NN_MSG, blockingMode.rawValue))

    defer {
        // not sure if this needed because of the deallocation using nn_freemsg() but doesn't seem to hurt
        // when we complete succesfully, but call it just in case we `throw` prior to doing the `nn_freemsg()`
        // underlying library documentation says that `buffer` is unallocated if `nn_recv` fails.
        buffer.deinitialize(count: (bytesReceived < 0) ? 0 : bytesReceived)
    }

    guard (bytesReceived >= 0) else {
        let errno = nn_errno()

        if (blockingMode == .NonBlocking && errno == EAGAIN) {
            throw NanoMessageError.MessageNotAvailable
        } else if (errno == ETIMEDOUT) {
            let timeout = wrapper(do: { () -> TimeInterval in
                                      try getSocketOption(nanoSocket, .ReceiveTimeout)
                                  },
                                  catch: { failure in
                                      nanoMessageLogger(failure)
                                  })

            throw NanoMessageError.ReceiveTimedOut(timeout: timeout!)
        }

        throw NanoMessageError.ReceiveMessage(code: errno)
    }

    let message = Message(value: UnsafeMutableBufferPointer(start: buffer, count: bytesReceived))

    guard (nn_freemsg(buffer) >= 0) else {
        throw NanoMessageError.ReceiveMessage(code: nn_errno())
    }

    return ReceiveMessage(bytes: bytesReceived, message: message)
}
