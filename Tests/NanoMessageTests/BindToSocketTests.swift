/*
    LoopBackTests.swift

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
import Dispatch

@testable import NanoMessage

class BindToSocketTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testBindToSocket(connectAddress: String, bindAddress: String = "") {
        guard let connectURL1 = URL(string: connectAddress + "5") else {
            XCTAssert(false, "connectURL is invalid")
            return
        }

        guard let bindURL1 = URL(string: bindAddress + "5") else {
            XCTAssert(false, "bindURL is invalid")
            return
        }

        guard let connectURL2 = URL(string: connectAddress + "6") else {
            XCTAssert(false, "connectURL is invalid")
            return
        }

        guard let bindURL2 = URL(string: bindAddress + "6") else {
            XCTAssert(false, "bindURL is invalid")
            return
        }

        var completed = false

        do {
            let node0 = try ReplySocket(socketDomain: .RawSocket, url: bindURL1, type: .Bind)
            let node1 = try RequestSocket(socketDomain: .RawSocket, url: bindURL2, type: .Bind)

            node0.bindToSocket(node1, queue: DispatchQueue(label: "com.nanomessage.bindtosocket"))

            let node2 = try RequestSocket()
            let node3 = try ReplySocket()

            try node2.setSendTimeout(seconds: 1)
            try node2.setReceiveTimeout(seconds: 1)
            try node3.setSendTimeout(seconds: 1)
            try node3.setReceiveTimeout(seconds: 1)

            let node2EndPointId: Int = try node2.createEndPoint(url: connectURL1, type: .Connect)
            XCTAssertGreaterThanOrEqual(node2EndPointId, 0, "node2.createEndPoint('\(connectURL1)', .Connect) < 0")

            let node3EndPointId: Int = try node3.createEndPoint(url: connectURL2, type: .Connect)
            XCTAssertGreaterThanOrEqual(node3EndPointId, 0, "node3.createEndPoint('\(connectURL2)', .Connect) < 0")

            for _ in 0 ..< 10_000 {
                let node2Sent = try node2.sendMessage(payload)
                XCTAssertEqual(node2Sent.bytes, payload.count, "node2Sent.bytes != payload.count")

                let sent: MessagePayload = try node3.receiveMessage { received in
                    XCTAssertEqual(received.bytes, received.message.count, "received.bytes != received.message.count")
                    XCTAssertEqual(received.message, payload, "received.message != payload")

                    return received.message
                }
                XCTAssertEqual(sent.bytes, payload.count, "sent.bytes != payload.count")

                let node2Received = try node2.receiveMessage()
                XCTAssertEqual(node2Received.bytes, node2Received.message.count, "node2Received.bytes != node2Received.message.count")
                XCTAssertEqual(node2Received.message, payload, "node2Received.message != payload")
            }

            print("Total Messages (Sent/Received): (\(node2.messagesSent!),\(node3.messagesReceived!)), Total Bytes (Sent/Received): (\(node2.bytesSent!),\(node3.bytesReceived!))")

            completed = true
        } catch let error as NanoMessageError {
            XCTAssert(false, "\(error)")
        } catch {
            XCTAssert(false, "an unexpected error '\(error)' has occured in the library libNanoMessage.")
        }

        XCTAssert(completed, "test not completed")
    }

    func testTCPBindToSocket() {
        testBindToSocket(connectAddress: "tcp://localhost:555", bindAddress: "tcp://*:555")
    }

#if !os(OSX)
    static let allTests = [
        ("testTCPBindToSocket", testTCPBindToSocket)
    ]
#endif
}
