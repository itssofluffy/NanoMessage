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
    public private(set) var topic: Topic? = nil
    public let message: Message

    public let direction: MessageDirection
    public let timestamp: TimeInterval

    internal init(bytes:     Int,
                  message:   Message,
                  direction: MessageDirection) {
        self.bytes = bytes
        self.message = message
        self.direction = direction
        timestamp = Date().timeIntervalSinceReferenceDate
    }

    internal init(bytes:     Int,
                  topic:     Topic,
                  message:   Message,
                  direction: MessageDirection,
                  timestamp: TimeInterval = Date().timeIntervalSinceReferenceDate) {
        self.bytes = bytes
        self.topic = topic
        self.message = message
        self.direction = direction
        self.timestamp = timestamp
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

        if let unwrappedTopic = topic {
            description = "topic: \(unwrappedTopic), "
        }

        description += "message: (\(message)), direction: \(direction), timestamp: \(timestamp)"

        return description
    }
}
