# Sparkle Framework Setup Guide for macOS Apps

## Overview
Sparkle is an open-source software update framework for macOS applications that enables automatic updates with security features like EdDSA signatures and sandboxing support.

## Prerequisites
- macOS 10.13 or later (runtime)
- Latest Xcode (stable or beta)
- HTTPS server for serving updates
- GitHub repository (for this guide's distribution method)

## Step-by-Step Setup

### 1. Repository and GitHub Pages Setup
1. Create a GitHub repository for your app distribution
2. Go to **Settings** → **Pages**
3. Set source to **Main branch** and **Root folder**
4. Wait ~1 minute for deployment
5. Copy the GitHub Pages URL (e.g., `https://olyaee.github.io/testSparkle`)

### 2. Add Sparkle Package to Project
1. In Xcode, add Swift Package: `https://github.com/sparkle-project/Sparkle`
2. Navigate to **SourcePackages** → **artifacts** → **Sparkle** → **Bin**
3. Run `generate_keys` to create EdDSA key pair
4. Save the generated public key for Info.plist configuration

### 3. Info.plist Configuration
Add these keys to your app's Info.plist:

```xml
<key>SUEnableInstallerLauncherService</key>
<true/>
<key>SUFeedURL</key>
<string>https://olyaee.github.io/testSparkle/appcast.xml</string>
<key>SUPublicEDKey</key>
<string>758Lgr0SYTf5oW+qehB8DGLJ0YA9/HqFaXpmr5DiKgg=</string>
```

**Note**: For sandboxed apps, also add:
```xml
<key>SUEnableDownloaderService</key>
<false/>
```

### 4. Entitlements File Setup
Create or modify your entitlements file (`File` → `New` → `macOS` → `Resource` → `Property List`):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Optional: keep if you sandbox the app -->
    <key>com.apple.security.app-sandbox</key>
    <true/>
    
    <!-- Required for network access -->
    <key>com.apple.security.network.client</key>
    <true/>
    
    <!-- Required for Sparkle XPC services -->
    <key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
    <array>
        <string>$(PRODUCT_BUNDLE_IDENTIFIER)-spks</string>
        <string>$(PRODUCT_BUNDLE_IDENTIFIER)-spki</string>
    </array>
</dict>
</plist>
```

### 5. Signing & Capabilities
In Xcode project settings → **Signing & Capabilities**:
- Add **Incoming Connections (Server)**
- Add **Outgoing Connections (Client)**

### 6. Build and Release Preparation
1. Build your app and create a DMG file
2. Create a GitHub release with your DMG file
3. Right-click the DMG → **Copy Link** to get the download URL

### 7. Generate Appcast.xml
Run the generate_appcast tool to create the appcast file with proper signatures:

```bash
/Users/ehsanolyaee/Library/Developer/Xcode/DerivedData/testSparkle-{hash}/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast /path/to/your/releases/folder/
```

Example:
```bash
/Users/ehsanolyaee/Library/Developer/Xcode/DerivedData/testSparkle-ccaurpzylufeyxaczvttsufdtdko/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast releases
```

### 8. Upload and Deploy
1. Upload the generated `appcast.xml` to your GitHub repository root
2. Ensure the GitHub Pages site is serving the appcast.xml file
3. Verify the SUFeedURL in Info.plist matches your appcast location

## Testing Updates
1. Open your app
2. Go to **File** → **Check for Updates**
3. If configured correctly, it should report "You are up to date"

## Important Notes
- **Security**: Never commit private keys to your repository
- **Versioning**: Always increment build numbers for updates
- **HTTPS**: Use HTTPS URLs for all update feeds
- **Code Signing**: Sign XPC services individually, never use `--deep`
- **Bundle IDs**: Never change Sparkle's XPC service bundle IDs

## Troubleshooting
- Ensure your app has network entitlements if sandboxed
- Verify appcast.xml is accessible via the SUFeedURL
- Check that the public key in Info.plist matches the generated key pair
- Confirm entitlements include both `-spks` and `-spki` exceptions

This setup enables secure, automatic updates for your macOS app using the latest Sparkle 2 framework features.

---

## Actual Release and Testing Workflow

### Commands Used in testSparkle Project

#### 1. Initial Analysis
```bash
# Check project structure
ls -la
find . -name "*.plist" -o -name "*.entitlements"

# Check current app version
plutil -p testSparkle.app/Contents/Info.plist | grep -E "(CFBundleShortVersionString|CFBundleVersion)"
# Result: Version 0.9
```

#### 2. Fix Entitlements File
**Critical Fix**: Added missing Sparkle XPC service exceptions to `testSparkle/testSparkle.entitlements`:

```xml
<key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
<array>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)-spks</string>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)-spki</string>
</array>
```

#### 3. Build New Release Version
```bash
# Build version 1.0 using existing build script
./build_and_sign_dmg.sh 1.0

