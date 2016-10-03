/*
    EndPoint.swift

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

import FNVHashValue

public struct EndPoint {
    public let id: Int
    public let address: String
    public let connectionType: ConnectionType
    public var transportMechanism: TransportMechanism {
        return TransportMechanism(rawValue: self.address)
    }
    public var name: String

    public init(endPointId: Int, endPointAddress: String, connectionType: ConnectionType, endPointName: String = "") {
        self.id = endPointId
        self.address = endPointAddress
        self.connectionType = connectionType
        self.name = endPointName
    }
}

extension EndPoint: Hashable {
    public var hashValue: Int {
        return fnv1a(self.id)
    }

    public static func ==(lhs: EndPoint, rhs: EndPoint) -> Bool {
        return (lhs.id == rhs.id)
    }
}
