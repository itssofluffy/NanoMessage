/*
    PollSocketTests.swift

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

class PollSocketTests: XCTestCase {
    private func testPollSocket(connectAddress: String, bindAddress: String = "") {
        let bAddress = (bindAddress == "") ? connectAddress : bindAddress
        var completed = false

        do {
            let node0 = try PushSocket()
            let node1 = try PullSocket()

            let node0EndPointId: Int = try node0.connectToAddress(connectAddress)
            XCTAssertGreaterThanOrEqual(node0EndPointId, 0, "node0.connectToAddress(endPointAddress: '\(connectAddress)') < 0")

            let node1EndPointId: Int = try node1.bindToAddress(bAddress)
            XCTAssertGreaterThanOrEqual(node1EndPointId, 0, "node1.bindToAddress(endPointAddress: '\(bAddress)') < 0")

            sleep(1)    // give nn_bind a chance to asynchronously bind to the port

            var node1Poll: (messageIsWaiting: Bool, sendIsBlocked: Bool) = try node1.pollSocket(timeout: 1000)
            XCTAssertEqual(node1Poll.messageIsWaiting, false, "node1Poll.messageIsWaiting != false")
            XCTAssertEqual(node1Poll.sendIsBlocked, false, "node1Poll.sendIsBlocked != false")

            let bytesSent = try node0.sendMessage(payload)
            XCTAssertEqual(bytesSent, payload.utf8.count, "bytesSent != payload.utf8.count")

            node1Poll = try node1.pollSocket()
            XCTAssertEqual(node1Poll.messageIsWaiting, true, "node1Poll.messageIsWaiting != true")
            XCTAssertEqual(node1Poll.sendIsBlocked, false, "node1Poll.sendIsBlocked != false")

            let node1Received: (bytes: Int, message: String) = try node1.receiveMessage()
            XCTAssertEqual(node1Received.bytes, node1Received.message.utf8.count, "bytes != message.utf8.count")
            XCTAssertEqual(node1Received.message, payload, "message != payload")

            node1Poll = try node1.pollSocket()
            XCTAssertEqual(node1Poll.messageIsWaiting, false, "node1Poll.messageIsWaiting != false")
            XCTAssertEqual(node1Poll.sendIsBlocked, false, "node1Poll.sendIsBlocked != false")

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

    func testTCPPollSocket() {
        print("TCP tests...")
        testPollSocket(connectAddress: "tcp://localhost:5555", bindAddress: "tcp://*:5555")
    }

    func testInProcessPollSocket() {
        print("In-Process tests...")
        testPollSocket(connectAddress: "inproc:///tmp/pipeline.inproc")
    }

    func testInterProcessPollSocket() {
        print("Inter Process tests...")
        testPollSocket(connectAddress: "ipc:///tmp/pipeline.ipc")
    }

    func testWebSocketPollSocket() {
        print("Web Socket tests...")
        testPollSocket(connectAddress: "ws://localhost:5555", bindAddress: "ws://*:5555")
    }

#if !os(OSX)
    static let allTests = [
        ("testTCPPollSocket", testTCPPollSocket),
        ("testInProcessPollSocket", testInProcessPollSocket),
        ("testInterProcessPollSocket", testInterProcessPollSocket),
        ("testWebSocketPollSocket", testWebSocketPollSocket)
    ]
#endif
}
