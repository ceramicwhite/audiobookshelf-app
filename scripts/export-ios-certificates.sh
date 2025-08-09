#!/bin/bash

# Script to export iOS certificates and provisioning profiles for GitHub Actions
# Run this on your Mac where you have the certificates installed

echo "iOS Certificate Export Script for GitHub Actions"
echo "================================================"
echo ""
echo "This script will help you export your certificates and provisioning profiles"
echo "for use with GitHub Actions."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}This script must be run on macOS${NC}"
    exit 1
fi

# Create export directory
EXPORT_DIR="./ios-certificates-export"
mkdir -p "$EXPORT_DIR"

echo "Step 1: Finding your Team ID"
echo "----------------------------"
echo "Looking for Team ID in your provisioning profiles..."

# Try to find Team ID from existing provisioning profiles
TEAM_ID=$(security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision 2>/dev/null | grep -o '<key>TeamIdentifier</key>.*<string>[A-Z0-9]*</string>' | head -1 | sed 's/.*<string>\([A-Z0-9]*\)<\/string>/\1/')

if [ -n "$TEAM_ID" ]; then
    echo -e "${GREEN}Found Team ID: $TEAM_ID${NC}"
else
    echo -e "${YELLOW}Could not automatically find Team ID${NC}"
    echo "Please enter your Team ID (found in Apple Developer Portal):"
    read -r TEAM_ID
fi

echo ""
echo "Step 2: Export Distribution Certificate"
echo "---------------------------------------"
echo "Please enter a password for the P12 file (you'll use this in GitHub Secrets as P12_PASSWORD):"
read -s P12_PASSWORD
echo ""

# Find distribution certificate
CERT_NAME=$(security find-certificate -c "Apple Distribution" -p login.keychain | openssl x509 -noout -subject | sed 's/.*CN=\([^\/]*\).*/\1/' | head -1)

if [ -z "$CERT_NAME" ]; then
    echo -e "${YELLOW}No Apple Distribution certificate found. Trying iPhone Distribution...${NC}"
    CERT_NAME=$(security find-certificate -c "iPhone Distribution" -p login.keychain | openssl x509 -noout -subject | sed 's/.*CN=\([^\/]*\).*/\1/' | head -1)
fi

if [ -n "$CERT_NAME" ]; then
    echo -e "${GREEN}Found certificate: $CERT_NAME${NC}"
    
    # Export certificate
    security export -t identities -f pkcs12 -k login.keychain -P "$P12_PASSWORD" -o "$EXPORT_DIR/Certificates.p12"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Certificate exported successfully${NC}"
    else
        echo -e "${RED}Failed to export certificate. You may need to do this manually from Keychain Access${NC}"
        echo "Manual steps:"
        echo "1. Open Keychain Access"
        echo "2. Find your Apple Distribution certificate"
        echo "3. Right-click and select 'Export'"
        echo "4. Save as Certificates.p12 in $EXPORT_DIR"
    fi
else
    echo -e "${RED}No distribution certificate found${NC}"
    echo "Please export manually from Keychain Access"
fi

echo ""
echo "Step 3: Copy Provisioning Profile"
echo "---------------------------------"

# Find provisioning profile for the app
PROFILE_PATH=$(ls -t ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision 2>/dev/null | while read -r profile; do
    if security cms -D -i "$profile" 2>/dev/null | grep -q "com.audiobookscasa.app"; then
        echo "$profile"
        break
    fi
done)

if [ -n "$PROFILE_PATH" ] && [ -f "$PROFILE_PATH" ]; then
    cp "$PROFILE_PATH" "$EXPORT_DIR/Audiobookscasa.mobileprovision"
    echo -e "${GREEN}Provisioning profile copied${NC}"
    
    # Extract profile name for ExportOptions.plist
    PROFILE_NAME=$(security cms -D -i "$PROFILE_PATH" 2>/dev/null | grep -A1 '<key>Name</key>' | grep '<string>' | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    echo "Profile name: $PROFILE_NAME"
else
    echo -e "${YELLOW}Could not find provisioning profile for com.audiobookscasa.app${NC}"
    echo "Please download from Apple Developer Portal and place in $EXPORT_DIR"
fi

echo ""
echo "Step 4: Generate Base64 Encoded Secrets"
echo "---------------------------------------"

if [ -f "$EXPORT_DIR/Certificates.p12" ]; then
    CERT_BASE64=$(base64 -i "$EXPORT_DIR/Certificates.p12" | tr -d '\n')
    echo "BUILD_CERTIFICATE_BASE64 generated (${#CERT_BASE64} characters)"
    echo "$CERT_BASE64" > "$EXPORT_DIR/BUILD_CERTIFICATE_BASE64.txt"
fi

if [ -f "$EXPORT_DIR/Audiobookscasa.mobileprovision" ]; then
    PROFILE_BASE64=$(base64 -i "$EXPORT_DIR/Audiobookscasa.mobileprovision" | tr -d '\n')
    echo "BUILD_PROVISION_PROFILE_BASE64 generated (${#PROFILE_BASE64} characters)"
    echo "$PROFILE_BASE64" > "$EXPORT_DIR/BUILD_PROVISION_PROFILE_BASE64.txt"
fi

# Generate random keychain password
KEYCHAIN_PASSWORD=$(openssl rand -base64 32)
echo "$KEYCHAIN_PASSWORD" > "$EXPORT_DIR/KEYCHAIN_PASSWORD.txt"

echo ""
echo "Step 5: Update ExportOptions.plist"
echo "----------------------------------"

if [ -n "$TEAM_ID" ] && [ -n "$PROFILE_NAME" ]; then
    cat > "$EXPORT_DIR/ExportOptions.plist" <<EOF
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
    <string>Apple Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.audiobookscasa.app</key>
        <string>$PROFILE_NAME</string>
    </dict>
</dict>
</plist>
EOF
    echo -e "${GREEN}ExportOptions.plist created${NC}"
    echo "Copy this file to ios/App/ExportOptions.plist"
fi

echo ""
echo "================================================================"
echo -e "${GREEN}Export Complete!${NC}"
echo "================================================================"
echo ""
echo "Files created in: $EXPORT_DIR"
echo ""
echo "GitHub Secrets to add:"
echo "---------------------"
echo "1. BUILD_CERTIFICATE_BASE64: Use contents of BUILD_CERTIFICATE_BASE64.txt"
echo "2. P12_PASSWORD: The password you entered earlier"
echo "3. BUILD_PROVISION_PROFILE_BASE64: Use contents of BUILD_PROVISION_PROFILE_BASE64.txt"
echo "4. KEYCHAIN_PASSWORD: Use contents of KEYCHAIN_PASSWORD.txt"
echo ""
echo "For App Store Connect API (recommended):"
echo "5. APP_STORE_CONNECT_API_KEY_ID: Get from App Store Connect"
echo "6. APP_STORE_CONNECT_API_ISSUER_ID: Get from App Store Connect"
echo "7. APP_STORE_CONNECT_API_KEY_CONTENT: Base64 encoded .p8 key file"
echo ""
echo -e "${YELLOW}Important: Keep these files secure and delete them after adding to GitHub Secrets${NC}"