#!/bin/bash

# Simple script to encode certificates after manual export

echo "Certificate Base64 Encoder"
echo "========================="
echo ""

# Check if the export directory exists
if [ ! -d "ios-certificates-export" ]; then
    mkdir -p ios-certificates-export
    echo "Created ios-certificates-export directory"
fi

echo "Please ensure you have:"
echo "1. Certificates.p12 in ios-certificates-export/"
echo "2. Your .mobileprovision file in ios-certificates-export/"
echo ""
echo "Press Enter to continue..."
read

# Encode certificate
if [ -f "ios-certificates-export/Certificates.p12" ]; then
    base64 -i ios-certificates-export/Certificates.p12 | tr -d '\n' > ios-certificates-export/BUILD_CERTIFICATE_BASE64.txt
    echo "✅ Created BUILD_CERTIFICATE_BASE64.txt"
else
    echo "❌ Certificates.p12 not found in ios-certificates-export/"
fi

# Find and encode provisioning profile
PROFILE=$(ls ios-certificates-export/*.mobileprovision 2>/dev/null | head -1)
if [ -n "$PROFILE" ]; then
    base64 -i "$PROFILE" | tr -d '\n' > ios-certificates-export/BUILD_PROVISION_PROFILE_BASE64.txt
    echo "✅ Created BUILD_PROVISION_PROFILE_BASE64.txt"
    
    # Extract profile name
    PROFILE_NAME=$(security cms -D -i "$PROFILE" 2>/dev/null | grep -A1 '<key>Name</key>' | grep '<string>' | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    echo "   Profile name: $PROFILE_NAME"
else
    echo "❌ No .mobileprovision file found in ios-certificates-export/"
fi

# Generate keychain password
openssl rand -base64 32 > ios-certificates-export/KEYCHAIN_PASSWORD.txt
echo "✅ Created KEYCHAIN_PASSWORD.txt"

# Update ExportOptions.plist with the profile name if found
if [ -n "$PROFILE_NAME" ]; then
    cat > ios-certificates-export/ExportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>4PA2S8A753</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Apple Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.audiobookscasa.app</key>
        <string>$PROFILE_NAME</string>
    </dict>
</dict>
</plist>
EOF
    echo "✅ Created ExportOptions.plist"
    echo "   Copy this to ios/App/ExportOptions.plist"
fi

echo ""
echo "================================"
echo "✅ Encoding Complete!"
echo "================================"
echo ""
echo "GitHub Secrets to add:"
echo "1. BUILD_CERTIFICATE_BASE64 - from BUILD_CERTIFICATE_BASE64.txt"
echo "2. P12_PASSWORD - the password you used when exporting"
echo "3. BUILD_PROVISION_PROFILE_BASE64 - from BUILD_PROVISION_PROFILE_BASE64.txt"
echo "4. KEYCHAIN_PASSWORD - from KEYCHAIN_PASSWORD.txt"
echo ""
echo "Files are in: ios-certificates-export/"