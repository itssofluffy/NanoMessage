/*
    NanoMessage.swift

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

/// On publish/subscribe sockets the maximum size of a topic
public let maximumTopicLength = 128

/// The underlying nanomsg libraries ABI version.
public var nanoMsgABIVersion: (current: Int, revision: Int, age: Int) {
    return (Int(NN_VERSION_CURRENT), Int(NN_VERSION_REVISION), Int(NN_VERSION_AGE))
}

/// NanoMessage library version.
public var nanoMessageVersion: (current: Int, revision: Int, age: Int) {
    return (current: 0, revision: 0, age: 12)
}

/// Notify all sockets about process termination.
public func terminate() {
    nn_term()
}

private var _nanomsgSymbol = Dictionary<String, CInt>()
/// A dictionary of nanomsg symbol names and values.
public var nanomsgSymbol: Dictionary<String, CInt> {
    func _getSymbol(_ index: CInt) -> (name: String, value: CInt)? {
        var value: CInt = 0

        if let symbolName = nn_symbol(index, &value) {
            return (String(cString: symbolName), value)
        }

        return nil
    }

    if (_nanomsgSymbol.isEmpty) {
        var index: CInt = 0

        while (true) {
            if let symbol = _getSymbol(index) {
                _nanomsgSymbol[symbol.name] = symbol.value
            } else {
                break     // no more symbols
            }

            index += 1
        }
    }

    return _nanomsgSymbol
}

private var _symbolProperty = Set<SymbolProperty>()
/// A set of nanomsg symbol properties.
public var symbolProperty: Set<SymbolProperty> {
    if (_symbolProperty.isEmpty) {
        var buffer = nn_symbol_properties()
        let bufferLength = CInt(MemoryLayout<nn_symbol_properties>.size)
        var index: CInt = 0

        while (true) {
            let returnCode = nn_symbol_info(index, &buffer, bufferLength)

            if (returnCode == 0) {    // no more symbol properties
                break
            }

            _symbolProperty.insert(SymbolProperty(namespace: buffer.ns,
                                                  name:      String(cString: buffer.name),
                                                  value:     buffer.value,
                                                  type:      buffer.type,
                                                  unit:      buffer.unit))

            index += 1
        }
    }

    return _symbolProperty
}
