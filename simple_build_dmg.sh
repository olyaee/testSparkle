#!/bin/bash

# Simple Build and DMG Script for testSparkle
# This is a simplified version for testing without signing requirements

set -e

# Configuration
APP_NAME="testSparkle"
SCHEME="testSparkle"
CONFIGURATION="Release"
BUILD_DIR="build"
DMG_NAME="${APP_NAME}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
echo_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
echo_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Clean and create build directory
echo_info "Preparing build directory..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Build the app
echo_info "Building ${APP_NAME}..."
xcodebuild -project "${APP_NAME}.xcodeproj" \
           -scheme "${SCHEME}" \
           -configuration "${CONFIGURATION}" \
           -derivedDataPath "${BUILD_DIR}/DerivedData" \
           build

if [ $? -ne 0 ]; then
    echo_error "Build failed"
    exit 1
fi

# Find the built app
APP_PATH="${BUILD_DIR}/DerivedData/Build/Products/${CONFIGURATION}/${APP_NAME}.app"

if [ ! -d "${APP_PATH}" ]; then
    echo_error "Built app not found at ${APP_PATH}"
    exit 1
fi

echo_info "App built successfully at ${APP_PATH}"

# Check if create-dmg is available
if ! command -v create-dmg >/dev/null 2>&1; then
    echo_warning "create-dmg not found. Creating simple DMG with hdiutil..."
    
    # Create a temporary directory for DMG contents
    DMG_TEMP_DIR="${BUILD_DIR}/dmg_temp"
    mkdir -p "${DMG_TEMP_DIR}"
    
    # Copy app to temp directory
    cp -R "${APP_PATH}" "${DMG_TEMP_DIR}/"
    
    # Create Applications symlink
    ln -s /Applications "${DMG_TEMP_DIR}/Applications"
    
    # Create DMG with hdiutil
    echo_info "Creating DMG with hdiutil..."
    hdiutil create -volname "${APP_NAME}" \
                   -srcfolder "${DMG_TEMP_DIR}" \
                   -ov -format UDZO \
                   "${BUILD_DIR}/${DMG_NAME}.dmg"
    
    # Clean up temp directory
    rm -rf "${DMG_TEMP_DIR}"
else
    echo_info "Creating DMG with create-dmg..."
    
    # Copy app to build directory for create-dmg
    cp -R "${APP_PATH}" "${BUILD_DIR}/"
    
    create-dmg \
        --volname "${APP_NAME}" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 175 120 \
        --hide-extension "${APP_NAME}.app" \
        --app-drop-link 425 120 \
        "${BUILD_DIR}/${DMG_NAME}.dmg" \
        "${BUILD_DIR}"
fi

if [ $? -eq 0 ]; then
    echo_info "✅ DMG created successfully!"
    echo_info "📦 DMG location: ${BUILD_DIR}/${DMG_NAME}.dmg"
    echo_info "📏 DMG size: $(du -h "${BUILD_DIR}/${DMG_NAME}.dmg" | cut -f1)"
    
    # Open build directory if on macOS
    if [[ "$OSTYPE" == "darwin"* ]] && command -v open >/dev/null 2>&1; then
        echo_info "Opening build directory..."
        open "${BUILD_DIR}"
    fi
else
    echo_error "DMG creation failed"
    exit 1
fi

echo_info "Done!"