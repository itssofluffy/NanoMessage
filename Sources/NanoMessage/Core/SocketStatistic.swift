/*
    SocketStatistic.swift

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

public enum SocketStatistic: CInt {
    case EstablishedConnections         // The number of connections successfully established that were initiated from this socket.
    case AcceptedConnections            // The number of connections successfully established that were accepted by this socket.
    case DroppedConnections             // The number of established connections that were dropped by this socket.
    case BrokenConnections              // The number of established connections that were closed by this socket, typically due to protocol errors.
    case ConnectErrors                  // The number of errors encountered by this socket trying to connect to a remote peer.
    case BindErrors                     // The number of errors encountered by this socket trying to bind to a local address.
    case AcceptErrors                   // The number of errors encountered by this socket trying to accept a a connection from a remote peer.
    case CurrentConnections             // The number of connections currently estabalished to this socket.
    case MessagesSent                   // The number messages sent by this socket.
    case MessagesReceived               // The number messages received by this socket.
    case BytesSent                      // The number of bytes sent by this socket.
    case BytesReceived                  // The number of bytes received by this socket.
    case CurrentInProgressConnections   // The number of current connections that are in progress - undocumented socket statistic.
    case CurrentSendPriority            // The current send priority of the socket - undocumented socket statistic.
    case CurrentEndPointErrors          // The current number of end-point errors - undocumented socket statistic.

    public var rawValue: CInt {
        switch self {
            case .EstablishedConnections:
                return NN_STAT_ESTABLISHED_CONNECTIONS
            case .AcceptedConnections:
                return NN_STAT_ACCEPTED_CONNECTIONS
            case .DroppedConnections:
                return NN_STAT_DROPPED_CONNECTIONS
            case .BrokenConnections:
                return NN_STAT_BROKEN_CONNECTIONS
            case .ConnectErrors:
                return NN_STAT_CONNECT_ERRORS
            case .BindErrors:
                return NN_STAT_BIND_ERRORS
            case .AcceptErrors:
                return NN_STAT_ACCEPT_ERRORS
            case .CurrentConnections:
                return NN_STAT_CURRENT_CONNECTIONS
            case .MessagesSent:
                return NN_STAT_MESSAGES_SENT
            case .MessagesReceived:
                return NN_STAT_MESSAGES_RECEIVED
            case .BytesSent:
                return NN_STAT_BYTES_SENT
            case .BytesReceived:
                return NN_STAT_BYTES_RECEIVED
            case .CurrentInProgressConnections:
                return NN_STAT_INPROGRESS_CONNECTIONS
            case .CurrentSendPriority:
                return NN_STAT_CURRENT_SND_PRIORITY
            case .CurrentEndPointErrors:
                return NN_STAT_CURRENT_EP_ERRORS
        }
    }
}

extension SocketStatistic: CustomStringConvertible {
    public var description: String {
        switch self {
            case .EstablishedConnections:
                return "established connections"
            case .AcceptedConnections:
                return "accepted connections"
            case .DroppedConnections:
                return "dropped connections"
            case .BrokenConnections:
                return "broken connections"
            case .ConnectErrors:
                return "connect errors"
            case .BindErrors:
                return "bind errors"
            case .AcceptErrors:
                return "accept errors"
            case .CurrentConnections:
                return "current connections"
            case .MessagesSent:
                return "messages sent"
            case .MessagesReceived:
                return "messages received"
            case .BytesSent:
                return "bytes sent"
            case .BytesReceived:
                return "bytes received"
            case .CurrentInProgressConnections:
                return "current in progress connections"
            case .CurrentSendPriority:
                return "current send priority"
            case .CurrentEndPointErrors:
                return "current end-point errors"
        }
    }
}

/// Retrieves the value of a statistic from the socket. Not all statistics are relevant to all transports.
/// For example, the nn_inproc(7) transport does not maintain any of the connection related statistics.
///
/// - Parameters:
///   - socketFd: The NanoSocket file descriptor
///   - option:   The nanomsg statistic option.
///
/// - Throws: `NanoMessageError.GetSocketStatistic` if an issue was encountered.
///
/// - Returns: the resulting statistic.
///
/// - Note:    While this extension API is stable, these statistics are intended for human consumption,
///            to facilitate observability and debugging. The actual statistics themselves as well as
///            their meanings are unstable, and subject to change without notice. Programs should not
///            depend on the presence or values of any particular statistic. 
internal func getSocketStatistic(_ socketFd: CInt, _ option: SocketStatistic) throws -> UInt64 {
    let statistic = nn_get_statistic(socketFd, option.rawValue)

    guard (statistic >= 0) else {
        throw NanoMessageError.GetSocketStatistic(code: nn_errno(), option: option)
    }

    return statistic
}

/// Retrieves the value of a statistic from the socket. Not all statistics are relevant to all transports.
/// For example, the nn_inproc(7) transport does not maintain any of the connection related statistics.
///
/// - Parameters:
///   - socketFd: The NanoSocket file descriptor
///   - option:   The nanomsg statistic option.
///
/// - Throws: `NanoMessageError.GetSocketStatistic` if an issue was encountered.
///
/// - Returns: the resulting statistic.
///
/// - Note:    While this extension API is stable, these statistics are intended for human consumption,
///            to facilitate observability and debugging. The actual statistics themselves as well as
///            their meanings are unstable, and subject to change without notice. Programs should not
///            depend on the presence or values of any particular statistic. 
internal func getSocketStatistic(_ socketFd: CInt, _ option: SocketStatistic) throws -> Priority {
    let statistic = nn_get_statistic(socketFd, option.rawValue)

    guard (statistic >= 0) else {
        throw NanoMessageError.GetSocketStatistic(code: nn_errno(), option: option)
    }

    return Priority(level: Int(statistic))
}
