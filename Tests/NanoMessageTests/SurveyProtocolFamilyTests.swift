/*
    SurveyProtocolFamilyTests.swift

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
import ISFLibrary

import NanoMessage

class SurveyProtocolFamilyTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSurvey(connectAddress: String, bindAddress: String = "") {
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
            print("survey with deadline reached...")

            let node0 = try SurveyorSocket()
            let node1 = try RespondentSocket()

            try node0.setSendTimeout(seconds: 1)          // set send timeout to 1 seconds.
            try node1.setSendTimeout(seconds: 1)          // set send timeout to 1 seconds.
            try node1.setReceiveTimeout(seconds: 1)       // set receive timeout to 1 seconds.

            let node0EndPointId: Int = try node0.createEndPoint(url: connectURL, type: .Connect)
            XCTAssertGreaterThanOrEqual(node0EndPointId, 0, "node0.createEndPoint('\(connectURL)', .Connect) < 0")

            try node0.setDeadline(seconds: 0.5)           // set the suryeyor deadline to 1/2 second.

            let node1EndPointId: Int = try node1.createEndPoint(url: bindURL, type: .Bind)
            XCTAssertGreaterThanOrEqual(node1EndPointId, 0, "node1.createEndPoint('\(bindURL)'. Bind) < 0")

            pauseForBind()

            var sent = try node0.sendMessage(payload)
            XCTAssertEqual(sent.bytes, payload.count, "sent.bytes != payload.count")

            usleep(TimeInterval(seconds: 0.75)) // sleep for 3/4 second, deadline is 1/2 second, will cause node0.receiveMessage() to timeout.

            let received = try node1.receiveMessage()
            XCTAssertEqual(received.bytes, received.message.count, "received.bytes != received.message.count")
            XCTAssertEqual(received.message, payload, "received.message != payload")

            sent = try node1.sendMessage(payload)

            do {
                _ = try node0.receiveMessage(blockingMode: .Blocking)
                XCTAssert(false, "received a message on node0!!!")
            } catch let error as NanoMessageError {
                switch error {
                    case .DeadlineExpired:
                        XCTAssert(true, "\(error)")   // we have deadline expired!!!
                    default:
                        throw error
                }
            } catch {
                throw error
            }

            completed = true
        } catch let error as NanoMessageError {
            XCTAssert(false, "\(error)")
        } catch {
            XCTAssert(false, "an unexpected error '\(error)' has occured in the library libNanoMessage.")
        }

        XCTAssert(completed, "test not completed")
    }

    func testTCPSurvey() {
        testSurvey(connectAddress: "tcp://localhost:5500", bindAddress: "tcp://*:5500")
    }

    func testInProcessSurvey() {
        testSurvey(connectAddress: "inproc:///tmp/survey.inproc")
    }

    func testInterProcessSurvey() {
        testSurvey(connectAddress: "ipc:///tmp/survey.ipc")
    }

    func testWebSocketSurvey() {
        testSurvey(connectAddress: "ws://localhost:5505", bindAddress: "ws://*:5505")
    }

#if os(Linux)
    static let allTests = [
        ("testTCPSurvey", testTCPSurvey),
        ("testInProcessSurvey", testInProcessSurvey),
        ("testInterProcessSurvey", testInterProcessSurvey),
        ("testWebSocketSurvey", testWebSocketSurvey)
    ]
#endif
}
