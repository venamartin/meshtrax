# MeshTrax

**MeshTrax** is a free, open-source client for **[MeshCore](https://meshcore.io/)** LoRa mesh-networking radios. Chat across long-range, off-grid mesh networks — no towers, no internet, no accounts.


> **MeshTrax is UNOFFICIAL.**
> It is an independent, community-built app. It is **not** affiliated with, endorsed by, or supported by MeshCore or its creator. If you want the first-party experience, please use the **official MeshCore app** (see credits below).

---

## Credit

MeshTrax exists only because of the incredible work of the people who built the MeshCore ecosystem. Please support them:

- **[MeshCore](https://meshcore.io/)** — the open, lightweight LoRa mesh radio protocol, firmware, and official apps — is created and maintained by the MeshCore project and its community. It is the entire foundation this ecosystem, and this app, are built on. **If you want the official, best-supported experience, use the official MeshCore app, available from [meshcore.io](https://meshcore.io/).**

- **[MeshCore Open](https://github.com/zjs81/meshcore-open)** and its contributors — the fabulous open-source Flutter client that **MeshTrax is forked from.** MeshTrax builds directly on their excellent work.

MeshTrax is simply one more community client in the MeshCore world. All credit for the protocol, firmware, and official apps goes to the **MeshCore project and its creators**; all credit for the client foundation goes to **MeshCore Open** and its contributors.

Learn more about MeshCore:
- Official site: <https://meshcore.io/>
- Documentation: <https://docs.meshcore.io/>
- Protocol / firmware: <https://github.com/meshcore-dev/MeshCore>

---

## 📷 Screenshots

<!-- TODO: replace these placeholders with real screenshots (phone + tablet). -->
<!-- Suggested location: docs/store/screenshots/ -->

| Unified chats | Channel | Map |
|:---:|:---:|:---:|
| _screenshot coming soon_ | _screenshot coming soon_ | _screenshot coming soon_ |

---

## Features

- **Unified chat inbox** — all your direct messages and channels together in one modern, messaging-app-style conversation list (think Signal/WhatsApp), rather than scattered across separate screens.
- **Direct & channel messaging** — 1:1 messages and encrypted channels secured with pre-shared keys.
- **Rich chat** — swipe-to-reply, emoji reactions, and inline GIFs.
- **Reliable delivery** — message delivery status and automatic retry over the mesh.
- **Background notifications** — get notified of new messages even when the app is closed, with a foreground service that keeps your radio connected.
- **Contacts** — add contacts by scanning or sharing QR codes, and organize them into groups.
- **Map** — see nodes, repeaters, and neighbors on an interactive map; cache map areas for offline use; run line-of-sight terrain analysis; export tracks as GPX.
- **Telemetry** — view device and repeater sensor readings and battery levels.
- **Routing tools** — message path tracing and automatic route rotation for better delivery.
- **Moderation** — block abusive senders and report objectionable content.
- **Auto-connect** — reconnect to your last device automatically on launch.
- **Themes & languages** — light/dark themes and many localizations.

### Connect your way
- **Bluetooth Low Energy (BLE)** — wireless pairing with your radio
- **USB serial** — wired connection, where supported
- **Local network / Wi-Fi (TCP)** — connect over your network by IP

---

## Requirements

MeshTrax is a **client** — it requires a compatible **MeshCore** device (a supported LoRa radio running MeshCore firmware) to do anything useful. It is not a standalone messenger. See <https://meshcore.io/> for supported hardware and firmware.

---

## 🚀 Getting started

- **Google Play:** _coming soon._
- **Build from source:** see below.

### Build from source

MeshTrax is a [Flutter](https://flutter.dev/) app.

```bash
# Install dependencies
flutter pub get

# Run on a connected device
flutter run

# Build an Android APK
flutter build apk

# Run on Windows
flutter run Windows

# Run on Linux
flutter run linux
```

---

## Privacy & Terms

- [Privacy Policy](docs/privacy.md)
- [Terms of Use](docs/terms.md)

MeshTrax has no accounts, no analytics, and no MeshTrax servers. Your messages, contacts, and keys are stored only on your device and exchanged only with your own MeshCore hardware and the LoRa mesh. See the Privacy Policy for the full details, including the optional map/terrain/GIF features that connect to third-party services.

---

## License

MeshTrax is released under the **MIT License**. It is a fork of [MeshCore Open](https://github.com/zjs81/meshcore-open); see [LICENSE](LICENSE) for copyright details.

## Acknowledgments

- The **[MeshCore](https://meshcore.io/)** project and its creators — the protocol, firmware, and official apps that make all of this possible.
- **[MeshCore Open](https://github.com/zjs81/meshcore-open)** and its contributors — the upstream client MeshTrax is built from.
- Built with [Flutter](https://flutter.dev/).
- Map tiles from [OpenStreetMap](https://www.openstreetmap.org/); elevation data from [Open-Meteo](https://open-meteo.com/); GIFs from [Giphy](https://giphy.com/).
