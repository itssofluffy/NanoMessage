/*
    request.swift

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

var urlToUse = "tcp://localhost:5555"
var sendCount = 1

switch (CommandLine.arguments.count) {
    case 1:
        break
    case 2:
        urlToUse = CommandLine.arguments[1]
    case 3:
        urlToUse = CommandLine.arguments[1]
        sendCount = Int(CommandLine.arguments[2])!
    default:
        fatalError("usage: request [url]")
}

guard let url = URL(string: urlToUse) else {
    fatalError("url is not valid")
}

if (sendCount < 1) {
    sendCount = 1
}

do {
    let node0 = try RequestSocket()

    let endPoint: EndPoint = try node0.createEndPoint(url: url, type: .Connect, name: "request end-point")

    usleep(TimeInterval(milliseconds: 200))

    print(endPoint)

    let timeout = TimeInterval(seconds: 10)
    let message = Message(value: "ping")

    for _ in 0 ..< sendCount {
        let received = try node0.sendMessage(message,
                                             sendTimeout: timeout,
                                             receiveTimeout: timeout,
                                             { sent in
                                                 print("sent \(sent)")
                                                 print("waiting for a response...")
                                             })

        print("and recieved \(received)")
    }

    print("messages sent    : \(node0.messagesSent!)")
    print("bytes sent       : \(node0.bytesSent!)")
    print("messages received: \(node0.messagesReceived!)")
    print("bytes received   : \(node0.bytesReceived!)")
} catch let error as NanoMessageError {
    print(error, to: &errorStream)
} catch {
    print("an unexpected error '\(error)' has occured in the library libNanoMessage.", to: &errorStream)
}

exit(EXIT_SUCCESS)
