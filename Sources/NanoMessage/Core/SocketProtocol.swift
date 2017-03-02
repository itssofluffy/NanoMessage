/*
    SocketProtocol.swift

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

/// Sockets protocol.
public enum SocketProtocol {
    case PairProtocol       // One-to-one protocol.
    case PublisherProtocol  // Publish/Subscribe protocol. This socket type is used to distribute messages to multiple destinations.
    case SubscriberProtocol // Publish/Subscribe protocol. This socket type is used to receives messages from the publisher.
    case RequestProtocol    // Request/reply protocol. This socket type is used to send requests and receive replies.
    case ReplyProtocol      // Request/reply protocol. This socket type is used to receive requests and sends replies.
    case PushProtocol       // Pipeline protocol. This socket type is used to send message to a cluster of load-balanced nodes.
    case PullProtocol       // Pipeline protocol. This socket type is used to receive a message from a cluster of nodes.
    case SurveyorProtocol   // Survey protocol. This socket type is used to send the survrey.
    case RespondentProtocol // Survey protocol. This socket type is used to respond to the survey.
    case BusProtocol        // Message bus protocol.

    public var rawValue: CInt {
        switch self {
            case .PairProtocol:
                return NN_PAIR
            case .PublisherProtocol:
                return NN_PUB
            case .SubscriberProtocol:
                return NN_SUB
            case .RequestProtocol:
                return NN_REQ
            case .ReplyProtocol:
                return NN_REP
            case .PushProtocol:
                return NN_PUSH
            case .PullProtocol:
                return NN_PULL
            case .SurveyorProtocol:
                return NN_SURVEYOR
            case .RespondentProtocol:
                return NN_RESPONDENT
            case .BusProtocol:
                return NN_BUS
        }
    }
}

extension SocketProtocol: CustomStringConvertible {
    public var description: String {
        switch self {
            case .PairProtocol:
                return "pair"
            case .PublisherProtocol:
                return "publisher"
            case .SubscriberProtocol:
                return "subscriber"
            case .RequestProtocol:
                return "request"
            case .ReplyProtocol:
                return "reply"
            case .PushProtocol:
                return "push"
            case .PullProtocol:
                return "pull"
            case .SurveyorProtocol:
                return "surveyor"
            case .RespondentProtocol:
                return "respondent"
            case .BusProtocol:
                return "bus"
        }
    }
}
