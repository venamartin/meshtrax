#!/usr/bin/env bash
#
# Build, sign, notarize, and staple the macOS release.
#
# One-time setup:
#   1. A "Developer ID Application" certificate in the login keychain
#      (Xcode -> Settings -> Accounts -> Manage Certificates -> + ;
#      only the team Account Holder can create one).
#   2. xcrun notarytool store-credentials meshtrax-notary
#      (Apple ID + app-specific password + team ID W79PF54N77)
#
# Usage:  bash tool/release_macos.sh
#
# Output: build/macos/MeshTrax-macos-<version>.zip — signed, notarized,
# stapled; installs with a plain double-click, no Gatekeeper bypass.
set -euo pipefail

cd "$(dirname "$0")/.."

PROFILE="meshtrax-notary"
IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)"/\1/')
if [ -z "$IDENTITY" ]; then
  echo "ERROR: no 'Developer ID Application' certificate in the keychain." >&2
  echo "Create one in Xcode -> Settings -> Accounts -> Manage Certificates." >&2
  exit 1
fi
echo "==> Signing as: $IDENTITY"

VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: *//; s/+.*//')

echo "==> Building"
flutter build macos --release

APP=$(ls -d build/macos/Build/Products/Release/*.app | head -1)
echo "==> App: $APP"

echo "==> Signing nested code"
find "$APP/Contents/Frameworks" \( -name "*.framework" -o -name "*.dylib" \) -maxdepth 1 | while read -r item; do
  codesign --force --options runtime --timestamp --sign "$IDENTITY" "$item"
done

echo "==> Signing app bundle"
codesign --force --options runtime --timestamp \
  --entitlements macos/Runner/Release.entitlements \
  --sign "$IDENTITY" "$APP"

echo "==> Verifying signature"
codesign --verify --deep --strict "$APP"

ZIP="build/macos/MeshTrax-notarize.zip"
FINAL="build/macos/MeshTrax-macos-${VERSION}.zip"

echo "==> Submitting for notarization (usually 1-5 minutes)"
ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait

echo "==> Stapling ticket"
xcrun stapler staple "$APP"

echo "==> Packaging"
rm -f "$ZIP" "$FINAL"
ditto -c -k --keepParent "$APP" "$FINAL"

echo "==> Gatekeeper check"
spctl --assess --type execute --verbose=2 "$APP"

echo ""
echo "Done: $FINAL"
