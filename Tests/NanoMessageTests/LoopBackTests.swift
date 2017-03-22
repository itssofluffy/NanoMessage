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

class LoopBackTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testLoopBack(connectAddress: String, bindAddress: String = "") {
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
            let node0 = try BusSocket(socketDomain: .RawSocket)

            let node0EndPointId: Int = try node0.createEndPoint(url: bindURL, type: .Bind)
            XCTAssertGreaterThanOrEqual(node0EndPointId, 0, "node0.createEndPoint('\(bindURL)', .Bind) < 0")

            node0.loopBack(queue: DispatchQueue(label: "com.nanomessage.loopback"))

            let node1 = try BusSocket()
            let node2 = try BusSocket()

            try node1.setSendTimeout(seconds: 1)
            try node2.setReceiveTimeout(seconds: 1)

            let node1EndPointId: Int = try node1.createEndPoint(url: connectURL, type: .Connect)
            XCTAssertGreaterThanOrEqual(node1EndPointId, 0, "node1.createEndPoint('\(connectURL)', .Connect) < 0")

            let node2EndPointId: Int = try node2.createEndPoint(url: connectURL, type: .Connect)
            XCTAssertGreaterThanOrEqual(node2EndPointId, 0, "node2.createEndPoint('\(connectURL)', .Connect) < 0")

            for _ in 0 ..< 10_000 {
                let node1bytesSent = try node1.sendMessage(payload)
                XCTAssertEqual(node1bytesSent, payload.count, "node1bytesSent != payload.count")

                let node2Received = try node2.receiveMessage()
                XCTAssertEqual(node2Received.bytes, node2Received.message.count, "node2.bytes != node2Received.message.count")
                XCTAssertEqual(node2Received.message, payload, "node2.message != payload")
            }

            print("Total Messages (Sent/Received): (\(node1.messagesSent!),\(node2.messagesReceived!)), Total Bytes (Sent/Received): (\(node1.bytesSent!),\(node2.bytesReceived!))")

            completed = true
        } catch let error as NanoMessageError {
            XCTAssert(false, "\(error)")
        } catch {
            XCTAssert(false, "an unexpected error '\(error)' has occured in the library libNanoMessage.")
        }

        XCTAssert(completed, "test not completed")
    }

    func testInProcessLoopBack() {
        testLoopBack(connectAddress: "inproc:///tmp/pipeline.inproc")
    }

#if !os(OSX)
    static let allTests = [
        ("testInProcessLoopBack", testInProcessLoopBack)
    ]
#endif
}
