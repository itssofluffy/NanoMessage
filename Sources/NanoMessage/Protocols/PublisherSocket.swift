/*
    PublisherSocket.swift

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

import C7
import CNanoMessage

public final class PublisherSocket: NanoSocket, ProtocolSocket, Sender, PublisherSubscriber {
    public var _nanoSocket: NanoSocket {
        return self
    }

    public var topicSeperator: Byte = Byte("|")
    public var sendTopic = Data()
    public fileprivate(set) var sentTopics = Dictionary<Data, UInt>()

    public var prependTopic = true
    public var ignoreTopicSeperator = false

    public init(socketDomain: SocketDomain) throws {
        try super.init(socketDomain: socketDomain, socketProtocol: .PublisherProtocol)
    }

    public convenience init() throws {
        try self.init(socketDomain: .StandardSocket)
    }
}

extension PublisherSocket {
    @discardableResult
    public func sendMessage(_ message: Data, blockingMode: BlockingMode = .Blocking) throws -> Int {
        var messagePayload: Data

        if (self.prependTopic) {
            if (self.sendTopic.isEmpty) {
                throw NanoMessageError.NoTopic
            }

            if (self.ignoreTopicSeperator) {
                messagePayload = self.sendTopic + message
            } else {
                messagePayload = self.sendTopic + [self.topicSeperator] + message
            }
        } else {
            messagePayload = message
        }

        let bytesSent = try sendPayloadToSocket(self.socketFd, messagePayload, blockingMode)

        if var topicCount = sentTopics[self.sendTopic] {
            topicCount += 1
            sentTopics[self.sendTopic] = topicCount
        } else {
            sentTopics[self.sendTopic] = 1
        }

        return bytesSent
    }

    @discardableResult
    public func sendMessage(_ message: String, blockingMode: BlockingMode = .Blocking) throws -> Int {
        return try self.sendMessage(Data(message), blockingMode: blockingMode)
    }
}
