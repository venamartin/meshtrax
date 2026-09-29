# Microsoft Store notes

Paste-ready text for the Partner Center submission of MeshTrax for Windows.
Adapted from the App Store listing in [../app-review-notes.md](../app-review-notes.md)
— kept in sync by hand. The Windows app has no notifications, camera, or
background service, so those lines are left out here.

## Store identity

- Store ID: `9N0DM90LRH49`
- Listing: https://apps.microsoft.com/detail/9N0DM90LRH49
- Package family name: `MartinGreatorex.MeshTrax_a1f4byw357jqj`
- Identity values live in `msix_config` in `pubspec.yaml` (Partner Center →
  MeshTrax → Product identity).

## Building the package

```
./release.sh --msix
```

Builds the Windows release, runs the bundle checks, and writes both
`dist/meshtrax-windows-v<version>.zip` (GitHub) and
`dist/meshtrax-v<version>.msix` (upload to Partner Center → Packages). The
`.msix` is unsigned — the Store signs it — so it is never attached to the
GitHub release. The script refuses to package while `msix_config` in
`pubspec.yaml` still has `PLACEHOLDER` identity values.

Every submission needs a higher version than the last: the MSIX version is
`major.minor.patch.0` taken from pubspec `version:`, so the normal patch bump
covers it. The `+build` number is not used.

## Sideload test before submitting

Store packages cannot be installed locally. Build a self-signed test package
from the same bundle (msix creates and installs a test certificate):

```
flutter build windows --release
dart run msix:create
```

Install the `.msix` it prints, then check BLE scan/connect, USB serial, that
data survives a restart, and that the window size is remembered. Run the
Windows App Certification Kit (`appcertui.exe`, in the Windows SDK) against it.

## Submission options

- **Pricing:** Free. **Markets:** all.
- **Category:** Utilities & tools (primary).
- **Privacy policy URL:**

```
https://github.com/venamartin/meshtrax/blob/master/docs/privacy.md
```

- **Website / support contact:**

```
https://github.com/venamartin/meshtrax/issues
```

## Restricted capability justification (runFullTrust)

```
MeshTrax is a Flutter desktop (Win32) application. It runs at full trust to
open USB serial (COM) ports to MeshCore LoRa radios and to use the WinRT
Bluetooth LE APIs to connect to them. It does not install drivers, services,
or run other processes.
```

## Notes for certification

The main defense against a "doesn't do anything" rejection: a tester without
a LoRa radio sees an empty scanner screen.

```
MeshTrax is a client application for MeshCore LoRa mesh-networking radios
(https://meshcore.co.uk/). It is a companion app: it requires a physical
MeshCore device, connected over Bluetooth LE, USB serial, or the local
network, to do anything beyond its initial screen.

Without hardware, the app launches to a scanner screen that lists no devices.
This is correct behaviour, not a crash or an incomplete feature.

There is no account system, no login, and no server component — all
communication is directly between the computer and the LoRa device, and then
over the LoRa mesh.

Source code: https://github.com/venamartin/meshtrax
Demo video: <link to the unlisted demo video>
```

## Listing

### Short description (1000 chars max; shown at the top on some surfaces)

```
Off-grid messaging over LoRa mesh radio. No internet, no accounts, no servers — your messages stay on your own hardware.
```

### Description

```
MeshTrax is a free, open-source companion app for MeshCore LoRa mesh networking devices. Connect to your radio and send messages across the mesh — no internet, no accounts, and no cloud servers.

Communicate off-grid over long-range LoRa radio — hiking, at an event, in an emergency, or just exploring mesh networking. Your messages, contacts, and keys stay on your computer and your own hardware.

Note: MeshTrax is an independent, community-built client and is not the official MeshCore app. It requires a compatible MeshCore device to be useful, it is not a standalone messenger.

A MODERN CHAT EXPERIENCE
• Unified inbox, all your direct messages and channels in one clean, messaging-app-style list
• Swipe to reply, emoji reactions, and inline GIFs
• Delivery status and automatic message retry

MESSAGING & CHANNELS
• Direct one-to-one messages
• Channel and group messaging
• Encrypted channels using pre-shared keys

CONTACTS
• Share contacts as QR codes
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
• USB serial
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
A compatible MeshCore device (a supported LoRa radio running MeshCore firmware) and a PC with Bluetooth LE, a USB port, or network access to the device.

Source & issues: https://github.com/venamartin/meshtrax
```

### Search terms (up to 7)

```
lora, mesh, meshcore, off-grid, radio, messenger, repeater
```

### Screenshots

At least 1, up to 10; 1366×768 or larger, PNG. Take them from the Windows
app: unified inbox, a channel conversation, node map, contacts, device
settings. Blur contact names as in the iOS set.

### Store logo

1:1 at 300×300 or larger: `mesh-icon.png` (1024×1024).

## Existing GitHub-zip users

The Store app keeps its data in its own package folder, so someone switching
from the zip starts with no contacts or history. Put this in the first Store
release notes: in the zip version, Settings → Export Contacts (Backup) saves a
JSON file; import it in the Store version. Message history does not carry
over.
