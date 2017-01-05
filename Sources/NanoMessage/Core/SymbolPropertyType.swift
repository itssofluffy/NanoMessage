/*
    SymbolPropertyType.swift

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

public enum SymbolPropertyType: CInt {
    case None
    case Integer
    case String
    case Unknown

    public var rawValue: CInt {
        switch self {
            case .None:
                return NN_TYPE_NONE
            case .Integer:
                return NN_TYPE_INT
            case .String:
                return NN_TYPE_STR
            case .Unknown:
                return CInt.max
        }
    }

    public init(rawValue: CInt) {
        switch rawValue {
            case NN_TYPE_NONE:
                self = .None
            case NN_TYPE_INT:
                self = .Integer
            case NN_TYPE_STR:
                self = .String
            default:
                self = .Unknown
        }
    }
}

extension SymbolPropertyType: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
            case .None:
                return "none"
            case .Integer:
                return "integer"
            case .String:
                return "string"
            case .Unknown:
                return "unknown"
        }
    }
}
