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

import Foundation
import C7
import ISFLibrary

/// Publisher socket.
public final class PublisherSocket: NanoSocket, ProtocolSocket, Publisher, PublisherSubscriber {
    public var _nanoSocket: NanoSocket {
        return self
    }

    /// The seperator used between topic and message.
    public var topicSeperator: Byte = Byte("|")
    /// The topic to send.
    public var sendTopic = C7.Data()
    /// A Dictionary of the topics sent with a count of the times sent.
    public fileprivate(set) var sentTopics = Dictionary<C7.Data, UInt64>()
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
    public func sendMessage(_ message: C7.Data, blockingMode: BlockingMode = .Blocking) throws -> Int {
        var messagePayload: C7.Data

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
            if var topicCount = self.sentTopics[self.sendTopic] {
                topicCount += 1
                self.sentTopics[self.sendTopic] = topicCount
            } else {
                self.sentTopics[self.sendTopic] = 1
            }

            if (self.resetTopicAfterSend) {                       // are we resetting the topic?
                self.sendTopic = C7.Data()
            }
        }

        return bytesSent
    }
}

extension PublisherSocket {
    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - topic:          The topic to send.
    ///   - message:        The message to send.
    ///   - blockingMode:   Specifies that the send should be performed in non-blocking mode.
    ///                     If the message cannot be sent straight away, the closureHandler
    ///                     will be passed `NanoMessageError.MessageNotSent`
    ///   - closureHandler: The closure to use when the sendMessage completes.
    public func sendMessage(topic: C7.Data, message: C7.Data, blockingMode: BlockingMode, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.ioQueue.async(group: self.ioGroup) {
            do {
                try self.mutex.lock {
                    var bytesSent: Int?
                    var errorMessage: Error?

                    self.sendTopic = topic

                    do {
                        bytesSent = try self.sendMessage(message, blockingMode: blockingMode)
                    } catch {
                        errorMessage = error
                    }

                    closureHandler(bytesSent, errorMessage)
                }
            } catch {
                print(error, to: &errorStream)
            }
        }
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - topic:          The topic to send.
    ///   - message:        The message to send.
    ///   - blockingMode:   Specifies that the send should be performed in non-blocking mode.
    ///                     If the message cannot be sent straight away, the closureHandler
    ///                     will be passed `NanoMessageError.MessageNotSent`
    ///   - closureHandler: The closure to use when the sendMessage completes.
    public func sendMessage(topic: C7.Data, message: String, blockingMode: BlockingMode, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.sendMessage(topic: topic, message: C7.Data(message), blockingMode: blockingMode, closureHandler)
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - topic:          The topic to send.
    ///   - message:        The message to send.
    ///   - blockingMode:   Specifies that the send should be performed in non-blocking mode.
    ///                     If the message cannot be sent straight away, the closureHandler
    ///                     will be passed `NanoMessageError.MessageNotSent`
    ///   - closureHandler: The closure to use when the sendMessage completes.
    public func sendMessage(topic: String, message: C7.Data, blockingMode: BlockingMode, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.sendMessage(topic: C7.Data(topic), message: message, blockingMode: blockingMode, closureHandler)
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - topic:          The topic to send.
    ///   - message:        The message to send.
    ///   - blockingMode:   Specifies that the send should be performed in non-blocking mode.
    ///                     If the message cannot be sent straight away, the closureHandler
    ///                     will be passed `NanoMessageError.MessageNotSent`
    ///   - closureHandler: The closure to use when the sendMessage completes.
    public func sendMessage(topic: String, message: String, blockingMode: BlockingMode, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.sendMessage(topic: C7.Data(topic), message: C7.Data(message), blockingMode: blockingMode, closureHandler)
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - topic:          The topic to send.
    ///   - message:        The message to send.
    ///   - closureHandler: The closure to use when the sendMessage completes.
    ///
    /// - Note:             'sendMessage()' will be called with blocking.
    public func sendMessage(topic: C7.Data, message: C7.Data, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.sendMessage(topic: topic, message: message, blockingMode: .Blocking, closureHandler)
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - topic:          The topic to send.
    ///   - message:        The message to send.
    ///   - closureHandler: The closure to use when the sendMessage completes.
    ///
    /// - Note:             'sendMessage()' will be called with blocking.
    public func sendMessage(topic: C7.Data, message: String, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.sendMessage(topic: topic, message: C7.Data(message), blockingMode: .Blocking, closureHandler)
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - topic:          The topic to send.
    ///   - message:        The message to send.
    ///   - closureHandler: The closure to use when the sendMessage completes.
    ///
    /// - Note:             'sendMessage()' will be called with blocking.
    public func sendMessage(topic: String, message: C7.Data, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.sendMessage(topic: C7.Data(topic), message: message, blockingMode: .Blocking, closureHandler)
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - topic:          The topic to send.
    ///   - message:        The message to send.
    ///   - closureHandler: The closure to use when the sendMessage completes.
    ///
    /// - Note:             'sendMessage()' will be called with blocking.
    public func sendMessage(topic: String, message: String, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.sendMessage(topic: C7.Data(topic), message: C7.Data(message), blockingMode: .Blocking, closureHandler)
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - topic:          The topic to send.
    ///   - message:        The message to send.
    ///   - timeout:        The timeout interval to set.
    ///   - closureHandler: The closure to use when the sendMessage completes.
    public func sendMessage(topic: C7.Data, message: C7.Data, timeout: TimeInterval, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.ioQueue.async(group: self.ioGroup) {
            do {
                try self.mutex.lock {
                    var bytesSent: Int?
                    var errorMessage: Error?

                    self.sendTopic = topic

                    do {
                        bytesSent = try self.sendMessage(message, timeout: timeout)
                    } catch {
                        errorMessage = error
                    }

                    closureHandler(bytesSent, errorMessage)
                }
            } catch {
                print(error, to: &errorStream)
            }
        }
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - topic:          The topic to send.
    ///   - message:        The message to send.
    ///   - timeout:        The timeout interval to set.
    ///   - closureHandler: The closure to use when the sendMessage completes.
    public func sendMessage(topic: C7.Data, message: String, timeout: TimeInterval, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.sendMessage(topic: topic, message: C7.Data(message), timeout: timeout, closureHandler)
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - topic:          The topic to send.
    ///   - message:        The message to send.
    ///   - timeout:        The timeout interval to set.
    ///   - closureHandler: The closure to use when the sendMessage completes.
    public func sendMessage(topic: String, message: C7.Data, timeout: TimeInterval, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.sendMessage(topic: C7.Data(topic), message: message, timeout: timeout, closureHandler)
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - topic:          The topic to send.
    ///   - message:        The message to send.
    ///   - timeout:        The timeout interval to set.
    ///   - closureHandler: The closure to use when the sendMessage completes.
    public func sendMessage(topic: String, message: String, timeout: TimeInterval, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.sendMessage(topic: C7.Data(topic), message: C7.Data(message), timeout: timeout, closureHandler)
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - topic:          The topic to send.
    ///   - message:        The message to send.
    ///   - timeout:        .Never
    ///   - closureHandler: The closure to use when the sendMessage completes.
    public func sendMessage(topic: C7.Data, message: C7.Data, timeout: Timeout, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.ioQueue.async(group: self.ioGroup) {
            do {
                try self.mutex.lock {
                    var bytesSent: Int?
                    var errorMessage: Error?

                    self.sendTopic = topic

                    do {
                        bytesSent = try self.sendMessage(message, timeout: timeout)
                    } catch {
                        errorMessage = error
                    }

                    closureHandler(bytesSent, errorMessage)
                }
            } catch {
                print(error, to: &errorStream)
            }
        }
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - topic:          The topic to send.
    ///   - message:        The message to send.
    ///   - timeout:        .Never
    ///   - closureHandler: The closure to use when the sendMessage completes.
    public func sendMessage(topic: C7.Data, message: String, timeout: Timeout, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.sendMessage(topic: topic, message: C7.Data(message), timeout: timeout, closureHandler)
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - topic:          The topic to send.
    ///   - message:        The message to send.
    ///   - timeout:        .Never
    ///   - closureHandler: The closure to use when the sendMessage completes.
    public func sendMessage(topic: String, message: C7.Data, timeout: Timeout, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.sendMessage(topic: C7.Data(topic), message: message, timeout: timeout, closureHandler)
    }

    /// Asynchronous send a message.
    ///
    /// - Parameters:
    ///   - topic:          The topic to send.
    ///   - message:        The message to send.
    ///   - timeout:        .Never
    ///   - closureHandler: The closure to use when the sendMessage completes.
    public func sendMessage(topic: String, message: String, timeout: Timeout, _ closureHandler: @escaping (Int?, Error?) -> Void) {
        self.sendMessage(topic: C7.Data(topic), message: C7.Data(message), timeout: timeout, closureHandler)
    }
}
