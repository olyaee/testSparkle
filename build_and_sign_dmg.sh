#!/bin/bash

# Build and Sign DMG Script for testSparkle
# This script builds the app, creates a DMG, and signs everything
#
# Usage: ./build_and_sign_dmg.sh <version>
# Example: ./build_and_sign_dmg.sh 1.3.0

set -e  # Exit on any error

# Configuration
APP_NAME="testSparkle"
SCHEME="testSparkle"
CONFIGURATION="Release"
DEVELOPER_ID="L34TH4QX2W"  # Your development team ID
SIGNING_IDENTITY="Developer ID Application: ehsan Olyaee (${DEVELOPER_ID})"
BUILD_DIR="build"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"
RELEASES_DIR="releases"

# Version management
NEW_VERSION=${1}  # Version provided by user (e.g., 1.3.0)
PROJECT_FILE="${APP_NAME}.xcodeproj/project.pbxproj"
INFO_PLIST_FILE="${APP_NAME}/Info.plist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get current version from Xcode project
get_current_version() {
    grep -A1 "MARKETING_VERSION" "${PROJECT_FILE}" | grep -o '[0-9]\+\.[0-9]\+' | head -1
}


# Function to update version in project file
update_project_version() {
    local new_version=$1
    echo_info "Updating project version to ${new_version}"
    
    # Update MARKETING_VERSION (handle both X.Y and X.Y.Z formats)
    sed -i.bak "s/MARKETING_VERSION = [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*;/MARKETING_VERSION = ${new_version};/g" "${PROJECT_FILE}"
    sed -i.bak "s/MARKETING_VERSION = [0-9][0-9]*\.[0-9][0-9]*;/MARKETING_VERSION = ${new_version};/g" "${PROJECT_FILE}"
    
    # Update CURRENT_PROJECT_VERSION (handle both X.Y and X.Y.Z formats)
    sed -i.bak "s/CURRENT_PROJECT_VERSION = [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*;/CURRENT_PROJECT_VERSION = ${new_version};/g" "${PROJECT_FILE}"
    sed -i.bak "s/CURRENT_PROJECT_VERSION = [0-9][0-9]*\.[0-9][0-9]*;/CURRENT_PROJECT_VERSION = ${new_version};/g" "${PROJECT_FILE}"
    
    # Remove backup file
    rm -f "${PROJECT_FILE}.bak"
}


# Check required tools
echo_info "Checking required tools..."
if ! command_exists xcodebuild; then
    echo_error "xcodebuild not found. Make sure Xcode is installed."
    exit 1
fi

if ! command_exists create-dmg; then
    echo_warning "create-dmg not found. Installing via Homebrew..."
    if command_exists brew; then
        brew install create-dmg
    else
        echo_error "Homebrew not found. Please install create-dmg manually or install Homebrew."
        echo_error "Install create-dmg with: brew install create-dmg"
        exit 1
    fi
fi

# Version management
if [ -z "$NEW_VERSION" ]; then
    echo_error "Usage: $0 <version>"
    echo_error "Example: $0 1.3.0"
    exit 1
fi

echo_info "Setting version to: ${NEW_VERSION}"
CURRENT_VERSION=$(get_current_version)
echo_info "Current version: ${CURRENT_VERSION:-"unknown"}"

# Set up versioned paths
DMG_NAME="${APP_NAME}-${NEW_VERSION}"
DMG_PATH="${BUILD_DIR}/${DMG_NAME}.dmg"
VERSION_DIR="${RELEASES_DIR}/${NEW_VERSION}"

