/*
    SymbolProperty.swift

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

import FNVHashValue
import ISFLibrary

/// Nanomsg symbol.
public struct SymbolProperty {
    public let namespace: SymbolPropertyNamespace
    public let name: String
    public let value: CInt
    public let type: SymbolPropertyType
    public let unit: SymbolPropertyUnit

    public init(namespace: CInt,
                name:      String,
                value:     CInt,
                type:      CInt,
                unit:      CInt) {
        self.namespace = SymbolPropertyNamespace(rawValue: namespace)
        self.name = name
        self.value = value
        self.type = SymbolPropertyType(rawValue: type)
        self.unit = SymbolPropertyUnit(rawValue: unit)
    }
}

extension SymbolProperty: Hashable {
    public var hashValue: Int {
        return fnv1a(typeToBytes(namespace) + typeToBytes(value))
    }
}

extension SymbolProperty: Comparable {
    public static func <(lhs: SymbolProperty, rhs: SymbolProperty) -> Bool {
        return ((lhs.namespace.rawValue < rhs.namespace.rawValue) ||
                (lhs.namespace.rawValue == rhs.namespace.rawValue && lhs.value < rhs.value))
    }
}

extension SymbolProperty: Equatable {
    public static func ==(lhs: SymbolProperty, rhs: SymbolProperty) -> Bool {
        return (lhs.namespace == rhs.namespace && lhs.value == rhs.value)
    }
}

extension SymbolProperty: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "namespace: \(namespace), name: \(name), value: \(value), type: \(type), unit: \(unit)"
    }
}
