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

/// Endpoint.
public struct EndPoint {
    public let id: Int                                      // end-point id
    public let address: String                              // end-point address
    public let connectionType: ConnectionType               // end-point connection type (connect/bind)
    public var transportMechanism: TransportMechanism {     // end-points transport mechanism
        return TransportMechanism(rawValue: self.address)
    }
    public var name: String                                 // user defined name of the end-point

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

extension EndPoint: CustomStringConvertible {
    public var description: String {
        var description = "id: \(self.id), address: \(self.address), connection type: \(self.connectionType), transport: \(self.transportMechanism)"
        if (self.name != "") {
            description += ", name: \(self.name)"
        }

        return description
    }
}
