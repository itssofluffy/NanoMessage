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
            let node0 = try ReplySocket(socketDomain: .RawSocket)
            let node1 = try RequestSocket(socketDomain: .RawSocket)

            let node0EndPointId: Int = try node0.bindToURL(bindURL1)
            XCTAssertGreaterThanOrEqual(node0EndPointId, 0, "node0.bindToURL('\(bindURL1)') < 0")

            let node1EndPointId: Int = try node1.bindToURL(bindURL2)
            XCTAssertGreaterThanOrEqual(node1EndPointId, 0, "node1.bindToURL('\(bindURL2)') < 0")

            let queue = DispatchQueue(label: "com.nanomessage.bindtosocket")
            let group = DispatchGroup()

            let workItem = node0.bindToSocket(node1, queue: queue, group: group, {
                if let error = $0 {
                    print(error)
                }
            })

            let node2 = try RequestSocket()
            let node3 = try ReplySocket()

            try node2.setSendTimeout(seconds: 1)
            try node2.setReceiveTimeout(seconds: 1)
            try node3.setSendTimeout(seconds: 1)
            try node3.setReceiveTimeout(seconds: 1)

            let node2EndPointId: Int = try node2.connectToURL(connectURL1)
            XCTAssertGreaterThanOrEqual(node2EndPointId, 0, "node2.connectToURL('\(connectURL1)') < 0")

            let node3EndPointId: Int = try node3.connectToURL(connectURL2)
            XCTAssertGreaterThanOrEqual(node3EndPointId, 0, "node3.connectToURL('\(connectURL2)') < 0")

            let node2bytesSent = try node2.sendMessage(payload)
            XCTAssertEqual(node2bytesSent, payload.utf8.count, "node2bytesSent != payload.utf8.count")

            let node3Received: ReceiveString = try node3.receiveMessage()
            XCTAssertEqual(node3Received.bytes, node3Received.message.utf8.count, "node3.bytes != message.utf8.count")
            XCTAssertEqual(node3Received.message, payload, "node3.message != payload")

            let node3bytesSent = try node3.sendMessage(payload)
            XCTAssertEqual(node3bytesSent, payload.utf8.count, "node3bytesSent != payload.utf8.count")

            let node2Received: ReceiveString = try node2.receiveMessage()
            XCTAssertEqual(node2Received.bytes, node2Received.message.utf8.count, "node2.bytes != message.utf8.count")
            XCTAssertEqual(node2Received.message, payload, "node2.message != payload")

            let messagesSent = try node2.getMessagesSent()
            let messagesReceived = try node3.getMessagesReceived()
            let bytesSent = try node2.getBytesSent()
            let bytesReceived = try node3.getBytesReceived()

            print("Total Messages (Sent/Received): (\(messagesSent),\(messagesReceived)), Total Bytes (Sent/Received): (\(bytesSent),\(bytesReceived))")

            workItem.cancel()                                           // ummm...doesn't seem to cancel the work item.

            workItem.notify(queue: queue) {
                print("node0.bindToSocket(): \(workItem.isCancelled)")
            }

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
