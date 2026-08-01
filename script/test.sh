#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FALLBACK_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk"
DEVELOPER_FRAMEWORKS="/Library/Developer/CommandLineTools/Library/Developer/Frameworks"
TESTING_LIBRARIES="/Library/Developer/CommandLineTools/Library/Developer/usr/lib"
SWIFT_TEST_ARGS=()

if ! xcodebuild -version >/dev/null 2>&1 && [ -d "$FALLBACK_SDK" ]; then
    SWIFT_TEST_ARGS+=(
        --build-system native
        --sdk "$FALLBACK_SDK"
        -Xswiftc -F
        -Xswiftc "$DEVELOPER_FRAMEWORKS"
        -Xlinker -F
        -Xlinker "$DEVELOPER_FRAMEWORKS"
        -Xlinker -rpath
        -Xlinker "$DEVELOPER_FRAMEWORKS"
        -Xlinker -rpath
        -Xlinker "$TESTING_LIBRARIES"
    )
fi

cd "$ROOT_DIR"
swift test "${SWIFT_TEST_ARGS[@]}"
