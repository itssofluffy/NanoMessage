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
import ISFLibrary

/// On publish/subscribe sockets the maximum size of a topic
public let maximumTopicLength = 128

// define nn_poll() event masks.
private let _pollinMask = CShort(NN_POLLIN)
private let _polloutMask = CShort(NN_POLLOUT)

// nanomsg library has terminated.
internal private(set) var nanomsgTerminated = false

/// The underlying nanomsg libraries ABI version.
public var nanoMsgABIVersion: ABIVersion {
    return ABIVersion(current: UInt(NN_VERSION_CURRENT), revision: UInt(NN_VERSION_REVISION), age: UInt(NN_VERSION_AGE))
}

/// NanoMessage library version.
public var nanoMessageVersion: SemanticVersion {
    return SemanticVersion(major: 0, minor: 3, patch: 2)
}

/// The string encoding to use by default for topics and messages.
public var stringEncoding: String.Encoding = .utf8

/// Notify all sockets about process termination.
public func terminate() {
    nanomsgTerminated = true

    nn_term()
}

private var _nanomsgSymbol = Dictionary<String, CInt>()
/// A dictionary of nanomsg symbol names and values.
public var nanomsgSymbol: Dictionary<String, CInt> {
    typealias Symbol = (name: String, value:CInt)

    if (_nanomsgSymbol.isEmpty) {
        var index: CInt = 0

        let symbolName: () -> Symbol? = {
            var value: CInt = 0

            if let symbolName = nn_symbol(index, &value) {
                return Symbol(name: String(cString: symbolName), value: value)
            }

            return nil
        }

        while (true) {
            if let symbol = symbolName() {
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
            if (nn_symbol_info(index, &buffer, bufferLength) == 0) {  // no more symbol properties.
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
///
/// - Notes:   If a message has been received on a SubscriberSocket will return that a message is waiting irrespective
///            of the topic being subscribed too.
public func poll(sockets: Array<NanoSocket>, timeout: TimeInterval = TimeInterval(seconds: 1)) throws -> Array<PollResult> {
    var pollFds = Array<nn_pollfd>()

    for socket in sockets {
        guard (!socket.socketIsADevice) else {                          // guard against polling a device socket.
            throw NanoMessageError.SocketIsADevice(socket: socket)
        }

        var eventMask = CShort.allZeros                                 //
        if (socket.receiverSocket) {                                    // if the socket can receive then set the event mask appropriately.
            eventMask = _pollinMask
        }
        if (socket.senderSocket) {                                      // if the socket can send then set the event mask appropriately.
            eventMask = eventMask | _polloutMask
        }

        pollFds.append(nn_pollfd(fd:      socket.fileDescriptor,
                                 events:  eventMask,
                                 revents: CShort.allZeros))
    }

    try pollFds.withUnsafeMutableBufferPointer { fileDescriptors in     // poll the list of nano sockets.
        guard (nn_poll(fileDescriptors.baseAddress, CInt(sockets.count), CInt(timeout.milliseconds)) >= 0) else {
            throw NanoMessageError.PollSocket(code: nn_errno())
        }
    }

    var pollResults = Array<PollResult>()

    for pollFd in pollFds {
        let messageIsWaiting = ((pollFd.revents & _pollinMask) != 0)    // using the event masks determine our return values
        let sendIsBlocked = ((pollFd.revents & _polloutMask) != 0)      //

        pollResults.append(PollResult(messageIsWaiting: messageIsWaiting, sendIsBlocked: sendIsBlocked))
    }

    return pollResults
}
