/*
    TimeInterval.swift

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

extension TimeInterval {
    public init(seconds: Int) {
        self = Double(seconds)
    }

    public init(seconds: Double) {
        self = seconds
    }

    public init(seconds: Timeout) {
        self = seconds.rawValue
    }
}

extension TimeInterval {
    public init(milliseconds: Int) {
        self = TimeInterval(milliseconds) / 1000
    }

    public init(milliseconds: Timeout) {
        self = milliseconds.rawValue
    }

    public var asMilliseconds: Int {
        return Int(self * 1000)
    }
}

extension TimeInterval {
    public init(microseconds: CUnsignedInt) {
        self = Double(microseconds) / 1000000
    }

    public init(microseconds: Timeout) {
        self = microseconds.rawValue
    }

    public var asMicroseconds: CUnsignedInt {
        return CUnsignedInt(self * 1000000)
    }
}
