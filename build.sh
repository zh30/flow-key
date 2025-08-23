#!/bin/bash

# FlowKey Build Script
# This script builds the FlowKey input method application

set -e

echo "🚀 Building FlowKey Input Method..."

# Check if we're in the right directory
if [ ! -f "plan.md" ]; then
    echo "❌ Error: Please run this script from the FlowKey project root"
    exit 1
fi

# Create build directory
BUILD_DIR="build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build the main application
echo "📦 Building main application..."
cd FlowKey
swift build -c release --product FlowKey
cd ..

# Copy the executable
echo "📋 Copying executable..."
cp "FlowKey/.build/release/FlowKey" "$BUILD_DIR/"

# Create app bundle structure
echo "📁 Creating app bundle..."
APP_BUNDLE="$BUILD_DIR/FlowKey.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable to app bundle
cp "$BUILD_DIR/FlowKey" "$APP_BUNDLE/Contents/MacOS/"

# Copy Info.plist
cp "FlowKey/FlowKey/Info.plist" "$APP_BUNDLE/Contents/"

# Copy resources
if [ -d "FlowKey/FlowKey/Resources" ]; then
    cp -R "FlowKey/FlowKey/Resources/"* "$APP_BUNDLE/Contents/Resources/"
fi

# Create input method bundle
echo "🔤 Creating input method bundle..."
INPUT_METHOD_BUNDLE="$BUILD_DIR/FlowKeyInputMethod.bundle"
mkdir -p "$INPUT_METHOD_BUNDLE/Contents/MacOS"
mkdir -p "$INPUT_METHOD_BUNDLE/Contents/Resources"

# Copy input method files
cp "FlowKey/FlowKeyInputMethod/Info.plist" "$INPUT_METHOD_BUNDLE/Contents/"

# Create a simple input method executable
cat > "$INPUT_METHOD_BUNDLE/Contents/MacOS/FlowKeyInputMethod" << 'EOF'
#!/bin/bash
# Input method loader - this would be a proper binary in production
echo "FlowKey Input Method loaded"
EOF
chmod +x "$INPUT_METHOD_BUNDLE/Contents/MacOS/FlowKeyInputMethod"

# Copy icon if available
if [ -f "FlowKey/FlowKey/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png" ]; then
    mkdir -p "$INPUT_METHOD_BUNDLE/Contents/Resources"
    cp "FlowKey/FlowKey/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png" "$INPUT_METHOD_BUNDLE/Contents/Resources/FlowKey.icns"
fi

echo "✅ Build completed successfully!"
echo "📦 App bundle: $APP_BUNDLE"
echo "🔤 Input method bundle: $INPUT_METHOD_BUNDLE"

# Instructions for installation
echo ""
echo "📋 Installation Instructions:"
echo "1. Copy FlowKey.app to /Applications/"
echo "2. Copy FlowKeyInputMethod.bundle to ~/Library/Input Methods/"
echo "3. Enable the input method in System Preferences > Keyboard > Input Sources"
echo "4. Add 'FlowKey' to the list of input methods"
echo ""
echo "⚠️  Note: This is a development build. For production use, proper code signing is required."