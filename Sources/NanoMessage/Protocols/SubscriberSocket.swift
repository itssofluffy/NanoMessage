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
import CNanoMessage

public final class SubscriberSocket: NanoSocket, ProtocolSocket, Receiver, PublisherSubscriber {
    public var _nanoSocket: NanoSocket {
        return self
    }

    public var topicSeperator: Byte = Byte("|")                             // the seperator used between topic and message
    public fileprivate(set) var ignoreTopicSeperator = false                // ignore topic seperator, true means that all topics must be of an equal length
                                                                            // use flipIgnoreTopicSeperator() to flip between flase/true true/false

    public fileprivate(set) var receivedTopic = Data()                      // the topic last received
    public fileprivate(set) var receivedTopics = Dictionary<Data, UInt>()   // a dictionary of topics and their count that have been received
    public var removeTopicFromMessage: Bool = true                          // remove the topic from the received data
    public fileprivate(set) var subscribedTopics = Set<Data>()              // a set of all the subscribed topics
    public fileprivate(set) var subscribedToAllTopics = false               //

    public init(socketDomain: SocketDomain) throws {
        try super.init(socketDomain: socketDomain, socketProtocol: .SubscriberProtocol)
    }

    public convenience init() throws {
        try self.init(socketDomain: .StandardSocket)
    }
}

extension SubscriberSocket {
    private func _messageHasTopic(_ topic: Data, _ message: Data) -> Bool {
        if (((self.ignoreTopicSeperator) ? topic.count : topic.count + 1) <= message.count) {
            if (Data(message[0 ..< topic.count]) != topic) {
                return false
            } else if (self.ignoreTopicSeperator || message[topic.count] == self.topicSeperator) {
                return true
            }
        }

        return false
    }

    private func _getTopicFromMessage(_ message: Data) -> Data {
        if let index = message.index(of: self.topicSeperator) {
            return Data(message[0 ..< index])
        }

        return message
    }

    public func receiveMessage(blockingMode: BlockingMode = .Blocking) throws -> (bytes: Int, message: Data) {
        var received: (bytes: Int, message: Data) = try receivePayloadFromSocket(self.socketFd, blockingMode)

        if (received.bytes > 0) {
            self.receivedTopic = Data()

            if (!self.subscribedToAllTopics || self.ignoreTopicSeperator) {
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

            if (self.receivedTopic.isEmpty) {
                throw NanoMessageError(errorNumber: 4, errorMessage: "unknown topic received")
            }

            if (self.removeTopicFromMessage) {
                var offset = self.receivedTopic.count
                if (self.subscribedToAllTopics || !self.ignoreTopicSeperator) {
                    offset += 1
                }

                let range = received.message.startIndex ..< received.message.index(received.message.startIndex, offsetBy: offset)
                received.message.removeSubrange(range)
            }

            if var topicCount = receivedTopics[self.receivedTopic] {
                topicCount += 1
                receivedTopics[self.receivedTopic] = topicCount
            } else {
                receivedTopics[self.receivedTopic] = 1
            }
        }

        return received
    }

    public func receiveMessage(blockingMode: BlockingMode = .Blocking) throws -> (bytes: Int, message: String) {
        let received: (bytes: Int, message: Data) = try self.receiveMessage(blockingMode: blockingMode)

        return (received.bytes, try String(data: received.message))
    }
}

extension SubscriberSocket {
    public func isTopicSubscribed(_ topic: Data) -> Bool {
        return self.subscribedTopics.contains(topic)
    }

    public func isTopicSubscribed(_ topic: String) -> Bool {
        return self.isTopicSubscribed(Data(topic))
    }

    private func _validTopicLengths(_ topic: Data) -> Bool {
        let topics: (equalLengths: Bool, count: Int) = _validateTopicLengths()

        if (!topics.equalLengths) {
            return false
        } else if (topics.count < 0) {
            return true
        } else if (topic.count != topics.count) {
            return false
        }

        return true
    }

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

        return (equalLengths: equalLengths, count: topicLengths)
    }

    public func flipIgnoreTopicSeperator() throws -> Bool {
        if (!self.subscribedToAllTopics) {
            if (!self.ignoreTopicSeperator) {
                let topics: (equalLengths: Bool, _: Int) = _validateTopicLengths()

                if (!topics.equalLengths) {
                    throw NanoMessageError(errorNumber: 4, errorMessage: "topics of unequal length")
                }
            }

            self.ignoreTopicSeperator = !self.ignoreTopicSeperator

            return true
        }

        return false
    }

    @discardableResult
    public func subscribeTo(topic: Data) throws -> Bool {
        let topicSubscribed = self.isTopicSubscribed(topic)

        if (!topicSubscribed) {
            if (self.subscribedToAllTopics) {
                try self.unsubscribeFromAllTopics()
            } else if (self.ignoreTopicSeperator && !_validTopicLengths(topic)) {
                throw NanoMessageError(errorNumber: 4, errorMessage: "topics of unequal length")
            }

            try setSocketOption(self.socketFd, NN_SUB_SUBSCRIBE, topic, .SubscriberProtocol)
            self.subscribedTopics.insert(topic)
        }

        return !topicSubscribed
    }

    @discardableResult
    public func subscribeTo(topic: String) throws -> Bool {
        return try self.subscribeTo(topic: Data(topic))
    }

    @discardableResult
    public func unsubscribeFrom(topic: Data) throws -> Bool {
        let topicSubscribed = self.isTopicSubscribed(topic)

        if (topicSubscribed) {
            try setSocketOption(self.socketFd, NN_SUB_UNSUBSCRIBE, topic, .SubscriberProtocol)
            self.subscribedTopics.remove(topic)

            if (self.subscribedTopics.isEmpty) {
                try self.unsubscribeFromAllTopics()
            }
        }

        return topicSubscribed
    }

    @discardableResult
    public func unsubscribeFrom(topic: String) throws -> Bool {
        return try self.unsubscribeFrom(topic: Data(topic))
    }

    public func subscribeToAllTopics() throws -> Bool {
        if (!self.ignoreTopicSeperator) {
            if (!self.subscribedToAllTopics) {
                for topic in self.subscribedTopics {
                    try self.unsubscribeFrom(topic: topic)
                }

                try setSocketOption(self.socketFd, NN_SUB_SUBSCRIBE, "", .SubscriberProtocol)

                self.subscribedToAllTopics = true
            }

            return self.subscribedToAllTopics
        }

        return false
    }

    public func unsubscribeFromAllTopics() throws {
        for topic in self.subscribedTopics {
            try self.unsubscribeFrom(topic: topic)
        }

        if (self.subscribedToAllTopics) {
            try setSocketOption(self.socketFd, NN_SUB_UNSUBSCRIBE, "", .SubscriberProtocol)
        }

        self.subscribedToAllTopics = false
    }
}
