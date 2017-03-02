/*
    push.swift

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
import C7

var urlToUse = "tcp://localhost:5555"
var sendCount = 1
var messageSize = 128

switch (CommandLine.arguments.count) {
    case 1:
        break
    case 2:
        urlToUse = CommandLine.arguments[1]
    case 3:
        urlToUse = CommandLine.arguments[1]
        sendCount = Int(CommandLine.arguments[2])!
    case 4:
        urlToUse = CommandLine.arguments[1]
        sendCount = Int(CommandLine.arguments[2])!
        messageSize = Int(CommandLine.arguments[3])!
    default:
        fatalError("usage: push [url] [send_count] [message_size]")
}

guard let url = URL(string: urlToUse) else {
    fatalError("url is not valid")
}

if (sendCount < 1) {
    sendCount = 1
}

if (messageSize < 1) {
    messageSize = 1
}

do {
    let node0 = try PushSocket()

    let endPoint: EndPoint = try node0.createEndPoint(url: url, type: .Connect, name: "send end-point")

    usleep(TimeInterval(milliseconds: 200))

    print(endPoint)

    let messagePayload = Message(value: [Byte](repeating: 0xff, count: messageSize))

    for _ in 1 ... sendCount {
        try node0.sendMessage(messagePayload, timeout: TimeInterval(seconds: 10))
    }

    print("messages: \(node0.messagesSent!)")
    print("bytes   : \(node0.bytesSent!)")
} catch let error as NanoMessageError {
    print(error, to: &errorStream)
} catch {
    print("an unexpected error '\(error)' has occured in the library libNanoMessage.", to: &errorStream)
}

exit(EXIT_SUCCESS)
