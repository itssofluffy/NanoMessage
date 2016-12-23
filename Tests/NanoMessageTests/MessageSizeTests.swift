/*
    MessageSizeTests.swift

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
import C7

@testable import NanoMessage

class MessageSizeTests: XCTestCase {
    private func testMessageSize(connectAddress: String, bindAddress: String = "") {
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
            let node0 = try PushSocket()
            let node1 = try PullSocket()

            let timeout = TimeInterval(seconds: 1)

            try node0.setSendTimeout(seconds: timeout)
            try node1.setReceiveTimeout(seconds: timeout)

            let node0EndPoint: EndPoint = try node0.connectToURL(connectURL)
            let node1EndPoint: EndPoint = try node1.bindToURL(bindURL)

            pauseForBind()

            var messageSize = 1
            let maximumMessageSize = try node1.getMaximumMessageSize()

            while (messageSize <= maximumMessageSize) {
                let messagePayload = Data([Byte](repeating: 0xff, count: messageSize))

                let _ = try node0.sendMessage(messagePayload)
                let _: ReceiveData = try node1.receiveMessage()

                messageSize *= 2
            }

            let messagesSent = try node0.getMessagesSent()
            let messagesReceived = try node1.getMessagesReceived()
            let bytesSent = try node0.getBytesSent()
            let bytesReceived = try node1.getBytesReceived()

            XCTAssertEqual(messagesSent, messagesReceived, "messagesSent != messagesReceived")
            XCTAssertEqual(bytesSent, bytesReceived, "bytesSent != bytesReceived")

            print("Total Messages (Sent/Received): (\(messagesSent),\(messagesReceived)), Total Bytes (Sent/Received): (\(bytesSent),\(bytesReceived))")

            let node0Removed = try node0.removeEndPoint(node0EndPoint)
            XCTAssertTrue(node0Removed, "node0.removeEndPoint(\(node0EndPoint))")
            let node1Removed = try node1.removeEndPoint(node1EndPoint)
            XCTAssertTrue(node1Removed, "node1.removeEndPoint(\(node1EndPoint))")

            completed = true
        } catch let error as NanoMessageError {
            XCTAssert(false, "\(error)")
        } catch {
            XCTAssert(false, "an unexpected error '\(error)' has occured in the library libNanoMessage.")
        }

        XCTAssert(completed, "test not completed")
    }

    func testTCPMessageSize() {
        print("TCP tests...")
        testMessageSize(connectAddress: "tcp://localhost:5555", bindAddress: "tcp://*:5555")
    }

    func testInProcessMessageSize() {
        print("In-Process tests...")
        testMessageSize(connectAddress: "inproc:///tmp/pipeline.inproc")
    }

    func testInterProcessMessageSize() {
        print("Inter Process tests...")
        testMessageSize(connectAddress: "ipc:///tmp/pipeline.ipc")
    }

    func testWebSocketMessageSize() {
        print("Web Socket tests...")
        testMessageSize(connectAddress: "ws://localhost:5555", bindAddress: "ws://*:5555")
    }

#if !os(OSX)
    static let allTests = [
        ("testTCPMessageSize", testTCPMessageSize),
        ("testInProcessMessageSize", testInProcessMessageSize),
        ("testInterProcessMessageSize", testInterProcessMessageSize),
        ("testWebSocketMessageSize", testWebSocketMessageSize)
    ]
#endif
}