# Verify new version was built
plutil -p build/export/testSparkle.app/Contents/Info.plist | grep -E "(CFBundleShortVersionString|CFBundleVersion)"
# Result: Version 1.0
```

#### 4. Prepare Release Files
```bash
# Check build results
ls -la build/
ls -la releases/

# Copy new DMG to releases with version-specific name
cp build/testSparkle.dmg releases/testSparkle-1.0.dmg
```

#### 5. Generate Updated Appcast
```bash
# Find Sparkle's generate_appcast tool
find ~/Library/Developer/Xcode/DerivedData -name "generate_appcast" -type f 2>/dev/null | head -5

# Generate appcast with version 1.0 and delta updates
/Users/ehsanolyaee/Library/Developer/Xcode/DerivedData/testSparkle-ccaurpzylufeyxaczvttsufdtdko/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast releases/

# Output: "Wrote 1 new update, updated 1 existing update, and removed 0 old updates in appcast.xml"
```

**Results**:
- Updated `appcast.xml` with version 1.0
- Created delta update file: `testSparkle1.0-0.9.delta` (only 9KB instead of 887KB full download)
- Generated EdDSA signatures for security

#### 6. Deploy to GitHub Pages
```bash
# Add release files to git
git add releases/

# Check what's being committed
git status

# Commit changes
git commit -m "Add version 1.0 release with delta update - Updated appcast.xml with new version and delta patch"

# Push to GitHub (auto-deploys to GitHub Pages)
git push
```

#### 7. Test Auto-Update
```bash
# Check code signing status
codesign -dv testSparkle.app
spctl -a -v build/export/testSparkle.app

# Launch the new version for testing
open build/export/testSparkle.app
```

#### 8. Verify Final Setup
```bash
# Check all release files are present
ls -la releases/
# Shows:
# - appcast.xml (updated with v1.0)
# - testSparkle-1.0.dmg (new version)
# - testSparkle.dmg (original v0.9)
# - testSparkle1.0-0.9.delta (delta update)
```

### Live URLs After Deployment
- Appcast: `https://olyaee.github.io/testSparkle/releases/appcast.xml`
- v1.0 DMG: `https://olyaee.github.io/testSparkle/releases/testSparkle-1.0.dmg`
- Delta file: `https://olyaee.github.io/testSparkle/releases/testSparkle1.0-0.9.delta`

### Testing Results
- ✅ Version 1.0 app launches successfully
- ✅ Appcast.xml properly formatted with delta updates
- ✅ EdDSA signatures generated for security
- ✅ Files deployed to GitHub Pages
- ✅ Auto-update system ready for testing

### For Future Updates
To create version 1.1 and test actual update functionality:

```bash
# Build new version
./build_and_sign_dmg.sh 1.1

# Copy to releases
cp build/testSparkle.dmg releases/testSparkle-1.1.dmg

# Generate updated appcast
/path/to/generate_appcast releases/

# Commit and push
git add releases/
git commit -m "Release version 1.1"
git push
```

Then open version 1.0 and use **File** → **Check for Updates** to see the update to 1.1.