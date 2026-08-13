# App Review notes

Paste-ready text for App Store Connect review forms. Keeping it here means it
does not have to be rewritten for every submission.

## App Review Information → Notes

Use for both Beta App Review (external TestFlight) and App Store review. This
is the main defense against a Guideline 4.2 (minimum functionality) rejection:
a reviewer without a LoRa radio sees an empty scanner screen, and these notes
are what tells them that is correct behaviour.

```
MeshTrax is a client application for MeshCore LoRa mesh-networking radios
(https://meshcore.co.uk/). It is a companion app: it requires a physical
MeshCore device, connected over Bluetooth LE or USB serial, to do anything
beyond its initial screen.

Without hardware, the app launches to a scanner screen that lists no devices.
This is correct behaviour, not a crash or an incomplete feature. Bluetooth
permission is requested on first launch so the app can scan for these devices.

Camera and photo library permissions are used only to scan QR codes for
joining communities and channels.

There is no account system, no login, and no server component — all
communication is directly between the phone and the LoRa device over
Bluetooth/USB, and then over the LoRa mesh.

Source code: https://github.com/venamartin/meshtrax
```

If possible, attach a short screen recording of the app connected to a real
MeshCore device — it materially reduces the rejection risk.

## Beta App Description (TestFlight → Test Information)

```
MeshTrax is an open-source client for MeshCore LoRa mesh networking devices.
Connect to a MeshCore device over Bluetooth LE or USB serial to send and
receive messages across the mesh, manage contacts and channels, view nodes on
a map, and administer repeaters.
```

## Privacy Policy URL

```
https://github.com/venamartin/meshtrax/blob/master/docs/privacy.md
```

## App Store listing

Adapted from the Google Play listing (kept in sync by hand — Play Console is
the other copy). Nothing in App Store metadata may mention Android or Google
Play.

### Subtitle (App Information, 30 chars max)

```
Off-grid LoRa mesh messaging
```

### Promotional Text (170 chars max; editable without a new review)

```
Off-grid messaging over LoRa mesh radio. No internet, no accounts, no servers — your messages stay on your own hardware.
```

### Keywords (hidden search field, 100 chars max; do not repeat the app name)

```
lora,mesh,meshcore,off-grid,radio,messenger,ble,walkie,repeater,emergency,hiking,camping
```

### Description

```
MeshTrax is a free, open-source companion app for MeshCore LoRa mesh networking devices. Connect to your radio and send messages across the mesh — no internet, no accounts, and no cloud servers.

Communicate off-grid over long-range LoRa radio — hiking, at an event, in an emergency, or just exploring mesh networking. Your messages, contacts, and keys stay on your device and your own hardware.

Note: MeshTrax is an independent, community-built client and is not the official MeshCore app. It requires a compatible MeshCore device to be useful, it is not a standalone messenger.

A MODERN CHAT EXPERIENCE
• Unified inbox, all your direct messages and channels in one clean, messaging-app-style list
• Swipe to reply, emoji reactions, and inline GIFs
• Delivery status and automatic message retry
• Notifications for new messages, even in the background

MESSAGING & CHANNELS
• Direct one-to-one messages
• Channel and group messaging
• Encrypted channels using pre-shared keys

CONTACTS
• Add contacts by scanning or sharing QR codes
• Organize contacts into groups

MAP & COVERAGE
• Nodes, repeaters, and neighbors on an interactive map
• Download map areas for offline use
• Line-of-sight terrain analysis
• Export tracks and points as GPX

DEVICE INSIGHTS
• Device and repeater telemetry and sensor readings
• Battery monitoring
• Message path tracing and routing tools

CONNECT YOUR WAY
• Bluetooth Low Energy (BLE)
• USB serial (where supported)
• Local network / Wi-Fi (TCP)

Plus auto-connect to your last device, light and dark themes, and many languages.

PRIVACY FIRST
• No accounts, no sign-up
• No ads, analytics, or tracking
• No MeshTrax servers — the developer receives none of your data
• Block and report tools to keep conversations civil

Optional online features (maps, terrain, GIFs) connect to third-party services only when you use them. See the privacy policy for details.

BUILT ON MESHCORE
MeshTrax builds on the open MeshCore ecosystem and is forked from the open-source MeshCore Open client. All credit for the protocol, firmware, and official apps goes to the MeshCore project.

REQUIREMENTS
A compatible MeshCore device (a supported LoRa radio running MeshCore firmware).

Source & issues: https://github.com/venamartin/meshtrax
```

### Category / other fields

- **Category:** Utilities (primary); Social Networking is a defensible
  secondary
- **Screenshots:** 6.5" iPhone set lives in `~/Downloads/appstore-shots/`
  (1242×2688; contact names blurred in 05). Map first — only the first 3 show
  on install sheets.
- **iPad:** deliberately deferred. The project still targets iPad
  (`TARGETED_DEVICE_FAMILY = "1,2"`); either capture 13" iPad screenshots
  before submitting, or switch to iPhone-only (`= 1`) — iPad support can be
  added later but never removed once shipped universal.

## Export compliance

Not settled — do not answer from memory. The app implements its own AES-128
ECB + HMAC-SHA256 over MeshCore channel payloads (`_decryptPayload` in
`lib/connector/meshcore_connector.dart`), which is not covered by Apple's
TLS/OS-provided/auth-only exemptions. See the "Export compliance" section in
[../TESTFLIGHT_GUIDE.md](../TESTFLIGHT_GUIDE.md) before answering the
questionnaire, and leave `ITSAppUsesNonExemptEncryption` unset in
`ios/Runner/Info.plist` until the question is resolved with someone qualified.
