# Swift classes for [nanomsg](http://nanomsg.org/)

## Usage

If [Swift Package Manager](https://github.com/apple/swift-package-manager) is
used, add this package as a dependency in `Package.swift`,

```swift
.Package(url: "https://github.com/itssofluffy/NanoMessage.git", majorVersion: 0)
```

## Example

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
