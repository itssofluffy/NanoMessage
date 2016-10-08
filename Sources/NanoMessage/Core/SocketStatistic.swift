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

/// Retrieves the value of a statistic from the socket. Not all statistics are relevant to all transports.
/// For example, the nn_inproc(7) transport does not maintain any of the connection related statistics.
///
/// - Parameters:
///   - socketFd:  The NanoSocket file descriptor
///   - statistic: The nanomsg statistic option.
///
/// - Throws: `NanoMessageError.GetSocketStatistic` if an issue was encountered.
///
/// - Returns: the resulting statistic.
///
/// - Note:    While this extension API is stable, these statistics are intended for human consumption,
///            to facilitate observability and debugging. The actual statistics themselves as well as
///            their meanings are unstable, and subject to change without notice. Programs should not
///            depend on the presence or values of any particular statistic. 
internal func getSocketStatistic(_ socketFd: CInt, _ statistic: CInt) throws -> UInt64 {
    let rc = nn_get_statistic(socketFd, statistic)

    guard (rc >= 0) else {
        throw NanoMessageError.GetSocketStatistic(code: nn_errno())
    }

    return rc
}
