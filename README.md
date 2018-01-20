# NanoMessage

[![Swift][swift-badge-3]][swift-url]
[![Swift][swift-badge-4]][swift-url]
[![Build Status][travis-build-badge]][travis-build-url]
[![License][mit-badge]][mit-url]

**NanoMessage** is a **Swift-3/4** class wrapper of [nanomsg](http://nanomsg.org/)

## Socket Protocols

- [x] Pair
- [x] Push/Pull
- [x] Request/Reply
- [x] Publisher/Subscriber
- [x] Surveyor/Respondent
- [x] Bus

## Transport Mechanisms

- [x] TCP/IP
- [x] In-Process Communication
- [x] Inter-Process Communication
- [x] Web Socket

## Features

- [x] Send/Receive (Synchronous/Asynchronous) Blocking/Non-Blocking And Timeout
- [x] Same message payload object for Send/Receive with message context
- [x] Socket Polling (Single or Multiple)
- [x] Device/Socket Binding (Synchronous/Asynchronous)
- [x] Socket Loopback (Synchronous/Asynchronous)

## Usage

If [Swift Package Manager](https://github.com/apple/swift-package-manager) is used, add this package as a dependency in `Package.swift`,

```swift
.Package(url: "https://github.com/itssofluffy/NanoMessage.git", majorVersion: 0)
```

## Examples

Push

```swift
import Foundation
import NanoMessage

do {
    guard let url = URL(string: "tcp://localhost:5555") else {
        fatalError("url is not valid")
    }

    let node = try PushSocket()

    let _: Int = try node.createEndPoint(url: url, type: .Connect)

    try node.sendMessage(Message(value: "This is earth calling...earth calling..."),
                         timeout: TimeInterval(seconds: 10))
} catch let error as NanoMessageError {
    print(error)
} catch {
    print("an unexpected error '\(error)' has occured in the library libNanoMessage.")
}

```

Pull

```swift
import Foundation
import NanoMessage

do {
    guard let url = URL(string: "tcp://*:5555") else {
        fatalError("url is not valid")
    }

    let node = try PullSocket()

    let endPoint: EndPoint = try node.createEndPoint(url: url, type: .Bind, name: "my local end-point")

    let received = try node.receiveMessage(timeout: TimeInterval(seconds: 10))

    print("bytes  : \(received.bytes)")            // 40
    print("message: \(received.message.string)")   // This is earth calling...earth calling...

    if (try node.removeEndPoint(endPoint)) {
        print("end-point removed")
    }
} catch let error as NanoMessageError {
    print(error)
} catch {
    print("an unexpected error '\(error)' has occured in the library libNanoMessage.")
}

```

Request

```swift
import Foundation
import NanoMessage

do {
    guard let url = URL(string: "tcp://localhost:5555") else {
        fatalError("url is not valid")
    }

    let node = try RequestSocket()

    let endPoint: EndPoint = try node.createEndPoint(url: url, type: .Connect, name: "request end-point")

    usleep(TimeInterval(milliseconds: 200))

    let timeout = TimeInterval(seconds: 10)
    let message = Message(value: "ping")

    let received = try node.sendMessage(message, sendTimeout: timeout, receiveTimeout: timeout) { sent in
        print("sent \(sent)")
    }

    print("and recieved \(received)")
} catch let error as NanoMessageError {
    print(error)
} catch {
    print("an unexpected error '\(error)' has occured in the library libNanoMessage.")
}

```

Reply

```swift
import Foundation
import NanoMessage

do {
    guard let url = URL(string: "tcp://*:5555") else {
        fatalError("url is not valid")
    }

    let node = try ReplySocket()

    let endPoint: EndPoint = try node.createEndPoint(url: url, type: .Bind, name: "reply end-point")

    usleep(TimeInterval(milliseconds: 200))

    let timeout = TimeInterval(seconds: 10)

    let sent = try node.receiveMessage(receiveTimeout: timeout, sendTimeout: timeout) { received in
        print("received \(received)")

        var message = ""

        if (received.message.string == "ping") {
            message = "pong"
        } else {
            message = "personally i prefer wiff-wafe"
        }

        return Message(value: message)
    }

    print("and sent \(sent)")
} catch let error as NanoMessageError {
    print(error)
} catch {
    print("an unexpected error '\(error)' has occured in the library libNanoMessage.")
}

```

## License

This project is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-badge-3]: https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat
[swift-badge-4]: https://img.shields.io/badge/Swift-4.0-orange.svg?style=flat
[swift-url]: https://swift.org
[travis-build-badge]: https://travis-ci.org/itssofluffy/NanoMessage.svg?branch=master
[travis-build-url]: https://travis-ci.org/itssofluffy/NanoMessage
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
