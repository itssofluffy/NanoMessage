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

public class NanoSocket {
    public private(set) var socketFd: CInt = -1
    public fileprivate(set) var endPoints = Set<EndPoint>()

    public var closureAttempts: UInt = 10

    public init(socketDomain: SocketDomain, socketProtocol: SocketProtocol) throws {
        self.socketFd = nn_socket(socketDomain.rawValue, socketProtocol.rawValue)

        if (self.socketFd < 0) {
            throw NanoMessageError()
        }
    }

    deinit {
        func closeSocket() throws {
            if (self.socketFd >= 0) {
                var loopCount: UInt = 0
                let milliseconds: UInt32 = UInt32(_getClosureTimeout() / self.closureAttempts)

                while (true) {
                    let rc = nn_close(self.socketFd)

                    if (rc < 0) {
                        // if we were interrupted by a signal, reattempt is allowed by the native library
                        if (nn_errno() == EINTR) {
                            if (loopCount >= self.closureAttempts) {
                                throw NanoMessageError(errorNumber: 1, errorMessage: "socket closure repeatedly interrupted")
                            } else {
                                usleep(milliseconds)
                            }

                            loopCount += 1
                        } else {
                            throw NanoMessageError()
                        }
                    } else {
                        break
                    }
                }
            }
        }

        do {
            try closeSocket()
        } catch NanoMessageError.nanomsgError(let errorNumber, let errorMessage) {
            errorPrint("Error : \(errorMessage) (#\(errorNumber))")
        } catch NanoMessageError.Error(let errorNumber, let errorMessage) {
            errorPrint("Error : \(errorMessage) (#\(errorNumber))")
        } catch (let errorMessage) {
            errorPrint("Error : An Unknown error '\(errorMessage)' has occured in the library NanoMessage.")
        }
    }

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
    public func bindToAddress(_ endPointAddress: String, endPointName: String = "") throws -> EndPoint {
        var endPointId: CInt = -1

        endPointAddress.withCString {
            endPointId = nn_bind(self.socketFd, $0)
        }

        if (endPointId < 0) {
            throw NanoMessageError()
        }

        let endPoint = EndPoint(endPointId: Int(endPointId), endPointAddress: endPointAddress, connectionType: .BindToAddress, endPointName: endPointName)

        self.endPoints.insert(endPoint)

        return endPoint
    }

    public func bindToAddress(_ endPointAddress: String, endPointName: String = "") throws -> Int {
        let endPoint: EndPoint = try self.bindToAddress(endPointAddress, endPointName: endPointName)

        return endPoint.id
    }

    public func connectToAddress(_ endPointAddress: String, endPointName: String = "") throws -> EndPoint {
        var endPointId: CInt = -1

        endPointAddress.withCString {
            endPointId = nn_connect(self.socketFd, $0)
        }

        if (endPointId < 0) {
            throw NanoMessageError()
        }

        let endPoint = EndPoint(endPointId: Int(endPointId), endPointAddress: endPointAddress, connectionType: .ConnectToAddress, endPointName: endPointName)

        self.endPoints.insert(endPoint)

        return endPoint
    }

    public func connectToAddress(_ endPointAddress: String, endPointName: String = "") throws -> Int {
        let endPoint: EndPoint = try self.connectToAddress(endPointAddress, endPointName: endPointName)

        return endPoint.id
    }

    @discardableResult
    public func removeEndPoint(_ endPoint: EndPoint) throws -> Bool {
        var loopCount: UInt = 0
        let milliseconds: UInt32 = UInt32(_getClosureTimeout() / self.closureAttempts)

        while (true) {
            let rc = nn_shutdown(self.socketFd, CInt(endPoint.id))

            if (rc < 0) {
                // if we were interrupted by a signal, reattempt is allowed by the native library
                if (nn_errno() == EINTR) {
                    if (loopCount >= self.closureAttempts) {
                        throw NanoMessageError(errorNumber: 1, errorMessage: "endpoint closure interrupted")
                    } else {
                        usleep(milliseconds)
                    }

                    loopCount += 1
                } else {
                    throw NanoMessageError()
                }
            } else {
                break
            }
        }

        self.endPoints.remove(endPoint)

        return true
    }

    @discardableResult
    public func removeEndPoint(_ endPoint: Int) throws -> Bool {
        for epoint in self.endPoints {
            if (endPoint == epoint.id) {
                return try self.removeEndPoint(epoint)
            }
        }

        return false
    }

    public func bindToSocket(_ nanoSocket: NanoSocket) throws {
        let rc = nn_device(self.socketFd, nanoSocket.socketFd)

        if (rc < 0) {
            throw NanoMessageError()
        }
    }
}

