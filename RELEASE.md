# WordBubbles Release Guide

This document explains how to create releases for the WordBubbles app that build the web version and Android artifacts. The Android App Bundle (AAB) is the Play Console artifact; the APK is retained for direct testing.

## Automated Release Process

The project now includes an automated release workflow that:
- Runs tests to ensure code quality
- Builds the web version as a ZIP file
- Builds a signed Android App Bundle for Google Play Console
- Builds a signed Android APK for direct testing
- Creates a GitHub release with web, AAB, and APK files attached
- Provides detailed installation instructions

## How to Create a Release

### Method 1: Using a version tag (Recommended)

1. Make sure all your changes are committed and pushed to the main branch
2. Update `pubspec.yaml`, commit, and push the version change.
3. Create and push a version tag:
   ```bash
   git tag -a v1.1.0 -m "WordBubbles 1.1.0"
   git push origin main
   git push origin v1.1.0
   ```
4. GitHub Actions runs tests, builds the web archive, builds the signed AAB/APK, and creates the GitHub release.

### Method 2: Manual Tag Creation

1. Update the version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+1  # Change 1.0.1 to your desired version
   ```

2. Commit the version change:
   ```bash
   git add pubspec.yaml
   git commit -m "Bump version to 1.0.1"
   ```

3. Create and push a version tag:
   ```bash
   git tag -a v1.0.1 -m "Release 1.0.1"
   git push origin main
   git push origin v1.0.1
   ```

### Method 3: Manual Workflow Trigger

You can manually trigger the workflow to test the build. A GitHub release is created only for a `v*.*.*` tag, so a manual run from `main` will not create a release named `main`.

## What Happens During Release

1. **Testing Phase**: The workflow runs `flutter analyze` and `flutter test` to ensure code quality
2. **Web Build**: Creates a production web build and packages it as a ZIP file
3. **Android Build**: Creates a signed production AAB and APK. The workflow installs Android API 36 and verifies that the AAB is signed.
4. **Release Creation**: Creates a GitHub release with:
   - Descriptive release notes
   - Installation instructions for both platforms
   - The web ZIP, Android AAB, and Android APK attached as downloadable assets

## Google Play Closed-testing gate

After the signed AAB job is green, upload the AAB to the Closed testing track and verify:

1. The version code is newer than the last submitted artifact.
2. Target API level is 36 and the signed bundle passes Play Console checks.
3. The tester list, release notes, pre-launch checks, and rollout state are correct.
4. The Play Console policy and account-status banners have been reviewed before submitting.

## Release Assets

Each release will include:

### Web Version (`wordbubbles-web-vX.X.X.zip`)
- Complete web application ready to serve
- Can be deployed to any web server
- Includes all necessary assets and files

### Android App Bundle (`wordbubbles-vX.X.X.aab`)
- Signed bundle to upload to Google Play Console testing or production tracks
- Targets Android 16 (API level 36)

### Android APK (`wordbubbles-vX.X.X.apk`)
- Release-signed APK for Android devices
- Compatible with Android 5.0 (API level 21) and higher
- Can be installed directly on Android devices

## Version Numbering

Follow semantic versioning (SemVer):
- **Major version** (X.0.0): Breaking changes or major new features
- **Minor version** (0.X.0): New features that are backward compatible
- **Patch version** (0.0.X): Bug fixes and small improvements

Examples:
- `1.0.0` - Initial release
- `1.0.1` - Bug fix release
- `1.1.0` - New feature release
- `2.0.0` - Major update with breaking changes

## Monitoring Releases

1. Go to your GitHub repository
2. Click on the "Actions" tab to monitor the build progress
3. Once complete, check the "Releases" section to see your new release
4. Share the release URL with users for easy download access

## Troubleshooting

### Build Failures
- Check the Actions tab for detailed error logs
- Ensure all tests pass locally before creating a release
- Verify that the Flutter version in the workflow matches your development environment

### Missing Files
- Ensure you've committed all necessary files before creating the release
- Check that the Android build configuration is correct
- Verify that web assets are properly configured

### Permission Issues
- The workflow requires `contents: write` permission to create releases
- This should be automatically granted, but check repository settings if issues occur

## Customizing Release Notes

You can customize the release notes by editing the `.github/workflows/release.yml` file. The current template includes:
- Version information
- Download links
- Installation instructions
- System requirements

Feel free to modify the release body template to match your project's needs.
