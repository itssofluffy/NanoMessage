/*
    NanoMessage.swift

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

/// On publish/subscribe sockets the maximum size of a topic
public let maximumTopicLength = 128

// define nn_poll() event masks.
private let _pollinMask = CShort(NN_POLLIN)
private let _polloutMask = CShort(NN_POLLOUT)

/// The underlying nanomsg libraries ABI version.
public var nanoMsgABIVersion: (current: Int, revision: Int, age: Int) {
    return (current: Int(NN_VERSION_CURRENT), revision: Int(NN_VERSION_REVISION), age: Int(NN_VERSION_AGE))
}

/// NanoMessage library version.
public var nanoMessageVersion: (major: Int, minor: Int, release: Int) {
    return (major: 0, minor: 2, release: 1)
}

/// Notify all sockets about process termination.
public func terminate() {
    nn_term()
}

private var _nanomsgSymbol = Dictionary<String, CInt>()
/// A dictionary of nanomsg symbol names and values.
public var nanomsgSymbol: Dictionary<String, CInt> {
    if (_nanomsgSymbol.isEmpty) {
        var index: CInt = 0

        while (true) {
            if let symbol = { () -> (name: String, value: CInt)? in
                                var value: CInt = 0

                                if let symbolName = nn_symbol(index, &value) {
                                    return (name: String(cString: symbolName), value: value)
                                }

                                return nil
                            }() {
                _nanomsgSymbol[symbol.name] = symbol.value
            } else {
                break     // no more symbols
            }

            index += 1
        }
    }

    return _nanomsgSymbol
}

private var _symbolProperty = Set<SymbolProperty>()
/// A set of nanomsg symbol properties.
public var symbolProperty: Set<SymbolProperty> {
    if (_symbolProperty.isEmpty) {
        var buffer = nn_symbol_properties()
        let bufferLength = CInt(MemoryLayout<nn_symbol_properties>.size)
        var index: CInt = 0

        while (true) {
            let returnCode = nn_symbol_info(index, &buffer, bufferLength)

            if (returnCode == 0) {    // no more symbol properties
                break
            }

            _symbolProperty.insert(SymbolProperty(namespace: buffer.ns,
                                                  name:      String(cString: buffer.name),
                                                  value:     buffer.value,
                                                  type:      buffer.type,
                                                  unit:      buffer.unit))

            index += 1
        }
    }

    return _symbolProperty
}

/// Check sockets and reports whether it’s possible to send a message to the socket and/or receive a message from the socket.
///
/// - Parameters:
///   - sockets : An array of nano sockets to examine.
///   - timeout : The maximum number of milliseconds to poll the socket for an event to occur,
///               default is 1000 milliseconds (1 second).
///
/// - Throws: `NanoMessageError.SocketIsADevice`
///           `NanoMessageError.PollSocket` if polling the socket fails.
///
/// - Returns: Message waiting and send queue blocked as a tuple of bools.
public func poll(sockets: [NanoSocket], timeout: TimeInterval = TimeInterval(seconds: 1)) throws -> [PollResult] {
    var pollFds = [nn_pollfd]()
    var pollResults = [PollResult]()

    for socket in sockets {
        guard (!socket.socketIsADevice) else {                                        // guard against polling a device socket.
            throw NanoMessageError.SocketIsADevice(socket: socket)
        }

        var eventMask = CShort.allZeros                                               //
        if (socket.receiverSocket) {                                                  // if the socket can receive then set the event mask appropriately.
            eventMask = _pollinMask
        }
        if (socket.senderSocket) {                                                    // if the socket can send then set the event mask appropriately.
            eventMask = eventMask | _polloutMask
        }

        pollFds.append(nn_pollfd(fd: socket.fileDescriptor, events: eventMask, revents: 0))
    }

    try pollFds.withUnsafeMutableBufferPointer { fileDescriptors in                   // poll the list of nano sockets.
        let returnCode = nn_poll(fileDescriptors.baseAddress, CInt(sockets.count), CInt(timeout.milliseconds))

        guard (returnCode >= 0) else {
            throw NanoMessageError.PollSocket(code: nn_errno())
        }
    }

    for loopCount in 0 ... sockets.count - 1 {
        let messageIsWaiting = ((pollFds[loopCount].revents & _pollinMask) != 0)      // using the event masks determine our return values
        let sendIsBlocked = ((pollFds[loopCount].revents & _polloutMask) != 0)        //

        pollResults.append(PollResult(messageIsWaiting: messageIsWaiting, sendIsBlocked: sendIsBlocked))
    }

    return pollResults
}
