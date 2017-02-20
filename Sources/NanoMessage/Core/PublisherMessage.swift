/*
    PublisherMessage.swift

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

import FNVHashValue
import ISFLibrary

public struct PublisherMessage {
    public private(set) var topic: Topic
    public private(set) var message: Message

    public init(topic: Topic, message: Message) {
        self.topic = topic
        self.message = message
    }
}

extension PublisherMessage: Hashable {
    public var hashValue: Int {
        return fnv1a(topic.data + message.data)
    }
}

extension PublisherMessage: Comparable {
    public static func <(lhs: PublisherMessage, rhs: PublisherMessage) -> Bool {
        return (compare(lhs: lhs.topic.data + lhs.message.data, rhs: rhs.topic.data + rhs.message.data) == .LessThan)
    }
}

extension PublisherMessage: Equatable {
    public static func ==(lhs: PublisherMessage, rhs: PublisherMessage) -> Bool {
        return (lhs.topic.data + lhs.message.data == rhs.topic.data + rhs.message.data)
    }
}
