/*
    SocketStatisticTests.swift

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

class SocketStatisticTests: XCTestCase {
    func testSocketStatistics(connectAddress: String, bindAddress: String = "") {
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
            let node0 = try PairSocket()
            let node1 = try PairSocket()

            let timeout = TimeInterval(seconds: 1)

            try node0.setSendTimeout(seconds: timeout)
            try node0.setReceiveTimeout(seconds: timeout)
            try node1.setSendTimeout(seconds: timeout)
            try node1.setReceiveTimeout(seconds: timeout)

            XCTAssertEqual(node0.establishedConnections!, 0, "node0.establishedConnections != 0")
            XCTAssertEqual(node0.acceptedConnections!, 0, "node0.acceptedConnections != 0")
            XCTAssertEqual(node0.droppedConnections!, 0, "node0.droppedConnections != 0")
            XCTAssertEqual(node0.brokenConnections!, 0, "node0.brokenConnections != 0")
            XCTAssertEqual(node0.connectErrors!, 0, "node0.connectErrors != 0")
            XCTAssertEqual(node0.bindErrors!, 0, "node0.bindErrors != 0")
            XCTAssertEqual(node0.acceptErrors!, 0, "node0.acceptErrors != 0")
            XCTAssertEqual(node0.currentConnections!, 0, "node0.currentConnections != 0")
            XCTAssertEqual(node0.messagesSent!, 0, "node0.messagesSent != 0")
            XCTAssertEqual(node0.messagesReceived!, 0, "node0.messagesReceived != 0")
            XCTAssertEqual(node0.bytesSent!, 0, "node0.bytesSent != 0")
            XCTAssertEqual(node0.bytesReceived!, 0, "node0.bytesReceived != 0")
            XCTAssertEqual(node0.currentInProgressConnections!, 0, "node0.currentInProgressConnections != 0")
            XCTAssertEqual(node0.currentSendPriority!, Priority(level: 0), "node0.currentSendPriority != Priority(level: 0)")
            XCTAssertEqual(node0.currentEndPointErrors!, 0, "node0.currentEndPointErrors != 0")

            XCTAssertEqual(node1.establishedConnections!, 0, "node1.establishedConnections != 0")
            XCTAssertEqual(node1.acceptedConnections!, 0, "node1.acceptedConnections != 0")
            XCTAssertEqual(node1.droppedConnections!, 0, "node1.droppedConnections != 0")
            XCTAssertEqual(node1.brokenConnections!, 0, "node1.brokenConnections != 0")
            XCTAssertEqual(node1.connectErrors!, 0, "node1.connectErrors != 0")
            XCTAssertEqual(node1.bindErrors!, 0, "node1.bindErrors != 0")
            XCTAssertEqual(node1.acceptErrors!, 0, "node1.acceptErrors != 0")
            XCTAssertEqual(node1.currentConnections!, 0, "node1.currentConnections != 0")
            XCTAssertEqual(node1.messagesSent!, 0, "node1.messagesSent != 0")
            XCTAssertEqual(node1.messagesReceived!, 0, "node1.messagesReceived != 0")
            XCTAssertEqual(node1.bytesSent!, 0, "node1.bytesSent != 0")
            XCTAssertEqual(node1.bytesReceived!, 0, "node1.bytesReceived != 0")
            XCTAssertEqual(node1.currentInProgressConnections!, 0, "node1.currentInProgressConnections != 0")
            XCTAssertEqual(node1.currentSendPriority!, Priority(level: 0), "node1.currentSendPriority != Priority(level: 0)")
            XCTAssertEqual(node1.currentEndPointErrors!, 0, "node1.currentEndPointErrors != 0")

            let node0EndPointId: Int = try node0.createEndPoint(url: connectURL, type: .Connect)
            XCTAssertGreaterThanOrEqual(node0EndPointId, 0, "node0.createEndPoint('\(connectURL)', .Connect) < 0")

            let node1EndPointId: Int = try node1.createEndPoint(url: bindURL, type: .Bind)
            XCTAssertGreaterThanOrEqual(node1EndPointId, 0, "node1.createEndPoint('\(bindURL)', .Bind) < 0")

            pauseForBind()

            var bytesSent = try node0.sendMessage(payload)
            XCTAssertEqual(bytesSent, payload.count, "node0.bytesSent != payload.count")

            let node1Received = try node1.receiveMessage()
            XCTAssertEqual(node1Received.bytes, node1Received.message.count, "node1Received.bytes != node1Received.message.count")
            XCTAssertEqual(node1Received.message, payload, "node1Received.message != payload")

            bytesSent = try node1.sendMessage(payload)
            XCTAssertEqual(bytesSent, payload.count, "node1.bytesSent != payload.count")

            let node0Received = try node0.receiveMessage()
            XCTAssertEqual(node0Received.bytes, node0Received.message.count, "node0Received.bytes != node0Received.message.count")
            XCTAssertEqual(node0Received.message, payload, "node0Received.message != payload")

            XCTAssertEqual(node0.establishedConnections!, 1, "node0.establishedConnections != 1")
            XCTAssertEqual(node0.acceptedConnections!, 0, "node0.acceptedConnections != 0")
            XCTAssertEqual(node0.currentConnections!, 1, "node0.currentConnections != 1")
            XCTAssertEqual(node0.messagesSent!, 1, "node0.messagesSent != 1")
            XCTAssertEqual(node0.messagesReceived!, 1, "node0.messagesReceived != 1")
            XCTAssertEqual(node0.bytesSent!, UInt64(payload.count), "node0.bytesSent != \(payload.count)")
            XCTAssertEqual(node0.bytesReceived!, UInt64(payload.count), "node0.bytesReceived != \(payload.count)")

            XCTAssertEqual(node1.establishedConnections!, 0, "node0.establishedConnections != 0")
            XCTAssertEqual(node1.acceptedConnections!, 1, "node1.acceptedConnections != 1")
            XCTAssertEqual(node1.currentConnections!, 1, "node1.currentConnections != 1")
            XCTAssertEqual(node1.messagesSent!, 1, "node1.messagesSent != 1")
            XCTAssertEqual(node1.messagesReceived!, 1, "node1.messagesReceived != 1")
            XCTAssertEqual(node1.bytesSent!, UInt64(payload.count), "node1.bytesSent != \(payload.count)")
            XCTAssertEqual(node1.bytesReceived!, UInt64(payload.count), "node1.bytesReceived != \(payload.count)")

            completed = true
        } catch let error as NanoMessageError {
            XCTAssert(false, "\(error)")
        } catch {
            XCTAssert(false, "an unexpected error '\(error)' has occured in the library libNanoMessage.")
        }

        XCTAssert(completed, "test not completed")
    }

    func testTCPSocketStatistic() {
        testSocketStatistics(connectAddress: "tcp://localhost:5555", bindAddress: "tcp://*:5555")
    }

    func testInProcessSocketStatistic() {
        testSocketStatistics(connectAddress: "inproc:///tmp/pipeline.inproc")
    }

    func testInterProcessSocketStatistic() {
        testSocketStatistics(connectAddress: "ipc:///tmp/pipeline.ipc")
    }

    func testWebSocketStatistic() {
        testSocketStatistics(connectAddress: "ws://localhost:5555", bindAddress: "ws://*:5555")
    }

#if !os(OSX)
    static let allTests = [
        ("testTCPSocketStatistic", testTCPSocketStatistic),
        ("testInProcessSocketStatistic", testInProcessSocketStatistic),
        ("testInterProcessSocketStatistic", testInterProcessSocketStatistic),
        ("testWebSocketStatistic", testWebSocketStatistic)
    ]
#endif
}
