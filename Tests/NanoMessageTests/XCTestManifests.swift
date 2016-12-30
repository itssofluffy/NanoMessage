/*
    XCTestManifests.swift

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

import Foundation
import XCTest

let payload = "This above all...to thine own self be true."

public var pauseTime = TimeInterval(seconds: 0.20).microseconds
public var pauseCount: UInt32 = 0

func pauseForBind() {
    usleep(pauseTime)
    pauseCount += 1
}

#if !os(OSX)
public let allTests = [
    testCase(NanoMsgTests.allTests),
    testCase(VersionTests.allTests),
    testCase(SocketOptionTests.allTests),
    testCase(EndPointTests.allTests),
    testCase(PipelineProtocolFamilyTests.allTests),
    testCase(PairProtocolFamilyTests.allTests),
    testCase(RequestReplyProtocolFamilyTests.allTests),
    testCase(PublishSubscribeProtocolFamilyTests.allTests),
    testCase(SurveyProtocolFamilyTests.allTests),
    testCase(BusProtocolFamilyTests.allTests),
    testCase(PollSocketTests.allTests),
    testCase(SocketStatisticTests.allTests),
    testCase(MessageSizeTests.allTests),
    testCase(MessageSpeedTests.allTests),
    testCase(BindToSocketTests.allTests),
    testCase(LoopBackTests.allTests)
]
#endif
