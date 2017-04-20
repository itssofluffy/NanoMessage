# NanoMessage

[![Swift][swift-badge]][swift-url]
[![Build Status][travis-build-badge]][travis-build-url]
[![License][mit-badge]][mit-url]

**NanoMessage** is a **Swift-3** class wrapper of [nanomsg](http://nanomsg.org/)

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

    let node0 = try PushSocket()

    let _: Int = try node0.createEndPoint(url: url, type: .Connect)

    try node0.sendMessage(Message(value: "This is earth calling...earth calling..."),
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

    let node0 = try PullSocket()

    let endPoint: EndPoint = try node0.createEndPoint(url: url, type: .Bind, name: "my local end-point")

    let received = try node0.receiveMessage(timeout: TimeInterval(seconds: 10))

    print("bytes  : \(received.bytes)")            // 40
    print("message: \(received.message.string)")   // This is earth calling...earth calling...

    if (try node0.removeEndPoint(endPoint)) {
        print("end-point removed")
    }
} catch let error as NanoMessageError {
    print(error)
} catch {
    print("an unexpected error '\(error)' has occured in the library libNanoMessage.")
}

```

## License

This project is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-badge]: https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat
[swift-url]: https://swift.org
[travis-build-badge]: https://travis-ci.org/itssofluffy/NanoMessage.swift.svg?branch=master)
[travis-build-url]: https://travis-ci.org/itssofluffy/NanoMessage.swift
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
