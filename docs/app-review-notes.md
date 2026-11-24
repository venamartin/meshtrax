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

The camera and photo library are used to scan QR codes for joining
communities and channels, and to take or choose a photo the user sends; a
photo is added to the library only when the user taps Save. The calendar is used only when the user taps
"Add to calendar" on an event message; the app never reads the calendar or
contacts (the contacts string covers Apple's add-event screen on iOS 16 and
earlier).

There is no account system and no login. All communication is directly
between the phone and the LoRa device over Bluetooth/USB, and then over the
LoRa mesh. MeshTrax's own servers only serve downloads (offline maps and the
photo model) and pass content reports on to the developer.

Photos: a user can send a photo to a channel over the mesh. An AI image codec
on the phone codes it to a few hundred bytes; each receiving phone rebuilds a
picture from that code with the same model, which is built on Stability AI's
SD-Turbo, and can enlarge it 4x with a small on-device Real-ESRGAN model.
These are the app's only AI features. They take no text prompts and cannot
create, edit or undress images: they rebuild only what the sender
photographed. An on-device image safety classifier checks every photo before
it is sent, and every rebuilt or enlarged picture before it is shown; a
flagged picture is hidden and never stored. Every rebuilt picture is marked
"AI reconstructed". Users can report a photo from inside the app (the report
goes to the developer's report inbox) and block its sender. The photo model
(about 1.2 GB) downloads only when the user turns on Photos in App settings
→ Messaging. Sending a photo needs two radios; the attached video shows it.

Source code: https://github.com/venamartin/meshtrax

The attached video shows the app next to a physical MeshCore radio: scanning,
connecting over Bluetooth, and exchanging messages with other nodes on a live
mesh.
```

Attach the demo video described below. If the attachment upload rejects the
file size, upload it unlisted to YouTube and put the link in the notes instead
— reviewers follow those.

## Demo video (attach to App Review Information)

Film with a second phone so the physical radio and the app are in the same
frame — a screen recording alone cannot prove the hardware exists. One
continuous take, 60–90 seconds, landscape:

1. The MeshCore radio on the table, powered, clearly visible
2. Launch MeshTrax next to it; the scanner finds the device
3. Connect; the signal/battery header appears
4. Send a channel message; ideally a reply or reaction arrives from another
   node — that proves the mesh, not just the link
5. Optional: the node map showing live nodes

Keep both the radio and the phone screen legible throughout.

For a submission with photos, add a second take with two phones and two
radios, 60–90 seconds:

1. Phone A: + → Photo, crop, Preview, type a tag, Send (the confirmation on
   a MeshCore frequency shows the photo's airtime)
2. Phone B: the photo arrives; one tap opens it full screen and rebuilds it,
   marked "AI reconstructed"
3. Enhance 4×, then Save
4. ⋮ → Report: the photo is hidden and the report is sent

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
• Line of sight and radio reach, offline from downloaded contours
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

The app reaches the internet only for the MeshTrax map server (map downloads) and Giphy (GIFs), plus links you tap. Line of sight, routing, and place search run on your device. See the privacy policy for details.

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
