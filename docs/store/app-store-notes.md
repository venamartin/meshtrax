# App Store releases (iOS and Mac)

`./release.sh --ios` and `./release.sh --macos` archive the app on a Mac and
upload the build to App Store Connect. They never submit for review. The Mac
app is released through the Mac App Store only.

Export settings: `tool/ExportOptions-appstore.plist`.

## One-time setup

1. Xcode → Settings → Accounts: sign in with the developer Apple account. The
   upload uses this sign-in.
2. Put the project's Giphy API key in `giphy.key` at the repo root (it is
   untracked). App Store builds stop without it, rather than ship Giphy's
   rate-limited public beta key.

## Releasing

```bash
git pull
./release.sh --ios --macos     # both App Stores
./release.sh --macos           # one platform
```

1. **Store notes**: `dist/whatsnew-v<version>.txt`, the same file Play and the
   Microsoft Store use (max 500 characters).
2. Each platform is archived into Xcode's Organizer as
   `MeshTrax <iOS|macOS> <version> (<build>)`. The script refuses an archive
   whose version is not the pubspec `version`, and a Mac archive without the
   sandbox or `device.serial` entitlement (USB radios need it).
3. **Test, then upload**: the script prints how to open the Mac build, then
   asks before uploading. Only `y` uploads; anything else leaves the archives
   in the Organizer.
4. After the uploads, What's New is on the clipboard. In App Store Connect,
   for each platform: **+** for the new version, paste What's New, Add Build
   once it has processed, Save, Add for Review, Submit.

## Build numbers

The pubspec `+build` number must be new on App Store Connect for each
platform, and a Mac build number must be higher than every earlier Mac build.
To redo one platform after an upload, raise `+build` in `pubspec.yaml` in a PR
of its own, then run that platform alone.

## If an upload fails

"App Store Connect access … is required" or "Failed to Use Accounts" means the
Xcode sign-in has expired. Sign in again under Xcode → Settings → Accounts,
then upload the same archive without rebuilding: run the `xcodebuild
-exportArchive` command the script prints, or use Distribute App in Xcode's
Organizer.
