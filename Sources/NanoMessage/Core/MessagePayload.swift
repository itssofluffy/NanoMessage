/*
    MessagePayload.swift

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
import ISFLibrary
import FNVHashValue

public struct MessagePayload {
    public let bytes: Int
    public let topic: Topic?
    public internal(set) var message: Message

    public let timestamp = Date().timeIntervalSinceReferenceDate

    public init(bytes: Int, message: Message) {
        self.bytes = bytes
        self.topic = nil
        self.message = message
    }

    public init(bytes: Int, topic: Topic, message: Message) {
        self.bytes = bytes
        self.topic = topic
        self.message = message
    }
}

extension MessagePayload: Hashable {
    public var hashValue: Int {
        return fnv1a(timestamp)
    }
}

extension MessagePayload: Comparable {
    public static func <(lhs: MessagePayload, rhs: MessagePayload) -> Bool {
        return (lhs.timestamp < rhs.timestamp)
    }
}

extension MessagePayload: Equatable {
    public static func ==(lhs: MessagePayload, rhs: MessagePayload) -> Bool {
        return (lhs.timestamp == rhs.timestamp)
    }
}

extension MessagePayload: CustomStringConvertible {
    public var description: String {
        var description = "bytes: \(bytes), "

        if let _ = topic {
            description = "topic: \(topic), "
        }

        description += "message: \(message), timestamp: \(timestamp)"

        return description
    }
}
