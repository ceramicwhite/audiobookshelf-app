#!/bin/bash
set -e

# This script handles iOS building for CI/CD with proper code signing

echo "🔨 Starting iOS CI Build..."

# Navigate to iOS directory
cd ios/App

# Extract provisioning profile information
PROFILE_PATH=$(ls ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision | head -1)
if [ -z "$PROFILE_PATH" ]; then
    echo "❌ No provisioning profile found"
    exit 1
fi

PROFILE_UUID=$(security cms -D -i "$PROFILE_PATH" | grep -A1 'UUID' | grep '<string>' | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
PROFILE_NAME=$(security cms -D -i "$PROFILE_PATH" | grep -A1 '<key>Name</key>' | grep '<string>' | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
TEAM_ID=$(security cms -D -i "$PROFILE_PATH" | grep -A1 '<key>TeamIdentifier</key>' -A2 | grep '<string>' | head -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')

echo "📱 Profile: $PROFILE_NAME"
echo "🆔 UUID: $PROFILE_UUID"
echo "👥 Team: $TEAM_ID"

# Find the signing certificate
CERT_NAME=$(security find-identity -v -p codesigning | grep "Apple Distribution" | head -1 | sed 's/.*"\(.*\)".*/\1/')
if [ -z "$CERT_NAME" ]; then
    echo "❌ No Apple Distribution certificate found"
    exit 1
fi
echo "📜 Certificate: $CERT_NAME"

# Clean build folder
echo "🧹 Cleaning build folders..."
rm -rf ~/Library/Developer/Xcode/DerivedData

# Use the latest available iOS SDK
IOS_SDK=$(xcodebuild -showsdks | grep iphoneos | tail -1 | awk '{print $NF}' || echo "iphoneos")
echo "📱 Using iOS SDK: $IOS_SDK"

xcodebuild clean -workspace App.xcworkspace -scheme App -sdk "$IOS_SDK" -quiet

# Build the archive without signing (to avoid Pod signing issues)
echo "🏗️ Building archive without signing..."
xcodebuild archive \
    -workspace App.xcworkspace \
    -scheme App \
    -configuration Release \
    -archivePath "$RUNNER_TEMP/Audiobookscasa.xcarchive" \
    -sdk "$IOS_SDK" \
    -quiet \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    ONLY_ACTIVE_ARCH=NO

# Check if archive was created
if [ ! -d "$RUNNER_TEMP/Audiobookscasa.xcarchive" ]; then
    echo "❌ Archive creation failed"
    exit 1
fi

echo "✅ Archive created successfully"

# Sign the app in the archive
echo "🔏 Signing the app..."
/usr/bin/codesign --force --sign "$CERT_NAME" \
    --entitlements App/App.entitlements \
    --timestamp \
    "$RUNNER_TEMP/Audiobookscasa.xcarchive/Products/Applications/Audiobookshelf.app"

if [ $? -ne 0 ]; then
    echo "❌ Code signing failed"
    exit 1
fi

echo "✅ App signed successfully"

# Create export options dynamically
echo "📝 Creating export options..."
cat > "$RUNNER_TEMP/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>$CERT_NAME</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.audiobookscasa.app</key>
        <string>$PROFILE_UUID</string>
    </dict>
</dict>
</plist>
EOF

# Export the IPA
echo "📦 Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath "$RUNNER_TEMP/Audiobookscasa.xcarchive" \
    -exportPath "$RUNNER_TEMP/export" \
    -exportOptionsPlist "$RUNNER_TEMP/ExportOptions.plist" \
    -quiet

# Check if IPA was created
if [ ! -f "$RUNNER_TEMP/export/App.ipa" ]; then
    echo "❌ IPA export failed"
    exit 1
fi

echo "✅ IPA exported successfully to $RUNNER_TEMP/export/App.ipa"
echo "🎉 iOS build completed successfully!"