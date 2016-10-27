/*
    NanoMsgTests.swift

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

@testable import CNanoMessage
@testable import NanoMessage

class NanoMsgTests: XCTestCase {
    func testNanoMsgSymbols() {
        // test socket protocol values that we hard coded and imported from CNanoMessage and used in NanoMessage
        XCTAssertEqual(nanomsgSymbol["NN_PAIR"], SocketProtocol.PairProtocol.rawValue, "nanomsg symbol value for NN_PAIR is different than expected.")
        XCTAssertEqual(nanomsgSymbol["NN_PUB"], SocketProtocol.PublisherProtocol.rawValue, "nanomsg symbol value for NN_PUB is different than expected.")
        XCTAssertEqual(nanomsgSymbol["NN_SUB"], SocketProtocol.SubscriberProtocol.rawValue, "nanomsg symbol value for NN_SUB is different than expected.")
        XCTAssertEqual(nanomsgSymbol["NN_REQ"], SocketProtocol.RequestProtocol.rawValue, "nanomsg symbol value for NN_REQ is different than expected.")
        XCTAssertEqual(nanomsgSymbol["NN_REP"], SocketProtocol.ReplyProtocol.rawValue, "nanomsg symbol value for NN_REP is different than expected.")
        XCTAssertEqual(nanomsgSymbol["NN_PUSH"], SocketProtocol.PushProtocol.rawValue, "nanomsg symbol value for NN_PUSH is different than expected.")
        XCTAssertEqual(nanomsgSymbol["NN_PULL"], SocketProtocol.PullProtocol.rawValue, "nanomsg symbol value for NN_PULL is different than expected.")
        XCTAssertEqual(nanomsgSymbol["NN_SURVEYOR"], SocketProtocol.SurveyorProtocol.rawValue, "nanomsg symbol value for NN_SURVEYOR is different than expected.")
        XCTAssertEqual(nanomsgSymbol["NN_RESPONDENT"], SocketProtocol.RespondentProtocol.rawValue, "nanomsg symbol value for NN_RESPONDENT is different than expected.")
        XCTAssertEqual(nanomsgSymbol["NN_BUS"], SocketProtocol.BusProtocol.rawValue, "nanomsg symbol value for NN_BUS is different than expected.")
        // test error values that we use explicitly in NanoMessage
        XCTAssertEqual(nanomsgSymbol["EINTR"], EINTR, "nanomsg symbol value for EINTR is different than expected.")
        XCTAssertEqual(nanomsgSymbol["EAGAIN"], EAGAIN, "nanomsg symbol value for EAGAIN is different than expected.")
        XCTAssertEqual(nanomsgSymbol["ETIMEDOUT"], ETIMEDOUT, "nanomsg symbol value for ETIMEDOUT is different than expected.")
        // test nanomsg POSIX equilivant error codes.
        XCTAssertEqual(nanomsgError[EINTR], "EINTR", "nanomsgError[EINTR] != \"EINTR\"")
        XCTAssertEqual(nanomsgError[EAGAIN], "EAGAIN", "nanomsgError[EAGAIN] != \"EAGAIN\"")
        XCTAssertEqual(nanomsgError[ETIMEDOUT], "ETIMEDOUT", "nanomsgError[ETIMEDOUT] != \"ETIMEDOUT\"")
        // test underlying error strings.
        XCTAssertEqual(nanoMessageError(EINTR), "Interrupted system call", "nanoMessageError(EINTR) returned an unexpected result.")

        for symbol in symbolProperty {
            // value: 2, name: NN_SNDBUF, namespace: socket option, type: integer, unit: byte
            if (symbol.namespace == .SocketOption && symbol.name == "NN_SNDBUF") {
                XCTAssertEqual(symbol.type, .Integer, "symbol.type != .Integer")
                XCTAssertEqual(symbol.unit, .Byte, "symbol.unit != .Byte")
            }
            debugPrint(symbol)
        }
    }

#if !os(OSX)
    static let allTests = [
        ("testNanoMsgSymbols", testNanoMsgSymbols)
   ]
#endif
}
