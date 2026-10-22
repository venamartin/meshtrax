# TestFlight and App Store Deployment Guide

Two paths through this document:

- **[Shipping an update to the existing TestFlight app](#part-a--shipping-an-update-the-usual-case)** —
  the usual case. `MeshTrax Beta` / `com.vena.meshtrax` already exists and
  already has testers. Start here.
- **[Setting up a brand-new TestFlight app](#part-b--setting-up-a-new-app-first-time-only)** —
  one-time setup, already done for this project. Only needed for a new bundle
  ID or a fresh Apple account.

If you come from Android: the App Store Connect website is **not** where builds
are uploaded. There is no upload button on the site. Builds can only be pushed
from a Mac, by Xcode or Transporter. The website is where they appear
afterwards, and where testers are managed.

## Prerequisites

- [x] Apple Developer Account ($99/year) - [developer.apple.com](https://developer.apple.com)
- [x] Xcode installed, signed into the Apple ID on the team (Xcode → Settings → Accounts)
- [ ] Apple Transporter app (optional — Xcode's Organizer uploads too)
- [x] App icons ready (1024x1024px)
- [x] Bundle ID configured: `com.vena.meshtrax` (matches the Android `applicationId`)

Current setup: team **Dill.dev LLC** (`W79PF54N77`), App Store Connect record
**MeshTrax Beta**, bundle ID `com.vena.meshtrax`.

---

# Part A — Shipping an update (the usual case)

## A1. Bump the version

App Store Connect **rejects a build number it has already seen**, so the build
number must increase every upload, even when the version name does not.

```yaml
# pubspec.yaml
version: 1.7.20+29  # version name (1.7.20) and build number (+29)
```

Check the TestFlight tab for the highest build number already uploaded and go
above it. `master` is protected, so this goes through a branch and a PR like
any other change.

## A2. Build the IPA

```bash
flutter clean
flutter build ipa
```

Takes a few minutes. Outputs:

- IPA — `build/ios/ipa/MeshTrax.ipa`
- Archive — `build/ios/archive/Runner.xcarchive`

Two warnings are expected and do **not** fail the build:

- `file_saver` and `flutter_foreground_task` "do not support Swift Package
  Manager for ios". Flutter falls back to CocoaPods for them, which still
  works; it becomes an error only once Flutter drops the fallback.
- "Launch image is set to the default placeholder icon." Fine for TestFlight;
  Apple will want it fixed before a public App Store submission.

Confirm the `App Settings Validation` block matches what you expect:

```
[✓] App Settings Validation
    • Version Number: 1.7.20
    • Build Number: 29
    • Bundle Identifier: com.vena.meshtrax
```

Note the archive's own signing identity reads `Apple Development` — that is
normal. The export step re-signs the IPA with the
`Cloud Managed Apple Distribution` certificate, which is what App Store Connect
requires. Verify with:

```bash
/usr/libexec/PlistBuddy -c "Print" build/ios/ipa/DistributionSummary.plist | head -20
```

## A3. Upload via Xcode Organizer

```bash
open build/ios/archive/Runner.xcarchive
```

This launches Xcode's **Organizer** window (titled *Archives*) with the archive
loaded. It can take 20–30 seconds if Xcode was not already running, and it may
open behind other windows.

1. Confirm the top row is the archive you just built — check the **Version**
   column reads the new build, e.g. `1.7.20 (29)`. The right-hand panel should
   show `com.vena.meshtrax` and the correct team.
2. *(Optional, recommended)* Click **Validate App** first. It runs Apple's
   checks without uploading, surfacing problems in ~2 minutes instead of after
   a 30-minute processing cycle.
3. Click **Distribute App** — the upper of the two buttons on the right.
4. Choose **App Store Connect** → **Next**.
5. Choose **Upload** (not *Export*) → **Next**.

   > There is no **Upload** button on the Organizer's main screen. It appears
   > only at this point, two screens into the Distribute wizard.

6. Accept the defaults, keep **Automatically manage signing**, click
   **Upload**.
7. Wait for **"App upload complete: MeshTrax x.y.z (nn) uploaded"**, then
   **Done**.

Alternative for repeat uploads: install
[Transporter](https://apps.apple.com/us/app/transporter/id1450874784) (free)
and drag `build/ios/ipa/MeshTrax.ipa` in. Fewer clicks than Organizer.

## A4. Wait for processing

Apple processes the build for **10–30 minutes** and emails you when it is done.
Until then it shows as *Processing* in the TestFlight tab. Nothing to do.

## A5. Clear export compliance

The new build may show a **"Missing Compliance"** warning and cannot be given
to testers until it is answered. Apple can carry the answer over from the
previous build (1.7.20+29 processed straight to *Ready to Submit* with no
prompt), so this step may not appear at all. If it does, see
[Export compliance](#export-compliance-read-before-answering) below — this app
implements its own AES encryption, so the answer is not the trivial one.

A build showing **"Ready to Submit"** is fine: that is TestFlight's label for
"processed and usable", not a task waiting on you. There is no general Submit
button — submission happens implicitly when a build is added to an external
group (A6).

## A6. Release to testers

Distribution goes through the **External** group (created in B3), which has
**automatic distribution** enabled and a public link. Per release:

1. TestFlight tab → the new **Version x.y.z** section → or open the
   **External** group → **Builds** → add the new build.
2. Adding the build to the external group submits it for **Beta App Review**
   automatically. The first review took 24–48 hours; subsequent builds are
   usually faster, since only significant changes trigger a full re-review.
3. On approval, everyone who joined via the public link gets the update
   automatically — nothing further to do, no emails to manage.

Updates install **in place** for testers, like a normal App Store update: same
bundle ID, data preserved, no uninstall/reinstall.

Builds expire **90 days** after upload.

> **Do not add testers per-build.** A build's detail page offers "Individual
> Testers … added to this specific build". That is how builds 23 and earlier
> were distributed, and it is a trap: the list does not carry forward, so every
> release means re-adding everyone by hand, and a new build silently goes to
> nobody. Groups (with automatic distribution) exist to solve exactly this.

---

# Part B — Setting up a new app (first time only)

Already done for `com.vena.meshtrax`. Needed only for a new bundle ID.

## B1. Register the bundle identifier

1. [Apple Developer - Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. **"+"** → **App IDs** → Continue → **App** → Continue
3. Fill in:
   - **Description**: MeshTrax
   - **Bundle ID**: Explicit — `com.vena.meshtrax`
   - **Capabilities**: leave defaults. The only background mode is
     `bluetooth-central`, which needs no App ID capability.
4. **Continue** → **Register**

Xcode's automatic signing registers the App ID on its own during the first
archive, so this step is often already done.

## B2. Create the app record in App Store Connect

**Do this before the first upload.** Without it the upload fails with
*"No suitable application records were found."*

1. [App Store Connect](https://appstoreconnect.apple.com) → **My Apps**
2. **"+"** → **New App**
3. Fill in:
   - **Platforms**: iOS
   - **Name**: `MeshTrax Beta` — must be unique across all of Apple. Plain
     "MeshTrax" is taken by the older `com.monitormx.meshcoreopen` record.
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: select `com.vena.meshtrax` from the dropdown
   - **SKU**: `meshtrax-vena-001` (internal only, any unique string)
   - **User Access**: Full Access
4. **Create**

The record is created with a placeholder version **1.0 "Prepare for
Submission"**. This is the *App Store version* record and is separate from
TestFlight builds — it stays at 1.0 and says "Prepare for Submission" even
after you have TestFlight builds live. Do not read it as "nothing uploaded";
check the **TestFlight** tab for that.

## B3. Create a testing group

TestFlight distinguishes two kinds of group, and the choice matters:

| | Internal | External |
|---|---|---|
| Who can join | Only App Store Connect users on the team | **Anyone, any email address** |
| Tester limit | 100 | 10,000 |
| Beta App Review | Not required — builds are live immediately | Required (first ~24–48 h, faster after) |
| Public link | No | **Yes** — one URL, testers self-join |

For outside testers — which is this project's situation — internal groups are
a dead end: the add-tester picker only offers team members. Use an
**external** group:

1. TestFlight sidebar → **EXTERNAL TESTING** → **+** → name the group.
2. Enable **automatic distribution** so each new build goes to the group
   without a per-release step.
3. Fill in **Test Information** (required before external review): beta app
   description, feedback email, and privacy policy URL — paste-ready text for
   all three is in [docs/app-review-notes.md](docs/app-review-notes.md).
4. Add a build to the group; this submits it for Beta App Review. The **What
   to Test** field is required at this point — a summary of user-facing
   changes since the last build (`git log --oneline <old>..master --no-merges`
   is a good starting point).
5. After the build is approved, enable the **Public Link** in the group's
   settings and share it. Testers tap the link, install TestFlight, and get
   every future approved build automatically.

This project's public link:
`https://testflight.apple.com/join/Sa4Pw4wh` — MeshTrax Beta, "External"
group. The link is dormant (testers cannot join) until the group has at least
one approved build, and it can be disabled or capped at any time. Note the
public link does not collect tester emails, so there is no way to contact
link-joined testers individually — feedback arrives through TestFlight.

Then follow **Part A** from A1.

---

# Reference

## Export compliance (read before answering)

Every upload asks whether the app uses encryption, and the build is unusable
until it is answered.

**This is not the trivial "yes, HTTPS" case.** MeshTrax implements its own
symmetric encryption: AES-128 ECB with an HMAC-SHA256 MAC over MeshCore channel
payloads, in `_decryptPayload` in
[lib/connector/meshcore_connector.dart](lib/connector/meshcore_connector.dart),
plus channel key derivation in [lib/models/channel.dart](lib/models/channel.dart)
via `crypto` and `pointycastle`.

Apple's exemptions cover encryption that is limited to HTTPS/TLS calls,
encryption provided by the operating system, or authentication and digital
signatures only. Custom AES over app payloads does not fall under any of them,
so answering "no non-exempt encryption" would not be accurate.

Consequences worth knowing before deciding:

- Declaring non-exempt encryption generally requires a self-classification
  report or an Encryption Registration Number (ERN) filed with the US Bureau of
  Industry and Security, renewed annually.
- There is a possible carve-out (Note 4 to Category 5 Part 2) where the
  cryptography is ancillary to the primary function. Whether mesh message
  encryption is "ancillary" for a mesh messaging app is a judgement call.

This is an export-control question, not a technical one — worth confirming with
someone qualified rather than guessing. Until it is settled, leave
`ITSAppUsesNonExemptEncryption` **unset** in
[ios/Runner/Info.plist](ios/Runner/Info.plist) and answer per-upload in App
Store Connect, so the declaration stays a deliberate choice.

Once settled, adding the key to `Info.plist` answers it automatically on every
future upload and the prompt stops appearing.

## Installing on a device over USB (no TestFlight)

For quick testing, skip TestFlight entirely. **The App Store IPA cannot be
sideloaded** — it is distribution-signed and iOS will refuse it. Build a
development-signed copy instead:

```bash
flutter devices                                   # get the device id
flutter build ios --release
flutter install -d <device-id> --release
```

Drop `-d <device-id>` if only one device is attached. Requires the phone
unlocked, "Trust This Computer" accepted, and Developer Mode on
(Settings → Privacy & Security → Developer Mode).

If the app installs but refuses to open with "Untrusted Developer":
Settings → General → VPN & Device Management → tap the developer profile →
Trust.

Alternatively `flutter run --release -d <device-id>` builds, installs, launches,
and streams logs; press `q` to detach, and the app stays installed.

## App Store submission

Beyond TestFlight, a public release additionally needs:

1. **EU trader status** — under the Digital Services Act, an Admin or Account
   Holder must provide it or the app is removed from the EU App Store. This
   does **not** block TestFlight.
2. **Screenshots** — iPhone 6.7" (1290 x 2796) and 6.5" (1242 x 2688), at least
   one each.
3. **A real launch image** — replace the placeholder flagged during the build.
4. **Privacy Policy URL** — required for Bluetooth apps. See
   [docs/privacy.md](docs/privacy.md).
5. **Category** (Utilities or Productivity), **age rating** questionnaire,
   **description**, **keywords** (`lora,mesh,networking,bluetooth,communication`),
   **support URL**.
6. **App Review Information** — contact details, and notes for the reviewer.
   The app needs MeshCore hardware to be useful; the biggest rejection risk is
   Guideline 4.2 (minimum functionality) from a reviewer who opens the app
   with no LoRa radio and sees an empty scanner. Paste the notes from
   [docs/app-review-notes.md](docs/app-review-notes.md), and attach a screen
   recording of the app working against a real device if possible.

Review typically takes 24–48 hours.

## macOS build

```bash
flutter build macos --release
cd build/macos/Build/Products/Release
zip -r MeshTrax-macos.zip MeshTrax.app
```

Distribution: share the zip; users unzip, drag to Applications, and right-click
→ Open on first run to bypass Gatekeeper.

Note the macOS bundle ID is `com.meshtrax.app`
([macos/Runner/Configs/AppInfo.xcconfig](macos/Runner/Configs/AppInfo.xcconfig)),
which differs from the iOS `com.vena.meshtrax`.

## Troubleshooting

### Build errors
- **CocoaPods not found**: `brew install cocoapods`
- **No signing certificate**: configure Team in Xcode (Signing & Capabilities)
- **Bundle ID mismatch**: check `ios/Runner.xcodeproj/project.pbxproj`

### Upload errors
- **No suitable application records were found**: the App Store Connect record
  does not exist, or its bundle ID does not match. See B2.
- **No profiles found**: create the app in App Store Connect first
- **Authentication failed**: use Xcode Organizer or Transporter instead of CLI
- **Build number already used**: increment `+nn` in `pubspec.yaml` and rebuild;
  a build number can never be reused, even after deleting the build
- **MinimumOSVersion too low**: a warning, not an error — the upload still
  succeeds. From Spring 2027 Apple requires 15.0 or later. The project is
  already at 15.5, so this should not appear; if it does, check
  `IPHONEOS_DEPLOYMENT_TARGET` in `ios/Runner.xcodeproj/project.pbxproj` and
  keep it in sync with `platform :ios` in `ios/Podfile`, or the app advertises
  support for iOS versions its Pods were never built for.
- **"Uploaded with warnings"**: this is a success state, not a failure.

### TestFlight issues
- **Build not appearing**: wait 10–30 minutes for processing
- **Build present but not installable**: almost always unanswered export
  compliance
- **Build says "Ready to Submit"**: not an error and not a pending task — it
  means processed and usable. There is no Submit button; adding the build to
  an external group is what submits it for review
- **New build reached nobody**: testers were attached to the previous build as
  per-build "Individual Testers" instead of a group. Add the testers to the
  external group (or the build to the group) — see A6
- **Group only offers team members**: it is an *internal* group; outside
  emails need an *external* group — see B3
- **Can't add testers**: check available slots (100 internal, 10,000 external)
- **TestFlight crashes**: check device logs in Xcode → Devices & Simulators

## Important files

- **iOS IPA**: `build/ios/ipa/MeshTrax.ipa`
- **iOS archive**: `build/ios/archive/Runner.xcarchive`
- **macOS App**: `build/macos/Build/Products/Release/MeshTrax.app`
- **Bundle ID config**: `ios/Runner.xcodeproj/project.pbxproj`
- **iOS Info.plist**: `ios/Runner/Info.plist`
- **Version**: `pubspec.yaml`

## Useful links

- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer Portal](https://developer.apple.com/account)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)

## Support

- **App Store Process**: [Apple Developer Support](https://developer.apple.com/contact/)
- **Flutter Build Issues**: [Flutter GitHub](https://github.com/flutter/flutter/issues)
- **MeshTrax App**: [GitHub Issues](https://github.com/venamartin/meshtrax/issues)
