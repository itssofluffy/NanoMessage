/*
    PairProtocolFamilyTests.swift

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

class PairProtocolFamilyTests: XCTestCase {
    private func testPair(connectAddress: String, bindAddress: String = "") {
        let bAddress = (bindAddress == "") ? connectAddress : bindAddress

        var completed = false

        do {
            let node0 = try PairSocket()
            let node1 = try PairSocket()

            try node0.setSendTimeout(milliseconds: 1000)
            try node0.setReceiveTimeout(milliseconds: 1000)
            try node1.setSendTimeout(milliseconds: 1000)
            try node1.setReceiveTimeout(milliseconds: 1000)

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

            completed = true
        } catch let error as NanoMessageError {
            XCTAssert(false, "\(error)")
        } catch {
            XCTAssert(false, "an unknown error '\(error)' has occured in the library NanoMessage.")
        }

        XCTAssert(completed, "test not completed")
    }

    func testTCPPair() {
        print("TCP tests...")
        testPair(connectAddress: "tcp://localhost:5555", bindAddress: "tcp://*:5555")
    }

    func testInProcessPair() {
        print("In-Process tests...")
        testPair(connectAddress: "inproc:///tmp/pipeline.inproc")
    }

    func testInterProcessPair() {
        print("Inter Process tests...")
        testPair(connectAddress: "ipc:///tmp/pipeline.ipc")
    }

    func testWebSocketPair() {
        print("Web Socket tests...")
        testPair(connectAddress: "ws://localhost:5555", bindAddress: "ws://*:5555")
    }

#if !os(OSX)
    static let allTests = [
        ("testTCPPair", testTCPPair),
        ("testInProcessPair", testInProcessPair),
        ("testInterProcessPair", testInterProcessPair),
        ("testWebSocketPair", testWebSocketPair)
    ]
#endif
}
