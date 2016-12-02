/*
    LoopBackTests.swift

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
import Dispatch

@testable import NanoMessage

class LoopBackTests: XCTestCase {
    private func testLoopBack(connectAddress: String, bindAddress: String = "") {
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

            let node0EndPointId: Int = try node0.bindToURL(bindURL)
            XCTAssertGreaterThanOrEqual(node0EndPointId, 0, "node0.bindToURL('\(bindURL)') < 0")

            let queue = DispatchQueue(label: "com.nanomessage.loopback")

            node0.loopBack(queue: queue, {
                if let error = $0 {
                    print("async node0.loopBack() error: \(error)")
                }
            })

            let node1 = try BusSocket()
            let node2 = try BusSocket()

            try node1.setSendTimeout(seconds: 1)
            try node2.setReceiveTimeout(seconds: 1)

            let node1EndPointId: Int = try node1.connectToURL(connectURL)
            XCTAssertGreaterThanOrEqual(node1EndPointId, 0, "node1.connectToURL('\(connectURL)') < 0")

            let node2EndPointId: Int = try node2.connectToURL(connectURL)
            XCTAssertGreaterThanOrEqual(node2EndPointId, 0, "node2.connectToURL('\(connectURL)') < 0")

            let bytesSent = try node1.sendMessage(payload)
            XCTAssertEqual(bytesSent, payload.utf8.count, "node1.bytesSent != payload.utf8.count")

            var node2Received: ReceiveString = try node2.receiveMessage()
            XCTAssertEqual(node2Received.bytes, node2Received.message.utf8.count, "node2.bytes != message.utf8.count")
            XCTAssertEqual(node2Received.message, payload, "node2.message != payload")

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
