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

/// Publisher socket.
public final class PublisherSocket: NanoSocket, ProtocolSocket, Publisher, PublisherSubscriber {
    public var _nanoSocket: NanoSocket {
        return self
    }

/// The seperator used between topic and message.
    public var topicSeperator: Byte = Byte("|")

/// The topic to send.
    public var sendTopic = Data()
/// A Dictionary of the topics sent with a count of the times sent.
    public fileprivate(set) var sentTopics = Dictionary<Data, UInt64>()

/// Prepend the topic to the start of the message when sending.
    public var prependTopic = true
/// When prepending the topic to the message do we ignore the topic seperator,
/// if true then the Subscriber socket should do the same and have subscribed to topics of equal length.
    public var ignoreTopicSeperator = false
/// Reset the send topic to empty after a sendMessage() has been performed.
    public var resetTopicAfterSend = false

    public init(socketDomain: SocketDomain) throws {
        try super.init(socketDomain: socketDomain, socketProtocol: .PublisherProtocol)
    }

    public convenience init() throws {
        try self.init(socketDomain: .StandardSocket)
    }
}

extension PublisherSocket {
/// Send a message.
///
/// - Parameters:
///   - message:      The message to send.
///   - blockingMode: Specifies that the send should be performed in non-blocking mode.
///                   If the message cannot be sent straight away, the function will throw
///                   `NanoMessageError.MessageNotSent`
///
/// - Throws:  `NanoMessageError.SocketIsADevice`
///            `NanoMessageError.sendMessage` there was a problem sending the message.
///            `NanoMessageError.TopicLength` if the topic length too large.
///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
///            `NanoMessageError.TimedOut` the send timedout.
///
/// - Returns: The number of bytes sent.
    @discardableResult
    public func sendMessage(_ message: Data, blockingMode: BlockingMode = .Blocking) throws -> Int {
        var messagePayload: Data

        if (self.prependTopic) {                                  // we are prepending the topic to the start of the message.
            if (self.sendTopic.isEmpty) {                         // check that we have a topic to send.
                throw NanoMessageError.NoTopic
            } else if (self.sendTopic.count > NanoMessage.maximumTopicLength) {
                throw NanoMessageError.TopicLength
            }

            if (self.ignoreTopicSeperator) {                      // check if we are ignoring the topic seperator.
                messagePayload = self.sendTopic + message
            } else {
                messagePayload = self.sendTopic + [self.topicSeperator] + message
            }
        } else {
            messagePayload = message
        }

        let bytesSent = try sendPayloadToSocket(self, messagePayload, blockingMode)

        if (!self.sendTopic.isEmpty) {                            // check that we have a send topic.
            // remember which topics we've sent and how many.
            if var topicCount = sentTopics[self.sendTopic] {
                topicCount += 1
                sentTopics[self.sendTopic] = topicCount
            } else {
                sentTopics[self.sendTopic] = 1
            }

            if (self.resetTopicAfterSend) {                       // are we resetting the topic?
                self.sendTopic = Data()
            }
        }

        return bytesSent
    }
}
