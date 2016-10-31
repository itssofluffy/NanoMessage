/*
    VersionTests.swift

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

@testable import NanoMessage

class VersionTests: XCTestCase {
    func testNanoMsgABIVersion() {
        let (current, revision, age) = nanoMsgABIVersion

         XCTAssertEqual(current, 5, "nanomsg ABI current not as expected")
         XCTAssertEqual(revision, 0, "nanomsg ABI revision not as expected")
         XCTAssertEqual(age, 0, "nanomsg ABI age not as expected")

         print("current: \(current), revision: \(revision), age: \(age)")
    }

    func testNanoMessageVersion() {
        let (current, revision, age) = nanoMessageVersion

         XCTAssertEqual(current, 0, "NanoMessage current not as expected")
         XCTAssertEqual(revision, 0, "NanoMessage revision not as expected")
         XCTAssertGreaterThanOrEqual(age, 8, "NanoMessage age not as expected")

         print("current: \(current), revision: \(revision), age: \(age)")
    }

#if !os(OSX)
    static let allTests = [
        ("testNanoMsgABIVersion", testNanoMsgABIVersion),
        ("testNanoMessageVersion", testNanoMessageVersion)
   ]
#endif
}
