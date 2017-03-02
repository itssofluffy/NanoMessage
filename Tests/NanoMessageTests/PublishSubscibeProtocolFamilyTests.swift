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

            try node0.setSendTopic(Topic(value: "shakespeare"))
            XCTAssertEqual(node0.prependTopic, true, "node0.prependTopic")

            let node1EndPointId: Int = try node1.createEndPoint(url: bindURL, type: .Bind)
            XCTAssertGreaterThanOrEqual(node1EndPointId, 0, "node1.createEndPoint('\(bindURL)', .Bind) < 0")

            pauseForBind()

            // standard publisher -> subscriber where the topic known.
            print("subscribe to an expected topic...")
            var done = try node1.subscribeTo(topic: node0.sendTopic)
            XCTAssertEqual(done, true, "node1.subscribeTo(topic: \(node0.sendTopic))")
            XCTAssertEqual(node1.isTopicSubscribed(node0.sendTopic), true, "node1.isTopicSubscribed()")
            XCTAssertEqual(node1.removeTopicFromMessage, true, "node1.removeTopicFromMessage")

            var bytesSent = try node0.sendMessage(payload)
            XCTAssertEqual(bytesSent, node0.sendTopic.count + 1 + payload.count, "node0.bytesSent != node0.sendTopic.count + 1 + payload.count")

            var node1Received = try node1.receiveMessage()
            XCTAssertEqual(node1Received.bytes, node1.receivedTopic.count + 1 + node1Received.message.count, "node1.bytes != node1.receivedTopic.count + 1 + node1Received.message.count")
            XCTAssertEqual(node1Received.message.count, payload.count, "node1Received.message.count != payload.count")
            XCTAssertEqual(node1Received.message, payload, "node1.message != payload")
            XCTAssertEqual(node1.receivedTopic, node0.sendTopic, "node1.receivedTopic != node0.sendTopic")

            // standard publisher -> subscriber where the topic is unknown.
            print("subscribe to an unknown topic...")
            try node1.unsubscribeFrom(topic: node0.sendTopic)
            try node1.subscribeTo(topic: Topic(value: "xxxx"))
            XCTAssertEqual(node1.subscribedTopics.count, 1, "node1.subscribedTopics.count != 0")

            bytesSent = try node0.sendMessage(payload)
            XCTAssertEqual(bytesSent, node0.sendTopic.count + 1 + payload.count, "node0.bytesSent != node0.sendTopic.count + 1 + payload.count")

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

            try node0.setSendTopic(Topic(value: "planet"))

            for planet in planets {
                let bytesSent = try node0.sendMessage(Message(value: planet))
                XCTAssertEqual(bytesSent, node0.sendTopic.count + 1 + planet.utf8.count, "node0.bytesSent != node0.sendTopic.count + 1 + planet.utf8.count")

                let _ = try node1.receiveMessage()
            }

            let dwarfPlanets = [ "Eris", "Pluto", "Makemake", "Or", "Haumea", "Quaoar", "Senda", "Orcus", "2002 MS", "Ceres", "Salacia" ]

            try node0.setSendTopic(Topic(value: "dwarfPlanet"))

            for dwarfPlanet in dwarfPlanets {
                let bytesSent = try node0.sendMessage(Message(value: dwarfPlanet))
                XCTAssertEqual(bytesSent, node0.sendTopic.count + 1 + dwarfPlanet.utf8.count, "node0.bytesSent != node0.sendTopic.count + 1 + dwarfPlanet.utf8.count")

                let _ = try node1.receiveMessage()
            }

            XCTAssertEqual(node0.sentTopics.count, 1 + 2, "node0.sentTopics.count != 3")
            XCTAssertEqual(node0.sentTopics[node0.sendTopic]!, UInt64(dwarfPlanets.count), "node0.sentTopics[\"\(node0.sendTopic)\"] != \(dwarfPlanets.count)")

            XCTAssertEqual(node1.subscribedTopics.count, 0, "node1.subscribedTopics.count != 0")
            XCTAssertEqual(node1.receivedTopics.count, 1 + 2, "node1.receivedTopics.count != 3")
            XCTAssertEqual(UInt64(planets.count), node1.receivedTopics[Topic(value: "planet")]!, "planets.count != node1.receivedTopics[\"planet\"]")
            XCTAssertEqual(UInt64(dwarfPlanets.count), node1.receivedTopics[Topic(value: "dwarfPlanet")]!, "planets.count != node1.receivedTopics[\"dwarfPlanet\"]")

            print("unsubscribe from all topics and subscribe to only one topic...")
            try node1.unsubscribeFromAllTopics()
            try node1.subscribeTo(topic: Topic(value: "dwarfPlanet"))

            try node0.setSendTopic(Topic(value: "planet"))

            for planet in planets {
                let bytesSent = try node0.sendMessage(Message(value: planet))
                XCTAssertEqual(bytesSent, node0.sendTopic.count + 1 + planet.utf8.count, "node0.bytesSent != node0.sendTopic.count + 1 + planet.utf8.count")
            }

            do {
                let _ = try node1.receiveMessage()
                XCTAssert(false, "received a message on node1")
            } catch NanoMessageError.ReceiveTimedOut {
                XCTAssert(true, "\(NanoMessageError.ReceiveTimedOut)")
            }

            try node0.setSendTopic(Topic(value: "dwarfPlanet"))

            for dwarfPlanet in dwarfPlanets {
                let bytesSent = try node0.sendMessage(Message(value: dwarfPlanet))
                XCTAssertEqual(bytesSent, node0.sendTopic.count + 1 + dwarfPlanet.utf8.count, "node0.bytesSent != node0.sendTopic.count + 1 + dwarfPlanet.utf8.count")
            }

            var received = try node1.receiveMessage()
            XCTAssertEqual(node1.receivedTopic, node0.sendTopic, "node1.receivedTopic != node0.sendTopic")
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

            try node0.setSendTopic(Topic(value: "AAA"))

            let _ = try node0.sendMessage(payload)

            received = try node1.receiveMessage()

            XCTAssertEqual(node1.receivedTopic.count, node0.sendTopic.count, "node1.receivedTopic.count != node0.sendTopic.count")
            XCTAssertEqual(node1.receivedTopic, node0.sendTopic, "node1.receivedTopic != node0.sendTopic")
            XCTAssertEqual(received.message, payload, "node1.receivedTopic != payload")

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
