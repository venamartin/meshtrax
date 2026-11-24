# MeshTrax docs

MeshTrax is an app for MeshCore LoRa radios: long-range radios that pass messages to each other with no phone network or internet. New words are explained in the [glossary](glossary.md).

## For everyone

| Page | What it covers |
|---|---|
| [Glossary](glossary.md) | Mesh, repeater, flood, route, advert and the other words you'll meet |
| [What's new](whatsnew.md) | What changed in each release |
| [Pathfinder](pathfinder.md) | How MeshTrax learns routes so your private messages get through |
| [Offline maps](offline-maps.md) | Downloading maps that work with no signal |
| [Photos](photos.md) | Sending photos over the mesh, and what a rebuilt photo is |
| [Privacy policy](privacy.md) | What the app stores, what it sends, and to whom |
| [Terms of use](terms.md) | The rules for using MeshTrax |

## For other app makers

| Page | What it covers |
|---|---|
| [Message format](message-format.md) | How MeshTrax writes replies, reactions, GIFs and cards into a message, so other apps can read them |
| [proposals/](proposals/) | Suggestions written for other app projects, and formats planned for MeshTrax (weather alerts) |

## For contributors

[technical/](technical/) holds the detailed material: protocol references, design records, plans and finished investigations. Each file starts with a short note saying what it is and whether it's current. They double as the working notes of the AI-assisted sessions that build MeshTrax, so they go into more detail than most readers need.

| Page | What it covers |
|---|---|
| [MeshCore protocol](technical/meshcore-protocol.md) | Byte-level reference for radio packets and app ↔ radio frames |
| [BLE protocol](technical/BLE_PROTOCOL.md) | Older overview of the Bluetooth connection and commands |
| [Pathfinder design](technical/path-graph-design.md) | Pathfinder's design, decisions and evidence rules |
| [Pathfinder build plan](technical/path-graph-implementation.md) | The original build plan (finished) |
| [TRAX mode](technical/trax-mode.md) | Moving a group's radios off the regular mesh and back: saved settings, the settings write, the TRAX message, Leave |
| [Regions](technical/regions.md) | Messages that travel only through one area's repeaters: firmware facts, decisions and the plan |
| [Offline maps notes](technical/offline-maps-notes.md) | Where the map code and data live, decisions, pitfalls |
| [Offline maps roadmap](technical/offline-maps-roadmap.md) | The offline maps plan and its status |
| [Report inbox](../tools/report-inbox/README.md) | The Cloudflare Worker that emails in-app reports to the developer, and keeps nothing |
| [Park maps](technical/park-maps.md) | Planned park map overlays (not built) |
| [Database plan](technical/phase3d-cut-plan.md) | How the message database became the one source of messages (finished) |
| [Bluetooth auto-connect findings](technical/ble-autoconnect-findings.md) | Three auto-connect bugs and their fixes (finished) |
| [Photos](technical/photos.md) | How photos work: the packet format, the photo model and its runtime, memory, safety and the rules on MeshCore frequencies |

To build the app or send a change, start with [CONTRIBUTING.md](../CONTRIBUTING.md).

## Store and release

Used when publishing MeshTrax to the app stores.

| Page | What it covers |
|---|---|
| [App Review notes](app-review-notes.md) | Ready-to-paste text for Apple's review forms |
| [App Store](store/app-store-notes.md) | iOS and Mac App Store releases |
| [Google Play](store/google-play-notes.md) | Setting up and running Play releases |
| [Microsoft Store](store/microsoft-store-notes.md) | Building and submitting the Windows package |
| [Photos in the stores](store/photo-review-notes.md) | What the App Store and Google Play ask of photos, and how MeshTrax meets it |
