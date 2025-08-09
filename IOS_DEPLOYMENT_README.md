# iOS Automated Deployment Setup

This guide helps you set up automated iOS builds and TestFlight deployment for your forked Audiobookshelf app.

## Overview

The workflow automatically:
1. Checks for upstream changes daily at 2 AM UTC
2. Merges changes from the original repository
3. Builds the iOS app with your custom bundle ID
4. Deploys to TestFlight for internal testing

## Prerequisites

- Apple Developer Account with App Store Connect access
- iOS app created in App Store Connect with bundle ID: `com.audiobookscasa.app`
- Distribution certificate and provisioning profile

## Quick Setup

### Step 1: Export Certificates (Run on your Mac)

```bash
# Run the export script
./scripts/export-ios-certificates.sh
```

This will create an `ios-certificates-export` folder with all necessary files.

### Step 2: Create App Store Connect API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **Users and Access** → **Keys**
3. Click **+** to create a new key
4. Select **App Manager** role
5. Download the `.p8` file (⚠️ Can only be downloaded once!)
6. Note the **Key ID** and **Issuer ID**

### Step 3: Add GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:

#### Required Secrets

| Secret Name | Description | How to Get |
|------------|-------------|------------|
| `BUILD_CERTIFICATE_BASE64` | Base64 encoded .p12 certificate | From export script |
| `P12_PASSWORD` | Password for the .p12 file | You set during export |
| `BUILD_PROVISION_PROFILE_BASE64` | Base64 encoded provisioning profile | From export script |
| `KEYCHAIN_PASSWORD` | Random password for temporary keychain | From export script |
| `APP_STORE_CONNECT_API_KEY_ID` | API Key ID | From App Store Connect |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Issuer ID | From App Store Connect |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Base64 encoded .p8 file | `base64 -i AuthKey_XXX.p8 \| tr -d '\n'` |

### Step 4: Update ExportOptions.plist

Copy the generated `ExportOptions.plist` from the export folder to:
```
ios/App/ExportOptions.plist
```

### Step 5: Test the Workflow

1. Go to **Actions** tab in your GitHub repository
2. Select **"Sync and Deploy iOS (Simplified)"**
3. Click **"Run workflow"**
4. Check **"Force deploy"** to test without waiting for upstream changes
5. Click **"Run workflow"**

## Workflow Options

### Two Workflows Available

1. **sync-and-deploy-ios-simple.yml** (Recommended)
   - Simpler setup
   - Uses manual certificate management
   - Better for getting started

2. **sync-and-deploy-ios.yml**
   - Uses Fastlane for more control
   - Requires additional Fastlane setup
   - Better for advanced users

### Manual Trigger

You can manually trigger the workflow anytime:
1. Go to Actions → Select workflow
2. Click "Run workflow"
3. Optionally check "Force deploy" to skip upstream check

### Schedule

The workflow runs automatically:
- Daily at 2 AM UTC
- Only deploys when upstream changes are detected
- Creates a git tag for each deployment

## Troubleshooting

### Common Issues

1. **Merge Conflicts**
   - The workflow will fail if there are conflicts
   - Manually resolve conflicts and push to master
   - Re-run the workflow

2. **Certificate Issues**
   ```
   error: No certificate for team 'XXX' matching 'Apple Distribution'
   ```
   - Ensure your certificate is properly exported
   - Check the P12_PASSWORD is correct
   - Verify the provisioning profile matches your certificate

3. **App Store Connect Issues**
   ```
   error: App Store Connect API key not found
   ```
   - Verify all three API key secrets are set correctly
   - Ensure the .p8 file is properly base64 encoded
   - Check the API key has "App Manager" role

### Verify Setup Locally

Test your certificates locally:
```bash
# Check certificate
security find-identity -v -p codesigning

# Check provisioning profile
ls ~/Library/MobileDevice/Provisioning\ Profiles/
```

### View Workflow Logs

1. Go to Actions tab
2. Click on a workflow run
3. Click on the job to see detailed logs

## Maintaining Your Fork

### Handling Upstream Changes

The workflow automatically handles most updates, but sometimes you may need to:

1. **Resolve conflicts manually**:
   ```bash
   git fetch upstream
   git merge upstream/master
   # Resolve conflicts
   git push origin master
   ```

2. **Keep your customizations**:
   - Your bundle ID changes are preserved
   - Add custom changes to a separate commit after merging

### Version Management

- Version numbers are synced from upstream `package.json`
- Build numbers are auto-generated timestamps
- Each deployment creates a git tag: `v{version}-build{timestamp}`

## Security Best Practices

1. **Rotate API Keys**: Regenerate App Store Connect API keys every 6 months
2. **Protect Secrets**: Never commit certificates or keys to the repository
3. **Use Environment Protection**: Consider adding approval requirements for production
4. **Monitor Deployments**: Set up notifications for deployment status

## Support

- Check workflow runs in the Actions tab for detailed logs
- Review `GITHUB_SECRETS_SETUP.md` for detailed secret configuration
- For upstream issues, check the [original repository](https://github.com/advplyr/audiobookshelf-app)

## Next Steps

After successful setup:
1. ✅ Workflow runs daily and syncs changes
2. ✅ iOS app builds automatically
3. ✅ TestFlight receives new builds
4. ✅ Internal testers get updates automatically

Consider:
- Setting up Slack/Discord notifications
- Adding external TestFlight testers
- Customizing the changelog for each build
- Setting up production deployment workflow