#!/usr/bin/env bash

set -eufx -o pipefail

git clone https://github.com/nanomsg/nanomsg.git /tmp/nanomsg
cd /tmp/nanomsg
git checkout 1.1.2

mkdir build && cd build
sudo apt-get update && sudo apt-get install --yes cmake
cmake ..
cmake --build .
sudo cmake --build . --target install

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
    sudo update_dyld_shared_cache
else
    sudo ldconfig
fi
