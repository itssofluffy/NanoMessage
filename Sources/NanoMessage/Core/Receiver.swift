/*
    Receiver.swift

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

/// Receiver socket protocol.
public protocol Receiver {
    // I-O functions.
    func receiveMessage(blockingMode: BlockingMode) throws -> (bytes: Int, message: C7.Data)
    func receiveMessage(blockingMode: BlockingMode) throws -> (bytes: Int, message: String)
    // socket option functions.
    func getReceiveBufferSize() throws -> UInt
    func setReceiveBufferSize(bytes: UInt) throws
    func getMaximumMessageSize() throws -> Int
    func setMaximumMessageSize(bytes: Int) throws
    func getReceiveTimeout() throws -> TimeInterval
    func setReceiveTimeout(seconds: TimeInterval) throws
    func getReceivePriority() throws -> Int
    func setReceivePriority(_ priority: Int) throws
    func getReceiveFd() throws -> Int
    // socket statistics functions.
    func getMessagesReceived() throws -> UInt64
    func getBytesReceived() throws -> UInt64
}
