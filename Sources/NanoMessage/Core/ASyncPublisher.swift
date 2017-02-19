/*
    ASyncPublisher.swift

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

import Foundation
import C7

/// ASync Publisher socket protocol.
public protocol ASyncPublisher {
    // ASync Output functions.
    func sendMessage(topic:        C7.Data,
                     message:      C7.Data,
                     blockingMode: BlockingMode,
                     success:      @escaping (Int) -> Void,
                     failure:      @escaping (Error) -> Void)
    func sendMessage(topic:        C7.Data,
                     message:      String,
                     blockingMode: BlockingMode,
                     success:      @escaping (Int) -> Void,
                     failure:      @escaping (Error) -> Void)
    func sendMessage(topic:        String,
                     message:      C7.Data,
                     blockingMode: BlockingMode,
                     success:      @escaping (Int) -> Void,
                     failure:      @escaping (Error) -> Void)
    func sendMessage(topic:        String,
                     message:      String,
                     blockingMode: BlockingMode,
                     success:      @escaping (Int) -> Void,
                     failure:      @escaping (Error) -> Void)
    func sendMessage(topic:        C7.Data,
                     message:      C7.Data,
                     timeout:      TimeInterval,
                     success:      @escaping (Int) -> Void,
                     failure:      @escaping (Error) -> Void)
    func sendMessage(topic:        C7.Data,
                     message:      String,
                     timeout:      TimeInterval,
                     success:      @escaping (Int) -> Void,
                     failure:      @escaping (Error) -> Void)
    func sendMessage(topic:        String,
                     message:      C7.Data,
                     timeout:      TimeInterval,
                     success:      @escaping (Int) -> Void,
                     failure:      @escaping (Error) -> Void)
    func sendMessage(topic:        String,
                     message:      String,
                     timeout:      TimeInterval,
                     success:      @escaping (Int) -> Void,
                     failure:      @escaping (Error) -> Void)
    func sendMessage(topic:        C7.Data,
                     message:      C7.Data,
                     timeout:      Timeout,
                     success:      @escaping (Int) -> Void,
                     failure:      @escaping (Error) -> Void)
    func sendMessage(topic:        C7.Data,
                     message:      String,
                     timeout:      Timeout,
                     success:      @escaping (Int) -> Void,
                     failure:      @escaping (Error) -> Void)
    func sendMessage(topic:        String,
                     message:      C7.Data,
                     timeout:      Timeout,
                     success:      @escaping (Int) -> Void,
                     failure:      @escaping (Error) -> Void)
    func sendMessage(topic:        String,
                     message:      String,
                     timeout:      Timeout,
                     success:      @escaping (Int) -> Void,
                     failure:      @escaping (Error) -> Void)
}
