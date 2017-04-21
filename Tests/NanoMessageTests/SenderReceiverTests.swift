/*
    SenderReceiverTests.swift

    Copyright (c) 2017 Stephen Whittle  All rights reserved.

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

import NanoMessage

class SenderReceiverTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSenderReceiver() {
        var completed = false

        do {
            let node0 = try PushSocket()
            let node1 = try PullSocket()
            let node2 = try PairSocket()
            let node3 = try RequestSocket()
            let node4 = try ReplySocket()
            let node5 = try PublisherSocket()
            let node6 = try SubscriberSocket()
            let node7 = try SurveyorSocket()
            let node8 = try RespondentSocket()
            let node9 = try BusSocket()

            XCTAssertEqual(node0.receiver, false, "PushSocket() cannot be a receiver socket")
            XCTAssertEqual(node0.sender, true, "PushSocket() must be a sender socket")

            XCTAssertEqual(node1.receiver, true, "PullSocket() must be a receiver socket")
            XCTAssertEqual(node1.sender, false, "PullSocket() cannot be a sender socket")

            XCTAssertEqual(node2.receiver, true, "PairSocket() must be a receiver socket")
            XCTAssertEqual(node2.sender, true, "PairSocket() must a sender socket")

            XCTAssertEqual(node3.receiver, true, "RequestSocket() must be a receiver socket")
            XCTAssertEqual(node3.sender, true, "RequestSocket() must a sender socket")

            XCTAssertEqual(node4.receiver, true, "ReplySocket() must be a receiver socket")
            XCTAssertEqual(node4.sender, true, "ReplySocket() must a sender socket")

            XCTAssertEqual(node5.receiver, false, "PublisherSocket() cannot be a receiver socket")
            XCTAssertEqual(node5.sender, true, "PublisherSocket() must be a sender socket")

            XCTAssertEqual(node6.receiver, true, "SubscriberSocket() must be a receiver socket")
            XCTAssertEqual(node6.sender, false, "SubscriberSocket() cannot be a sender socket")

            XCTAssertEqual(node7.receiver, true, "SurveyorSocket() must be a receiver socket")
            XCTAssertEqual(node7.sender, true, "SurveyorSocket() must a sender socket")

            XCTAssertEqual(node8.receiver, true, "RespondentSocket() must be a receiver socket")
            XCTAssertEqual(node8.sender, true, "RespondentSocket() must a sender socket")

            XCTAssertEqual(node9.receiver, true, "BusSocket() must be a receiver socket")
            XCTAssertEqual(node9.sender, true, "BusSocket() must a sender socket")

            completed = true
        } catch let error as NanoMessageError {
            XCTAssert(false, "\(error)")
        } catch {
            XCTAssert(false, "an unexpected error '\(error)' has occured in the library libNanoMessage.")
        }

        XCTAssert(completed, "test not completed")
    }

#if os(Linux)
    static let allTests = [
        ("testSenderReceiver", testSenderReceiver)
    ]
#endif
}
