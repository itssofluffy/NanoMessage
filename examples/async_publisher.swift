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

    messages.insert(DataSet(topic: "interesting", message: "this is message #1"))
    messages.insert(DataSet(topic: "not-really",  message: "this is message #2"))
    messages.insert(DataSet(topic: "interesting", message: "this is message #3"))
    messages.insert(DataSet(topic: "interesting", message: "this is message #4"))

    for dataSet in messages.sorted(by: { $0.message < $1.message }) {
        print("sending topic: \(dataSet.topic), message: \(dataSet.message)")

        node0.sendMessage(topic: dataSet.topic, message: dataSet.message, timeout: TimeInterval(seconds: 10), { bytesSent, error in
            if let error = error {
                print("\(error)")
            } else {
                print("topic     : \(node0.sendTopic)")
                print("message   : \(dataSet.message)")
                print("bytes sent: \(bytesSent!)")
            }
        })
    }

    if (try node0.removeEndPoint(url)) {
        print("end-point removed")
    }

    let messagesSent = try node0.getMessagesSent()
    let bytesSent = try node0.getBytesSent()

    print("messages sent: \(messagesSent)")
    print("bytes sent   : \(bytesSent)")

    for (topic, count) in node0.sentTopics {
        print("\(topic) : \(count)")
    }
} catch let error as NanoMessageError {
    print(error, to: &errorStream)
} catch {
    print("an unexpected error '\(error)' has occured in the library libNanoMessage.", to: &errorStream)
}

exit(EXIT_SUCCESS)
