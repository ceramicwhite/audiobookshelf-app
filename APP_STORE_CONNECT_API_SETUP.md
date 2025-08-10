# App Store Connect API Key Setup

## Creating an App Store Connect API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **Users and Access**
3. Select **Keys** tab under **Integrations**
4. Click the **+** button to create a new key
5. Give it a name (e.g., "GitHub Actions CI/CD")
6. Select the access level: **App Manager** (minimum required for TestFlight uploads)
7. Click **Generate**

## Important Information to Save

After creating the key, you'll need to save three pieces of information:

1. **Key ID**: Shown in the keys list (e.g., `ABC123DEF4`)
2. **Issuer ID**: Shown at the top of the API Keys page (e.g., `12345678-1234-1234-1234-123456789012`)
3. **Private Key (.p8 file)**: Download this immediately - you can only download it once!

## Preparing the Private Key for GitHub Secrets

The private key needs to be base64 encoded:

```bash
# Base64 encode the .p8 file
base64 -i AuthKey_ABC123DEF4.p8 | tr -d '\n' > APP_STORE_CONNECT_API_KEY_CONTENT.txt
```

## GitHub Secrets to Add

Add these secrets to your GitHub repository:

1. **APP_STORE_CONNECT_API_KEY_ID**: The Key ID from App Store Connect
2. **APP_STORE_CONNECT_API_ISSUER_ID**: The Issuer ID from App Store Connect  
3. **APP_STORE_CONNECT_API_KEY_CONTENT**: The base64-encoded content of the .p8 file

## Optional: App-Specific Information

If needed, you can also add:

4. **APP_APPLE_ID**: Your app's Apple ID (found in App Store Connect under App Information)
   - Format: `1234567890` (numeric ID)

## Verifying the Setup

Run the `test-upload.yml` workflow to verify everything is configured correctly.

## Troubleshooting

### "Exception caught" error
- Verify all three secrets are set correctly
- Ensure the API key has not expired
- Check that the key has App Manager permissions

### "Unable to authenticate" error
- The private key might be incorrectly encoded
- Re-encode the .p8 file ensuring no line breaks are included
- Verify the Key ID and Issuer ID match exactly

### TestFlight Upload Issues
- Ensure the app bundle ID matches what's configured in App Store Connect
- Verify the provisioning profile is for App Store distribution
- Check that the version and build numbers are unique