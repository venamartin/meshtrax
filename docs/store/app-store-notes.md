# App Store releases (iOS and Mac)

`./release.sh --ios` and `./release.sh --macos` archive the app on a Mac and
upload the build to App Store Connect. They never submit for review.

Bundle: `com.vena.meshtrax` on both platforms. Team: Dill.dev LLC (`W79PF54N77`).
Export settings: `tool/ExportOptions-appstore.plist`.

## One-time setup

1. Xcode → Settings → Accounts: sign in with the developer Apple account and
   check the Dill.dev LLC team is listed. The upload uses this sign-in. When
   it expires, the upload fails with "Failed to Use Accounts"; sign in again.
2. Mac only: the MeshTrax record in App Store Connect needs the macOS platform
   (Add Platform) before its first build can be attached.

## Releasing

```bash
./release.sh --ios --macos                 # both App Stores only
./release.sh --apk --play --ios            # GitHub APK + Play + iOS
```

1. **Store notes**: the same `dist/whatsnew-v<version>.txt` as Play and the
   Microsoft Store (max 500 characters).
2. Each platform is archived into Xcode's Organizer as
   `MeshTrax <platform> <version> (<build>)`. The script refuses an archive
   whose version is not the pubspec `version`, and a Mac archive without the
   sandbox or `device.serial` entitlement (USB radios need it).
3. Uploads happen last, after any GitHub release goes live. Then the What's
   New text is put on the clipboard.
4. In App Store Connect: add the version (the **+** beside the platform), pick
   the build once it has processed, paste What's New and submit for review.
   MeshTrax does not use TestFlight.

The pubspec `+build` number must be new on App Store Connect for each
platform. If an upload fails, retry one platform with `./release.sh --ios` or
`./release.sh --macos`, or upload the archive from the Organizer
(Distribute App → App Store Connect → Upload).

Giphy: builds use `giphy.key` when present, like the other platforms.
