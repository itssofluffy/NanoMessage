/*
    NanoSocketProtocol.swift

    Copyright (c) 2017 Stephen Whittle  All rights reserved.

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
import Dispatch
import Mutex

/// A NanoMessage base socket.
public protocol NanoSocketProtocol {
    /// The raw nanomsg socket file descriptor.
    var fileDescriptor: CInt { get }
    /// The domain of the socket as it was created with.
    var domain: SocketDomain { get }
    /// The protocol of the socket as it was created with.
    var `protocol`: SocketProtocol { get }
    /// The protocol family of the socket as it was created with.
    var protocolFamily: ProtocolFamily { get }
    /// Is the socket capable of receiving.
    var receiver: Bool { get }
    /// Is the socket capable of sending.
    var sender: Bool { get }
    /// A set of `EndPoint` structures that the socket is attached to either locally or remotly.
    var endPoints: Set<EndPoint> { get }

    var closeAttempts: Int { get set }
    /// Determine if when de-referencing the socket we are going to keep attempting to close the socket until successful.
    ///
    /// - Warning: Please not that if true this will block until the class has been de-referenced.
    var blockTillCloseSuccess: Bool { get set }
    /// Is the socket attached to a device.
    var isDevice: Bool { get }
    /// The dispatch queue that async send/receive messages are run on.
    var aioQueue: DispatchQueue { get set }
    /// The async dispatch queue's group.
    var aioGroup: DispatchGroup { get set }
    /// async mutex lock.
    var mutex: Mutex { get }

    /// Adds a local or remote endpoint to the socket. The library would then try to bind or connect to the specified endpoint.
    ///
    /// - Parameters:
    ///   - url:  Consists of two parts as follows: transport://address. The transport specifies the underlying
    ///           transport protocol to use. The meaning of the address part is specific to the underlying transport protocol.
    ///   - type: The connection type used to establish the endpoint.
    ///   - name: An optional endpoint name.
    ///
    /// - Throws:  `NanoMessageError.BindToURL` if there was a problem connecting the socket to the url.
    ///            `NanoMessageError.ConnectToURL` if there was a problem binding the socket to the url.
    ///            `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: An endpoint ID is returned. The endpoint ID can be later used to remove the endpoint from the
    ///            socket via the `removeEndPoint()` function.
    ///
    /// - Note:    Note that `createEndPoint()` may be called multiple times on the same socket thus allowing the
    ///            socket to communicate with multiple heterogeneous endpoints.
    func createEndPoint(url: URL, type: ConnectionType, name: String) throws -> EndPoint

    /// Adds a local or remote endpoint to the socket. The library would then try to bind or connect to the specified endpoint.
    ///
    /// - Parameters:
    ///   - url:  Consists of two parts as follows: transport://address. The transport specifies the underlying
    ///           transport protocol to use. The meaning of the address part is specific to the underlying transport protocol.
    ///   - type: The connection type used to establish the endpoint.
    ///   - name: An optional endpoint name.
    ///
    /// - Throws:  `NanoMessageError.BindToURL` if there was a problem connecting the socket to the url.
    ///            `NanoMessageError.ConnectToURL` if there was a problem binding the socket to the url.
    ///            `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: An endpoint ID is returned. The endpoint ID can be later used to remove the endpoint from the
    ///            socket via the `removeEndPoint()` function.
    ///
    /// - Note:    Note that `createEndPoint()` may be called multiple times on the same socket thus allowing the
    ///            socket to communicate with multiple heterogeneous endpoints.
    func createEndPoint(url: URL, type: ConnectionType, name: String) throws -> Int

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
    func removeEndPoint(_ endPoint: EndPoint) throws -> Bool

    /// Remove an endpoint from the socket.
    ///
    /// - Parameters:
    ///   - endPoint: An endpoint id.
    ///
    /// - Throws: `NanoMessageError.RemoveEndPoint` if the endpoint failed to be removed,
    ///           `NanoMessageError.Interrupted` if the endpoint removal was interrupted.
    ///
    /// - Returns: If the endpoint was removed, false indicates that the endpoint was not attached to the socket.
    @discardableResult
    func removeEndPoint(_ endPointId: Int) throws -> Bool

    /// Remove an endpoint from the socket.
    ///
    /// - Parameters:
    ///   - endPoint: An endpoint url.
    ///
    /// - Throws: `NanoMessageError.RemoveEndPoint` if the endpoint failed to be removed,
    ///           `NanoMessageError.Interrupted` if the endpoint removal was interrupted.
    ///
    /// - Returns: If the endpoint was removed, false indicates that the endpoint was not attached to the socket.
    @discardableResult
    func removeEndPoint(_ endPointURL: URL) throws -> Bool

    /// Check socket and reports whether it’s possible to send a message to the socket and/or receive a message from the socket.
    ///
    /// - Parameters:
    ///   - timeout : The maximum number of milliseconds to poll the socket for an event to occur,
    ///               default is 1000 milliseconds (1 second).
    ///
    /// - Throws: `NanoMessageError.SocketIsADevice`
    ///           `NanoMessageError.PollSocket` if polling the socket fails.
    ///
    /// - Returns: Message waiting and send queue blocked as a tuple of bools.
    func pollSocket(timeout: TimeInterval) throws -> PollResult

    /// Starts a device to bind the socket to another and forward messages between two sockets
    ///
    /// - Parameters:
    ///   - nanoSocket: The socket to bind too.
    ///
    /// - Throws: `NanoMessageError.SocketIsADevice`
    ///           `NanoMessageError.NoEndPoint`
    ///           `NanoMessageError.BindToSocket` if a problem has been encountered.
    func bindToSocket(_ nanoSocket: NanoSocket) throws

    /// Starts a device asynchronously to bind the socket to another and forward messages between the two sockets.
    ///
    /// - Parameters:
    ///   - nanoSocket: The socket to bind too.
    ///   - queue:      The dispatch queue to use
    ///   - group:      The dispatch group to use.
    func bindToSocket(_ nanoSocket: NanoSocket, queue: DispatchQueue, group: DispatchGroup)

    /// Starts a 'loopback' on the socket, it loops and sends any messages received from the socket back to itself.
    ///
    /// - Throws: `NanoMessageError.SocketIsADevice`
    ///           `NanoMessageError.NoEndPoint`
    ///           `NanoMessageError.LoopBack` if a problem has been encountered.
    func loopBack() throws

    /// Starts a 'loopback' on the socket asynchronously, it loops and sends any messages received from the socket back to itself.
    ///
    /// - Parameters:
    ///   - queue:   The dispatch queue to use
    ///   - group:   The dispatch group to use.
    func loopBack(queue: DispatchQueue, group: DispatchGroup)

    /// Specifies how long the socket should try to send pending outbound messages after the socket
    /// has been de-referenced, in milliseconds. A Negative value means infinite linger.
    ///
    /// Default value is 1000 milliseconds (1 second).
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The linger time on the socket.
    ///
    /// - Note:    The underlying nanomsg library no longer supports setting the linger option,
    ///            linger time will therefore always it's default value.
    func getLinger() throws -> TimeInterval

    /// For connection-based transports such as TCP, this specifies how long to wait, in milliseconds,
    /// when connection is broken before trying to re-establish it. Note that actual reconnect interval
    /// may be randomised to some extent to prevent severe reconnection storms.
    ///
    /// Default value is 100 milliseconds (0.1 second).
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets reconnect interval.
    func getReconnectInterval() throws -> TimeInterval

    /// For connection-based transports such as TCP, this specifies how long to wait, in milliseconds,
    /// when connection is broken before trying to re-establish it. Note that actual reconnect interval
    /// may be randomised to some extent to prevent severe reconnection storms.
    ///
    /// - Parameters:
    ///   - seconds: The reconnection interval in timeinterval.
    ///
    /// - Throws: `NanoMessageError.GetSocketOption`
    ///           `NanoMessageError.SetSocketOption`
    ///
    /// - Returns: The sockets reconnect interval before being set.
    @discardableResult
    func setReconnectInterval(seconds: TimeInterval) throws -> TimeInterval

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
    func getReconnectIntervalMaximum() throws -> TimeInterval

    /// This is to be used only in addition to `set/getReconnectInterval()`. It specifies maximum reconnection
    /// interval. On each reconnect attempt, the previous interval is doubled until `getReconnectIntervalMax()`
    /// is reached. Value of zero means that no exponential backoff is performed and reconnect interval is based
    /// only on `getReconnectInterval()`.
    /// If `getReconnectIntervalMax()` is less than `getReconnectInterval()`, it is ignored.
    ///
    /// - Parameters:
    ///   - seconds: The reconnection maximum interval in timeinterval.
    ///
    /// - Throws: `NanoMessageError.GetSocketOption`
    ///           `NanoMessageError.SetSocketOption`
    ///
    /// - Returns: The sockets reconnect maximum interval before being set.
    @discardableResult
    func setReconnectIntervalMaximum(seconds: TimeInterval) throws -> TimeInterval

    /// Socket name for error reporting and statistics.
    ///
    /// Default value is "N" where N is socket file descriptor.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets name.
    ///
    /// - Note:    This feature is deamed as experimental by the underlying nanomsg library.
    func getSocketName() throws -> String

    /// Socket name for error reporting and statistics.
    ///
    /// - Parameters:
    ///   - socketName: Name of the socket.
    ///
    /// - Throws: `NanoMessageError.GetSocketOption`
    ///           `NanoMessageError.SetSocketOption`
    ///
    /// - Returns: The sockets name before being set.
    ///
    /// - Note:    This feature is deamed as experimental by the underlying nanomsg library.
    @discardableResult
    func setSocketName(_ socketName: String) throws -> String

    /// If true, only IPv4 addresses are used. If false, both IPv4 and IPv6 addresses are used.
    ///
    /// Default value is true.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The IP4v4/Ipv6 type.
    func getIPv4Only() throws -> Bool

    /// If true, only IPv4 addresses are used. If false, both IPv4 and IPv6 addresses are used.
    ///
    /// - Parameters:
    ///   - ip4Only: Use IPv4 or IPv4 and IPv6.
    ///
    /// - Throws: `NanoMessageError.GetSocketOption`
    ///           `NanoMessageError.SetSocketOption`
    ///
    /// - Returns: The IP4v4/Ipv6 type before being set.
    @discardableResult
    func setIPv4Only(_ ip4Only: Bool) throws -> Bool

    /// The maximum number of "hops" a message can go through before it is dropped. Each time the
    /// message is received (for example via the `bindToSocket()` function) counts as a single hop.
    /// This provides a form of protection against inadvertent loops.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The number of hops before a message is dropped.
    func getMaximumTTL() throws -> Int

    /// The maximum number of "hops" a message can go through before it is dropped. Each time the
    /// message is received (for example via the `bindToSocket()` function) counts as a single hop.
    /// This provides a form of protection against inadvertent loops.
    ///
    /// - Parameters:
    ///   - hops: The number of hops before a message is dropped.
    ///
    /// - Throws: `NanoMessageError.GetSocketOption`
    ///           `NanoMessageError.SetSocketOption`
    ///
    /// - Returns: The number of hops before a message is dropped before being set.
    @discardableResult
    func setMaximumTTL(hops: Int) throws -> Int

    /// When true, disables Nagle’s algorithm. It also disables delaying of TCP acknowledgments.
    /// Using this option improves latency at the expense of throughput.
    ///
    /// Default value is false.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: Is Nagle's algorithm enabled.
    func getTCPNoDelay(transportMechanism: TransportMechanism) throws -> Bool

    /// When true, disables Nagle’s algorithm. It also disables delaying of TCP acknowledgments.
    /// Using this option improves latency at the expense of throughput.
    ///
    /// - Parameters:
    ///   - disableNagles: Disable or enable Nagle's algorithm.
    ///
    /// - Throws: `NanoMessageError.GetSocketOption`
    ///           `NanoMessageError.SetSocketOption`
    ///
    /// - Returns: Is Nagle's algorithm enabled before being set.
    @discardableResult
    func setTCPNoDelay(disableNagles: Bool, transportMechanism: TransportMechanism) throws -> Bool

    /// This value determines whether data messages are sent as WebSocket text frames, or binary frames,
    /// per RFC 6455. Text frames should contain only valid UTF-8 text in their payload, or they will be
    /// rejected. Binary frames may contain any data. Not all WebSocket implementations support binary frames.
    ///
    /// The default is to send binary frames.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The web sockets message type.
    func getWebSocketMessageType() throws -> WebSocketMessageType

    /// This value determines whether data messages are sent as WebSocket text frames, or binary frames,
    /// per RFC 6455. Text frames should contain only valid UTF-8 text in their payload, or they will be
    /// rejected. Binary frames may contain any data. Not all WebSocket implementations support binary frames.
    ///
    /// - Parameters:
    ///   - type: Define the web socket message type.
    ///
    /// - Throws: `NanoMessageError.GetSocketOption`
    ///           `NanoMessageError.SetSocketOption`
    ///
    /// - Returns: The web sockets message type before being set.
    @discardableResult
    func setWebSocketMessageType(_ type: WebSocketMessageType) throws -> WebSocketMessageType

    /// The number of connections successfully established that were initiated from this socket.
    /// - Note: This feature is undocumented in the underlying nanomsg library
    var establishedConnections: UInt64? { get }

    /// The number of connections successfully established that were accepted by this socket.
    /// - Note: This feature is undocumented in the underlying nanomsg library
    var acceptedConnections: UInt64? { get }

    /// The number of established connections that were dropped by this socket.
    /// - Note: This feature is undocumented in the underlying nanomsg library
    var droppedConnections: UInt64? { get }

    /// The number of established connections that were closed by this socket, typically due to protocol errors.
    /// - Note: This feature is undocumented in the underlying nanomsg library
    var brokenConnections: UInt64? { get }

    /// The number of errors encountered by this socket trying to connect to a remote peer.
    /// - Note: This feature is undocumented in the underlying nanomsg library
    var connectErrors: UInt64? { get }

    /// The number of errors encountered by this socket trying to bind to a local address.
    /// - Note: This feature is undocumented in the underlying nanomsg library
    var bindErrors: UInt64? { get }

    /// The number of errors encountered by this socket trying to accept a a connection from a remote peer.
    /// - Note: This feature is undocumented in the underlying nanomsg library
    var acceptErrors: UInt64? { get }

    /// The number of connections currently in progress to this socket.
    /// - Note: This feature is undocumented in the underlying nanomsg library
    var currentInProgressConnections: UInt64? { get }

    /// The number of connections currently estabalished to this socket.
    /// - Note: This feature is undocumented in the underlying nanomsg library
    var currentConnections: UInt64? { get }

    /// The number of end-point errors.
    /// - Note: This feature is undocumented in the underlying nanomsg library
    var currentEndPointErrors: UInt64? { get }
}
