/*
    SymbolPropertyNamespace.swift

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

import CNanoMessage

public enum SymbolPropertyNamespace: CInt {
    case Namespace
    case Version
    case Domain
    case Transport
    case `Protocol`
    case OptionLevel
    case SocketOption
    case TransportOption
    case OptionType
    case OptionUnit
    case Flag
    case Error
    case Limit
    case Event
    case Statistic
    case Unknown

    public var rawValue: CInt {
        switch self {
            case .Namespace:
                return NN_NS_NAMESPACE
            case .Version:
                return NN_NS_VERSION
            case .Domain:
                return NN_NS_DOMAIN
            case .Transport:
                return NN_NS_TRANSPORT
            case .Protocol:
                return NN_NS_PROTOCOL
            case .OptionLevel:
                return NN_NS_OPTION_LEVEL
            case .SocketOption:
                return NN_NS_SOCKET_OPTION
            case .TransportOption:
                return NN_NS_TRANSPORT_OPTION
            case .OptionType:
                return NN_NS_OPTION_TYPE
            case .OptionUnit:
                return NN_NS_OPTION_UNIT
            case .Flag:
                return NN_NS_FLAG
            case .Error:
                return NN_NS_ERROR
            case .Limit:
                return NN_NS_LIMIT
            case .Event:
                return NN_NS_EVENT
            case .Statistic:
                return NN_NS_STATISTIC
            case .Unknown:
                return CInt.max
        }
    }

    public init(rawValue: CInt) {
        switch rawValue {
            case NN_NS_NAMESPACE:
                self = .Namespace
            case NN_NS_VERSION:
                self = .Version
            case NN_NS_DOMAIN:
                self = .Domain
            case NN_NS_TRANSPORT:
                self = .Transport
            case NN_NS_PROTOCOL:
                self = .Protocol
            case NN_NS_OPTION_LEVEL:
                self = .OptionLevel
            case NN_NS_SOCKET_OPTION:
                self = .SocketOption
            case NN_NS_TRANSPORT_OPTION:
                self = .TransportOption
            case NN_NS_OPTION_TYPE:
                self = .OptionType
            case NN_NS_OPTION_UNIT:
                self = .OptionUnit
            case NN_NS_FLAG:
                self = .Flag
            case NN_NS_ERROR:
                self = .Error
            case NN_NS_LIMIT:
                self = .Limit
            case NN_NS_EVENT:
                self = .Event
            case NN_NS_STATISTIC:
                self = .Statistic
            default:
                self = .Unknown
        }
    }
}

extension SymbolPropertyNamespace: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
            case .Namespace:
                return "namespace"
            case .Version:
                return "version"
            case .Domain:
                return "domain"
            case .Transport:
                return "transport"
            case .Protocol:
                return "protocol"
            case .OptionLevel:
                return "option level"
            case .SocketOption:
                return "socket option"
            case .TransportOption:
                return "transport option"
            case .OptionType:
                return "option type"
            case .OptionUnit:
                return "option unit"
            case .Flag:
                return "flag"
            case .Error:
                return "error"
            case .Limit:
                return "limit"
            case .Event:
                return "event"
            case .Statistic:
                return "statistic"
            case .Unknown:
                return "unknown"
        }
    }
}
