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
import NanoMessage

do {
    let node0 = try PushSocket()
    let _: Int = try node0.connectToAddress("inproc:///tmp/pipeline.inproc")

    try node0.sendMessage("This is earth calling...earth calling...")
} catch let error as NanoMessageError {
    print(error)
} catch {
    print("an unknown error '\(error)' has occured in the library NanoMessage.")
}

```

Pull

```swift
import NanoMessage

do {
    let node0 = try PullSocket()
    let _: Int = try node0.bindToAddress("inproc:///tmp/pipeline.inproc")

    let received: (bytes: Int, message: String) = try node0.receiveMessage()

    print("bytes  : \(received.bytes)")     // 39
    print("message: \(received.message)")   // This is earth calling...earth calling...
} catch let error as NanoMessageError {
    print(error)
} catch {
    print("an unknown error '\(error)' has occured in the library NanoMessage.")
}

```
