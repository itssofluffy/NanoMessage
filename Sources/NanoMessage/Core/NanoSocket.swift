/*
    NanoSocket.swift

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

import Foundation
import CNanoMessage
import ISFLibrary
import C7
import Dispatch
import Mutex

/// A NanoMessage base socket.
public class NanoSocket {
    @available(*, unavailable, renamed: "fileDescriptor")
    public let socketFd: CInt = -1
    /// The raw nanomsg socket file descriptor.
    public let fileDescriptor: CInt
    /// Is the socket capable of receiving.
    public let receiverSocket: Bool
    /// Is the socket capable of sending.
    public let senderSocket: Bool
    /// A set of `EndPoint` structures that the socket is attached to either locally or remotly.
    public fileprivate(set) var endPoints = Set<EndPoint>()

    private var _closeAttempts: Int = 20
    /// The number of attempts to close down a socket or endpoint, this is clamped to between 1 and 1000.
    ///
    /// - Note:  The `getLinger()` function is called to determine the number of milliseconds to
    ///          wait for a socket/endpoint to clear and close, this is divided by `closeAttempts`
    ///          to determine the minimum pause between each attempt.
    public var closeAttempts: Int {
        get {
            return self._closeAttempts
        }
        set (attempts) {
            self._closeAttempts = clamp(value: attempts, lower: 1, upper: 1000)
        }
    }
    /// The socket/end-point close time in timeinterval.
    fileprivate var _closeDelay: TimeInterval {
        var delay = TimeInterval(milliseconds: 1000)

        if let linger = try? self.getLinger() {
            if (linger > 0) {                               // account for infinate linger timeout.
                delay = linger
            }
        }

        return TimeInterval(milliseconds: delay.milliseconds / self.closeAttempts)
    }
    /// Determine if when de-referencing the socket we are going to keep attempting to close the socket until successful.
    ///
    /// - Warning: Please not that if true this will block until the class has been de-referenced.
    public var blockTillCloseSuccess = false
    /// Is the socket attached to a device.
    public fileprivate(set) var socketIsADevice = false
    /// The dispatch queue that async send/receive messages are run on.
    public var aioQueue = DispatchQueue(label: "com.nanomessage.aioqueue", qos: .userInitiated)
    /// The async dispatch queue's group.
    public var aioGroup = DispatchGroup()
    /// async mutex lock.
    internal var mutex: Mutex

    /// Creates a nanomsg socket with the specified socketDomain and socketProtocol.
    ///
    /// - Parameters:
    ///   - socketDomain:   The sockets Domain.
    ///   - socketProtocol: The sockets Protocol.
    ///
    /// - Throws: `MutexError.MutexInit`
    ///           `NanoMessageError.NanoSocket` if the nanomsg socket has failed to be created
    public init(socketDomain: SocketDomain, socketProtocol: SocketProtocol) throws {
        try self.mutex = Mutex()

        self.fileDescriptor = nn_socket(socketDomain.rawValue, socketProtocol.rawValue)

        guard (self.fileDescriptor >= 0) else {
            throw NanoMessageError.NanoSocket(code: nn_errno())
        }

        // rely on the fact that getting the receive/send file descriptor for a socket type from
        // the underlying library that does not support receive/send will throw a nil to determine
        // if the socket is capable of receiving or ending.
        if let _ = try? getSocketOption(self.fileDescriptor, .ReceiveFileDescriptor) {
            self.receiverSocket = true
        } else {
            self.receiverSocket = false
        }

        if let _ = try? getSocketOption(self.fileDescriptor, .SendFileDescriptor) {
            self.senderSocket = true
        } else {
            self.senderSocket = false
        }
    }

    deinit {
        func _closeSocket() throws {
            if (self.fileDescriptor >= 0) {                             // if we have a valid nanomsg socket file descriptor then...
                var loopCount = 0

                while (true) {
                    let returnCode = nn_close(self.fileDescriptor)      // try and close the nanomsg socket

                    if (returnCode < 0) {                               // if `nn_close()` failed then...
                        let errno = nn_errno()

                        if (errno == EINTR) {                           // if we were interrupted by a signal, reattempt is allowed by the native library
                            if (loopCount >= self.closeAttempts) {      // we've reached our limit so say we were interrupted
                                throw NanoMessageError.Interrupted
                            }
                        } else {
                            throw NanoMessageError.Close(code: errno)
                        }

                        usleep(self._closeDelay)                        // zzzz...

                        loopCount += 1
                    } else {
                        break                                           // we've closed the socket succesfully
                    }
                }
            }
        }

        // are we going to terminate the `repeat` loop below.
        var terminateLoop = true

        repeat {
            do {
                try _closeSocket()
            } catch NanoMessageError.Interrupted {
                let dynamicType = type(of: self)

                print("\(dynamicType).\(#function) failed: \(NanoMessageError.Interrupted))", to: &errorStream)

                if (self.blockTillCloseSuccess) {
                    terminateLoop = false
                }
            } catch let error as NanoMessageError {
                print(error, to: &errorStream)
                terminateLoop = true
            } catch {
                print("an unexpected error '\(error)' has occured in the library libNanoMessage.", to: &errorStream)
                terminateLoop = true
            }
        } while (!terminateLoop)
    }
}

extension NanoSocket {
    /// Establish an endpoint on the socket.
    ///
    /// - Parameters:
    ///   - url:                Consists of two parts as follows: transport://address. The transport specifies the
    ///                         underlying transport protocol to use. The meaning of the address part is specific
    ///                         to the underlying transport protocol.
    ///   - name:               An optional endpoint name.
    ///   - type:               The connection type used to establish the endpoint.
    ///   - establishEndPoint:  Closure used to establish the endpoint.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: An endpoint that has just been established. The endpoint can be later used to remove the
    ///            endpoint from the socket via `removeEndPoint()` function.
    private func _establishEndPoint(url: URL, name: String, type: ConnectionType, _ establishEndPoint: (UnsafePointer<Int8>) throws -> CInt) rethrows -> EndPoint {
        return try url.absoluteString.withCString { address in
            var receivePriority: Priority?
            var sendPriority: Priority?

            if (self.receiverSocket) {                                         // if this is a receiver socket then...
                receivePriority = try getSocketOption(self, .ReceivePriority)  // obtain the receive priority for the end-point.
            }
            if (self.senderSocket) {                                           // if this is a sender socket then...
                sendPriority = try getSocketOption(self, .SendPriority)        // obtain the send priority for the end-point.
            }

            let ipv4Only = try self.getIPv4Only()

            let endPointId = try establishEndPoint(address)

            let endPoint = EndPoint(id:         Int(endPointId),
                                    url:        url,
                                    type:       type,
                                    priorities: SocketPriorities(receivePriority: receivePriority, sendPriority: sendPriority),
                                    ipv4Only:   ipv4Only,
                                    name:       name)

            self.endPoints.insert(endPoint)

            return endPoint
        }
    }

    /// Adds a local endpoint to the socket. The endpoint can be then used by other applications to connect to.
    ///
    /// - Parameters:
    ///   - url:  Consists of two parts as follows: transport://address. The transport specifies the underlying
    ///           transport protocol to use. The meaning of the address part is specific to the underlying transport protocol.
    ///   - name: An optional endpoint name.
    ///
    /// - Throws:  `NanoMessageError.BindToURL` if there was a problem binding the socket to the address.
    ///            `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: An endpoint that has just been binded too. The endpoint can be later used to remove the
    ///            endpoint from the socket via `removeEndPoint()` function.
    ///
    /// - Note:    Note that `bindToURL()` may be called multiple times on the same socket thus allowing the
    ///            socket to communicate with multiple heterogeneous endpoints.
    public func bindToURL(_ url: URL, name: String = "") throws -> EndPoint {
        return try self._establishEndPoint(url: url, name: name, type: .Bind, { address in
            let endPointId = nn_bind(self.fileDescriptor, address)

            guard (endPointId >= 0) else {
                throw NanoMessageError.BindToURL(code: nn_errno(), url: url)
            }

            return endPointId
        })
    }

    /// Adds a local endpoint to the socket. The endpoint can be then used by other applications to connect to.
    ///
    /// - Parameters:
    ///   - url:  Consists of two parts as follows: transport://address. The transport specifies the underlying
    ///           transport protocol to use. The meaning of the address part is specific to the underlying transport protocol.
    ///   - name: An optional endpoint name.
    ///
    /// - Throws:  `NanoMessageError.BindToURL` if there was a problem binding the socket to the address.
    ///            `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: An endpoint ID is returned. The endpoint ID can be later used to remove the endpoint from
    ///            the socket via `removeEndPoint()` function.
    ///
    /// - Note:    Note that `bindToURL()` may be called multiple times on the same socket thus allowing the
    ///            socket to communicate with multiple heterogeneous endpoints.
    public func bindToURL(_ url: URL, name: String = "") throws -> Int {
        let endPoint: EndPoint = try self.bindToURL(url, name: name)

        return endPoint.id
    }

    /// Adds a remote endpoint to the socket. The library would then try to connect to the specified remote endpoint.
    ///
    /// - Parameters:
    ///   - url:  Consists of two parts as follows: transport://address. The transport specifies the underlying
    ///           transport protocol to use. The meaning of the address part is specific to the underlying transport protocol.
    ///   - name: An optional endpoint name.
    ///
    /// - Throws:  `NanoMessageError.ConnectToURL` if there was a problem binding the socket to the address.
    ///            `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The endpoint that has just been connected too. The endpoint can be later used to remove the
    ///            endpoint from the socket via `removeEndPoint()` function.
    ///
    /// - Note:    Note that `connectToURL()` may be called multiple times on the same socket thus allowing the
    ///            socket to communicate with multiple heterogeneous endpoints.
    public func connectToURL(_ url: URL, name: String = "") throws -> EndPoint {
        return try self._establishEndPoint(url: url, name: name, type: .Connect, { address in
            let endPointId = nn_connect(self.fileDescriptor, address)

            guard (endPointId >= 0) else {
                throw NanoMessageError.ConnectToURL(code: nn_errno(), url: url)
            }

            return endPointId
        })
    }

    /// Adds a remote endpoint to the socket. The library would then try to connect to the specified remote endpoint.
    ///
    /// - Parameters:
    ///   - url:  Consists of two parts as follows: transport://address. The transport specifies the underlying
    ///           transport protocol to use. The meaning of the address part is specific to the underlying transport protocol.
    ///   - name: An optional endpoint name.
    ///
    /// - Throws:  `NanoMessageError.ConnectToURL` if there was a problem binding the socket to the address.
    ///            `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: An endpoint ID is returned. The endpoint ID can be later used to remove the endpoint from the
    ///            socket via the `removeEndPoint()` function.
    ///
    /// - Note:    Note that `connectToURL()` may be called multiple times on the same socket thus allowing the
    ///            socket to communicate with multiple heterogeneous endpoints.
    public func connectToURL(_ url: URL, name: String = "") throws -> Int {
        let endPoint: EndPoint = try self.connectToURL(url, name: name)

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
            var loopCount = 0

            while (true) {
                let returnCode = nn_shutdown(self.fileDescriptor, CInt(endPoint.id))  // attempt to close down the endpoint

                if (returnCode < 0) {                                                 // if `nn_shutdown()` failed then...
                    let errno = nn_errno()

                    if (errno == EINTR) {                                             // if we were interrupted by a signal, reattempt is allowed by the native library
                        if (loopCount >= self.closeAttempts) {
                            throw NanoMessageError.Interrupted
                        }

                        usleep(self._closeDelay)                                      // zzzz...

                        loopCount += 1
                    } else {
                        throw NanoMessageError.RemoveEndPoint(code: errno, url: endPoint.url, endPointId: endPoint.id)
                    }
                } else {
                    break                                                             // we've closed the endpoint succesfully
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
    ///   - endPoint: An endpoint id.
    ///
    /// - Throws: `NanoMessageError.RemoveEndPoint` if the endpoint failed to be removed,
    ///           `NanoMessageError.Interrupted` if the endpoint removal was interrupted.
    ///
    /// - Returns: If the endpoint was removed, false indicates that the endpoint was not attached to the socket.
    @discardableResult
    public func removeEndPoint(_ endPointId: Int) throws -> Bool {
        if let endPoint = self.endPoints.first(where: { $0.id == endPointId }) {
            return try self.removeEndPoint(endPoint)            // access the first occurance as end-point.id is/should be unique!?
        }

        return false
    }

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
    public func removeEndPoint(_ endPointURL: URL) throws -> Bool {
        if let endPoint = self.endPoints.first(where: { $0.url.absoluteString == endPointURL.absoluteString }) {
            return try self.removeEndPoint(endPoint)            // access the first occurance as end-point.url is/should be unique!?
        }

        return false
    }

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
    public func pollSocket(timeout: TimeInterval = TimeInterval(seconds: 1)) throws -> PollResult {
        let pollResults = try poll(sockets: [self], timeout: timeout)

        return pollResults[0]
    }

    /// Starts a device to bind the socket to another and forward messages between two sockets
    ///
    /// - Parameters:
    ///   - nanoSocket: The socket to bind too.
    ///
    /// - Throws: `NanoMessageError.SocketIsADevice`
    ///           `NanoMessageError.BindToSocket` if a problem has been encountered.
    public func bindToSocket(_ nanoSocket: NanoSocket) throws {
        guard (!self.socketIsADevice) else {
            throw NanoMessageError.SocketIsADevice(socket: self)
        }

        guard (!nanoSocket.socketIsADevice) else {
            throw NanoMessageError.SocketIsADevice(socket: nanoSocket)
        }

        self.socketIsADevice = true
        nanoSocket.socketIsADevice = true

        defer {
            self.socketIsADevice = false
            nanoSocket.socketIsADevice = false
        }

        let returnCode = nn_device(self.fileDescriptor, nanoSocket.fileDescriptor)

        guard (returnCode >= 0) else {
            let errno = nn_errno()
            var nanoSocketName = String(nanoSocket.fileDescriptor)

            if let socketName = try? nanoSocket.getSocketName() {
                nanoSocketName = socketName
            }

            throw NanoMessageError.BindToSocket(code: errno, nanoSocketName: nanoSocketName)
        }
    }

    /// Starts a device asynchronously to bind the socket to another and forward messages between two sockets
    ///
    /// - Parameters:
    ///   - nanoSocket:     The socket to bind too.
    ///   - queue:          The dispatch queue to use
    ///   - group:          The dispatch group to use.
    ///   - closureHandler: The closure to use when the 'bind' terminates.
    ///
    /// - Returns:          The despatched work item.
    public func bindToSocket(_ nanoSocket: NanoSocket, queue: DispatchQueue, group: DispatchGroup, _ closureHandler: @escaping (Error?) -> Void) -> DispatchWorkItem {
        let workItem = DispatchWorkItem {
            do {
                try self.bindToSocket(nanoSocket)
            } catch {
                closureHandler(error)
            }
        }

        queue.async(group: group, execute: workItem)

        return workItem
    }

    /// Starts a 'loopback' on the socket, it loops and sends any messages received from the socket back to itself.
    ///
    /// - Throws: `NanoMessageError.SocketIsADevice`
    ///           `NanoMessageError.LoopBack` if a problem has been encountered.
    public func loopBack() throws {
        guard (!self.socketIsADevice) else {                                    // guard against socket already being a device socket.
            throw NanoMessageError.SocketIsADevice(socket: self)
        }

        self.socketIsADevice = true

        defer {
            self.socketIsADevice = false
        }

        let returnCode = nn_device(self.fileDescriptor, -1)

        guard (returnCode >= 0) else {
            throw NanoMessageError.LoopBack(code: nn_errno())
        }
    }

    /// Starts a 'loopback' on the socket asynchronously, it loops and sends any messages received from the socket back to itself.
    ///
    /// - Parameters:
    ///   - queue:          The dispatch queue to use
    ///   - group:          The dispatch group to use.
    ///   - closureHandler: The closure to use when the 'loopback' terminates.
    ///
    /// - Returns:          The despatched work item.
    public func loopBack(queue: DispatchQueue, group: DispatchGroup, _ closureHandler: @escaping (Error?) -> Void) -> DispatchWorkItem {
        let workItem = DispatchWorkItem {
            do {
                try self.loopBack()
            } catch {
                closureHandler(error)
            }
        }

        queue.async(group: group, execute: workItem)

        return workItem
    }
}

extension NanoSocket {
    /// Get the domain of the socket as it was created with.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets domain.
    public func getSocketDomain() throws -> SocketDomain {
        return SocketDomain(rawValue: try getSocketOption(self, .Domain))!
    }

    /// Get the protocol of the socket as it was created with.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets protocol.
    public func getSocketProtocol() throws -> SocketProtocol {
        return SocketProtocol(rawValue: try getSocketOption(self, .Protocol))!
    }

    /// Get the protocol family of the socket as it was created with.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets protocol family.
    public func getSocketProtocolFamily() throws -> ProtocolFamily {
        return ProtocolFamily(socketProtocol: try self.getSocketProtocol())
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
    /// - Note:    The underlying nanomsg library no longer supports setting the linger option,
    ///            linger time will therefore always it's default value.
    public func getLinger() throws -> TimeInterval {
        return try getSocketOption(self, .Linger)
    }

    /// Specifies how long the socket should try to send pending outbound messages after the socket
    /// has been de-referenced, in milliseconds. A Negative value means infinite linger.
    ///
    /// - Parameters:
    ///   - seconds: The linger time.
    ///
    /// - Throws: `NanoMessageError.GetSocketOption`
    ///           `NanoMessageError.SetSocketOption`
    ///
    /// - Returns: The linger time on the socket before being set.
    ///
    /// - Note:   The underlying nanomsg library no longer supports this feature, linger time is always it's default value.
    @available(*, unavailable, message: "nanomsg library no longer supports this feature")
    @discardableResult
    public func setLinger(seconds: TimeInterval) throws -> TimeInterval {
        let originalValue = try self.getLinger()

        try setSocketOption(self, .Linger, seconds)

        return originalValue
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
    public func getReconnectInterval() throws -> TimeInterval {
        return try getSocketOption(self, .ReconnectInterval)
    }

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
    public func setReconnectInterval(seconds: TimeInterval) throws -> TimeInterval {
        let originalValue = try self.getReconnectInterval()

        try setSocketOption(self, .ReconnectInterval, seconds)

        return originalValue
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
    public func getReconnectIntervalMaximum() throws -> TimeInterval {
        return try getSocketOption(self, .ReconnectIntervalMaximum)
    }

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
    public func setReconnectIntervalMaximum(seconds: TimeInterval) throws -> TimeInterval {
        let originalValue = try self.getReconnectInterval()

        try setSocketOption(self, .ReconnectIntervalMaximum, seconds)

        return originalValue
    }

    /// Socket name for error reporting and statistics.
    ///
    /// Default value is "N" where N is socket file descriptor.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The sockets name.
    ///
    /// - Note:    This feature is deamed as experimental by the underlying nanomsg library.
    public func getSocketName() throws -> String {
        return try getSocketOption(self, .SocketName)
    }

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
    public func setSocketName(_ socketName: String) throws -> String {
        let originalValue = try self.getSocketName()

        try setSocketOption(self, .SocketName, socketName)

        return originalValue
    }

    /// If true, only IPv4 addresses are used. If false, both IPv4 and IPv6 addresses are used.
    ///
    /// Default value is true.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The IP4v4/Ipv6 type.
    public func getIPv4Only() throws -> Bool {
        return try getSocketOption(self, .IPv4Only)
    }

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
    public func setIPv4Only(_ ip4Only: Bool) throws -> Bool {
        let originalValue = try self.getIPv4Only()

        try setSocketOption(self, .IPv4Only, ip4Only)

        return originalValue
    }

    @available(*, unavailable, renamed: "getMaximumTTL")
    public func getMaxTTL() throws -> Int { fatalError() }
    /// The maximum number of "hops" a message can go through before it is dropped. Each time the
    /// message is received (for example via the `bindToSocket()` function) counts as a single hop.
    /// This provides a form of protection against inadvertent loops.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The number of hops before a message is dropped.
    public func getMaximumTTL() throws -> Int {
        return try getSocketOption(self, .MaximumTTL)
    }

    @available(*, unavailable, renamed: "setMaximumTTL")
    @discardableResult
    public func setMaxTTL(hops: Int) throws -> Int { fatalError() }
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
    public func setMaximumTTL(hops: Int) throws -> Int {
        let originalValue = try self.getMaximumTTL()

        try setSocketOption(self, .MaximumTTL, hops)

        return originalValue
    }

    /// When true, disables Nagle’s algorithm. It also disables delaying of TCP acknowledgments.
    /// Using this option improves latency at the expense of throughput.
    ///
    /// Default value is false.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: Is Nagle's algorithm enabled.
    public func getTCPNoDelay(transportMechanism: TransportMechanism = .TCP) throws -> Bool {
        let valueReturned: CInt = try getSocketOption(self, .TCPNoDelay, transportMechanism)

        return (valueReturned == NN_TCP_NODELAY)
    }

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
    public func setTCPNoDelay(disableNagles: Bool, transportMechanism: TransportMechanism = .TCP) throws -> Bool {
        let originalValue = try self.getTCPNoDelay(transportMechanism: transportMechanism)

        let valueToSet: CInt = (disableNagles) ? NN_TCP_NODELAY : 0

        try setSocketOption(self, .TCPNoDelay, valueToSet, transportMechanism)

        return originalValue
    }

    /// This value determines whether data messages are sent as WebSocket text frames, or binary frames,
    /// per RFC 6455. Text frames should contain only valid UTF-8 text in their payload, or they will be
    /// rejected. Binary frames may contain any data. Not all WebSocket implementations support binary frames.
    ///
    /// The default is to send binary frames.
    ///
    /// - Throws:  `NanoMessageError.GetSocketOption`
    ///
    /// - Returns: The web sockets message type.
    public func getWebSocketMessageType() throws -> WebSocketMessageType {
        return WebSocketMessageType(rawValue: try getSocketOption(self, .WebSocketMessageType, .WebSocket))
    }

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
    public func setWebSocketMessageType(_ type: WebSocketMessageType) throws -> WebSocketMessageType {
        let originalValue = try self.getWebSocketMessageType()

        try setSocketOption(self, .WebSocketMessageType, type, .WebSocket)

        return originalValue
    }
}

extension NanoSocket {
    /// The number of connections successfully established that were initiated from this socket.
    ///
    /// - Throws:  `NanoMessageError.GetSocketStatistic`
    ///
    /// - Returns: As per description.
    public func getEstablishedConnections() throws -> UInt64 {
        return try getSocketStatistic(self, .EstablishedConnections)
    }

    /// The number of connections successfully established that were accepted by this socket.
    ///
    /// - Throws:  `NanoMessageError.GetSocketStatistic`
    ///
    /// - Returns: As per description.
    public func getAcceptedConnections() throws -> UInt64 {
        return try getSocketStatistic(self, .AcceptedConnections)
    }

    /// The number of established connections that were dropped by this socket.
    ///
    /// - Throws:  `NanoMessageError.GetSocketStatistic`
    ///
    /// - Returns: As per description.
    public func getDroppedConnections() throws -> UInt64 {
        return try getSocketStatistic(self, .DroppedConnections)
    }

    /// The number of established connections that were closed by this socket, typically due to protocol errors.
    ///
    /// - Throws:  `NanoMessageError.GetSocketStatistic`
    ///
    /// - Returns: As per description.
    public func getBrokenConnections() throws -> UInt64 {
        return try getSocketStatistic(self, .BrokenConnections)
    }

    /// The number of errors encountered by this socket trying to connect to a remote peer.
    ///
    /// - Throws:  `NanoMessageError.GetSocketStatistic`
    ///
    /// - Returns: As per description.
    public func getConnectErrors() throws -> UInt64 {
        return try getSocketStatistic(self, .ConnectErrors)
    }

    /// The number of errors encountered by this socket trying to bind to a local address.
    ///
    /// - Throws:  `NanoMessageError.GetSocketStatistic`
    ///
    /// - Returns: As per description.
    public func getBindErrors() throws -> UInt64 {
        return try getSocketStatistic(self, .BindErrors)
    }

    /// The number of errors encountered by this socket trying to accept a a connection from a remote peer.
    ///
    /// - Throws:  `NanoMessageError.GetSocketStatistic`
    ///
    /// - Returns: As per description.
    public func getAcceptErrors() throws -> UInt64 {
        return try getSocketStatistic(self, .AcceptErrors)
    }

    /// The number of connections currently in progress to this socket.
    ///
    /// - Throws:  `NanoMessageError.GetSocketStatistic`
    ///
    /// - Returns: As per description.
    ///
    /// - Note:    This feature is undocumented in the underlying nanomsg library
    public func getCurrentInProgressConnections() throws -> UInt64 {
        return try getSocketStatistic(self, .CurrentInProgressConnections)
    }

    /// The number of connections currently estabalished to this socket.
    ///
    /// - Throws:  `NanoMessageError.GetSocketStatistic`
    ///
    /// - Returns: As per description.
    ///
    /// - Note:    This feature is undocumented in the underlying nanomsg library
    public func getCurrentConnections() throws -> UInt64 {
        return try getSocketStatistic(self, .CurrentConnections)
    }

    /// The number of end-point errors.
    ///
    /// - Throws:  `NanoMessageError.GetSocketStatistic`
    ///
    /// - Returns: As per description.
    ///
    /// - Note:    This feature is undocumented in the underlying nanomsg library
    public func getCurrentEndPointErrors() throws -> UInt64 {
        return try getSocketStatistic(self, .CurrentEndPointErrors)
    }
}
