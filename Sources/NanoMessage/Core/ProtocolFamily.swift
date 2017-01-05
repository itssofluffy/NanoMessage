/*
    ProtocolFamily.swift

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

/// Socket protocol family.
public enum ProtocolFamily {
    case OneToOne          // One-to-one protocol family.
    case PublishSubscribe  // Publish/Subscribe protocol family. These socket types are used to distribute messages to multiple destinations.
    case RequestReply      // Request/reply protocol family. These socket types are used to send requests and receive replies.
    case Pipeline          // Pipeline protocol family. These socket types are used to send message to a cluster of load-balanced nodes.
    case Survey            // Survey protocol family. These socket types are used to send the survrey.
    case Bus               // Message bus protocol family.

    public init(socketProtocol: SocketProtocol) {
        switch socketProtocol {
            case .PairProtocol:
                self = .OneToOne
            case .PublisherProtocol, .SubscriberProtocol:
                self = .PublishSubscribe
            case .RequestProtocol, .ReplyProtocol:
                self = .RequestReply
            case .PushProtocol, .PullProtocol:
                self = .Pipeline
            case .SurveyorProtocol, .RespondentProtocol:
                self = .Survey
            case .BusProtocol:
                self = .Bus
        }
    }
}

extension ProtocolFamily: CustomStringConvertible {
    public var description: String {
        switch self {
            case .OneToOne:
                return "one-to-one"
            case .PublishSubscribe:
                return "publish/subscribe"
            case .RequestReply:
                return "request/reply"
            case .Pipeline:
                return "pipeline"
            case .Survey:
                return "survey"
            case .Bus:
                return "bus"
        }
    }
}
