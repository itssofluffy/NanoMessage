/*
    PublishSubscibeProtocolFamilyTests.swift

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

import XCTest
import Foundation

@testable import NanoMessage

class PublishSubscribeProtocolFamilyTests: XCTestCase {
    func testPublishSubscribeStandard(connectAddress: String, bindAddress: String = "") {
        let bAddress = (bindAddress == "") ? connectAddress : bindAddress

        var completed = false

        do {
            let node0 = try PublisherSocket()
            let node1 = try SubscriberSocket()

            let node0EndPointId: Int = try node0.connectToAddress(connectAddress)
            XCTAssertGreaterThanOrEqual(node0EndPointId, 0, "node0.connectToAddress(endPointAddress: '\(connectAddress)') < 0")

            node0.sendTopic = "shakespeare"
            XCTAssertEqual(node0.prependTopic, true, "node0.prependTopic")

            let node1EndPointId: Int = try node1.bindToAddress(bAddress)
            XCTAssertGreaterThanOrEqual(node1EndPointId, 0, "node1.bindToAddress(endPointAddress: '\(bAddress)') < 0")

            sleep(1)    // give nn_bind a chance to asynchronously bind to the port

            // standard publisher -> subscriber where the topic known.
            print("subscribe to an expected topic...")
            let done = try node1.subscribeTo(topic: node0.sendTopic)
            XCTAssertEqual(done, true, "node1.subscribeTo(topic: \(node0.sendTopic))")
            XCTAssertEqual(node1.isTopicSubscribed(node0.sendTopic), true, "node1.isTopicSubscribed()")
            XCTAssertEqual(node1.removeTopicFromMessage, true, "node1.removeTopicFromMessage")

            var bytesSent = try node0.sendMessage(payload)
            XCTAssertEqual(bytesSent, node0.sendTopic.count + 1 + payload.utf8.count, "node0.bytesSent != node0.sendTopic.count + 1 + payload.utf8.count")

            var node1Received: (bytes: Int, message: String) = try node1.receiveMessage()
            XCTAssertEqual(node1Received.bytes, node1.receivedTopic.count + 1 + node1Received.message.utf8.count, "node1.bytes != node1.receivedTopic.count + 1 + message.utf8.count")
            XCTAssertEqual(node1Received.message.utf8.count, payload.utf8.count, "node1.message.utf8.count != payload.utf8.count")
            XCTAssertEqual(node1Received.message, payload, "node1.message != payload")
            XCTAssertEqual(node1.receivedTopic, node0.sendTopic, "node1.receivedTopic != node0.sendTopic")

            // standard publisher -> subscriber where the topic is unknown.
            print("subscribe to an unknown topic...")
            try node1.unsubscribeFrom(topic: node0.sendTopic)
            try node1.subscribeTo(topic: "xxxx")
            XCTAssertEqual(node1.subscribedTopics.count, 1, "node1.subscribedTopics.count != 0")
            try node1.setReceiverTimeout(milliseconds: 1000)   // set receiver timeout to 1 second

            bytesSent = try node0.sendMessage(payload)
            XCTAssertEqual(bytesSent, node0.sendTopic.count + 1 + payload.utf8.count, "node0.bytesSent != node0.sendTopic.count + 1 + payload.utf8.count")

            do {
                node1Received = try node1.receiveMessage()
                XCTAssert(false, "received a message on node1")
            } catch NanoMessageError.Error(let errorNumber, let errorMessage) {
                XCTAssertEqual(errorNumber, 3, "\(errorMessage) (#\(errorNumber))")   // have we timedout
            }

            completed = true
        } catch NanoMessageError.nanomsgError(let errorNumber, let errorMessage) {
            XCTAssert(false, "\(errorMessage) (#\(errorNumber))")
        } catch NanoMessageError.Error(let errorNumber, let errorMessage) {
            XCTAssert(false, "\(errorMessage) (#\(errorNumber))")
        } catch (let errorMessage) {
            XCTAssert(false, "An Unknown error '\(errorMessage)' has occured in the library NanoMessage.")
        }

        XCTAssert(completed, "test not completed")
    }

    func testPublishSubscribeAllTopics(connectAddress: String, bindAddress: String = "") {
        let bAddress = (bindAddress == "") ? connectAddress : bindAddress

        var completed = false

        do {
            print("subscribe to all topics...")
            let node0 = try PublisherSocket()
            let node1 = try SubscriberSocket()

            let node0EndPointId: Int = try node0.connectToAddress(connectAddress)
            XCTAssertGreaterThanOrEqual(node0EndPointId, 0, "node0.connectToAddress(endPointAddress: '\(connectAddress)') < 0")

            let node1EndPointId: Int = try node1.bindToAddress(bAddress)
            XCTAssertGreaterThanOrEqual(node1EndPointId, 0, "node1.bindToAddress(endPointAddress: '\(bAddress)') < 0")

            sleep(1)    // give nn_bind a chance to asynchronously bind to the port

            try node1.setReceiverTimeout(milliseconds: 1000)

            let done = try node1.subscribeToAllTopics()
            XCTAssertEqual(done, true, "node1.subscribeToAllTopics()")

            let planets = [ "mercury", "venus", "mars", "earth", "mars", "jupiter", "saturn", "uranus", "neptune" ]

            node0.sendTopic = "planet"

            for planet in planets {
                let bytesSent = try node0.sendMessage(planet)
                XCTAssertEqual(bytesSent, node0.sendTopic.count + 1 + planet.utf8.count, "node0.bytesSent != node0.sendTopic.count + 1 + planet.utf8.count")

                let _: (bytes: Int, message: String) = try node1.receiveMessage()
            }

            let dwarfPlanets = [ "Eris", "Pluto", "Makemake", "Or", "Haumea", "Quaoar", "Senda", "Orcus", "2002 MS", "Ceres", "Salacia" ]

            node0.sendTopic = "dwarfPlanet"

            for dwarfPlanet in dwarfPlanets {
                let bytesSent = try node0.sendMessage(dwarfPlanet)
                XCTAssertEqual(bytesSent, node0.sendTopic.count + 1 + dwarfPlanet.utf8.count, "node0.bytesSent != node0.sendTopic.count + 1 + dwarfPlanet.utf8.count")

                let _: (bytes: Int, message: String) = try node1.receiveMessage()
            }

            XCTAssertEqual(node0.sentTopics.count, 2, "node0.sentTopics.count != 2")
            XCTAssertEqual(node0.sentTopics[node0.sendTopic]!, UInt(dwarfPlanets.count), "node0.sentTopics[\"\(node0.sendTopic)\"] != \(dwarfPlanets.count)")

            XCTAssertEqual(node1.subscribedTopics.count, 0, "node1.subscribedTopics.count != 0")
            XCTAssertEqual(node1.receivedTopics.count, 2, "node1.receivedTopics.count != 1")
            XCTAssertEqual(UInt(planets.count), node1.receivedTopics["planet"]!, "planets.count != node1.receivedTopics[\"planet\"]")
            XCTAssertEqual(UInt(dwarfPlanets.count), node1.receivedTopics["dwarfPlanet"]!, "planets.count != node1.receivedTopics[\"dwarfPlanet\"]")

            print("unsubscribe from all topics and subscribe to only one topic...")
            try node1.unsubscribeFromAllTopics()
            try node1.subscribeTo(topic: "dwarfPlanet")
            try node1.setReceiverTimeout(milliseconds: 1000)   // set receiver timeout to 1 second

            node0.sendTopic = "planet"

            for planet in planets {
                let bytesSent = try node0.sendMessage(planet)
                XCTAssertEqual(bytesSent, node0.sendTopic.count + 1 + planet.utf8.count, "node0.bytesSent != node0.sendTopic.count + 1 + planet.utf8.count")
            }

            do {
                let _: (bytes: Int, message: String) = try node1.receiveMessage()
                XCTAssert(false, "received a message on node1")
            } catch NanoMessageError.Error(let errorNumber, let errorMessage) {
                XCTAssertEqual(errorNumber, 3, "\(errorMessage) (#\(errorNumber))")   // have we timedout
            }

            node0.sendTopic = "dwarfPlanet"

            for dwarfPlanet in dwarfPlanets {
                let bytesSent = try node0.sendMessage(dwarfPlanet)
                XCTAssertEqual(bytesSent, node0.sendTopic.count + 1 + dwarfPlanet.utf8.count, "node0.bytesSent != node0.sendTopic.count + 1 + dwarfPlanet.utf8.count")
            }

            let received: (bytes: Int, message: String) = try node1.receiveMessage()
            XCTAssertEqual(node1.receivedTopic, node0.sendTopic, "node1.receivedTopic != node0.sendTopic")
            XCTAssertEqual(received.message, dwarfPlanets[0], "received.message != \"\(dwarfPlanets[0])\"")

            completed = true
        } catch NanoMessageError.nanomsgError(let errorNumber, let errorMessage) {
            XCTAssert(false, "\(errorMessage) (#\(errorNumber))")
        } catch NanoMessageError.Error(let errorNumber, let errorMessage) {
            XCTAssert(false, "\(errorMessage) (#\(errorNumber))")
        } catch (let errorMessage) {
            XCTAssert(false, "An Unknown error '\(errorMessage)' has occured in the library NanoMessage.")
        }

        XCTAssert(completed, "test not completed")
    }

    func testPublishSubscribeIgnoreTopicSeperator(connectAddress: String, bindAddress: String = "") {
        let bAddress = (bindAddress == "") ? connectAddress : bindAddress

        var completed = false

        do {
            print("ignore topic seperator...")
            let node0 = try PublisherSocket()
            let node1 = try SubscriberSocket()

            let node0EndPointId: Int = try node0.connectToAddress(connectAddress)
            XCTAssertGreaterThanOrEqual(node0EndPointId, 0, "node0.connectToAddress(endPointAddress: '\(connectAddress)') < 0")

            let node1EndPointId: Int = try node1.bindToAddress(bAddress)
            XCTAssertGreaterThanOrEqual(node1EndPointId, 0, "node1.bindToAddress(endPointAddress: '\(bAddress)') < 0")

            sleep(1)    // give nn_bind a chance to asynchronously bind to the port

            node0.ignoreTopicSeperator = true

            try node1.subscribeTo(topic: "AAA")
            try node1.subscribeTo(topic: "BBB")
            try node1.subscribeTo(topic: "CCCC")
            try node1.subscribeTo(topic: "DDD")

            do {
                let _ = try node1.flipIgnoreTopicSeperator()
            } catch NanoMessageError.Error(let errorNumber, let errorMessage) {
                XCTAssertEqual(errorNumber, 4, "\(errorMessage) (#\(errorNumber))")   // have we timedout
            }

            try node1.unsubscribeFrom(topic: "CCCC")
            try node1.subscribeTo(topic: "CCC")

            let _ = try node1.flipIgnoreTopicSeperator()
            XCTAssertEqual(node1.ignoreTopicSeperator, true, "node1.ignoreTopicSeperator")

            try node1.setReceiverTimeout(milliseconds: 1000)

            node0.sendTopic = "AAA"

            let _ = try node0.sendMessage(payload)

            let received: (bytes: Int, message: String) = try node1.receiveMessage()

            XCTAssertEqual(node1.receivedTopic.count, node0.sendTopic.count, "node1.receivedTopic.count != node0.sendTopic.count")
            XCTAssertEqual(node1.receivedTopic, node0.sendTopic, "node1.receivedTopic != node0.sendTopic")
            XCTAssertEqual(received.message, payload, "node1.receivedTopic != payload")

            completed = true
        } catch NanoMessageError.nanomsgError(let errorNumber, let errorMessage) {
            XCTAssert(false, "\(errorMessage) (#\(errorNumber))")
        } catch NanoMessageError.Error(let errorNumber, let errorMessage) {
            XCTAssert(false, "\(errorMessage) (#\(errorNumber))")
        } catch (let errorMessage) {
            XCTAssert(false, "An Unknown error '\(errorMessage)' has occured in the library NanoMessage.")
        }

        XCTAssert(completed, "test not completed")
    }

    func testTCPPublishSubscribe() {
        print("TCP tests...")
        testPublishSubscribeStandard(connectAddress: "tcp://localhost:5555", bindAddress: "tcp://*:5555")
        testPublishSubscribeAllTopics(connectAddress: "tcp://localhost:5555", bindAddress: "tcp://*:5555")
        testPublishSubscribeIgnoreTopicSeperator(connectAddress: "tcp://localhost:5555", bindAddress: "tcp://*:5555")
    }

    func testInProcessPublishSubscribe() {
        print("In-Process tests...")
        testPublishSubscribeStandard(connectAddress: "inproc:///tmp/pipeline.inproc")
        testPublishSubscribeAllTopics(connectAddress: "inproc:///tmp/pipeline.inproc")
        testPublishSubscribeIgnoreTopicSeperator(connectAddress: "inproc:///tmp/pipeline.inproc")
    }

    func testInterProcessPublishSubscribe() {
        print("Inter Process tests...")
        testPublishSubscribeStandard(connectAddress: "ipc:///tmp/pipeline.ipc")
        testPublishSubscribeAllTopics(connectAddress: "ipc:///tmp/pipeline.ipc")
        testPublishSubscribeIgnoreTopicSeperator(connectAddress: "ipc:///tmp/pipeline.ipc")
    }

    func testWebSocketPublishSubscribe() {
        print("Web Socket tests...")
        testPublishSubscribeStandard(connectAddress: "ws://localhost:5555", bindAddress: "ws://*:5555")
        testPublishSubscribeAllTopics(connectAddress: "ws://localhost:5555", bindAddress: "ws://*:5555")
        testPublishSubscribeIgnoreTopicSeperator(connectAddress: "ws://localhost:5555", bindAddress: "ws://*:5555")
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
