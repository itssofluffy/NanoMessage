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
import C7

/// Subscriber socket.
public final class SubscriberSocket: NanoSocket, ProtocolSocket, Subscriber, PublisherSubscriber {
    public var _nanoSocket: NanoSocket {
        return self
    }

    /// The seperator used between topic and message.
    public var topicSeperator: Byte = Byte("|")
    /// Ignore topic seperator, true means that all topics must be of an equal length.
    /// Use flipIgnoreTopicSeperator() to flip between flase/true true/false
    public fileprivate(set) var ignoreTopicSeperator = false
    /// The topic last received.
    public fileprivate(set) var receivedTopic = Topic(value: C7.Data())
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

    public convenience init(socketDomain: SocketDomain = .StandardSocket, connectTo url: URL) throws {
        try self.init(socketDomain: socketDomain)

        let _: EndPoint = try connectToURL(url)
    }

    public convenience init(socketDomain: SocketDomain = .StandardSocket, connectTo urls: [URL]) throws {
        try self.init(socketDomain: socketDomain)

        for url in urls {
            let _: EndPoint = try connectToURL(url)
        }
    }

    public convenience init(socketDomain: SocketDomain = .StandardSocket, bindTo url: URL) throws {
        try self.init(socketDomain: socketDomain)

        let _: EndPoint = try bindToURL(url)
    }

    public convenience init(socketDomain: SocketDomain = .StandardSocket, bindTo urls: [URL]) throws {
        try self.init(socketDomain: socketDomain)

        for url in urls {
            let _: EndPoint = try bindToURL(url)
        }
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
    ///            `NanoMessageError.receiveMessage` there was an issue when receiving the message.
    ///            `NanoMessageError.MessageNotReceived` in non-blocking mode there was no message to receive.
    ///            `NanoMessageError.TimedOut` the receive timedout.
    ///
    /// - Returns: the number of bytes received and the received message
    public func receiveMessage(blockingMode: BlockingMode = .Blocking) throws -> ReceiveMessage {
        /// Does the message/payload contain the specified topic
        func _messageHasTopic(_ topic: Topic, _ message: Message) -> Bool {
            if (((ignoreTopicSeperator) ? topic.count : topic.data.count + 1) <= message.count) {
                if (C7.Data(message.data[0 ..< topic.count]) != topic.data) {
                    return false
                } else if (ignoreTopicSeperator || message.data[topic.count] == topicSeperator) {
                    return true
                }
            }

            return false
        }

        /// Get the topic from the message/payload if it exists using the topic seperator.
        func _getTopicFromMessage(_ message: Message) -> Topic {
            if let index = message.data.index(of: topicSeperator) {
                return Topic(value: C7.Data(message.data[0 ..< index]))
            }

            return Topic(value: message.data)
        }

        receivedTopic = Topic(value: C7.Data())

        var received = try receivePayloadFromSocket(self, blockingMode)

        if (received.bytes > 0) {                                               // we have a message to process...
            if (!subscribedToAllTopics || ignoreTopicSeperator) {               // determine how to extract the topic.
                for topic in subscribedTopics {
                    if (_messageHasTopic(topic, received.message)) {
                        receivedTopic = topic

                        break
                    }
                }
            } else {
                let topic = _getTopicFromMessage(received.message)

                if (topic.data != received.message.data) {
                    receivedTopic = topic
                }
            }

            if (receivedTopic.isEmpty) {                                        // check we've extracted a topic
                throw NanoMessageError.NoTopic
            }

            if (removeTopicFromMessage) {                                       // are we removing the topic from the message/payload...
                var offset = receivedTopic.count
                if (subscribedToAllTopics || !ignoreTopicSeperator) {
                    offset += 1
                }

                let range = received.message.data.startIndex ..< received.message.data.index(received.message.data.startIndex, offsetBy: offset)
                received.message.data.removeSubrange(range)
            }

            // remember which topics we've received and how many.
            if var topicCount = receivedTopics[receivedTopic] {
                topicCount += 1
                receivedTopics[receivedTopic] = topicCount
            } else {
                receivedTopics[receivedTopic] = 1
            }
        }

        return received
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

    /// Check all topics for equal lengths.
    ///
    /// - Returns: Tuple of all topics of equal length and then standard topic length/count.
    private func _validateTopicLengths() -> (equalLengths: Bool, count: Int) {
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

        return (equalLengths: equalLengths, count: topicLengths)
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
        /// Check topic length against (any) existing topics is see if it is of equal length.
        func _validTopicLengths(_ topic: Topic) -> Bool {
            let topics = _validateTopicLengths()

            if (!topics.equalLengths) {
                return false
            } else if (topics.count < 0) {
                return true
            } else if (topic.count != topics.count) {
                return false
            }

            return true
        }

        if (!topic.isEmpty) {
            let topicSubscribed = isTopicSubscribed(topic)

            if (!topicSubscribed) {
                if (subscribedToAllTopics) {
                    try unsubscribeFromAllTopics()
                } else if (ignoreTopicSeperator && !_validTopicLengths(topic)) {
                    throw NanoMessageError.InvalidTopic
                }

                if (topic.count > NanoMessage.maximumTopicLength) {
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
}
