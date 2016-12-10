/*
    EndPointTests.swift

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

class EndPointTests: XCTestCase {
    private func testEndPoints(connectAddress: String, bindAddress: String = "") {
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

            try node0.setSendTimeout(seconds: 1)
            try node1.setReceiveTimeout(seconds: 1)

            XCTAssertEqual(node0.endPoints.count, 0, "node0.endPoints.count != 0")
            XCTAssertEqual(node1.endPoints.count, 0, "node1.endPoints.count != 0")

            let node0EndPointId: Int = try node0.connectToURL(connectURL)
            XCTAssertGreaterThanOrEqual(node0EndPointId, 0, "node0.connectToURL('\(connectURL)') != 0")

            let node1EndPoint: EndPoint = try node1.bindToURL(bindURL)
            XCTAssertGreaterThanOrEqual(node1EndPoint.id, 0, "node1.bindToURL('\(bindURL)') != 0")

            pauseForBind()

            XCTAssertEqual(node0.endPoints.count, 1, "node0.endPoints.count != 1")
            XCTAssertEqual(node1.endPoints.count, 1, "node1.endPoints.count != 1")

            let node0EndPointRemoved = try node0.removeEndPoint(node0EndPointId)
            XCTAssertEqual(node0EndPointRemoved, true, "node0.removeEndPoint(\(node0EndPointId))")

            let node1EndPointRemoved = try node1.removeEndPoint(node1EndPoint)
            XCTAssertEqual(node1EndPointRemoved, true, "node1.removeEndPoint(\(node1EndPoint.id))")

            let endPointName = "end-point at the end of the line"

            try node0.setSendPriority(Priority(level: 2))

            let node0EndPoint: EndPoint = try node0.connectToURL(connectURL, name: endPointName)

            XCTAssertGreaterThanOrEqual(node0EndPoint.id, 0, "node0EndPoint.id != 0")
            XCTAssertEqual(node0EndPoint.url.absoluteString, connectURL.absoluteString, "node0EndPoint.url.absoluteString != '\(connectURL)'")
            XCTAssertEqual(node0EndPoint.type, ConnectionType.Connect, "node0EndPoint.type != '\(ConnectionType.Connect)'")
            XCTAssertEqual(node0EndPoint.transport, TransportMechanism.TCP, "node0EndPoint.transport != '\(TransportMechanism.TCP)'")
            if let _ = node0EndPoint.priorities.receive {
                XCTAssert(false, "node0EndPoint.priorities.receive != nil")
            }
            XCTAssertEqual(node0EndPoint.priorities.send, Priority(level: 2), "node0EndPoint.priorities.send != Priority(level: 2)")
            XCTAssertEqual(node0EndPoint.ipv4Only, true, "node0EndPoint.ipv4Only != true")
            XCTAssertEqual(node0EndPoint.name, endPointName, "node0EndPoint.name != '\(endPointName)'")

            completed = true
        } catch let error as NanoMessageError {
            XCTAssert(false, "\(error)")
        } catch {
            XCTAssert(false, "an unexpected error '\(error)' has occured in the library libNanoMessage.")
        }

        XCTAssert(completed, "test not completed")
    }

    func testEndPoint() {
        print("EndPoint tests...")
        testEndPoints(connectAddress: "tcp://localhost:5555", bindAddress: "tcp://*:5555")
    }

#if !os(OSX)
    static let allTests = [
        ("testEndPoint", testEndPoint)
    ]
#endif
}
