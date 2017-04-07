/*
    SubscriberSocket.swift

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

/// Subscriber socket.
public final class SubscriberSocket: NanoSocket, ProtocolSocket, PublishSubscribeSocket, SubscribeSocket {
    /// The seperator used between topic and message.
    public var topicSeperator: Byte = Byte("|")
    /// Ignore topic seperator, true means that all topics must be of an equal length.
    /// Use flipIgnoreTopicSeperator() to flip between flase/true true/false
    public fileprivate(set) var ignoreTopicSeperator = false
    /// remember which topics we've received and how many.
    public var topicCounts = true
    /// A dictionary of topics and their count that have been received
    public fileprivate(set) var receivedTopics = Dictionary<Topic, UInt64>()
    /// Remove the topic from the received data.
    public var removeTopicFromMessage = true
    /// A set of all the subscribed topics.
    public fileprivate(set) var subscribedTopics = Set<Topic>()
    /// Is the socket subscribed to all topics
    public fileprivate(set) var subscribedToAllTopics = false

    public init(socketDomain: SocketDomain = .StandardSocket) throws {
        try super.init(socketDomain: socketDomain, socketProtocol: .SubscriberProtocol)
    }
}

extension SubscriberSocket {
    /// Receive a message.
    ///
    /// - Parameters:
    ///   - blockingMode: Specifies if the socket should operate in blocking or non-blocking mode.
    ///                   if in non-blocking mode and there is no message to receive the function
    ///                   will throw `NanoMessageError.MessageNotReceived`.
    ///
    /// - Throws:  `NanoMessageError.SocketIsADevice`
    ///            `NanoMessageError.NoEndPoint`
    ///            `NanoMessageError.receiveMessage` there was an issue when receiving the message.
    ///            `NanoMessageError.MessageNotReceived` in non-blocking mode there was no message to receive.
    ///            `NanoMessageError.TimedOut` the receive timedout.
    ///
    /// - Returns: The message payload received.
    public func receiveMessage(blockingMode: BlockingMode = .Blocking) throws -> MessagePayload {
        var receivedTopic = Topic()

        let received = try receiveFromSocket(self, blockingMode)

        var message = received.message.data

        if (received.bytes > 0) {                                   // we have a message to process...
            if (!subscribedToAllTopics || ignoreTopicSeperator) {   // determine how to extract the topic.
                for topic in subscribedTopics {
                    let containsTopic: () -> Bool = {
                        if (((self.ignoreTopicSeperator) ? topic.count : topic.count + 1) <= message.count) {
                            if (Data(message[0 ..< topic.count]) != topic.data) {
                                return false
                            } else if (self.ignoreTopicSeperator || message[topic.count] == self.topicSeperator) {
                                return true
                            }
                        }

                        return false
                    }

                    if (containsTopic()) {
                        receivedTopic = topic

                        break
                    }
                }
            } else {
                let setTopic: () throws -> Topic = {                // Get the topic from the message/payload if it exists using the topic seperator.
                    if let index = message.index(of: self.topicSeperator) {
                        return try Topic(value: Data(message[0 ..< index]))
                    }

                    return try Topic(value: received.message.data)
                }

                let topic = try setTopic()

                if (topic.data != message) {
                    receivedTopic = topic
                }
            }

            if (receivedTopic.isEmpty) {                            // check we've extracted a topic
                throw NanoMessageError.NoTopic
            }

            if (removeTopicFromMessage) {                           // are we removing the topic from the message/payload...
                var offset = receivedTopic.count

                if (subscribedToAllTopics || !ignoreTopicSeperator) {
                    offset += 1
                }

                message.removeSubrange(message.startIndex ..< message.index(message.startIndex, offsetBy: offset))
            }

            if (topicCounts) {                                      // remember which topics we've received and how many.
                if var topicCount = receivedTopics[receivedTopic] {
                    topicCount += 1
                    receivedTopics[receivedTopic] = topicCount
                } else {
                    receivedTopics[receivedTopic] = 1
                }
            }
        }

        return MessagePayload(bytes:     received.bytes,
                              topic:     receivedTopic,
                              message:   Message(value: message),
                              direction: .Received,
                              timestamp: received.timestamp)
    }
}

extension SubscriberSocket {
    /// Is the specified topic already subscribed too.
    ///
    /// - Parameters:
    ///   - topic: The topic to check.
    ///
    /// - Returns: If the topic has been subscribed too.
    public func isTopicSubscribed(_ topic: Topic) -> Bool {
        return subscribedTopics.contains(topic)
    }

    private typealias TopicLengths = (equalLengths: Bool, count: Int)

    /// Check all topics for equal lengths.
    ///
    /// - Returns: Tuple of all topics of equal length and then standard topic length/count.
    private func _validateTopicLengths() -> TopicLengths {
        var equalLengths = true
        var topicLengths = -1

        for topic in subscribedTopics {
            if (topicLengths < 0) {
                topicLengths = topic.count
            } else if (topicLengths != topic.count) {
                equalLengths = false

                break
            }
        }

        return TopicLengths(equalLengths: equalLengths, count: topicLengths)
    }

    /// Flip the ignore topic seperator, when true all topic lengths must be of equal length.
    ///
    /// - Throws:  `NanoMessageError.SetSocketOption`
    ///            `NanoMessageError.InvalidTopic`
    ///
    /// - Returns: Has the function been successful.
    public func flipIgnoreTopicSeperator() throws -> Bool {
        if (!subscribedToAllTopics) {
            if (!ignoreTopicSeperator && !_validateTopicLengths().equalLengths) {
                throw NanoMessageError.InvalidTopic
            }

            ignoreTopicSeperator = !ignoreTopicSeperator

            return true
        }

        return false
    }

    /// Subscibe to a topic.
    ///
    /// - Parameters:
    ///   - topic: The topic to subscribe to.
    ///
    /// - Throws:  `NanoMessageError.SetSocketOption` if an issue has been encountered.
    ///            `NanoMessageError.InvalidTopic` if the topic is invalid (unequal length).
    ///            `NanoMessageError.TopicLength` if the topic size is too large.
    ///
    /// - Returns: If we managed to subscribed to the topic.
    @discardableResult
    public func subscribeTo(topic: Topic) throws -> Bool {
        if (!topic.isEmpty) {
            let topicSubscribed = isTopicSubscribed(topic)

            if (!topicSubscribed) {
                let validTopicLength: () -> Bool = {            // Check topic length against (any) existing topics is see if it is of equal length.
                    let topics = self._validateTopicLengths()

                    if (!topics.equalLengths) {
                        return false
                    } else if (topics.count < 0) {
                        return true
                    } else if (topics.count != topic.count) {
                        return false
                    }

                    return true
                }

                if (subscribedToAllTopics) {
                    try unsubscribeFromAllTopics()
                } else if (ignoreTopicSeperator && !validTopicLength()) {
                    throw NanoMessageError.InvalidTopic
                } else if (topic.count > NanoMessage.maximumTopicLength) {
                    throw NanoMessageError.TopicLength
                }

                try setSocketOption(self, .Subscribe, topic.data, .SubscriberProtocol)

                subscribedTopics.insert(topic)
            }

            return !topicSubscribed
        }

        return false
    }

    /// Unsubscibe from a topic.
    ///
    /// - Parameters:
    ///   - topic: The topic to unsubscribe from.
    ///
    /// - Throws:  `NanoMessageError.SetSocketOption` if an issue has been encountered.
    ///
    /// - Returns: If we managed to unsubscribed from the topic.
    @discardableResult
    public func unsubscribeFrom(topic: Topic) throws -> Bool {
        if (!topic.isEmpty) {
            let topicSubscribed = isTopicSubscribed(topic)

            if (topicSubscribed) {
                try setSocketOption(self, .UnSubscribe, topic.data, .SubscriberProtocol)

                subscribedTopics.remove(topic)

                if (subscribedTopics.isEmpty) {
                    try unsubscribeFromAllTopics()
                }
            }

            return topicSubscribed
        }

        return false
    }

    /// Subscribe to all topics.
    ///
    /// - Throws: `NanoMessageError.SetSocketOption` if an issue has been encountered.
    ///
    /// - Returns: If we have managed to subscribe to all topics.
    ///
    /// - Note:    You cannot subscribe to all topics if `ignoreTopicSeperator` is true.
    public func subscribeToAllTopics() throws -> Bool {
        if (!ignoreTopicSeperator) {
            if (!subscribedToAllTopics) {
                for topic in subscribedTopics {
                    try unsubscribeFrom(topic: topic)
                }

                try setSocketOption(self, .Subscribe, "", .SubscriberProtocol)

                subscribedToAllTopics = true
            }

            return subscribedToAllTopics
        }

        return false
    }

    /// Unsubscribe from all topics.
    ///
    /// - Throws: `NanoMessageError.SetSocketOption` if an issue has been encountered.
    public func unsubscribeFromAllTopics() throws {
        for topic in subscribedTopics {
            try unsubscribeFrom(topic: topic)
        }

        if (subscribedToAllTopics) {
            try setSocketOption(self, .UnSubscribe, "", .SubscriberProtocol)
        }

        subscribedToAllTopics = false
    }

    /// reset the topic counts.
    public func resetTopicCounts() {
        receivedTopics = Dictionary<Topic, UInt64>()
    }
}
