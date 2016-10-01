/*
    NanoMessageError.swift

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

#if os(Linux)
import Glibc
#else
import Darwin
#endif
import CNanoMessage

public enum NanoMessageError: Error {
    case nanomsgError(errorNumber: Int, errorMessage: String)
    case Error(errorNumber: Int, errorMessage: String)

    init() {
        var nanoError: (Int, String) {
            let errorNumber = nn_errno()
            let errorMessage = String(cString: nn_strerror(errorNumber))

            return (Int(errorNumber), errorMessage)
        }
        let (errorNumber, errorMessage) = nanoError

        self = .nanomsgError(errorNumber: errorNumber, errorMessage: errorMessage)
    }

    init(errorNumber: Int, errorMessage: String) {
        self = .Error(errorNumber: errorNumber, errorMessage: errorMessage)
    }
}


public struct StderrOutputStream: TextOutputStream {
    public mutating func write(_ string: String) {
        fputs(string, stderr)
    }
}

public var stdErrorStream = StderrOutputStream()

public func errorPrint(_ message: String) {
    debugPrint(message, to: &stdErrorStream)
}
