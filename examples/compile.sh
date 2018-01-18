#!/bin/bash
#
#  compile.sh
#
#  Copyright (c) 2016, 2017, 2018 Stephen Whittle  All rights reserved.
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"),
#  to deal in the Software without restriction, including without limitation
#  the rights to use, copy, modify, merge, publish, distribute, sublicense,
#  and/or sell copies of the Software, and to permit persons to whom
#  the Software is furnished to do so, subject to the following conditions:
#  The above copyright notice and this permission notice shall be included
#  in all copies or substantial portions of the Software.
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
#  IN THE SOFTWARE.

base_dir="$(dirname "$(pwd)")"

if [[ -d "$base_dir/.build/release" ]] ; then
    export lib_path="$base_dir/.build/release"
else
    export lib_path="$base_dir/.build/debug"
fi

CNanoMessageHeader="CNanoMessage.h"

CNanoMessagePath="$(dirname "$(find "$base_dir/Packages" \
                                    -name "$CNanoMessageHeader" 2>/dev/null)")"
if [[ "$CNanoMessagePath" == "." ]] ; then
    CNanoMessagePath="$(dirname "$(find "$base_dir/.build" \
                                        -name "$CNanoMessageHeader" 2>/dev/null)")"
fi

if [[ "$CNanoMessagePath" == "." ]] ; then
    printf "%s : failed to find '%s'.\n" "$(basename "$0")" \
                                         "$CNanoMessageHeader" >&2

    exit 1
fi

for fname in $(ls *.swift)
do
    swiftc -I "$lib_path" \
           -I "$CNanoMessagePath" \
           -L "$lib_path" \
           -L "$CNanoMessagePath" \
           -lNanoMessage \
           "$fname"
done

exit 0
