/*
    BusProtocolFamilyTests.swift

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

class BusProtocolFamilyTests: XCTestCase {
    private func testBus(address1: String, address2: String) {
        var completed = false

        do {
            let node0 = try BusSocket()
            let node1 = try BusSocket()
            let node2 = try BusSocket()

            let _: Int = try node0.bindToAddress(address1)

            let _: Int = try node1.connectToAddress(address1)
            let _: Int = try node1.bindToAddress(address2)

            let _: Int = try node2.connectToAddress(address1)
            let _: Int = try node2.connectToAddress(address2)

            sleep(1)    // give nn_bind a chance to asynchronously bind to the port

            try node0.sendMessage("A")
            try node1.sendMessage("AB")
            try node2.sendMessage("ABC")

            for _ in 0 ... 1 {
                let received: (bytes: Int, message: String) = try node0.receiveMessage()
                XCTAssertGreaterThanOrEqual(received.bytes, 0, "node0.received.bytes < 0")
                let boolTest = (received.bytes == 2 || received.bytes == 3) ? true : false
                XCTAssertEqual(boolTest, true, "node0.received.bytes != 2 && node0.received.bytes != 3")
            }

            for _ in 0 ... 1 {
                let received: (bytes: Int, message: String) = try node1.receiveMessage()
                XCTAssertGreaterThanOrEqual(received.bytes, 0, "node1.received.bytes < 0")
                let boolTest = (received.bytes == 1 || received.bytes == 3) ? true : false
                XCTAssertEqual(boolTest, true, "node1.received.bytes != 2 && node1.received.bytes != 3")
            }

            for _ in 0 ... 1 {
                let received: (bytes: Int, message: String) = try node2.receiveMessage()
                XCTAssertGreaterThanOrEqual(received.bytes, 0, "node2.received.bytes < 0")
                let boolTest = (received.bytes == 1 || received.bytes == 2) ? true : false
                XCTAssertEqual(boolTest, true, "node2.received.bytes != 2 && node2.received.bytes != 2")
            }

            completed = true
        } catch let error as NanoMessageError {
            XCTAssert(false, "\(error)")
        } catch {
            XCTAssert(false, "an unknown error '\(error)' has occured in the library NanoMessage.")
        }

        XCTAssert(completed, "test not completed")
    }

    func testInProcessBus() {
        print("In-Process tests...")
        testBus(address1: "inproc:///tmp/pipeline_1.inproc", address2: "inproc:///tmp/pipeline_2.inproc")
    }

    func testInterProcessBus() {
        print("Inter Process tests...")
        testBus(address1: "ipc:///tmp/pipeline_1.ipc", address2: "ipc:///tmp/pipeline_2.ipc")
    }

#if !os(OSX)
    static let allTests = [
        ("testInProcessBus", testInProcessBus),
        ("testInterProcessBus", testInterProcessBus)
    ]
#endif
}
