#!/bin/sh
# Build rkdeveloptool natively on macOS (Homebrew), into ./src/rkdeveloptool
set -e
brew install libusb automake autoconf pkg-config dtc
[ -d src/rkdeveloptool ] || git clone --depth 1 https://github.com/rockchip-linux/rkdeveloptool.git src/rkdeveloptool
cd src/rkdeveloptool
autoreconf -i
./configure
# Recent clang rejects its variable-length arrays with -Werror
make -j8 CXXFLAGS="-g -O2 -Wno-vla-cxx-extension -Wno-error"
./rkdeveloptool -v
echo "export RKDEV=$PWD/rkdeveloptool"
