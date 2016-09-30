/*
    Package.swift

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

import PackageDescription

let package = Package (
    name:    "NanoMessage",
    dependencies: [
        .Package (
            url:          "https://github.com/open-swift/C7.git",
            majorVersion: 0
        ),
        .Package (
            url:          "https://github.com/itssofluffy/FNVHashValue.git",
            majorVersion: 0
        ),
        .Package (
            url:          "https://github.com/itssofluffy/CNanoMessage",
            majorVersion: 0
        )
    ]
)

let sharedObject = Product (
    name:    "NanoMessage",
    type:    .Library(.Dynamic),
    modules: "NanoMessage"
)

products.append(sharedObject)
