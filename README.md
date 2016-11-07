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
    guard let url = URL(string: "ipc:///tmp/pipeline.ipc") else {
        fatalError("url is not valid")
    }

    let node0 = try PushSocket()
    let _: Int = try node0.connectToURL(url)

    try node0.sendMessage("This is earth calling...earth calling...", timeout: TimeInterval(seconds: 10))
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
    guard let url = URL(string: "ipc:///tmp/pipeline.ipc") else {
        fatalError("url is not valid")
    }

    let node0 = try PullSocket()
    let _: EndPoint = try node0.bindToURL(url, name: "my local end-point")

    let received: (bytes: Int, message: String) = try node0.receiveMessage(timeout: TimeInterval(seconds: 10))

    print("bytes  : \(received.bytes)")     // 40
    print("message: \(received.message)")   // This is earth calling...earth calling...
} catch let error as NanoMessageError {
    print(error)
} catch {
    print("an unexpected error '\(error)' has occured in the library libNanoMessage.")
}

```
