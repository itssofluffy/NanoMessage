/*
    SocketOption.swift

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

import C7
import CNanoMessage

/// Get socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be returned.
///   - level:    The optional (defaults to a Standard Socket Level) socket level.
///
/// - Throws:  `NanoMessageError.GetSocketOption` if an issue is encountered.
///
/// - Returns: The result as a `CInt` type.
internal func getSocketOption(_ socketFd: CInt, _ option: CInt, _ level: CInt = NN_SOL_SOCKET) throws -> CInt {
    var optval: CInt = -1
    var optvallen = MemoryLayout<CInt>.size

    let rc = nn_getsockopt(socketFd, level, option, &optval, &optvallen)

    guard (rc >= 0) else {
        throw NanoMessageError.GetSocketOption(code: nn_errno())
    }

    return optval
}

/// Get socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be returned.
///   - level:    The optional (defaults to a Standard Socket Level) socket level.
///
/// - Throws:  `NanoMessageError.GetSocketOption` if an issue is encountered.
///
/// - Returns: The result as a `Data` type.
internal func getSocketOption(_ socketFd: CInt, _ option: CInt, _ level: CInt = NN_SOL_SOCKET) throws -> Data {
    var optvallen: Int = Int.max
    var optval = Data.buffer(with: optvallen)

    let rc = nn_getsockopt(socketFd, level, option, &optval.bytes, &optvallen)

    guard (rc >= 0) else {
        throw NanoMessageError.GetSocketOption(code: nn_errno())
    }

    return Data(optval[0 ..< optvallen])
}

/// Get socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be returned.
///   - level:    The optional (defaults to a Standard Socket Level) socket level.
///
/// - Throws:  `NanoMessageError.GetSocketOption` if an issue is encountered.
///
/// - Returns: The result as a `String` type.
internal func getSocketOption(_ socketFd: CInt, _ option: CInt, _ level: CInt = NN_SOL_SOCKET) throws -> String {
    let returnValue: Data = try getSocketOption(socketFd, option, level)

    return try String(data: returnValue)
}

/// Get socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be returned.
///   - level:    The optional (defaults to a Standard Socket Level) socket level.
///
/// - Throws:  `NanoMessageError.GetSocketOption` if an issue is encountered.
///
/// - Returns: The result as a `UInt` type.
internal func getSocketOption(_ socketFd: CInt, _ option: CInt, _ level: CInt = NN_SOL_SOCKET) throws -> UInt {
    let returnValue: CInt = try getSocketOption(socketFd, option, level)

    return UInt(returnValue)
}

/// Get socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be returned.
///   - level:    The optional (defaults to a Standard Socket Level) socket level.
///
/// - Throws:  `NanoMessageError.GetSocketOption` if an issue is encountered.
///
/// - Returns: The result as a `Int` type.
internal func getSocketOption(_ socketFd: CInt, _ option: CInt, _ level: CInt = NN_SOL_SOCKET) throws -> Int {
    let returnValue: CInt = try getSocketOption(socketFd, option, level)

    return Int(returnValue)
}

/// Get socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be returned.
///   - level:    The optional (defaults to a Standard Socket Level) socket level.
///
/// - Throws:  `NanoMessageError.GetSocketOption` if an issue is encountered.
///
/// - Returns: The result as a `Bool` type.
internal func getSocketOption(_ socketFd: CInt, _ option: CInt, _ level: CInt = NN_SOL_SOCKET) throws -> Bool {
    let returnValue: CInt = try getSocketOption(socketFd, option, level)

    return (returnValue == 0) ? false : true
}

/// Get socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be returned.
///   - level:    The socket level as type `TransportMechanism`.
///
/// - Throws:  `NanoMessageError.GetSocketOption` if an issue is encountered.
///
/// - Returns: The result as a `CInt` type.
internal func getSocketOption(_ socketFd: CInt, _ option: CInt, _ level: TransportMechanism) throws -> CInt {
    return try getSocketOption(socketFd, option, level.rawValue)
}

/// Get socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be returned.
///   - level:    The socket level as type `SocketProtocol`.
///
/// - Throws: `NanoMessageError.GetSocketOption` if an issue is encountered.
///
/// - Returns: the result as a `CInt` type.
internal func getSocketOption(_ socketFd: CInt, _ option: CInt, _ level: SocketProtocol) throws -> CInt {
    return try getSocketOption(socketFd, option, level.rawValue)
}

/// Get socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be returned.
///   - level:    The socket level as type `SocketProtocol`.
///
/// - Throws:  `NanoMessageError.GetSocketOption` if an issue is encountered.
///
/// - Returns: The result as a `Int` type.
internal func getSocketOption(_ socketFd: CInt, _ option: CInt, _ level: SocketProtocol) throws -> Int {
    return try getSocketOption(socketFd, option, level.rawValue)
}

/// Get socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be returned.
///   - level:    The socket level as type `SocketProtocol`.
///
/// - Throws:  `NanoMessageError.GetSocketOption` if an issue is encountered.
///
/// - Returns: The result as a `UInt` type.
internal func getSocketOption(_ socketFd: CInt, _ option: CInt, _ level: SocketProtocol) throws -> UInt {
    let returnValue: CInt = try getSocketOption(socketFd, option, level)

    return UInt(returnValue)
}

/// Get socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be returned.
///   - level:    The socket level as type `SocketProtocol`.
///
/// - Throws:  `NanoMessageError.GetSocketOption` if an issue is encountered.
///
/// - Returns: The result as a `Bool` type.
internal func getSocketOption(_ socketFd: CInt, _ option: CInt, _ level: SocketProtocol) throws -> Bool {
    let returnValue: CInt = try getSocketOption(socketFd, option, level)

    return (returnValue == 0) ? false : true
}

/// Set socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be set.
///   - optval:   The value of the option to be set.
///   - level:    The optional (defaults to a Standard Socket Level) socket level.
///
/// - Throws: `NanoMessageError.SetSocketOption` if an issue is encountered.
internal func setSocketOption(_ socketFd: CInt, _ option: CInt, _ optval: CInt, _ level: CInt = NN_SOL_SOCKET) throws {
    var value = optval

    let rc = nn_setsockopt(socketFd, level, option, &value, MemoryLayout<CInt>.size)

    guard (rc >= 0) else {
        throw NanoMessageError.SetSocketOption(code: nn_errno())
    }
}

/// Set socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be set.
///   - optval:   The value of the option to be set.
///   - level:    The optional (defaults to a Standard Socket Level) socket level.
///
/// - Throws: `NanoMessageError.SetSocketOption` if an issue is encountered.
internal func setSocketOption(_ socketFd: CInt, _ option: CInt, _ optval: Data, _ level: CInt = NN_SOL_SOCKET) throws {
    let rc = nn_setsockopt(socketFd, level, option, optval.bytes, optval.count)

    guard (rc >= 0) else {
        throw NanoMessageError.SetSocketOption(code: nn_errno())
    }
}

/// Set socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be set.
///   - optval:   The value of the option to be set.
///   - level:    The optional (defaults to a Standard Socket Level) socket level.
///
/// - Throws: `NanoMessageError.SetSocketOption` if an issue is encountered.
internal func setSocketOption(_ socketFd: CInt, _ option: CInt, _ optval: String, _ level: CInt = NN_SOL_SOCKET) throws {
    try setSocketOption(socketFd, option, Data(optval), level)
}

/// Set socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be set.
///   - optval:   The value of the option to be set.
///   - level:    The optional (defaults to a Standard Socket Level) socket level.
///
/// - Throws: `NanoMessageError.SetSocketOption` if an issue is encountered.
internal func setSocketOption(_ socketFd: CInt, _ option: CInt, _ optval: UInt, _ level: CInt = NN_SOL_SOCKET) throws {
    try setSocketOption(socketFd, option, CInt(optval), level)
}

/// Set socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be set.
///   - optval:   The value of the option to be set.
///   - level:    The optional (defaults to a Standard Socket Level) socket level.
///
/// - Throws: `NanoMessageError.SetSocketOption` if an issue is encountered.
internal func setSocketOption(_ socketFd: CInt, _ option: CInt, _ optval: Int, _ level: CInt = NN_SOL_SOCKET) throws {
    try setSocketOption(socketFd, option, CInt(optval), level)
}

/// Set socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be set.
///   - optval:   The value of the option to be set.
///   - level:    The optional (defaults to a Standard Socket Level) socket level.
///
/// - Throws: `NanoMessageError.SetSocketOption` if an issue is encountered.
internal func setSocketOption(_ socketFd: CInt, _ option: CInt, _ optval: Bool, _ level: CInt = NN_SOL_SOCKET) throws {
    let valueToSet: CInt = (optval) ? 1 : 0

    try setSocketOption(socketFd, option, valueToSet, level)
}

/// Set socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be set.
///   - optval:   The value of the option to be set.
///   - level:    The socket level as type `SocketProtocol`.
///
/// - Throws: `NanoMessageError.SetSocketOption` if an issue is encountered.
internal func setSocketOption(_ socketFd: CInt, _ option: CInt, _ optval: Data, _ level: SocketProtocol) throws {
    try setSocketOption(socketFd, option, optval, level.rawValue)
}

/// Set socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be set.
///   - optval:   The value of the option to be set.
///   - level:    The socket level as type `SocketProtocol`.
///
/// - Throws: `NanoMessageError.SetSocketOption` if an issue is encountered.
internal func setSocketOption(_ socketFd: CInt, _ option: CInt, _ optval: String, _ level: SocketProtocol) throws {
    try setSocketOption(socketFd, option, Data(optval), level.rawValue)
}

/// Set socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be set.
///   - optval:   The value of the option to be set.
///   - level:    The socket level as type `SocketProtocol`.
///
/// - Throws: `NanoMessageError.SetSocketOption` if an issue is encountered.
internal func setSocketOption(_ socketFd: CInt, _ option: CInt, _ optval: Int, _ level: SocketProtocol) throws {
    try setSocketOption(socketFd, option, optval, level.rawValue)
}

/// Set socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be set.
///   - optval:   The value of the option to be set.
///   - level:    The socket level as type `SocketProtocol`.
///
/// - Throws: `NanoMessageError.SetSocketOption` if an issue is encountered.
internal func setSocketOption(_ socketFd: CInt, _ option: CInt, _ optval: CInt, _ level: SocketProtocol) throws {
    try setSocketOption(socketFd, option, optval, level.rawValue)
}

/// Set socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be set.
///   - optval:   The value of the option to be set.
///   - level:    The socket level as type `SocketProtocol`.
///
/// - Throws: `NanoMessageError.SetSocketOption` if an issue is encountered.
internal func setSocketOption(_ socketFd: CInt, _ option: CInt, _ optval: UInt, _ level: SocketProtocol) throws {
    try setSocketOption(socketFd, option, CInt(optval), level)
}

/// Set socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be set.
///   - optval:   The value of the option to be set.
///   - level:    The socket level as type `TransportMechanism`.
///
/// - Throws: `NanoMessageError.SetSocketOption` if an issue is encountered.
internal func setSocketOption(_ socketFd: CInt, _ option: CInt, _ optval: CInt, _ level: TransportMechanism) throws {
    try setSocketOption(socketFd, option, optval, level.rawValue)
}

/// Set socket option.
///
/// - Parameters:
///   - socketFd: Nano socket file descriptor.
///   - option:   The option to be set.
///   - optval:   The value of the option to be set as type `WebSocketMessageType`.
///   - level:    The socket level as type `TransportMechanism`.
///
/// - Throws: `NanoMessageError.SetSocketOption` if an issue is encountered.
internal func setSocketOption(_ socketFd: CInt, _ option: CInt, _ optval: WebSocketMessageType, _ level: TransportMechanism) throws {
    try setSocketOption(socketFd, option, optval.rawValue, level)
}
