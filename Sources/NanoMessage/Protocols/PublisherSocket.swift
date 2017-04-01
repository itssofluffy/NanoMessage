/*
    PublisherSocket.swift

    Copyright (c) 2016, 2017 Stephen Whittle  All rights reserved.

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

/// Publisher socket.
public final class PublisherSocket: NanoSocket, ProtocolSocket, PublishSubscribeSocket, PublishSocket {
    public var _nanoSocket: NanoSocket {
        return self
    }

    /// The topic to send.
    fileprivate var _topic = Topic()

    /// The seperator used between topic and message.
    public var topicSeperator: Byte = Byte("|")
    /// remember which topics we've sent and how many.
    public var topicCounts = true
    /// A Dictionary of the topics sent with a count of the times sent.
    public fileprivate(set) var sentTopics = Dictionary<Topic, UInt64>()
    /// Prepend the topic to the start of the message when sending.
    public var prependTopic = true
    /// When prepending the topic to the message do we ignore the topic seperator,
    /// if true then the Subscriber socket should do the same and have subscribed to topics of equal length.
    public var ignoreTopicSeperator = false
    /// Reset the send topic to empty after a sendMessage() has been performed.
    public var resetTopicAfterSend = false

    public init(socketDomain: SocketDomain = .StandardSocket) throws {
        try super.init(socketDomain: socketDomain, socketProtocol: .PublisherProtocol)
    }
}

extension PublisherSocket {
    /// validate the passed topic.
    ///
    /// - Parameters:
    ///   - topic:  The topic to validate.
    ///
    /// - Throws:   `NanoMessageError.NoTopic` if there was no topic defined.
    ///             `NanoMessageError.TopicLength` if the topic length too large.
    fileprivate func _validateTopic(_ topic: Topic) throws {
        if (topic.isEmpty) {
            throw NanoMessageError.NoTopic
        } else if (topic.count > NanoMessage.maximumTopicLength) {
            throw NanoMessageError.TopicLength
        }
    }

    /// Send a message.
    ///
    /// - Parameters:
    ///   - message:      The message to send.
    ///   - blockingMode: Specifies that the send should be performed in non-blocking mode.
    ///                   If the message cannot be sent straight away, the function will throw
    ///                   `NanoMessageError.MessageNotSent`
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.NoEndPoint`
    ///            `NanoMessageError.SendMessage` there was a problem sending the message.
    ///            `NanoMessageError.NoTopic` if there was no topic defined to send.
    ///            `NanoMessageError.TopicLength` if the topic length too large.
    ///            `NanoMessageError.MessageNotSent` the send has beem performed in non-blocking mode and the message cannot be sent straight away.
    ///            `NanoMessageError.TimedOut` the send timedout.
    ///
    /// - Returns: The message payload sent.
    @discardableResult
    public func sendMessage(_ message:    Message,
                            blockingMode: BlockingMode = .Blocking) throws -> MessagePayload {
        let payload: () throws -> Data = {
            if (self.prependTopic) {                          // we are prepending the topic to the start of the message.
                try self._validateTopic(self._topic)          // check that we have a valid topic to send.

                if (self.ignoreTopicSeperator) {              // check if we are ignoring the topic seperator.
                    return self._topic.data + message.data
                }

                return self._topic.data + [self.topicSeperator] + message.data
            }

            return message.data
        }

        let sent = try sendToSocket(self, payload(), blockingMode)

        if (!_topic.isEmpty) {                                // check that we have a send topic.
            if (topicCounts) {                                // remember which topics we've sent and how many.
                if var topicCount = sentTopics[_topic] {
                    topicCount += 1
                    sentTopics[_topic] = topicCount
                } else {
                    sentTopics[_topic] = 1
                }
            }
        }

        defer {
            if (!_topic.isEmpty && resetTopicAfterSend) {     // are we resetting the topic?
                _topic = Topic()                              // reset the topic, don't use setSendTopic() as this checks for isEmpty!
            }
        }

        return MessagePayload(bytes:     sent.bytes,
                              topic:     _topic,
                              message:   message,
                              direction: .Sent,
                              timestamp: sent.timestamp)
    }

    /// Asynchrounous execute a passed sender closure.
    ///
    /// - Parameters:
    ///   - payload: A PublisherMessage to send.
    ///   - closure: The closure to use to perform the send
    ///   - success: The closure to use when `closure()` is succesful.
    ///   - capture: The closure to use to pass any objects required when an error occurs.
    private func _asyncSendToSocket(payload: Message,
                                    closure: @escaping (Message) throws -> MessagePayload,
                                    success: @escaping (MessagePayload) -> Void,
                                    capture: @escaping () -> Array<Any>) {
        aioQueue.async(group: aioGroup) {
            wrapper(do: {
                        try self.mutex.lock {
                            try self.setTopic(payload.topic!)

                            try success(closure(Message(value: payload.data)))
                        }
                    },
                    catch: { failure in
                        nanoMessageErrorLogger(failure)
                    },
                    capture: capture)
        }
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - message:      The message to send.
    ///   - blockingMode: Specifies that the send should be performed in non-blocking mode.
    ///                   If the message cannot be sent straight away, the closureHandler
    ///                   will be passed `NanoMessageError.MessageNotSent`
    ///   - success:      The closure to use when the async functionality completes succesfully.
    public func sendMessage(_ message:    Message,
                            blockingMode: BlockingMode = .Blocking,
                            success:      @escaping (MessagePayload) -> Void) {
        let payload = Message(topic: _topic, value: message.data)

        _asyncSendToSocket(payload: payload,
                           closure: { message in
                               return try self.sendMessage(message, blockingMode: blockingMode)
                           },
                           success: success,
                           capture: {
                               return [self, payload, blockingMode, self.aioQueue, self.aioGroup]
                           })
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - message: The message to send.
    ///   - timeout: The timeout interval to set.
    ///   - success: The closure to use when the async functionality completes succesfully.
    public func sendMessage(_ message: Message,
                            timeout:   TimeInterval,
                            success:   @escaping (MessagePayload) -> Void) {
        let payload = Message(topic: _topic, value: message.data)

        _asyncSendToSocket(payload: payload,
                           closure: { message in
                               return try self.sendMessage(message, timeout: timeout)
                           },
                           success: success,
                           capture: {
                               return [self, payload, timeout, self.aioQueue, self.aioGroup]
                           })
    }
}

extension PublisherSocket {
    /// set the topic to send.
    ///
    /// - Parameters:
    ///   - topic:  The topic to send.
    ///
    /// - Throws:   `NanoMessageError.NoTopic` if there was no topic defined to send.
    ///             `NanoMessageError.TopicLength` if the topic length too large.
    public func setTopic(_ topic: Topic) throws {
        try _validateTopic(topic)               // check that we have a valid topic.

        _topic = topic
    }

    /// reset the topic counts.
    public func resetTopicCounts() {
        sentTopics = Dictionary<Topic, UInt64>()
    }
}
