/*
    PairProtocolFamilyTests.swift

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

class PairProtocolFamilyTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testPair(connectAddress: String, bindAddress: String = "") {
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
            let node0 = try PairSocket(url: connectURL, type: .Connect)
            let node1 = try PairSocket(url: bindURL, type: .Bind)

            try node0.setSendTimeout(seconds: 1)
            try node0.setReceiveTimeout(seconds: 1)
            try node1.setSendTimeout(seconds: 1)
            try node1.setReceiveTimeout(seconds: 1)

            pauseForBind()

            var bytesSent = try node0.sendMessage(payload)
            XCTAssertEqual(bytesSent, payload.count, "node0.bytesSent != payload.count")

            let node1Received = try node1.receiveMessage()
            XCTAssertEqual(node1Received.bytes, node1Received.message.count, "node1.bytes != node1Received.message.count")
            XCTAssertEqual(node1Received.message, payload, "node1.message != payload")

            bytesSent = try node1.sendMessage(payload)
            XCTAssertEqual(bytesSent, payload.count, "node1.bytesSent != payload.count")

            let node0Received = try node0.receiveMessage()
            XCTAssertEqual(node0Received.bytes, node0Received.message.count, "node0.bytes != node0Received.message.count")
            XCTAssertEqual(node0Received.message, payload, "node0.message != payload")

            completed = true
        } catch let error as NanoMessageError {
            XCTAssert(false, "\(error)")
        } catch {
            XCTAssert(false, "an unexpected error '\(error)' has occured in the library libNanoMessage.")
        }

        XCTAssert(completed, "test not completed")
    }

    func testTCPPair() {
        testPair(connectAddress: "tcp://localhost:5555", bindAddress: "tcp://*:5555")
    }

    func testInProcessPair() {
        testPair(connectAddress: "inproc:///tmp/pipeline.inproc")
    }

    func testInterProcessPair() {
        testPair(connectAddress: "ipc:///tmp/pipeline.ipc")
    }

    func testWebSocketPair() {
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
