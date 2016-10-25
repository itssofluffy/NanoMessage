/*
    SocketStatisticTests.swift

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

class SocketStatisticTests: XCTestCase {
    private func testSocketStatistics(connectAddress: String, bindAddress: String = "") {
        let bAddress = (bindAddress == "") ? connectAddress : bindAddress
        var completed = false

        do {
            let node0 = try PairSocket()
            let node1 = try PairSocket()

            try node0.setSendTimeout(milliseconds: 1000)
            try node0.setReceiveTimeout(milliseconds: 1000)
            try node1.setSendTimeout(milliseconds: 1000)
            try node1.setReceiveTimeout(milliseconds: 1000)

            var node0EstablishedConnections = try node0.getEstablishedConnections()
            XCTAssertEqual(node0EstablishedConnections, 0, "node0.getEstablishedConnections() != 0")
            var node0AcceptedConnections = try node0.getAcceptedConnections()
            XCTAssertEqual(node0AcceptedConnections, 0, "node0.getAcceptedConnections() != 0")
            let node0DroppedConnections = try node0.getDroppedConnections()
            XCTAssertEqual(node0DroppedConnections, 0, "node0.getDroppedConnections() != 0")
            let node0BrokenConnections = try node0.getBrokenConnections()
            XCTAssertEqual(node0BrokenConnections, 0, "node0.getBrokenConnections() != 0")
            let node0ConnectErrors = try node0.getConnectErrors()
            XCTAssertEqual(node0ConnectErrors, 0, "node0.getConnectErrors() != 0")
            let node0BindErrors = try node0.getBindErrors()
            XCTAssertEqual(node0BindErrors, 0, "node0.getBindErrors() != 0")
            let node0AcceptErrors = try node0.getAcceptErrors()
            XCTAssertEqual(node0AcceptErrors, 0, "node0.getAcceptErrors() != 0")
            var node0CurrentConnections = try node0.getCurrentConnections()
            XCTAssertEqual(node0CurrentConnections, 0, "node0.getCurrentConnections() != 0")
            var node0MessagesSent = try node0.getMessagesSent()
            XCTAssertEqual(node0MessagesSent, 0, "node0.getMessagesSent() != 0")
            var node0MessagesReceived = try node0.getMessagesReceived()
            XCTAssertEqual(node0MessagesReceived, 0, "node0.getMessagesReceived() != 0")
            var node0BytesSent = try node0.getBytesSent()
            XCTAssertEqual(node0BytesSent, 0, "node0.getBytesSent() != 0")
            var node0BytesReceived = try node0.getBytesReceived()
            XCTAssertEqual(node0BytesReceived, 0, "node0.getBytesReceived() != 0")
            let node0CurrentSendPriority = try node0.getCurrentSendPriority()
            XCTAssertEqual(node0CurrentSendPriority, 0, "node0.getCurrentSendPriority() != 0")

            var node1EstablishedConnections = try node1.getEstablishedConnections()
            XCTAssertEqual(node1EstablishedConnections, 0, "node1.getEstablishedConnections() != 0")
            var node1AcceptedConnections = try node1.getAcceptedConnections()
            XCTAssertEqual(node1AcceptedConnections, 0, "node1.getAcceptedConnections() != 0")
            let node1DroppedConnections = try node1.getDroppedConnections()
            XCTAssertEqual(node1DroppedConnections, 0, "node1.getDroppedConnections() != 0")
            let node1BrokenConnections = try node1.getBrokenConnections()
            XCTAssertEqual(node1BrokenConnections, 0, "node1.getBrokenConnections() != 0")
            let node1ConnectErrors = try node1.getConnectErrors()
            XCTAssertEqual(node1ConnectErrors, 0, "node1.getConnectErrors() != 0")
            let node1BindErrors = try node1.getBindErrors()
            XCTAssertEqual(node1BindErrors, 0, "node1.getBindErrors() != 0")
            let node1AcceptErrors = try node1.getAcceptErrors()
            XCTAssertEqual(node1AcceptErrors, 0, "node1.getAcceptErrors() != 0")
            var node1CurrentConnections = try node1.getCurrentConnections()
            XCTAssertEqual(node1CurrentConnections, 0, "node1.getCurrentConnections() != 0")
            var node1MessagesSent = try node1.getMessagesSent()
            XCTAssertEqual(node1MessagesSent, 0, "node1.getMessagesSent() != 0")
            var node1MessagesReceived = try node1.getMessagesReceived()
            XCTAssertEqual(node1MessagesReceived, 0, "node1.getMessagesReceived() != 0")
            var node1BytesSent = try node1.getBytesSent()
            XCTAssertEqual(node1BytesSent, 0, "node1.getBytesSent() != 0")
            var node1BytesReceived = try node1.getBytesReceived()
            XCTAssertEqual(node1BytesReceived, 0, "node1.getBytesReceived() != 0")
            let node1CurrentSendPriority = try node1.getCurrentSendPriority()
            XCTAssertEqual(node1CurrentSendPriority, 0, "node1.getCurrentSendPriority() != 0")

            let node0EndPointId: Int = try node0.connectToAddress(connectAddress)
            XCTAssertGreaterThanOrEqual(node0EndPointId, 0, "node0.connectToAddress(endPointAddress: '\(connectAddress)') < 0")

            let node1EndPointId: Int = try node1.bindToAddress(bAddress)
            XCTAssertGreaterThanOrEqual(node1EndPointId, 0, "node1.bindToAddress(endPointAddress: '\(bAddress)') < 0")

            pauseForBind()

            var bytesSent = try node0.sendMessage(payload)
            XCTAssertEqual(bytesSent, payload.utf8.count, "node0.bytesSent != payload.utf8.count")

            var node1Received: (bytes: Int, message: String) = try node1.receiveMessage()
            XCTAssertEqual(node1Received.bytes, node1Received.message.utf8.count, "node1.bytes != message.utf8.count")
            XCTAssertEqual(node1Received.message, payload, "node1.message != payload")

            bytesSent = try node1.sendMessage(payload)
            XCTAssertEqual(bytesSent, payload.utf8.count, "node1.bytesSent != payload.utf8.count")

            var node0Received: (bytes: Int, message: String) = try node0.receiveMessage()
            XCTAssertEqual(node0Received.bytes, node0Received.message.utf8.count, "node0.bytes != message.utf8.count")
            XCTAssertEqual(node0Received.message, payload, "node0.message != payload")

            node0EstablishedConnections = try node0.getEstablishedConnections()
            XCTAssertEqual(node0EstablishedConnections, 1, "node0.getEstablishedConnections() != 1")
            node0AcceptedConnections = try node0.getAcceptedConnections()
            XCTAssertEqual(node0AcceptedConnections, 0, "node0.getAcceptedConnections() != 0")
            node0CurrentConnections = try node0.getCurrentConnections()
            XCTAssertEqual(node0CurrentConnections, 1, "node0.getCurrentConnections() != 1")
            node0MessagesSent = try node0.getMessagesSent()
            XCTAssertEqual(node0MessagesSent, 1, "node0.getMessagesSent() != 1")
            node0MessagesReceived = try node0.getMessagesReceived()
            XCTAssertEqual(node0MessagesReceived, 1, "node0.getMessagesReceived() != 1")
            node0BytesSent = try node0.getBytesSent()
            XCTAssertEqual(node0BytesSent, UInt64(payload.utf8.count), "node0.getBytesSent() != \(payload.utf8.count)")
            node0BytesReceived = try node0.getBytesReceived()
            XCTAssertEqual(node0BytesReceived, UInt64(payload.utf8.count), "node0.getBytesReceived() != \(payload.utf8.count)")

            node1EstablishedConnections = try node1.getEstablishedConnections()
            XCTAssertEqual(node1EstablishedConnections, 0, "node0.getEstablishedConnections() != 0")
            node1AcceptedConnections = try node1.getAcceptedConnections()
            XCTAssertEqual(node1AcceptedConnections, 1, "node1.getAcceptedConnections() != 1")
            node1CurrentConnections = try node1.getCurrentConnections()
            XCTAssertEqual(node1CurrentConnections, 1, "node1.getCurrentConnections() != 1")
            node1MessagesSent = try node1.getMessagesSent()
            XCTAssertEqual(node1MessagesSent, 1, "node1.getMessagesSent() != 1")
            node1MessagesReceived = try node1.getMessagesReceived()
            XCTAssertEqual(node1MessagesReceived, 1, "node1.getMessagesReceived() != 1")
            node1BytesSent = try node1.getBytesSent()
            XCTAssertEqual(node1BytesSent, UInt64(payload.utf8.count), "node1.getBytesSent() != \(payload.utf8.count)")
            node1BytesReceived = try node1.getBytesReceived()
            XCTAssertEqual(node1BytesReceived, UInt64(payload.utf8.count), "node1.getBytesReceived() != \(payload.utf8.count)")

            completed = true
        } catch let error as NanoMessageError {
            XCTAssert(false, "\(error)")
        } catch {
            XCTAssert(false, "an unexpected error '\(error)' has occured in the library libNanoMessage.")
        }

        XCTAssert(completed, "test not completed")
    }

    func testTCPSocketStatistic() {
        print("TCP tests...")
        testSocketStatistics(connectAddress: "tcp://localhost:5555", bindAddress: "tcp://*:5555")
    }

    func testInProcessSocketStatistic() {
        print("In-Process tests...")
        testSocketStatistics(connectAddress: "inproc:///tmp/pipeline.inproc")
    }

    func testInterProcessSocketStatistic() {
        print("Inter Process tests...")
        testSocketStatistics(connectAddress: "ipc:///tmp/pipeline.ipc")
    }

    func testWebSocketStatistic() {
        print("Web Socket tests...")
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
