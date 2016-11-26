/*
    SubscriberSocket.swift

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
    public fileprivate(set) var receivedTopic = Data()
/// A dictionary of topics and their count that have been received
    public fileprivate(set) var receivedTopics = Dictionary<Data, UInt64>()
/// Remove the topic from the received data.
    public var removeTopicFromMessage = true
/// A set of all the subscribed topics.
    public fileprivate(set) var subscribedTopics = Set<Data>()
/// Is the socket subscribed to all topics
    public fileprivate(set) var subscribedToAllTopics = false

    public init(socketDomain: SocketDomain) throws {
        try super.init(socketDomain: socketDomain, socketProtocol: .SubscriberProtocol)
    }

    public convenience init() throws {
        try self.init(socketDomain: .StandardSocket)
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
/// - Throws:  `NanoMessageError.receiveMessage` there was an issue when receiving the message.
///            `NanoMessageError.MessageNotReceived` in non-blocking mode there was no message to receive.
///            `NanoMessageError.TimedOut` the receive timedout.
///
/// - Returns: the number of bytes received and the received message
    public func receiveMessage(blockingMode: BlockingMode = .Blocking) throws -> (bytes: Int, message: Data) {
/// Does the message/payload contain the specified topic
        func _messageHasTopic(_ topic: Data, _ message: Data) -> Bool {
            if (((self.ignoreTopicSeperator) ? topic.count : topic.count + 1) <= message.count) {
                if (Data(message[0 ..< topic.count]) != topic) {
                    return false
                } else if (self.ignoreTopicSeperator || message[topic.count] == self.topicSeperator) {
                    return true
                }
            }

            return false
        }

/// Get the topic from the message/payload if it exists using the topic seperator.
        func _getTopicFromMessage(_ message: Data) -> Data {
            if let index = message.index(of: self.topicSeperator) {
                return Data(message[0 ..< index])
            }

            return message
        }

        self.receivedTopic = Data()

        var received: (bytes: Int, message: Data) = try receivePayloadFromSocket(self.socketFd, blockingMode)

        if (received.bytes > 0) {                                               // we have a message to process...
            if (!self.subscribedToAllTopics || self.ignoreTopicSeperator) {     // determine how to extract the topic.
                for topic in self.subscribedTopics {
                    if (_messageHasTopic(topic, received.message)) {
                        self.receivedTopic = topic

                        break
                    }
                }
            } else {
                let topic = _getTopicFromMessage(received.message)

                if (topic != received.message) {
                    self.receivedTopic = topic
                }
            }

            if (self.receivedTopic.isEmpty) {                                   // check we've extracted a topic
                throw NanoMessageError.NoTopic
            }

            if (self.removeTopicFromMessage) {                                  // are we removing the topic from the message/payload...
                var offset = self.receivedTopic.count
                if (self.subscribedToAllTopics || !self.ignoreTopicSeperator) {
                    offset += 1
                }

                let range = received.message.startIndex ..< received.message.index(received.message.startIndex, offsetBy: offset)
                received.message.removeSubrange(range)
            }

            // remember which topics we've received and how many.
            if var topicCount = receivedTopics[self.receivedTopic] {
                topicCount += 1
                receivedTopics[self.receivedTopic] = topicCount
            } else {
                receivedTopics[self.receivedTopic] = 1
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
    public func isTopicSubscribed(_ topic: Data) -> Bool {
        return self.subscribedTopics.contains(topic)
    }

/// Is the specified topic already subscribed too.
///
/// - Parameters:
///   - topic: The topic to check.
///
/// - Returns: If the topic has been subscribed too.
    public func isTopicSubscribed(_ topic: String) -> Bool {
        return self.isTopicSubscribed(Data(topic))
    }

/// Check all topics for equal lengths.
///
/// - Returns: Tuple of all topics of equal length and then standard topic length/count.
    private func _validateTopicLengths() -> (equalLengths: Bool, count: Int) {
        var equalLengths = true
        var topicLengths = -1

        for topic in self.subscribedTopics {
            if (topicLengths < 0) {
                topicLengths = topic.count
            } else if (topicLengths != topic.count) {
                equalLengths = false

                break
            }
        }

        return (equalLengths, topicLengths)
    }

/// Flip the ignore topic seperator, when true all topic lengths must be of equal length.
///
/// - Throws:  `NanoMessageError.SetSocketOption`
///            `NanoMessageError.InvalidTopic`
///
/// - Returns: Has the function been successful.
    public func flipIgnoreTopicSeperator() throws -> Bool {
        if (!self.subscribedToAllTopics) {
            if (!self.ignoreTopicSeperator) {
                let topics = self._validateTopicLengths()

                if (!topics.equalLengths) {
                    throw NanoMessageError.InvalidTopic
                }
            }

            self.ignoreTopicSeperator = !self.ignoreTopicSeperator

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
    public func subscribeTo(topic: Data) throws -> Bool {
/// Check topic length against (any) existing topics is see if it is of equal length.
        func _validTopicLengths(_ topic: Data) -> Bool {
            let topics = self._validateTopicLengths()

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
            let topicSubscribed = self.isTopicSubscribed(topic)

            if (!topicSubscribed) {
                if (self.subscribedToAllTopics) {
                    try self.unsubscribeFromAllTopics()
                } else if (self.ignoreTopicSeperator && !_validTopicLengths(topic)) {
                    throw NanoMessageError.InvalidTopic
                }

                if (topic.count > NanoMessage.maximumTopicLength) {
                    throw NanoMessageError.TopicLength
                }

                try setSocketOption(self.socketFd, .Subscribe, topic, .SubscriberProtocol)

                self.subscribedTopics.insert(topic)
            }

            return !topicSubscribed
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
    public func subscribeTo(topic: String) throws -> Bool {
        return try self.subscribeTo(topic: Data(topic))
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
    public func unsubscribeFrom(topic: Data) throws -> Bool {
        if (!topic.isEmpty) {
            let topicSubscribed = self.isTopicSubscribed(topic)

            if (topicSubscribed) {
                try setSocketOption(self.socketFd, .UnSubscribe, topic, .SubscriberProtocol)

                self.subscribedTopics.remove(topic)

                if (self.subscribedTopics.isEmpty) {
                    try self.unsubscribeFromAllTopics()
                }
            }

            return topicSubscribed
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
    public func unsubscribeFrom(topic: String) throws -> Bool {
        return try self.unsubscribeFrom(topic: Data(topic))
    }

/// Subscribe to all topics.
///
/// - Throws: `NanoMessageError.SetSocketOption` if an issue has been encountered.
///
/// - Returns: If we have managed to subscribe to all topics.
///
/// - Note:    You cannot subscribe to all topics if `ignoreTopicSeperator` is true.
    public func subscribeToAllTopics() throws -> Bool {
        if (!self.ignoreTopicSeperator) {
            if (!self.subscribedToAllTopics) {
                for topic in self.subscribedTopics {
                    try self.unsubscribeFrom(topic: topic)
                }

                try setSocketOption(self.socketFd, .Subscribe, "", .SubscriberProtocol)

                self.subscribedToAllTopics = true
            }

            return self.subscribedToAllTopics
        }

        return false
    }

/// Unsubscribe from all topics.
///
/// - Throws: `NanoMessageError.SetSocketOption` if an issue has been encountered.
    public func unsubscribeFromAllTopics() throws {
        for topic in self.subscribedTopics {
            try self.unsubscribeFrom(topic: topic)
        }

        if (self.subscribedToAllTopics) {
            try setSocketOption(self.socketFd, .UnSubscribe, "", .SubscriberProtocol)
        }

        self.subscribedToAllTopics = false
    }
}
