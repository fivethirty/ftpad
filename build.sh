#!/bin/sh
set -e

SHA=$(git rev-parse --short HEAD)
if ! git diff --quiet || ! git diff --cached --quiet; then
    SHA="$SHA-dirty"
fi

swift build -c release

mkdir -p ftpad.app/Contents/MacOS
mkdir -p ftpad.app/Contents/Resources
cp .build/release/ftpad ftpad.app/Contents/MacOS/ftpad
sed "s/{{BUILD_SHA}}/$SHA/" Info.plist > ftpad.app/Contents/Info.plist
cp ftpad.icns ftpad.app/Contents/Resources/AppIcon.icns

codesign --sign - --force --deep ftpad.app

echo "Built ftpad.app — drag to /Applications"
