/*
    NanoSocket.swift

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

import Foundation
import CNanoMessage

/// A NanoMessage base socket.
public class NanoSocket {
/// The raw nanomsg socket file descriptor.
    public private(set) var socketFd: CInt = -1
/// A set of `EndPoint` structures that the socket is attached to either locally or remotly.
    public fileprivate(set) var endPoints = Set<EndPoint>()

    private var _closureAttempts: UInt = 10
/// The number of attempts to close down a socket or endpoint.
///
/// - Note:  The `getLinger()` function is called to determine the number of milliseconds to
///          wait for a socket/endpoint to clear and close, this is divided by `closureAttempts`
///          to determine the minimum pause between each attempt.
    public var closureAttempts: UInt {
        get {
            return self._closureAttempts
        }
        set (attempts) {
            self._closureAttempts = (attempts > 0) ? attempts : 1
        }
    }
/// Determine if when de-referencing the socket we are going to keep attempting to close the socket until successful.
///
/// - Warning: Please not that if true this will block until the class has been de-referenced.
    public var blockTillCloseSuccess = false

/// Creates a nanomsg socket with the specified socketDomain and socketProtocol.
///
/// - Parameters:
///   - socketDomain:   The sockets Domain.
///   - socketProtocol: The sockets Protocol.
///
/// - Throws: `NanoMessageError.NanoSocket` if the nanomsg socket has failed to be created
    public init(socketDomain: SocketDomain, socketProtocol: SocketProtocol) throws {
        self.socketFd = nn_socket(socketDomain.rawValue, socketProtocol.rawValue)

        guard (self.socketFd >= 0) else {
            throw NanoMessageError.NanoSocket(code: nn_errno())
        }
    }

    deinit {
        func closeSocket(_ microSecondsDelay: UInt32) throws {
            if (self.socketFd >= 0) {                                   // if we have a valid nanomsg socket file descriptor then...
                var loopCount: UInt = 0

                while (true) {
                    let returnCode = nn_close(self.socketFd)            // try and close the nanomsg socket

                    if (returnCode < 0) {                               // if `nn_close()` failed then...
                        let errno = nn_errno()

                        if (errno == EINTR) {                           // if we were interrupted by a signal, reattempt is allowed by the native library
                            if (loopCount >= self.closureAttempts) {    // we've reached our limit so say we were interrupted
                                throw NanoMessageError.Interrupted
                            }
                        } else {
                            throw NanoMessageError.Close(code: errno)
                        }

                        usleep(microSecondsDelay)                       // zzzz...

                        loopCount += 1
                    } else {
                        break                                           // we've closed the socket succesfully
                    }
                }
            }
        }

        // calculate the delay between re-attempts of closing the socket.
        let microSecondsDelay = UInt32(_getClosureTimeout() * 1000 / self.closureAttempts)
        // are we going to terminate the `repeat` loop below.
        var terminateLoop = true

        repeat {
            do {
                try closeSocket(microSecondsDelay)
            } catch NanoMessageError.Interrupted {
                print("NanoSocket.deinit(): \(NanoMessageError.Interrupted))")
                if (self.blockTillCloseSuccess) {
                    terminateLoop = false
                }
            } catch let error as NanoMessageError {
                print(error)
                terminateLoop = true
            } catch {
                print("an unexpected error '\(error)' has occured in the library libNanoMessage.")
                terminateLoop = true
            }
        } while (!terminateLoop)
    }

/// Get the time in milliseconds to allow to attempt to close a socket or endpoint.
///
/// - Returns: The closure time in milliseconds.
    fileprivate func _getClosureTimeout() -> UInt {
        if var milliseconds = try? self.getLinger() {
            if (milliseconds <= 0) {
                milliseconds = 1000
            }

            return UInt(milliseconds)
        }

        return 1000
    }
}

extension NanoSocket {
/// Get socket priorites (receive/send)
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///
/// - Returns: Tuple of receive and send send priorities, if either is nil then
///            socket is either not a receiver or sender.
    private func _socketPriorities() throws -> (receivePriority: Int?, sendPriority: Int?) {
        var receivePriority: Int?
        var sendPriority: Int?

        if let _: Int = try? getSocketOption(socketFd, .ReceiveFd) {                  // if this is a receiver socket then...
            receivePriority = try getSocketOption(self.socketFd, .ReceivePriority)    // obtain the receive priority for the end-point.
        }
        if let _: Int = try? getSocketOption(socketFd, .SendFd) {                     // if this is a sender socket then...
            sendPriority = try getSocketOption(self.socketFd, .SendPriority)          // obtain the send priority for the end-point.
        }

        return (receivePriority, sendPriority)
    }

/// Adds a local endpoint to the socket. The endpoint can be then used by other applications to connect to.
///
/// - Parameters:
///   - endPointAddress: Consists of two parts as follows: transport://address. The transport specifies the
///                      underlying transport protocol to use. The meaning of the address part is specific
///                      to the underlying transport protocol.
///   - endPointName:    An optional endpoint name.
///
/// - Throws:  `NanoMessageError.BindToAddress` if there was a problem binding the socket to the address.
///            `NanoMessageError.GetSocketOption`
///
/// - Returns: An endpoint that has just been binded too. The endpoint can be later used to remove the
///            endpoint from the socket via `removeEndPoint()` function.
///
/// - Note:    Note that `bindToAddress()` may be called multiple times on the same socket thus allowing the
///            socket to communicate with multiple heterogeneous endpoints.
    public func bindToAddress(_ endPointAddress: String, endPointName: String = "") throws -> EndPoint {
        var endPointId: CInt = -1

        let socket: (receivePriority: Int?, sendPriority: Int?) = try _socketPriorities()

        endPointAddress.withCString {
            endPointId = nn_bind(self.socketFd, $0)
        }

        guard (endPointId >= 0) else {
            throw NanoMessageError.BindToAddress(code: nn_errno(), address: endPointAddress)
        }

        let endPoint = EndPoint(endPointId: Int(endPointId),
                                endPointAddress: endPointAddress,
                                connectionType: .BindToAddress,
                                receivePriority: socket.receivePriority,
                                sendPriority: socket.sendPriority,
                                endPointName: endPointName)

        self.endPoints.insert(endPoint)

        return endPoint
    }

/// Adds a local endpoint to the socket. The endpoint can be then used by other applications to connect to.
///
/// - Parameters:
///   - endPointAddress: Consists of two parts as follows: transport://address. The transport specifies the
///                      underlying transport protocol to use. The meaning of the address part is specific
///                      to the underlying transport protocol.
///   - endPointName:    An optional endpoint name.
///
/// - Throws:  `NanoMessageError.BindToAddress` if there was a problem binding the socket to the address.
///            `NanoMessageError.GetSocketOption`
///
/// - Returns: An endpoint ID is returned. The endpoint ID can be later used to remove the endpoint from
///            the socket via `removeEndPoint()` function.
///
/// - Note:    Note that `bindToAddress()` may be called multiple times on the same socket thus allowing the
///            socket to communicate with multiple heterogeneous endpoints.
    public func bindToAddress(_ endPointAddress: String, endPointName: String = "") throws -> Int {
        let endPoint: EndPoint = try self.bindToAddress(endPointAddress, endPointName: endPointName)

        return endPoint.id
    }

/// Adds a remote endpoint to the socket. The library would then try to connect to the specified remote endpoint.
///
/// - Parameters:
///   - endPointAddress: Consists of two parts as follows: transport://address. The transport specifies the
///                      underlying transport protocol to use. The meaning of the address part is specific
///                      to the underlying transport protocol.
///   - endPointName:    An optional endpoint name.
///
/// - Throws:  `NanoMessageError.ConnectToAddress` if there was a problem binding the socket to the address.
///            `NanoMessageError.GetSocketOption`
///
/// - Returns: The endpoint that has just been connected too. The endpoint can be later used to remove the
///            endpoint from the socket via `removeEndPoint()` function.
///
/// - Note:    Note that `connectToAddress()` may be called multiple times on the same socket thus allowing the
///            socket to communicate with multiple heterogeneous endpoints.
    public func connectToAddress(_ endPointAddress: String, endPointName: String = "") throws -> EndPoint {
        var endPointId: CInt = -1

        let socket: (receivePriority: Int?, sendPriority: Int?) = try _socketPriorities()

        endPointAddress.withCString {
            endPointId = nn_connect(self.socketFd, $0)
        }

        guard (endPointId >= 0) else {
            throw NanoMessageError.ConnectToAddress(code: nn_errno(), address: endPointAddress)
        }

        let endPoint = EndPoint(endPointId: Int(endPointId),
                                endPointAddress: endPointAddress,
                                connectionType: .ConnectToAddress,
                                receivePriority: socket.receivePriority,
                                sendPriority: socket.sendPriority,
                                endPointName: endPointName)

        self.endPoints.insert(endPoint)

        return endPoint
    }

/// Adds a remote endpoint to the socket. The library would then try to connect to the specified remote endpoint.
///
/// - Parameters:
///   - endPointAddress: Consists of two parts as follows: transport://address. The transport specifies the
///                      underlying transport protocol to use. The meaning of the address part is specific
///                      to the underlying transport protocol.
///   - endPointName:    An optional endpoint name.
///
/// - Throws:  `NanoMessageError.ConnectToAddress` if there was a problem binding the socket to the address.
///            `NanoMessageError.GetSocketOption`
///
/// - Returns: An endpoint ID is returned. The endpoint ID can be later used to remove the endpoint from the
///            socket via the `removeEndPoint()` function.
///
/// - Note:    Note that `connectToAddress()` may be called multiple times on the same socket thus allowing the
///            socket to communicate with multiple heterogeneous endpoints.
    public func connectToAddress(_ endPointAddress: String, endPointName: String = "") throws -> Int {
        let endPoint: EndPoint = try self.connectToAddress(endPointAddress, endPointName: endPointName)

        return endPoint.id
    }

/// Remove an endpoint from the socket.
///
/// - Parameters:
///   - endPoint: An endpoint.
///
/// - Throws: `NanoMessageError.RemoveEndPoint` if the endpoint failed to be removed,
///           `NanoMessageError.Interrupted` if the endpoint removal was interrupted.
///
/// - Returns: If the endpoint was removed, false indicates that the endpoint was not attached to the socket.
    @discardableResult
    public func removeEndPoint(_ endPoint: EndPoint) throws -> Bool {
        if (self.endPoints.contains(endPoint)) {
            var loopCount: UInt = 0
            // calculate the delay between re-attempts of closing the socket.
            let microSecondsDelay = UInt32(_getClosureTimeout() * 1000 / self.closureAttempts)

            while (true) {
                let returnCode = nn_shutdown(self.socketFd, CInt(endPoint.id))  // attempt to close down the endpoint

                if (returnCode < 0) {                                           // if `nn_shutdown()` failed then...
                    let errno = nn_errno()

                    if (errno == EINTR) {                                       // if we were interrupted by a signal, reattempt is allowed by the native library
                        if (loopCount >= self.closureAttempts) {
                            throw NanoMessageError.Interrupted
                        }

                        usleep(microSecondsDelay)                               // zzzz...

                        loopCount += 1
                    } else {
                        throw NanoMessageError.RemoveEndPoint(code: errno, address: endPoint.address, endPointId: endPoint.id)
                    }
                } else {
                    break                                                       // we've closed the endpoint succesfully
                }
            }

            self.endPoints.remove(endPoint)

            return true
        }

        return false
    }

/// Remove an endpoint from the socket.
///
/// - Parameters:
///   - endPoint: An endpoint.
///
/// - Throws: `NanoMessageError.RemoveEndPoint` if the endpoint failed to be removed,
///           `NanoMessageError.Interrupted` if the endpoint removal was interrupted.
///
/// - Returns: If the endpoint was removed, false indicates that the endpoint was not attached to the socket.
    @discardableResult
    public func removeEndPoint(_ endPointId: Int) throws -> Bool {
        for endPoint in self.endPoints {
            if (endPointId == endPoint.id) {
                return try self.removeEndPoint(endPoint)
            }
        }

        return false
    }

/// Check a socket and reports whether it’s possible to send a message to the socket and/or receive a message from the socket.
///
/// - Parameters:
///   - timeout milliseconds: The maximum number of milliseconds to poll the socket for an event to occur,
///                           default is 1000 milliseconds (1 second).
///
/// - Throws: `NanoMessageError.PollSocket` if polling the socket fails.
///
/// - Returns: Message waiting and send queue blocked as a tuple of bools.
    public func pollSocket(timeout milliseconds: Int = 1000) throws -> (messageIsWaiting: Bool, sendIsBlocked: Bool) {
        let pollinMask = CShort(NN_POLLIN)                                      // define nn_poll event masks as short's so we only
        let polloutMask = CShort(NN_POLLOUT)                                    // cast once in the function

        var eventMask = CShort.allZeros                                         //
        if let _: Int = try? getSocketOption(self.socketFd, .ReceiveFd) {       // rely on the fact that getting the for example receive
            eventMask = pollinMask                                              // file descriptor for a socket type that does not support
        }                                                                       // receiving will throw a nil return value to determine
        if let _: Int = try? getSocketOption(self.socketFd, .SendFd) {          // what our polling event mask will be.
            eventMask = eventMask | polloutMask                                 //
        }                                                                       //

        var pfd = nn_pollfd(fd: self.socketFd, events: eventMask, revents: 0)   // define the pollfd struct for this socket

        let returnCode = nn_poll(&pfd, 1, CInt(milliseconds))                   // poll the nano socket

        guard (returnCode >= 0) else {
            throw NanoMessageError.PollSocket(code: nn_errno())
        }

        let messageIsWaiting = ((pfd.revents & pollinMask) != 0) ? true : false // using the event masks determine our return values
        let sendIsBlocked = ((pfd.revents & polloutMask) != 0) ? true : false   //

        return (messageIsWaiting, sendIsBlocked)
    }

/// Starts a device to bind the socket to another and forward messages between two sockets
///
/// - Parameters:
///   - nanoSocket: The socket to bind too.
///
/// - Throws: `NanoMessageError.BindToSocket` if a problem has been encountered.
    public func bindToSocket(_ nanoSocket: NanoSocket) throws {
        let returnCode = nn_device(self.socketFd, nanoSocket.socketFd)

        guard (returnCode >= 0) else {
            throw NanoMessageError.BindToSocket(code: nn_errno())
        }
    }

/// Starts a 'loopback' on the socket, it loops and sends any messages received from the socket back to itself.
///
/// - Throws: `NanoMessageError.BindToSocket` if a problem has been encountered.
    public func loopBack() throws {
        let returnCode = nn_device(self.socketFd, -1)

        guard (returnCode >= 0) else {
            throw NanoMessageError.LoopBack(code: nn_errno())
        }
    }
}

extension NanoSocket {
/// Get the domain of the socket as it was created with.
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///
/// - Returns: The sockets domain.
    public func getSocketDomain() throws -> SocketDomain {
        return SocketDomain(rawValue: try getSocketOption(self.socketFd, .Domain))!
    }

/// Get the protocol of the socket as it was created with.
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///
/// - Returns: The sockets protocol.
    public func getSocketProtocol() throws -> SocketProtocol {
        return SocketProtocol(rawValue: try getSocketOption(self.socketFd, .Protocol))!
    }

/// Get the protocol family of the socket as it was created with.
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///
/// - Returns: The sockets protocol family.
    public func getSocketProtocolFamily() throws -> ProtocolFamily {
        return ProtocolFamily(rawValue: try self.getSocketProtocol())
    }

/// Specifies how long the socket should try to send pending outbound messages after the socket
/// has been de-referenced, in milliseconds. A Negative value means infinite linger.
///
/// Default value is 1000 milliseconds (1 second).
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///
/// - Returns: The linger time on the socket.
///
/// - Note:    The nanomsg library no longer supports setting the linger option, linger time will
///            therefore always it's default value.
    public func getLinger() throws -> Int {
        return try getSocketOption(self.socketFd, .Linger)
    }

/// Specifies how long the socket should try to send pending outbound messages after the socket
/// has been de-referenced, in milliseconds. A Negative value means infinite linger.
///
/// - Parameters:
///   - milliseconds: The linger time in milliseconds.
///
/// - Throws: `NanoMessageError.SetSocketOption`
///
/// - Note:   The nanomsg library no longer supports this feature, linger time is always it's default value.
    @available(*, unavailable, message: "nanomsg library no longer supports this feature")
    public func setLinger(milliseconds: Int) throws {
        try setSocketOption(self.socketFd, .Linger, milliseconds)
    }

/// For connection-based transports such as TCP, this specifies how long to wait, in milliseconds,
/// when connection is broken before trying to re-establish it. Note that actual reconnect interval
/// may be randomised to some extent to prevent severe reconnection storms.
///
/// Default value is 100 milliseconds (0.1 second).
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///
/// - Returns: The sockets reconnect interval.
    public func getReconnectInterval() throws -> UInt {
        return try getSocketOption(self.socketFd, .ReconnectInterval)
    }

/// For connection-based transports such as TCP, this specifies how long to wait, in milliseconds,
/// when connection is broken before trying to re-establish it. Note that actual reconnect interval
/// may be randomised to some extent to prevent severe reconnection storms.
///
/// - Parameters:
///   - milliseconds: The reconnection interval in milliseconds.
///
/// - Throws:  `NanoMessageError.SetSocketOption`
    public func setReconnectInterval(milliseconds: UInt) throws {
        try setSocketOption(self.socketFd, .ReconnectInterval, milliseconds)
    }

/// This is to be used only in addition to `set/getReconnectInterval()`. It specifies maximum reconnection
/// interval. On each reconnect attempt, the previous interval is doubled until `getReconnectIntervalMax()`
/// is reached. Value of zero means that no exponential backoff is performed and reconnect interval is based
/// only on `getReconnectInterval()`.
/// If `getReconnectIntervalMax()` is less than `getReconnectInterval()`, it is ignored.
///
/// Default value is 0 milliseconds (0 seconds).
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///
/// - Returns: The sockets reconnect maximum interval.
    public func getReconnectIntervalMaximum() throws -> UInt {
        return try getSocketOption(self.socketFd, .ReconnectIntervalMaximum)
    }

/// This is to be used only in addition to `set/getReconnectInterval()`. It specifies maximum reconnection
/// interval. On each reconnect attempt, the previous interval is doubled until `getReconnectIntervalMax()`
/// is reached. Value of zero means that no exponential backoff is performed and reconnect interval is based
/// only on `getReconnectInterval()`.
/// If `getReconnectIntervalMax()` is less than `getReconnectInterval()`, it is ignored.
///
/// - Parameters:
///   - milliseconds: The reconnection maximum interval in milliseconds.
///
/// - Throws:  `NanoMessageError.SetSocketOption`
    public func setReconnectIntervalMaximum(milliseconds: UInt) throws {
        try setSocketOption(self.socketFd, .ReconnectIntervalMaximum, milliseconds)
    }

/// Socket name for error reporting and statistics.
///
/// Default value is "N" where N is socket file descriptor.
///
/// - Throws:  `NanoMessageError.GetSocketOption`
///
/// - Returns: The sockets name.
///
/// - Note:    This feature is deamed as experimental by the nanomsg library.
    public func getSocketName() throws -> String {
        return try getSocketOption(self.socketFd, .SocketName)
    }

/// Socket name for error reporting and statistics.
///
/// - Parameters:
///   - socketName: Name of the socket.
///
/// - Throws:  `NanoMessageError.SetSocketOption`
///
/// - Note:    This feature is deamed as experimental by the nanomsg library.
    public func setSocketName(_ socketName: String) throws {
        try setSocketOption(self.socketFd, .SocketName, socketName)
    }

/// If true, only IPv4 addresses are used. If false, both IPv4 and IPv6 addresses are used.
///
/// Default value is true.
///
/// - Returns: The IP4v4/Ipv6 type.
///
/// - Throws:  `NanoMessageError.GetSocketOption`
    public func getIPv4Only() throws -> Bool {
        return try getSocketOption(self.socketFd, .IPv4Only)
    }

/// If true, only IPv4 addresses are used. If false, both IPv4 and IPv6 addresses are used.
///
/// - Parameters:
///   - ip4Only: Use IPv4 or IPv4 and IPv6.
///
/// - Throws:  `NanoMessageError.SetSocketOption`
    public func setIPv4Only(_ ip4Only: Bool) throws {
        try setSocketOption(self.socketFd, .IPv4Only, ip4Only)
    }

/// The maximum number of "hops" a message can go through before it is dropped. Each time the
/// message is received (for example via the `bindToSocket()` function) counts as a single hop.
/// This provides a form of protection against inadvertent loops.
///
/// - Returns: The number of hops before a message is dropped.
///
/// - Throws:  `NanoMessageError.GetSocketOption`
    public func getMaxTTL() throws -> Int {
        return try getSocketOption(self.socketFd, .MaxTTL)
    }

/// The maximum number of "hops" a message can go through before it is dropped. Each time the
/// message is received (for example via the `bindToSocket()` function) counts as a single hop.
/// This provides a form of protection against inadvertent loops.
///
/// - Parameters:
///   - hops: The number of hops before a message is dropped.
///
/// - Throws:  `NanoMessageError.SetSocketOption`
    public func setMaxTTL(hops: Int) throws {
        try setSocketOption(self.socketFd, .MaxTTL, hops)
    }

/// When true, disables Nagle’s algorithm. It also disables delaying of TCP acknowledgments.
/// Using this option improves latency at the expense of throughput.
///
/// Default value is false.
///
/// - Returns: Is Nagele's algorithm enabled.
///
/// - Throws:  `NanoMessageError.GetSocketOption`
    public func getTCPNoDelay(transportMechanism: TransportMechanism = .TCP) throws -> Bool {
        let valueReturned: CInt = try getSocketOption(self.socketFd, .TCPNoDelay, transportMechanism)

        return (valueReturned == NN_TCP_NODELAY) ? true : false
    }

/// When true, disables Nagle’s algorithm. It also disables delaying of TCP acknowledgments.
/// Using this option improves latency at the expense of throughput.
///
/// - Parameters:
///   - disableNagles: Disable or enable Nagle's algorithm.
///
/// - Throws:  `NanoMessageError.SetSocketOption`
    public func setTCPNoDelay(disableNagles: Bool, transportMechanism: TransportMechanism = .TCP) throws {
        let valueToSet: CInt = (disableNagles) ? NN_TCP_NODELAY : 0

        try setSocketOption(self.socketFd, .TCPNoDelay, valueToSet, transportMechanism)
    }

/// This value determines whether data messages are sent as WebSocket text frames, or binary frames,
/// per RFC 6455. Text frames should contain only valid UTF-8 text in their payload, or they will be
/// rejected. Binary frames may contain any data. Not all WebSocket implementations support binary frames.
///
/// The default is to send binary frames.
///
/// - Returns: The web sockets message type.
///
/// - Throws:  `NanoMessageError.GetSocketOption`
    public func getWebSocketMessageType() throws -> WebSocketMessageType {
        return WebSocketMessageType(rawValue: try getSocketOption(self.socketFd, .WebSocketMessageType, .WebSocket))
    }

/// This value determines whether data messages are sent as WebSocket text frames, or binary frames,
/// per RFC 6455. Text frames should contain only valid UTF-8 text in their payload, or they will be
/// rejected. Binary frames may contain any data. Not all WebSocket implementations support binary frames.
///
/// - Parameters:
///   - type: Define the web socket message type.
///
/// - Throws:  `NanoMessageError.SetSocketOption`
    public func setWebSocketMessageType(_ type: WebSocketMessageType) throws {
        try setSocketOption(self.socketFd, .WebSocketMessageType, type, .WebSocket)
    }
}

extension NanoSocket {
/// The number of connections successfully established that were initiated from this socket.
///
/// - Returns: As per description.
///
/// - Throws:  `NanoMessageError.GetSocketStatistic`
    public func getEstablishedConnections() throws -> UInt64 {
        return try getSocketStatistic(self.socketFd, .EstablishedConnections)
    }

/// The number of connections successfully established that were accepted by this socket.
///
/// - Returns: As per description.
///
/// - Throws:  `NanoMessageError.GetSocketStatistic`
    public func getAcceptedConnections() throws -> UInt64 {
        return try getSocketStatistic(self.socketFd, .AcceptedConnections)
    }

/// The number of established connections that were dropped by this socket.
///
/// - Returns: As per description.
///
/// - Throws:  `NanoMessageError.GetSocketStatistic`
    public func getDroppedConnections() throws -> UInt64 {
        return try getSocketStatistic(self.socketFd, .DroppedConnections)
    }

/// The number of established connections that were closed by this socket, typically due to protocol errors.
///
/// - Returns: As per description.
///
/// - Throws:  `NanoMessageError.GetSocketStatistic`
    public func getBrokenConnections() throws -> UInt64 {
        return try getSocketStatistic(self.socketFd, .BrokenConnections)
    }

/// The number of errors encountered by this socket trying to connect to a remote peer.
///
/// - Returns: As per description.
///
/// - Throws:  `NanoMessageError.GetSocketStatistic`
    public func getConnectErrors() throws -> UInt64 {
        return try getSocketStatistic(self.socketFd, .ConnectErrors)
    }

/// The number of errors encountered by this socket trying to bind to a local address.
///
/// - Returns: As per description.
///
/// - Throws:  `NanoMessageError.GetSocketStatistic`
    public func getBindErrors() throws -> UInt64 {
        return try getSocketStatistic(self.socketFd, .BindErrors)
    }

/// The number of errors encountered by this socket trying to accept a a connection from a remote peer.
///
/// - Returns: As per description.
///
/// - Throws:  `NanoMessageError.GetSocketStatistic`
    public func getAcceptErrors() throws -> UInt64 {
        return try getSocketStatistic(self.socketFd, .AcceptErrors)
    }

/// The number of connections currently estabalished to this socket.
///
/// - Returns: As per description.
///
/// - Throws:  `NanoMessageError.GetSocketStatistic`
    public func getCurrentConnections() throws -> UInt64 {
        return try getSocketStatistic(self.socketFd, .CurrentConnections)
    }
}
