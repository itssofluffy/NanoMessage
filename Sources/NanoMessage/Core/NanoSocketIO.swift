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
import Foundation
import ISFLibrary

private let NN_MSG: size_t = -1

/// Is it valid to send or receive on the socket.
///
/// - Parameters:
///   - nanoSocket:   The nano socket to use.
///
/// - Throws:  `NanoMessageError.SocketIsADevice`
///            `NanoMessageError.NoEndPoint`
internal func validateNanoSocket(_ nanoSocket: NanoSocket) throws {
    guard (!nanoSocket.isDevice) else {
        throw NanoMessageError.SocketIsADevice(socket: nanoSocket)
    }

    guard (nanoSocket.endPoints.count > 0) else {
        throw NanoMessageError.NoEndPoint(socket: nanoSocket)
    }
}

/// The low-level send function.
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
internal func sendToSocket(_ nanoSocket:   NanoSocket,
                           _ payload:      Data,
                           _ blockingMode: BlockingMode) throws -> RawSentData {
    try validateNanoSocket(nanoSocket)

    let bytesSent = Int(nn_send(nanoSocket.fileDescriptor, payload.bytes, payload.count, blockingMode.rawValue))

    let timestamp = Date().timeIntervalSinceReferenceDate

    guard (bytesSent >= 0) else {
        let errno = nn_errno()

        if (blockingMode == .NonBlocking && errno == EAGAIN) {
            throw NanoMessageError.MessageNotSent
        } else if (errno == ETIMEDOUT) {
            let timeout = wrapper(do: { () -> TimeInterval in
                                      try getSocketOption(nanoSocket, .SendTimeout)
                                  },
                                  catch: { failure in
                                      nanoMessageErrorLogger(failure)
                                  })

            throw NanoMessageError.SendTimedOut(timeout: timeout!)
        }

        throw NanoMessageError.SendMessage(code: errno)
    }

    return RawSentData(bytes: bytesSent, timestamp: timestamp)
}

/// The low-level receive function.
///
/// - Parameters:
///   - nanoSocket:   The nano socket to use.
///   - blockingMode: Specifies if the socket should operate in blocking or non-blocking mode.
///                   if in non-blocking mode and there is no message to receive the function
///                   will throw `NanoMessageError.MessageNotReceived`.
///
/// - Throws:  `NanoMessageError.SocketIsADevice`
///            `NanoMessageError.NoEndPoint`
///            `NanoMessageError.ReceiveMessage` there was an issue when receiving the message.
///            `NanoMessageError.MessageNotAvailable` in non-blocking mode there was no message to receive.
///            `NanoMessageError.ReceiveTimedOut` the receive timedout.
///            `NanoMessageError.FreeMessage` deallocation of the message has failed.
///
/// - Returns: The number of bytes received and the received message
internal func receiveFromSocket(_ nanoSocket:   NanoSocket,
                                _ blockingMode: BlockingMode) throws -> MessagePayload {
    try validateNanoSocket(nanoSocket)

    // A raw null pointer, we allocate nothing. In C this would be a void*
    var buffer = UnsafeMutableRawPointer(bitPattern: 0)

    // We pass a pointer to the above null pointer, in C this would be a void**
    // nn_recv() will do the actual memory allocation, and change raw to point to the new memory.
    let bytesReceived = Int(nn_recv(nanoSocket.fileDescriptor, &buffer, NN_MSG, blockingMode.rawValue))

    let timestamp = Date().timeIntervalSinceReferenceDate

    guard (bytesReceived >= 0) else {
        let errno = nn_errno()

        if (blockingMode == .NonBlocking && errno == EAGAIN) {
            throw NanoMessageError.MessageNotAvailable
        } else if (errno == ETIMEDOUT) {
            let timeout = wrapper(do: { () -> TimeInterval in
                                      try getSocketOption(nanoSocket, .ReceiveTimeout)
                                  },
                                  catch: { failure in
                                      nanoMessageErrorLogger(failure)
                                  })

            throw NanoMessageError.ReceiveTimedOut(timeout: timeout!)
        }

        throw NanoMessageError.ReceiveMessage(code: errno)
    }

    // Swift doesn't like going between UnsafeMutableRawPointer and UnsafeMutableBufferPointer, so we create a
    // OpaquePointer out of our UnsafeMutableRawPointer, just to create an UnsafeMutablePointer which we can use to
    // create an UnsafeMutableBufferPointer. Thanks Apple.
    let p = UnsafeMutablePointer<Byte>(OpaquePointer(buffer))
    let message = Message(buffer: UnsafeMutableBufferPointer(start: p, count: bytesReceived))

    // finally call nn_freemsg() to free the memory that nn_recv() allocated for us
    guard (nn_freemsg(buffer) >= 0) else {
        throw NanoMessageError.FreeMessage(code: nn_errno())
    }

    return MessagePayload(bytes:     bytesReceived,
                          message:   message,
                          direction: .Received,
                          timestamp: timestamp)
}

/// Asynchrounous execute a passed operation closure.
///
/// - Parameters:
///   - nanoSocket: The socket to perform the operation on.
///   - closure:    The closure to use to perform the send
///   - success:    The closure to use when `closure()` is succesful.
///   - capture:    The closure to use to pass any objects required when an error occurs.
internal func asyncOperationOnSocket(nanoSocket: NanoSocket,
                                     closure:    @escaping () throws -> MessagePayload,
                                     success:    @escaping (MessagePayload) -> Void,
                                     capture:    @escaping () -> Array<Any>) {
    nanoSocket.aioQueue.async(group: nanoSocket.aioGroup) {
        wrapper(do: {
                    try nanoSocket.mutex.lock {
                        try success(closure())
                    }
                },
                catch: { failure in
                    nanoMessageErrorLogger(failure)
                },
                capture: capture)
    }
}
