# Publishing Setup Guide

This guide explains how to set up automatic publishing to pub.dev for the Weight Scale Flutter plugin.

## Prerequisites

1. **Be a Verified Publisher** on [pub.dev](https://pub.dev)
   - Go to https://pub.dev/publishers
   - Verify your domain or GitHub account
   - This allows publishing from GitHub Actions without manual authorization

## Setup Instructions

### 1. Get pub.dev Credentials

First, you need to publish manually once to generate credentials:

```bash
# Test publishing (doesn't actually publish)
dart pub publish --dry-run

# First-time publish (creates credentials)
dart pub publish
```

This will create credentials at `~/.config/dart/pub-credentials.json`

### 2. Add GitHub Secret

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secret:

**Name:** `CREDENTIAL_JSON`
**Value:** Copy the entire content of `~/.config/dart/pub-credentials.json`

The file looks like this:

```json
{
  "accessToken": "ya29.a0AfH6...",
  "refreshToken": "1//0GWt...",
  "tokenEndpoint": "https://oauth2.googleapis.com/token",
  "scopes": ["https://www.googleapis.com/auth/userinfo.email", "openid"],
  "expiration": 1628097600000
}
```

### 3. Test the Workflow

Once the secret is set up:

1. Create a release using the auto-release script:

   ```bash
   ./scripts/auto-release.sh
   ```

2. The workflow will:
   - ✅ Run tests
   - ✅ Create GitHub release
   - ✅ Publish to pub.dev automatically

## Alternative Setup (Legacy)

If you prefer using separate tokens:

Add these two secrets instead of `CREDENTIAL_JSON`:

- `OAUTH_ACCESS_TOKEN` - The accessToken from credentials file
- `OAUTH_REFRESH_TOKEN` - The refreshToken from credentials file

## Troubleshooting

### "Package already exists" Error

This is normal - the action automatically checks versions and only publishes if the version in `pubspec.yaml` is different from pub.dev.

### "Unauthorized" Error

- Make sure you're a verified publisher
- Check that the credentials are valid and not expired
- Try publishing manually once to refresh credentials

### "Invalid credentials" Error

- Double-check that you copied the entire JSON content
- Make sure there are no extra spaces or characters
- The JSON should be valid format

## How It Works

The release workflow (`release.yml`) uses:

- **Trigger**: Git tags starting with `v*` (e.g., `v1.0.1`)
- **Publisher**: `k-paxian/dart-package-publisher@v1.6`
- **Smart Publishing**: Only publishes if version changed

This means you can:

1. Update version in `pubspec.yaml`
2. Run `./scripts/auto-release.sh`
3. Everything else happens automatically! 🚀

## Security Notes

- **Never commit** pub credentials to git
- Use GitHub repository secrets (encrypted)
- Credentials are only accessible during workflow runs
- Access is limited to repository collaborators
