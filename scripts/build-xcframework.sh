#!/bin/bash

# DevLogCapture XCFramework Build Script
# This script builds a universal XCFramework that works on both iOS devices and simulators

set -e

FRAMEWORK_NAME="DevLogCapture"
PROJECT_NAME="DevLogCapture.xcodeproj"
SCHEME_NAME="DevLogCapture"
BUILD_DIR="build"
OUTPUT_DIR="."

echo "🚀 Building ${FRAMEWORK_NAME} XCFramework..."

# Clean up previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "${BUILD_DIR}"
rm -rf "${FRAMEWORK_NAME}.xcframework"

# Create build directory
mkdir -p "${BUILD_DIR}"

echo "📱 Building for iOS Device..."
xcodebuild archive \
  -project "${PROJECT_NAME}" \
  -scheme "${SCHEME_NAME}" \
  -destination "generic/platform=iOS" \
  -archivePath "${BUILD_DIR}/ios.xcarchive" \
  -derivedDataPath "${BUILD_DIR}/DerivedData" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  ONLY_ACTIVE_ARCH=NO

echo "📱 Building for iOS Simulator..."
xcodebuild archive \
  -project "${PROJECT_NAME}" \
  -scheme "${SCHEME_NAME}" \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "${BUILD_DIR}/ios-simulator.xcarchive" \
  -derivedDataPath "${BUILD_DIR}/DerivedData" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  ONLY_ACTIVE_ARCH=NO

echo "📦 Creating XCFramework..."
xcodebuild -create-xcframework \
  -framework "${BUILD_DIR}/ios.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
  -framework "${BUILD_DIR}/ios-simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
  -output "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"

echo "✅ Successfully created ${FRAMEWORK_NAME}.xcframework!"
echo ""
echo "📋 Next steps:"
echo "1. Drag ${FRAMEWORK_NAME}.xcframework into your Xcode project"
echo "2. Add it to your target's 'Frameworks, Libraries, and Embedded Content'"
echo "3. Set it to 'Embed & Sign'"
echo "4. Import the framework: import ${FRAMEWORK_NAME}"
echo ""
echo "📁 Build artifacts:"
echo "   - ${FRAMEWORK_NAME}.xcframework (Universal framework)"
echo "   - ${BUILD_DIR}/ (Build intermediates - can be deleted)"

# Optional: Clean up build intermediates
read -p "🗑️  Delete build intermediates? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "${BUILD_DIR}"
    echo "✅ Build intermediates cleaned up!"
fi

echo "🎉 Build complete!"
