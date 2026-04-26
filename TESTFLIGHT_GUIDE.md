# TestFlight and App Store Deployment Guide

## Prerequisites

- [x] Apple Developer Account ($99/year) - [developer.apple.com](https://developer.apple.com)
- [x] Xcode installed
- [x] Apple Transporter app installed
- [x] App icons ready (1024x1024px)
- [x] Bundle ID configured: `com.monitormx.meshcoreopen`

## Step 1: Register Bundle Identifier

1. Go to [Apple Developer - Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. Click the **"+"** button
3. Select **"App IDs"** → Continue
4. Select **"App"** → Continue
5. Fill in:
   - **Description**: MeshTrax
   - **Bundle ID**: Explicit - `com.monitormx.meshcoreopen`
   - **Capabilities**: Leave defaults (or add as needed)
6. Click **Continue** → **Register**

## Step 2: Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Sign in with your Apple ID
3. Click **"My Apps"**
4. Click the **"+"** button → **"New App"**
5. Fill in the form:
   - **Platforms**: iOS
   - **Name**: MeshTrax
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select `com.monitormx.meshcoreopen` from dropdown
   - **SKU**: `meshcore-open-001` (or any unique identifier)
   - **User Access**: Full Access
6. Click **"Create"**

## Step 3: Build the IPA

Run these commands from the project directory:

```bash
# Add CocoaPods to PATH
export PATH="/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"

# Clean previous builds
../flutter/bin/flutter clean

# Build IPA for App Store
../flutter/bin/flutter build ipa
```

The IPA will be created at: `build/ios/ipa/MeshTrax.ipa`

## Step 4: Upload to App Store Connect via Transporter

1. **Open Apple Transporter**
   - Launch from Applications folder
   - Sign in with your Apple ID

2. **Upload the IPA**
   - Drag and drop `build/ios/ipa/MeshTrax.ipa` into Transporter
   - Click **"Deliver"**
   - Wait for upload to complete (usually 1-5 minutes)

3. **Processing**
   - Apple will process your build (10-30 minutes)
   - You'll receive an email when processing is complete

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
   version: 0.5.0+6  # Increment version (0.5.0) and build number (+6)
   ```

2. **Build new IPA**:
   ```bash
   export PATH="/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"
   ../flutter/bin/flutter clean
   ../flutter/bin/flutter build ipa
   ```

3. **Upload via Transporter** (same process as above)

4. **Create new version** in App Store Connect:
   - Click **"+"** next to versions
   - Select version number
   - Update "What's New" text
   - Select new build
   - Submit for review

## macOS Build (Bonus)

To build for macOS:

```bash
export PATH="/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH"
../flutter/bin/flutter build macos --release
cd build/macos/Build/Products/Release
zip -r MeshTrax-macos.zip MeshTrax.app
```

Distribution:
- Share the zip file directly
- Users unzip and drag to Applications
- First run: Right-click → Open (to bypass Gatekeeper)

## Troubleshooting

### Build Errors
- **CocoaPods not found**: Ensure PATH includes `/opt/homebrew/lib/ruby/gems/4.0.0/bin`
- **No signing certificate**: Configure Team in Xcode (Signing & Capabilities)
- **Bundle ID mismatch**: Check `ios/Runner.xcodeproj/project.pbxproj`

### Upload Errors
- **No profiles found**: Create app in App Store Connect first
- **Bundle ID not registered**: Register in Apple Developer portal
- **Authentication failed**: Use Transporter app instead of CLI

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
- **MeshTrax App**: [GitHub Issues](https://github.com/wel97459/meshcore-open/issues)
