# GitHub Secrets Setup for iOS TestFlight Deployment

This guide explains how to configure the necessary GitHub secrets for the automated iOS build and TestFlight deployment workflow.

## Required Secrets

### 1. Apple App Store Connect API Key (Recommended)

For the most reliable authentication, use App Store Connect API:

1. **APP_STORE_CONNECT_API_KEY_ID**
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Navigate to Users and Access → Keys
   - Create a new key with "App Manager" role
   - Copy the Key ID

2. **APP_STORE_CONNECT_API_ISSUER_ID**
   - Found on the same Keys page
   - Copy the Issuer ID (same for all keys in your account)

3. **APP_STORE_CONNECT_API_KEY_CONTENT**
   - Download the .p8 key file (can only be downloaded once!)
   - Encode it as base64: `base64 -i AuthKey_XXXXXX.p8 | tr -d '\n'`
   - Store the base64 string as this secret

### 2. Alternative: Apple ID Authentication

If not using API key, configure these:

- **FASTLANE_USER**: Your Apple ID email
- **FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD**: 
  - Generate at [appleid.apple.com](https://appleid.apple.com)
  - Sign in → Security → App-Specific Passwords → Generate

### 3. Code Signing with Match (Optional but Recommended)

If using Fastlane Match for certificate management:

- **MATCH_GIT_URL**: URL to your private certificates repository
- **MATCH_PASSWORD**: Password to decrypt certificates
- **MATCH_GIT_BASIC_AUTHORIZATION**: Base64 encoded "username:personal_access_token"
  - Create with: `echo -n "username:token" | base64`

### 4. App Configuration

- **APP_APPLE_ID**: Your app's Apple ID (found in App Store Connect)
  - Example: "1234567890"

### 5. Optional Notifications

- **SLACK_WEBHOOK_URL**: For deployment notifications (optional)

## Setting Up Secrets in GitHub

1. Go to your repository on GitHub
2. Navigate to Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add each secret with the exact name and value

## Manual Code Signing Setup (Without Match)

If not using Match, you'll need to:

1. Export your certificates and provisioning profiles from Xcode
2. Convert to base64:
   ```bash
   base64 -i certificate.p12 | tr -d '\n'
   base64 -i profile.mobileprovision | tr -d '\n'
   ```
3. Store as secrets:
   - **BUILD_CERTIFICATE_BASE64**
   - **P12_PASSWORD**
   - **BUILD_PROVISION_PROFILE_BASE64**

4. Update the Fastfile to use manual signing instead of Match

## Testing the Workflow

1. **Manual Trigger**:
   - Go to Actions tab in GitHub
   - Select "Sync Upstream and Deploy to TestFlight"
   - Click "Run workflow"
   - Optionally check "Force deploy" to test without upstream changes

2. **Automatic Runs**:
   - Workflow runs daily at 2 AM UTC
   - Only deploys when upstream changes are detected

## Troubleshooting

- **Merge Conflicts**: If the workflow fails due to merge conflicts, you'll need to resolve them manually
- **Signing Issues**: Ensure your provisioning profile matches the bundle ID (com.audiobookscasa.app)
- **Build Numbers**: The workflow automatically generates unique build numbers using timestamps

## Security Notes

- Never commit sensitive information to the repository
- Rotate API keys periodically
- Use repository secrets, not organization secrets, for better security isolation
- Consider using environment protection rules for production deployments