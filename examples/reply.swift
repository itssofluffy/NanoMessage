/*
    reply.swift

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

import Foundation
import NanoMessage
import ISFLibrary

var urlToUse = "tcp://*:5555"

switch (CommandLine.arguments.count) {
    case 1:
        break
    case 2:
        urlToUse = CommandLine.arguments[1]
    default:
        fatalError("usage: reply [url]")
}

guard let url = URL(string: urlToUse) else {
    fatalError("url is not valid")
}

do {
    let node0 = try ReplySocket()

    let endPoint: EndPoint = try node0.createEndPoint(url: url, type: .Bind, name: "reply end-point")

    usleep(TimeInterval(milliseconds: 200))

    print(endPoint)

    let timeout = TimeInterval(seconds: 10)

    let sent = try node0.receiveMessage(receiveTimeout: timeout,
                                        sendTimeout: timeout,
                                        { (received) -> Message in
                                            print("received \(received.bytes) bytes as message '\(received.message.string)'...")

                                            if (received.message.string == "ping") {
                                                return Message(value: "pong")
                                            }

                                            return Message(value: "i don't like wiff wafe")
                                        })

    print("...and sent \(sent.bytes) bytes as a message of '\(sent.message.string)'")

    print("messages received: \(node0.messagesReceived!)")
    print("bytes received   : \(node0.bytesReceived!)")
    print("messages sent    : \(node0.messagesSent!)")
    print("bytes sent       : \(node0.bytesSent!)")
} catch let error as NanoMessageError {
    print(error, to: &errorStream)
} catch {
    print("an unexpected error '\(error)' has occured in the library libNanoMessage.", to: &errorStream)
}

exit(EXIT_SUCCESS)
