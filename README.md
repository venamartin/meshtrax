# MeshTrax

**MeshTrax** is a free, open-source client for **[MeshCore](https://meshcore.io/)** LoRa mesh-networking radios. Chat across long-range, off-grid mesh networks — no towers, no internet, no accounts.

> ⚠️ **MeshTrax is UNOFFICIAL.**
> It is an independent, community-built app. It is **not** affiliated with, endorsed by, or supported by MeshCore or its creator. If you want the first-party experience, please use the **official MeshCore app** (see credits below).

---

## 🙏 Huge credit — this stands on the work of others

MeshTrax exists only because of the incredible work of the people who built the MeshCore ecosystem. Please support them:

- **Liam Cottle** — creator of **[MeshCore](https://meshcore.io/)**, the open, lightweight LoRa mesh radio protocol and firmware, and author of the **official MeshCore companion app** ([Google Play](https://play.google.com/store/apps/details?id=com.liamcottle.meshcore.android) · [App Store](https://apps.apple.com/us/app/meshcore/id6742354151)). Liam's work is the entire foundation this whole ecosystem — and this app — is built on. **If you want the official, best-supported experience, use Liam's app.** MeshTrax is just a community alternative that would not exist without him.

- **[MeshCore Open](https://github.com/zjs81/meshcore-open)** by **zjs81** and its 30+ contributors — the fabulous open-source Flutter client that **MeshTrax is forked from.** Enormous thanks to that community; MeshTrax builds directly on their excellent foundation.

All credit for the protocol, firmware, and ecosystem goes to **Liam and MeshCore**. All credit for the client foundation goes to **MeshCore Open**. MeshTrax is simply one more community client in that world.

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

## ✨ Features

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

## 📱 Requirements

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

# Build an Android App Bundle (for the Play Store)
flutter build appbundle
```

---

## 🔒 Privacy & Terms

- [Privacy Policy](docs/privacy.md)
- [Terms of Use](docs/terms.md)

MeshTrax has no accounts, no analytics, and no MeshTrax servers. Your messages, contacts, and keys are stored only on your device and exchanged only with your own MeshCore hardware and the LoRa mesh. See the Privacy Policy for the full details, including the optional map/terrain/GIF features that connect to third-party services.

---

## 📄 License

MeshTrax is released under the **MIT License**. It is a fork of [MeshCore Open](https://github.com/zjs81/meshcore-open) (© 2025 zjs81). See [LICENSE](LICENSE).

## Acknowledgments

- **Liam Cottle** and the **[MeshCore](https://meshcore.io/)** project — the protocol, firmware, and official app that make all of this possible.
- **[MeshCore Open](https://github.com/zjs81/meshcore-open)** (zjs81 and contributors) — the upstream client MeshTrax is built from.
- Built with [Flutter](https://flutter.dev/).
- Map tiles from [OpenStreetMap](https://www.openstreetmap.org/); elevation data from [Open-Meteo](https://open-meteo.com/); GIFs from [Giphy](https://giphy.com/).
