/*
    Sender.swift

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
import C7

/// Sender socket protocol.
public protocol Sender {
    // I-O functions.
    func sendMessage(_ message: C7.Data, blockingMode: BlockingMode) throws -> Int
    func sendMessage(_ message: String, blockingMode: BlockingMode) throws -> Int
    func sendMessage(_ message: C7.Data, timeout: TimeInterval) throws -> Int
    func sendMessage(_ message: String, timeout: TimeInterval) throws -> Int
    // socket option functions.
    func getSendBufferSize() throws -> UInt
    func setSendBufferSize(bytes: UInt) throws
    func getSendTimeout() throws -> TimeInterval
    func setSendTimeout(seconds: TimeInterval) throws
    func getSendPriority() throws -> Priority
    func setSendPriority(_ priority: Priority) throws
    func getSendFd() throws -> Int
    // socket statistics functions.
    func getMessagesSent() throws -> UInt64
    func getBytesSent() throws -> UInt64
    func getCurrentSendPriority() throws -> Priority
}
