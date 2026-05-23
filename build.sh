#!/bin/sh
set -e

swift build -c release

mkdir -p ftpad.app/Contents/MacOS
cp .build/release/ftpad ftpad.app/Contents/MacOS/ftpad
cp Info.plist ftpad.app/Contents/Info.plist

codesign --sign - --force --deep ftpad.app

echo "Built ftpad.app — drag to /Applications"
