/*
    ASyncSender.swift

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

/// ASync Sender socket protocol.
public protocol ASyncSender {
    // ASync I-O functions.
    func sendMessage(_ message: C7.Data, blockingMode: BlockingMode, _ closureHandler: @escaping (Int?, Error?) -> Void)
    func sendMessage(_ message: String, blockingMode: BlockingMode, _ closureHandler: @escaping (Int?, Error?) -> Void)
    func sendMessage(_ message: C7.Data, timeout: TimeInterval, _ closureHandler: @escaping (Int?, Error?) -> Void)
    func sendMessage(_ message: String, timeout: TimeInterval, _ closureHandler: @escaping (Int?, Error?) -> Void)
    func sendMessage(_ message: C7.Data, timeout: Timeout, _ closureHandler: @escaping (Int?, Error?) -> Void)
    func sendMessage(_ message: String, timeout: Timeout, _ closureHandler: @escaping (Int?, Error?) -> Void)
}
