/*
    PublishSubscibeProtocolFamilyTests.swift

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

import XCTest
import Foundation

@testable import NanoMessage

class PublishSubscribeProtocolFamilyTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testPublishSubscribeTests(connectAddress: String, bindAddress: String = "") {
        guard let connectURL = URL(string: connectAddress) else {
            XCTAssert(false, "connectURL is invalid")
            return
        }

        guard let bindURL = URL(string: (bindAddress.isEmpty) ? connectAddress : bindAddress) else {
            XCTAssert(false, "bindURL is invalid")
            return
        }

        var completed = false

        do {
            let node0 = try PublisherSocket()
            let node1 = try SubscriberSocket()

            try node0.setSendTimeout(seconds: 0.5)
            try node1.setReceiveTimeout(seconds: 0.5)

            let node0EndPointId: Int = try node0.createEndPoint(url: connectURL, type: .Connect)
            XCTAssertGreaterThanOrEqual(node0EndPointId, 0, "node0.createEndPoint('\(connectURL)', .Connect) < 0")

            let node1EndPointId: Int = try node1.createEndPoint(url: bindURL, type: .Bind)
            XCTAssertGreaterThanOrEqual(node1EndPointId, 0, "node1.createEndPoint('\(bindURL)', .Bind) < 0")

            pauseForBind()

            // standard publisher -> subscriber where the topic known.
            print("subscribe to an expected topic...")

            var topic = try Topic(value: "shakespeare")
            var done = try node1.subscribeTo(topic: topic)

            XCTAssertEqual(done, true, "node1.subscribeTo(topic: \(topic))")
            XCTAssertEqual(node1.isTopicSubscribed(topic), true, "node1.isTopicSubscribed()")
            XCTAssertEqual(node1.removeTopicFromMessage, true, "node1.removeTopicFromMessage")

            var message = Message(topic: topic, message: payload.data)

            var node0Sent = try node0.sendMessage(message)
            XCTAssertEqual(node0Sent.bytes, topic.count + 1 + payload.count, "node0.bytesSent != topic.count + 1 + payload.count")

            var node1Received = try node1.receiveMessage()
            XCTAssertEqual(node1Received.bytes, node1Received.topic!.count + 1 + node1Received.message.count, "node1.bytes != node1received.topic.count + 1 + node1Received.message.count")
            XCTAssertEqual(node1Received.message.count, payload.count, "node1Received.message.count != payload.count")
            XCTAssertEqual(node1Received.message, payload, "node1.message != payload")
            XCTAssertEqual(node1Received.topic, topic, "node1Received.topic != topic")

            // standard publisher -> subscriber where the topic is unknown.
            print("subscribe to an unknown topic...")
            try node1.unsubscribeFrom(topic: topic)
            try node1.subscribeTo(topic: Topic(value: "xxxx"))
            XCTAssertEqual(node1.subscribedTopics.count, 1, "node1.subscribedTopics.count != 0")

            message = try Message(topic: Topic(value: "yyyy"), message: payload.data)

            node0Sent = try node0.sendMessage(message)
            XCTAssertEqual(node0Sent.bytes, node0Sent.topic!.count + 1 + payload.count, "node0.bytesSent != node0Sent.topic.count + 1 + payload.count")

            try node1.setReceiveTimeout(seconds: -1)

            do {
                node1Received = try node1.receiveMessage(timeout: TimeInterval(seconds: 0.5))
                XCTAssert(false, "received a message on node1")
            } catch NanoMessageError.ReceiveTimedOut {
                XCTAssert(true, "\(NanoMessageError.ReceiveTimedOut))")   // we have timedout
            }

            try node1.setReceiveTimeout(seconds: 0.5)

            try node1.unsubscribeFromAllTopics()

            print("subscribe to all topics...")

            done = try node1.subscribeToAllTopics()
            XCTAssertEqual(done, true, "node1.subscribeToAllTopics()")

            let planets = [ "mercury", "venus", "mars", "earth", "mars", "jupiter", "saturn", "uranus", "neptune" ]

            topic = try Topic(value: "planet")

            for planet in planets {
                message = Message(topic: topic, message: planet)

                let sent = try node0.sendMessage(message)
                XCTAssertEqual(sent.bytes, sent.topic!.count + 1 + planet.utf8.count, "sent.bytes != sent.topic.count + 1 + planet.utf8.count")

                let _ = try node1.receiveMessage()
            }

            let dwarfPlanets = [ "Eris", "Pluto", "Makemake", "Or", "Haumea", "Quaoar", "Senda", "Orcus", "2002 MS", "Ceres", "Salacia" ]

            topic = try Topic(value: "dwarfPlanet")

            for dwarfPlanet in dwarfPlanets {
                message = Message(topic: topic, message: dwarfPlanet)

                let sent = try node0.sendMessage(message)
                XCTAssertEqual(sent.bytes, sent.topic!.count + 1 + dwarfPlanet.utf8.count, "sent.bytes != sent.topic.count + 1 + dwarfPlanet.utf8.count")

                let _ = try node1.receiveMessage()
            }

            XCTAssertEqual(node0.sentTopics.count, 4, "node0.sentTopics.count != 3")
            XCTAssertEqual(node0.sentTopics[topic]!, UInt64(dwarfPlanets.count), "node0.sentTopics[\"\(topic)\"] != \(dwarfPlanets.count)")

            XCTAssertEqual(node1.subscribedTopics.count, 0, "node1.subscribedTopics.count != 0")
            XCTAssertEqual(node1.receivedTopics.count, 1 + 2, "node1.receivedTopics.count != 3")
            try XCTAssertEqual(UInt64(planets.count), node1.receivedTopics[Topic(value: "planet")]!, "planets.count != node1.receivedTopics[\"planet\"]")
            try XCTAssertEqual(UInt64(dwarfPlanets.count), node1.receivedTopics[Topic(value: "dwarfPlanet")]!, "planets.count != node1.receivedTopics[\"dwarfPlanet\"]")

            print("unsubscribe from all topics and subscribe to only one topic...")
            try node1.unsubscribeFromAllTopics()
            try node1.subscribeTo(topic: Topic(value: "dwarfPlanet"))


            for planet in planets {
                message = try Message(topic: Topic(value: "planet"), message: planet)

                let sent = try node0.sendMessage(message)
                XCTAssertEqual(sent.bytes, sent.topic!.count + 1 + planet.utf8.count, "sent.bytes != sent.topic.count + 1 + planet.utf8.count")
            }

            do {
                let _ = try node1.receiveMessage()
                XCTAssert(false, "received a message on node1")
            } catch NanoMessageError.ReceiveTimedOut {
                XCTAssert(true, "\(NanoMessageError.ReceiveTimedOut)")
            }

            topic = try Topic(value: "dwarfPlanet")

            for dwarfPlanet in dwarfPlanets {
                message = Message(topic: topic, message: dwarfPlanet)

                let sent = try node0.sendMessage(message)
                XCTAssertEqual(sent.bytes, sent.topic!.count + 1 + dwarfPlanet.utf8.count, "sent.bytes != node0.sendTopic.count + 1 + dwarfPlanet.utf8.count")
            }

            var received = try node1.receiveMessage()
            XCTAssertEqual(received.topic, topic, "received.topic != topic")
            XCTAssertEqual(received.message.string, dwarfPlanets[0], "received.message.string != \"\(dwarfPlanets[0])\"")

            try node1.unsubscribeFromAllTopics()

            print("ignore topic seperator...")

            node0.ignoreTopicSeperator = true

            try node1.subscribeTo(topic: Topic(value: "AAA"))
            try node1.subscribeTo(topic: Topic(value: "BBB"))
            try node1.subscribeTo(topic: Topic(value: "CCCC"))
            try node1.subscribeTo(topic: Topic(value: "DDD"))

            do {
                let _ = try node1.flipIgnoreTopicSeperator()
            } catch NanoMessageError.InvalidTopic {
                XCTAssert(true, "\(NanoMessageError.InvalidTopic))")   // have we unequal length topics
            }

            try node1.unsubscribeFrom(topic: Topic(value: "CCCC"))
            try node1.subscribeTo(topic: Topic(value: "CCC"))

            let _ = try node1.flipIgnoreTopicSeperator()
            XCTAssertEqual(node1.ignoreTopicSeperator, true, "node1.ignoreTopicSeperator")

            message = try Message(topic: Topic(value: "AAA"), message: payload.data)

            let sent = try node0.sendMessage(message)

            received = try node1.receiveMessage()

            XCTAssertEqual(received.topic!.count, sent.topic!.count, "received.topic.count != sent.topic.count")
            XCTAssertEqual(received.topic, sent.topic, "received.topic != sent.topic")
            XCTAssertEqual(received.message, payload, "received.topic != payload")

            completed = true
        } catch let error as NanoMessageError {
            XCTAssert(false, "\(error)")
        } catch {
            XCTAssert(false, "an unexpected error '\(error)' has occured in the library libNanoMessage.")
        }

        XCTAssert(completed, "test not completed")
    }

    func testTCPPublishSubscribe() {
        testPublishSubscribeTests(connectAddress: "tcp://localhost:5555", bindAddress: "tcp://*:5555")
    }

    func testInProcessPublishSubscribe() {
        testPublishSubscribeTests(connectAddress: "inproc:///tmp/pipeline.inproc")
    }

    func testInterProcessPublishSubscribe() {
        testPublishSubscribeTests(connectAddress: "ipc:///tmp/pipeline.ipc")
    }

    func testWebSocketPublishSubscribe() {
        testPublishSubscribeTests(connectAddress: "ws://localhost:5555", bindAddress: "ws://*:5555")
    }

#if !os(OSX)
    static let allTests = [
        ("testTCPPublishSubscribe", testTCPPublishSubscribe),
        ("testInProcessPublishSubscribe", testInProcessPublishSubscribe),
        ("testInterProcessPublishSubscribe", testInterProcessPublishSubscribe),
        ("testWebSocketPublishSubscribe", testWebSocketPublishSubscribe)
    ]
#endif
}
