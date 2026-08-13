# TestFlight and App Store Deployment Guide

## Prerequisites

- [x] Apple Developer Account ($99/year) - [developer.apple.com](https://developer.apple.com)
- [x] Xcode installed
- [ ] Apple Transporter app (optional — Xcode's Organizer uploads too)
- [x] App icons ready (1024x1024px)
- [x] Bundle ID configured: `com.vena.meshtrax` (matches the Android `applicationId`)

## Step 1: Register Bundle Identifier

1. Go to [Apple Developer - Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. Click the **"+"** button
3. Select **"App IDs"** → Continue
4. Select **"App"** → Continue
5. Fill in:
   - **Description**: MeshTrax
   - **Bundle ID**: Explicit - `com.vena.meshtrax`
   - **Capabilities**: Leave defaults. The only background mode is
     `bluetooth-central`, which needs no App ID capability.
6. Click **Continue** → **Register**

Xcode's automatic signing registers the App ID on its own during the first
archive, so this step is often already done.

## Step 2: Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Sign in with your Apple ID
3. Click **"My Apps"**
4. Click the **"+"** button → **"New App"**
5. Fill in the form:
   - **Platforms**: iOS
   - **Name**: `MeshTrax Beta` — the name must be unique across all of Apple,
     and plain "MeshTrax" is taken by the older `com.monitormx.meshcoreopen`
     record
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select `com.vena.meshtrax` from dropdown
   - **SKU**: `meshtrax-vena-001` (or any unique identifier)
   - **User Access**: Full Access
6. Click **"Create"**

The record is created with a placeholder version (1.0) that will not match
`pubspec.yaml`. TestFlight reads the version from the uploaded build, so this
only needs reconciling for an actual App Store submission.

## Step 3: Build the IPA

Run these commands from the project directory:

```bash
# Clean previous builds
flutter clean

# Build IPA for App Store
flutter build ipa
```

The IPA will be created at: `build/ios/ipa/MeshTrax.ipa`, and the archive at
`build/ios/archive/Runner.xcarchive`.

Two warnings are expected and do not fail the build:

- `file_saver` and `flutter_foreground_task` "do not support Swift Package
  Manager for ios". Flutter falls back to CocoaPods for them, which still
  works; it will become an error only once Flutter drops the fallback.
- "Launch image is set to the default placeholder icon."

Check the `App Settings Validation` block in the output before uploading —
version, build number, and bundle identifier must match `pubspec.yaml` and
`com.vena.meshtrax`.

## Step 4: Upload to App Store Connect

### Via Xcode Organizer (no extra tooling)

`flutter build ipa` also leaves an archive at
`build/ios/archive/Runner.xcarchive`. Open it to load Xcode's Organizer:

```bash
open build/ios/archive/Runner.xcarchive
```

Then **Distribute App** → **App Store Connect** → **Upload** → accept the
defaults → **Automatically manage signing** → **Upload**.

"Uploaded with warnings" is a success state.

### Via Transporter (alternative)

1. Install [Transporter](https://apps.apple.com/us/app/transporter/id1450874784)
   and sign in with your Apple ID
2. Drag `build/ios/ipa/MeshTrax.ipa` in, click **"Deliver"**

### Processing

Apple processes the build (10-30 minutes) and emails you when it is done.

## Step 5: Configure App Store Connect Metadata

### App Information
1. In App Store Connect, go to your app
2. Fill in required information:
   - **Subtitle**: Short description (30 chars max)
   - **Privacy Policy URL**: Required for Bluetooth apps
   - **Category**: Utilities or Productivity
   - **Age Rating**: Complete questionnaire

### App Store Listing
1. Go to **App Store** tab
2. Upload **Screenshots** (required):
   - iPhone 6.7" display (1290 x 2796 pixels) - At least 1 screenshot
   - iPhone 6.5" display (1242 x 2688 pixels) - At least 1 screenshot
   - Optional: iPad screenshots

3. Fill in **Description**:
   ```
   MeshTrax is a Flutter client for MeshCore LoRa mesh networking devices.

   Features:
   - BLE connectivity to MeshCore devices
   - Real-time mesh network communication
   - Map visualization with OpenStreetMap
   - Community management with QR code scanning
   - Message tracking and retry system

   Connect to your MeshCore LoRa device and start communicating over the mesh network.
   ```

4. **Keywords**: `lora,mesh,networking,bluetooth,communication`
5. **Support URL**: Your GitHub or website URL
6. **Marketing URL**: (Optional)

### Version Information
1. **What's New in This Version**:
   ```
   Initial release of MeshTrax

   - BLE device connectivity
   - Mesh network messaging
   - Map integration
   - Community features
   ```

2. **Build**: Select the uploaded build once processing completes

## Step 6: TestFlight Setup

### Internal Testing (No Review Required)
1. Go to **TestFlight** tab in App Store Connect
2. Click **Internal Testing** → **"+"** to create a group
3. Name your group (e.g., "Internal Testers")
4. Add yourself as a tester using your email
5. Select the build you uploaded
6. Testers will receive an email with TestFlight invitation

### External Testing (Requires Beta Review)
1. Click **External Testing** → **"+"** to create a group
2. Add build and testers
3. Fill in **Test Information**:
   - **What to Test**: Brief description of features
   - **Feedback Email**: Your email address
4. Click **Submit for Review**
5. Beta review typically takes 24-48 hours

## Step 7: App Store Submission

Once you're ready for public release:

1. Go to **App Store** tab
2. Complete all required metadata (if not done)
3. Select your build
4. Fill in **App Review Information**:
   - **Contact Information**: Your name, phone, email
   - **Demo Account**: If app requires login
   - **Notes**: Any special instructions for reviewers
5. Answer **Export Compliance** questions:
   - Does your app use encryption? **Yes** (uses TLS/HTTPS)
   - Is encryption registration required? **No** (standard encryption)
6. Click **Add for Review**
7. Review summary and click **Submit to App Review**

## Step 8: After Submission

- **App Review**: Typically 24-48 hours
- **Common Rejection Reasons**:
  - Missing privacy policy
  - Incomplete app information
  - Crashes or bugs
  - Misleading app description

- **If Approved**: You can release immediately or schedule a release date
- **If Rejected**: Address issues and resubmit

## Updating the App

When you need to release an update:

1. **Update version** in `pubspec.yaml`:
   ```yaml
   version: 1.7.20+29  # Increment version (1.7.20) and build number (+29)
   ```
   App Store Connect rejects a build number it has already seen, so the build
   number must increase even when the version name does not.

2. **Build new IPA**:
   ```bash
   flutter clean
   flutter build ipa
   ```

3. **Upload** (same process as Step 4 above)

4. **Create new version** in App Store Connect:
   - Click **"+"** next to versions
   - Select version number
   - Update "What's New" text
   - Select new build
   - Submit for review

## macOS Build (Bonus)

To build for macOS:

```bash
flutter build macos --release
cd build/macos/Build/Products/Release
zip -r MeshTrax-macos.zip MeshTrax.app
```

Distribution:
- Share the zip file directly
- Users unzip and drag to Applications
- First run: Right-click → Open (to bypass Gatekeeper)

## Troubleshooting

### Build Errors
- **CocoaPods not found**: Install with `brew install cocoapods`
- **No signing certificate**: Configure Team in Xcode (Signing & Capabilities)
- **Bundle ID mismatch**: Check `ios/Runner.xcodeproj/project.pbxproj`

### Upload Errors
- **No profiles found**: Create app in App Store Connect first
- **Bundle ID not registered**: Register in Apple Developer portal
- **Authentication failed**: Use Xcode Organizer or Transporter instead of CLI
- **MinimumOSVersion too low**: a warning, not an error — the upload still
  succeeds. From Spring 2027 Apple requires 15.0 or later. The project is
  already at 15.5, so this should not appear; if it does, check
  `IPHONEOS_DEPLOYMENT_TARGET` in `ios/Runner.xcodeproj/project.pbxproj` and
  keep it in sync with `platform :ios` in `ios/Podfile`, or the app advertises
  support for iOS versions its Pods were never built for.

### TestFlight Issues
- **Build not appearing**: Wait 10-30 minutes for processing
- **Can't add testers**: Check you have available slots (100 internal, 10,000 external)
- **TestFlight crashes**: Check device logs in Xcode → Devices & Simulators

## Important Files

- **iOS IPA**: `build/ios/ipa/MeshTrax.ipa`
- **macOS App**: `build/macos/Build/Products/Release/MeshTrax.app`
- **Bundle ID Config**: `ios/Runner.xcodeproj/project.pbxproj`
- **Version Info**: `pubspec.yaml`

## Useful Links

- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer Portal](https://developer.apple.com/account)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)

## Support

For issues with:
- **App Store Process**: [Apple Developer Support](https://developer.apple.com/contact/)
- **Flutter Build Issues**: [Flutter GitHub](https://github.com/flutter/flutter/issues)
- **MeshTrax App**: [GitHub Issues](https://github.com/venamartin/meshtrax/issues)