# Validate version format
if ! [[ "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    echo_error "Invalid version format. Use format: major.minor or major.minor.patch"
    echo_error "Examples: 1.3, 1.3.0, 2.0.1"
    exit 1
fi

# Update version in project file (Xcode will auto-generate Info.plist)
update_project_version "$NEW_VERSION"

# Clean previous build
echo_info "Cleaning previous build..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
mkdir -p "${EXPORT_PATH}"

# Archive the app
echo_info "Archiving ${APP_NAME}..."
xcodebuild archive \
    -project "${APP_NAME}.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -archivePath "${ARCHIVE_PATH}" \
    -destination "generic/platform=macOS" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="${SIGNING_IDENTITY}" \
    DEVELOPMENT_TEAM="${DEVELOPER_ID}"

if [ $? -ne 0 ]; then
    echo_error "Archive failed"
    exit 1
fi

# Export the app
echo_info "Exporting ${APP_NAME}..."
cat > "${BUILD_DIR}/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>${DEVELOPER_ID}</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>stripSwiftSymbols</key>
    <true/>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportPath "${EXPORT_PATH}" \
    -exportOptionsPlist "${BUILD_DIR}/ExportOptions.plist"

if [ $? -ne 0 ]; then
    echo_error "Export failed"
    exit 1
fi

# Verify the exported app exists
APP_PATH="${EXPORT_PATH}/${APP_NAME}.app"
if [ ! -d "${APP_PATH}" ]; then
    echo_error "Exported app not found at ${APP_PATH}"
    exit 1
fi

echo_info "App exported successfully to ${APP_PATH}"

# Verify code signing
echo_info "Verifying code signing..."
codesign --verify --deep --strict --verbose=2 "${APP_PATH}"
if [ $? -eq 0 ]; then
    echo_info "Code signing verification passed"
else
    echo_error "Code signing verification failed"
    exit 1
fi

# Create DMG
echo_info "Creating DMG..."
create-dmg \
    --volname "${APP_NAME}" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "${APP_NAME}.app" 175 120 \
    --hide-extension "${APP_NAME}.app" \
    --app-drop-link 425 120 \
    "${DMG_PATH}" \
    "${EXPORT_PATH}"

if [ $? -ne 0 ]; then
    echo_error "DMG creation failed"
    exit 1
fi

# Sign the DMG
echo_info "Signing DMG..."
codesign --sign "${SIGNING_IDENTITY}" --verbose "${DMG_PATH}"

if [ $? -ne 0 ]; then
    echo_error "DMG signing failed"
    exit 1
fi

# Verify DMG signing
echo_info "Verifying DMG signature..."
codesign --verify --deep --strict --verbose=2 "${DMG_PATH}"
if [ $? -eq 0 ]; then
    echo_info "DMG signing verification passed"
else
    echo_error "DMG signing verification failed"
    exit 1
fi

# Final verification
echo_info "Running final spctl verification..."
spctl --assess --type install "${DMG_PATH}"
if [ $? -eq 0 ]; then
    echo_info "Gatekeeper verification passed"
else
    echo_warning "Gatekeeper verification failed - the DMG may not be notarized"
fi

# Prepare versioned release
echo_info "Preparing versioned release..."
mkdir -p "${VERSION_DIR}"
cp "${DMG_PATH}" "${VERSION_DIR}/"
echo_info "DMG copied to: ${VERSION_DIR}/${DMG_NAME}.dmg"

# Generate appcast for all releases
echo_info "Generating appcast..."
SPARKLE_BIN="/Users/ehsanolyaee/Library/Developer/Xcode/DerivedData/testSparkle-ccaurpzylufeyxaczvttsufdtdko/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast"
if [ -f "${SPARKLE_BIN}" ]; then
    "${SPARKLE_BIN}" "${RELEASES_DIR}"
    echo_info "Appcast generated at: ${RELEASES_DIR}/appcast.xml"
else
    echo_warning "Sparkle generate_appcast tool not found. Please generate appcast manually."
fi

# Success
echo_info "✅ Build and signing completed successfully!"
echo_info "📦 DMG created at: ${DMG_PATH}"
echo_info "📏 DMG size: $(du -h "${DMG_PATH}" | cut -f1)"
echo_info "🚀 Release prepared at: ${VERSION_DIR}/"
echo_info "📋 Ready for upload to: https://olyaee.github.io/testSparkle/releases/"

# Optional: Open the releases directory
if command_exists open; then
    echo_info "Opening releases directory..."
    open "${RELEASES_DIR}"
fi

echo_info "Done!"