extension NanoSocket {
    public func getSocketDomain() throws -> SocketDomain {
        return SocketDomain(rawValue: try getSocketOption(self.socketFd, NN_DOMAIN))!
    }

    public func getSocketProtocol() throws -> SocketProtocol {
        return SocketProtocol(rawValue: try getSocketOption(self.socketFd, NN_PROTOCOL))!
    }

    public func getProtocolFamily() throws -> ProtocolFamily {
        return try ProtocolFamily(rawValue: self.getSocketProtocol())
    }

    public func getLinger() throws -> Int {
        return try getSocketOption(self.socketFd, NN_LINGER)
    }

    @available(*, unavailable, message: "nanomsg library no longer supports this feature")
    public func setLinger(milliseconds: Int) throws {
        try setSocketOption(self.socketFd, NN_LINGER, milliseconds)
    }

    public func getReconnectInterval() throws -> UInt {
        return try getSocketOption(self.socketFd, NN_RECONNECT_IVL)
    }

    public func setReconnectInterval(milliseconds: UInt) throws {
        try setSocketOption(self.socketFd, NN_RECONNECT_IVL, milliseconds)
    }

    public func getReconnectIntervalMax() throws -> UInt {
        return try getSocketOption(self.socketFd, NN_RECONNECT_IVL_MAX)
    }

    public func setReconnectIntervalMax(milliseconds: UInt) throws {
        try setSocketOption(self.socketFd, NN_RECONNECT_IVL_MAX, milliseconds)
    }

    public func getSocketName() throws -> String {
        return try getSocketOption(self.socketFd, NN_SOCKET_NAME)
    }

    public func setSocketName(socketName: String) throws {
        try setSocketOption(self.socketFd, NN_SOCKET_NAME, socketName)
    }

    public func getIPv4Only() throws -> Bool {
        return try getSocketOption(self.socketFd, NN_IPV4ONLY)
    }

    public func setIPv4Onlt(ip4Only: Bool) throws {
        try setSocketOption(self.socketFd, NN_IPV4ONLY, ip4Only)
    }

    public func getMaxTTL() throws -> Int {
        return try getSocketOption(self.socketFd, NN_MAXTTL)
    }

    public func setMaxTTL(hops: Int) throws {
        try setSocketOption(self.socketFd, NN_MAXTTL, hops)
    }

    public func getTCPNoDelay(transportMechanism: TransportMechanism = .TCP) throws -> Bool {
        let valueReturned: CInt = try getSocketOption(self.socketFd, NN_TCP_NODELAY, transportMechanism)

        return (valueReturned == NN_TCP_NODELAY) ? true : false
    }

    public func setTCPNoDelay(disableNagles: Bool, transportMechanism: TransportMechanism = .TCP) throws {
        let valueToSet: CInt = (disableNagles) ? NN_TCP_NODELAY : 0

        try setSocketOption(self.socketFd, NN_TCP_NODELAY, valueToSet, transportMechanism)
    }

    public func getWebSocketMessageType() throws -> WebSocketMessageType {
        return WebSocketMessageType(rawValue: try getSocketOption(self.socketFd, NN_WS_MSG_TYPE, .WebSocket))!
    }

    public func setWebSocketMessageType(type: WebSocketMessageType) throws {
        try setSocketOption(self.socketFd, NN_WS_MSG_TYPE, type, .WebSocket)
    }
}

extension NanoSocket {
    public func getEstablishedConnections() throws -> UInt64 {
        return try getStatistic(self.socketFd, NN_STAT_ESTABLISHED_CONNECTIONS)
    }

    public func getAcceptedConnections() throws -> UInt64 {
        return try getStatistic(self.socketFd, NN_STAT_ACCEPTED_CONNECTIONS)
    }

    public func getDroppedConnections() throws -> UInt64 {
        return try getStatistic(self.socketFd, NN_STAT_DROPPED_CONNECTIONS)
    }

    public func getBrokenConnections() throws -> UInt64 {
        return try getStatistic(self.socketFd, NN_STAT_BROKEN_CONNECTIONS)
    }

    public func getConnectErrors() throws -> UInt64 {
        return try getStatistic(self.socketFd, NN_STAT_CONNECT_ERRORS)
    }

    public func getBindErrors() throws -> UInt64 {
        return try getStatistic(self.socketFd, NN_STAT_BIND_ERRORS)
    }

    public func getAcceptErrors() throws -> UInt64 {
        return try getStatistic(self.socketFd, NN_STAT_ACCEPT_ERRORS)
    }

    public func getCurrentConnections() throws -> UInt64 {
        return try getStatistic(self.socketFd, NN_STAT_CURRENT_CONNECTIONS)
    }
}
