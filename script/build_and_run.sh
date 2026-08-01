#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="FlowKey"
BUNDLE_ID="com.flowkey.app"
MIN_SYSTEM_VERSION="15.0"
CONFIGURATION="${FLOWKEY_CONFIGURATION:-debug}"
INPUT_METHOD_NAME="FlowKey Compose"
INPUT_METHOD_EXECUTABLE="FlowKeyInputMethod"
INPUT_METHOD_BUNDLE_ID="com.flowkey.inputmethod"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
INPUT_METHOD_BUNDLE="$APP_CONTENTS/Library/Input Methods/$INPUT_METHOD_NAME.app"
INPUT_METHOD_CONTENTS="$INPUT_METHOD_BUNDLE/Contents"
INPUT_METHOD_MACOS="$INPUT_METHOD_CONTENTS/MacOS"
INPUT_METHOD_RESOURCES="$INPUT_METHOD_CONTENTS/Resources"
INPUT_METHOD_BINARY="$INPUT_METHOD_MACOS/$INPUT_METHOD_EXECUTABLE"
INPUT_METHOD_INFO_PLIST="$INPUT_METHOD_CONTENTS/Info.plist"

SWIFT_BUILD_ARGS=(-c "$CONFIGURATION")
FALLBACK_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk"

# The Swift 6.4 Command Line Tools ship a SwiftUI macro SDK without the
# matching plugin. The previous complete SDK plus SwiftPM's native backend is
# the only self-contained build path until full Xcode is installed.
if ! xcodebuild -version >/dev/null 2>&1 && [ -d "$FALLBACK_SDK" ]; then
    SWIFT_BUILD_ARGS+=(--build-system native --sdk "$FALLBACK_SDK")
fi

cd "$ROOT_DIR"
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build "${SWIFT_BUILD_ARGS[@]}"
BUILD_DIR="$(swift build "${SWIFT_BUILD_ARGS[@]}" --show-bin-path)"
BUILD_BINARY="$BUILD_DIR/$APP_NAME"
BUILD_INPUT_METHOD_BINARY="$BUILD_DIR/$INPUT_METHOD_EXECUTABLE"
APP_RESOURCE_BUNDLE="$BUILD_DIR/FlowKey_FlowKey.bundle"
INPUT_METHOD_RESOURCE_BUNDLE="$BUILD_DIR/FlowKey_FlowKeyInputMethod.bundle"

if [ ! -x "$BUILD_BINARY" ]; then
    echo "Built executable not found at $BUILD_BINARY" >&2
    exit 1
fi

if [ ! -x "$BUILD_INPUT_METHOD_BINARY" ]; then
    echo "Built input method executable not found at $BUILD_INPUT_METHOD_BINARY" >&2
    exit 1
fi

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES" "$INPUT_METHOD_MACOS" "$INPUT_METHOD_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
cp "$BUILD_INPUT_METHOD_BINARY" "$INPUT_METHOD_BINARY"
chmod +x "$APP_BINARY"
chmod +x "$INPUT_METHOD_BINARY"

copy_localizations() {
    local resource_bundle="$1"
    local destination="$2"

    for localization_directory in "$resource_bundle"/*.lproj; do
        [ -d "$localization_directory" ] || continue
        for strings_file in "$localization_directory"/*.strings; do
            [ -f "$strings_file" ] || continue
            plutil -lint "$strings_file" >/dev/null
        done
        cp -R "$localization_directory" "$destination/"
    done
}

copy_localizations "$APP_RESOURCE_BUNDLE" "$APP_RESOURCES"
copy_localizations "$INPUT_METHOD_RESOURCE_BUNDLE" "$INPUT_METHOD_RESOURCES"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleLocalizations</key>
  <array>
    <string>en</string>
    <string>zh-Hans</string>
  </array>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.utilities</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>FlowKey uses the microphone only when you start dictation.</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSSpeechRecognitionUsageDescription</key>
  <string>FlowKey turns speech into text only after you start dictation.</string>
</dict>
</plist>
PLIST

cat >"$INPUT_METHOD_INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>$INPUT_METHOD_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$INPUT_METHOD_EXECUTABLE</string>
  <key>CFBundleIdentifier</key>
  <string>$INPUT_METHOD_BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$INPUT_METHOD_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleLocalizations</key>
  <array>
    <string>en</string>
    <string>zh-Hans</string>
  </array>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>ComponentInputModeDict</key>
  <dict>
    <key>tsInputModeListKey</key>
    <dict>
      <key>com.flowkey.inputmethod.compose</key>
      <dict>
        <key>TISInputSourceID</key>
        <string>com.flowkey.inputmethod.compose</string>
        <key>tsInputModeDefaultStateKey</key>
        <true/>
        <key>tsInputModeIsVisibleKey</key>
        <true/>
        <key>tsInputModePrimaryInScriptKey</key>
        <false/>
        <key>tsInputModeScriptKey</key>
        <string>smUnicodeScript</string>
      </dict>
    </dict>
    <key>tsVisibleInputModeOrderedArrayKey</key>
    <array>
      <string>com.flowkey.inputmethod.compose</string>
    </array>
  </dict>
  <key>InputMethodConnectionName</key>
  <string>com.flowkey.inputmethod.connection</string>
  <key>InputMethodServerControllerClass</key>
  <string>FlowKeyInputController</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSSupportsSuddenTermination</key>
  <true/>
  <key>TISIconIsTemplate</key>
  <true/>
  <key>TISInputSourceID</key>
  <string>$INPUT_METHOD_BUNDLE_ID</string>
  <key>TISIntendedLanguage</key>
  <string>en</string>
  <key>tsInputMethodCharacterRepertoireKey</key>
  <array>
    <string>Latn</string>
  </array>
  <key>tsInputMethodScriptTypeKey</key>
  <string>smUnicodeScript</string>
</dict>
</plist>
PLIST

plutil -lint "$INFO_PLIST" >/dev/null
plutil -lint "$INPUT_METHOD_INFO_PLIST" >/dev/null
codesign --force --sign - "$INPUT_METHOD_BUNDLE" >/dev/null 2>&1
codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null 2>&1

open_app() {
    /usr/bin/open -n "$APP_BUNDLE"
}

verify_process() {
    for _ in {1..20}; do
        if pgrep -x "$APP_NAME" >/dev/null; then
            echo "$APP_NAME is running from $APP_BUNDLE"
            return 0
        fi
        sleep 0.25
    done

    echo "$APP_NAME did not start" >&2
    return 1
}

case "$MODE" in
    run)
        open_app
        ;;
    --build-only|build-only)
        echo "Built $APP_BUNDLE"
        ;;
    --debug|debug)
        lldb -- "$APP_BINARY"
        ;;
    --logs|logs)
        open_app
        /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
        ;;
    --telemetry|telemetry)
        open_app
        /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
        ;;
    --verify|verify)
        open_app
        verify_process
        ;;
    *)
        echo "usage: $0 [run|--build-only|--debug|--logs|--telemetry|--verify]" >&2
        exit 2
        ;;
esac
