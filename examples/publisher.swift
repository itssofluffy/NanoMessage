/*
    publisher.swift

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

import Foundation
import NanoMessage
import ISFLibrary
import C7
import FNVHashValue

struct DataSet: Hashable {
    let topic: String
    let message: String

    init(topic: String, message: String) {
        self.topic = topic
        self.message = message
    }

    var hashValue: Int {
        return fnv1a(self.topic + self.message)
    }

    static func ==(lhs: DataSet, rhs: DataSet) -> Bool {
        return (lhs.topic == rhs.topic && lhs.message == rhs.message)
    }
}

do {
    guard let url = URL(string: "tcp://localhost:5555") else {
        fatalError("url is not valid")
    }

    let node0 = try PublisherSocket()
    let endPoint: Int = try node0.connectToURL(url)

    var messages = Set<DataSet>()

    messages.insert(DataSet(topic: "bob calvert",   message: "This is earth calling...earth calling..."))
    messages.insert(DataSet(topic: "rodger waters", message: "We're just two lost souls, swimming in a fish bowl...year after year"))
    messages.insert(DataSet(topic: "bob calvert",   message: "Oh, for the wings of any bird, other than a battery hen..."))

    for dataSet in messages {
        node0.sendTopic = C7.Data(dataSet.topic)

        print("sending topic: \(node0.sendTopic), message: \(dataSet.message)")

        try node0.sendMessage(dataSet.message, timeout: TimeInterval(seconds: 10))
    }

    let messagesSent = try node0.getMessagesSent()
    let bytesSent = try node0.getBytesSent()

    print("messages sent: \(messagesSent)")
    print("bytes sent   : \(bytesSent)")
} catch let error as NanoMessageError {
    print(error, to: &errorStream)
} catch {
    print("an unexpected error '\(error)' has occured in the library libNanoMessage.", to: &errorStream)
}

exit(EXIT_SUCCESS)
