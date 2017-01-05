/*
    SymbolPropertyUnit.swift

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

import CNanoMessage

public enum SymbolPropertyUnit: CInt {
    case None
    case Byte
    case Milliseconds
    case Priority
    case Boolean
    case Counter
    case Messages
    case Unknown

    public var rawValue: CInt {
        switch self {
            case .None:
                return NN_UNIT_NONE
            case .Byte:
                return NN_UNIT_BYTES
            case .Milliseconds:
                return NN_UNIT_MILLISECONDS
            case .Priority:
                return NN_UNIT_PRIORITY
            case .Boolean:
                return NN_UNIT_BOOLEAN
            case .Counter:
                return NN_UNIT_COUNTER
            case .Messages:
                return NN_UNIT_MESSAGES
            case .Unknown:
                return CInt.max
        }
    }

    public init(rawValue: CInt) {
        switch rawValue {
            case NN_UNIT_NONE:
                self = .None
            case NN_UNIT_BYTES:
                self = .Byte
            case NN_UNIT_MILLISECONDS:
                self = .Milliseconds
            case NN_UNIT_PRIORITY:
                self = .Priority
            case NN_UNIT_BOOLEAN:
                self = .Boolean
            case NN_UNIT_COUNTER:
                self = .Counter
            case NN_UNIT_MESSAGES:
                self = .Messages
            default:
                self = .Unknown
        }
    }
}

extension SymbolPropertyUnit: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
            case .None:
                return "none"
            case .Byte:
                return "byte"
            case .Milliseconds:
                return "milliseconds"
            case .Priority:
                return "priority"
            case .Boolean:
                return "boolean"
            case .Counter:
                return "counter"
            case .Messages:
                return "messages"
            case .Unknown:
                return "unknown"
        }
    }
}
