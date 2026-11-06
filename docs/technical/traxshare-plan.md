# Location sharing on private channels: plan

> **What this is:** The build plan for sharing positions and short trails among the members of a private channel, over the radios, with no internet. Code name `traxshare`. It replaces an earlier draft spec written without access to the code. Every firmware and app fact below was checked against `./MeshCore` (tag companion-v1.18.0) and MeshTrax master `8b42148b` on 2026-11-05. The session building #210 then rechecked everything this plan takes from #210 against its head `9ba6f98`: the layers sheet, the pin sheet, Route here and the files both change.
>
> **Who it's for:** the developer or AI session building it.
>
> **Status:** active plan, nothing built. The work happens on branch `feat/traxshare` (draft PR).
>
> New to the terms? See the [glossary](../glossary.md).

## The feature in one paragraph

A member of a private channel taps **Where is everyone?** Each member who agrees answers once with their radio's GPS position, and, if they keep a track, a short trail of where they've been. Answers show as pins and lines on the map and in a strip at the top of the channel, never as chat messages. A pin offers **Route here** through the offline routing from #210. Later in the plan, a member can start timed sharing for up to 4 hours, reaching people in direct radio range. Nothing goes to a server, and the phone's own GPS is not used.

## Start here: working rules

These are how the owner, Martin, runs this repo. A session in a new worktree doesn't see the project's memory, so they're written out here.

**Git**
- `git fetch origin`, then branch from `origin/master`, never from local master. Work in a worktree (`git worktree add ../meshtrax-<topic> <branch>`); other sessions share the main checkout and may switch its branch. Stop processes by PID, never by name.
- Never commit on master. Stage named files only, never `git add -A`.
- Commit locally. Push only when Martin has tested and says so: the repo is public.
- "Ship it" means push, open or update the PR, wait for the `analyze` check, squash-merge, delete the branch, sync master. It never means a store release.

**Test builds for Martin's phone**
- Bump the version (patch and build number) above what is on his phone. That was 1.9.9+166 on 2026-11-05. Check `origin/master`'s `pubspec.yaml`, the tags and other open branches first.
- Commit the bump, then build with `./buildapk.sh`, never `flutter build apk`. Hand over `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.
- A worktree lacks four untracked files: copy `buildapk.sh`, `android/key.properties`, `giphy.key` and `pubspec.lock` from the main checkout. Never commit `giphy.key`.
- Ask Martin whether the bump stays in the PR. For #229 he had the test bumps reverted before merging.

**Radios**
- Firmware truth is the git-ignored checkout `./MeshCore` in the main repo folder (companion-v1.18.0). Comments and docs are not evidence; read the code path.
- Heavy or repeated transmissions go on 920.000 MHz only. On the live mesh (910.525 MHz), send at most a couple of frames.
- Never retune a radio in the US to 869 or 433 MHz to test Step 1B. 869 MHz is a cellular band there and 433 MHz needs an amateur licence.
- Ask before touching repeater F857. Bench radios and addresses are in `integration_test/harness/bench_config.dart`.

**Screens and text**
- Plain words on screen. Keep "airtime", "hop", "flood" and "zero-hop" off everyday controls; say what they mean ("people in direct range").
- Every new string goes in all 17 language files (`lib/l10n/app_*.arb`), with no hard-coded text.
- Dates and times go through `DateTimeHelper`; distances through `GeoFormat.distanceText` with the user's unit setting. Once #210 is in, coordinates follow its coordinate-format setting.
- Never name other apps in code, docs, commits or PR text.
- Before an APK with a new screen, render it at phone size (1080×2340 at 2.625) with real fonts and look at it. Widget tests use a block font and hide layout problems.

**Tests**
- Inject clocks. Connector code calls `DateTime.now()`, which `fakeAsync` doesn't move.
- Known Windows-only failures, not caused by a branch: `contact_advert_evidence_test` (timing), traxmap's `style_registry_test` (4) and `gap_fill_provider_test` (2). CI runs the full suite on Ubuntu.
- After `flutter test` or `pub get`, line-ending-only changes appear in `lib/l10n/` and the plugin registrants: `git checkout -- lib/l10n linux macos windows`.
- `build_runner --delete-conflicting-outputs` deletes the checked-in `lib/l10n/*.dart`; restore them from git.
- Multi-line `sed` or `perl` edits fail on this CRLF tree.

**Working with Martin**
- Put open decisions in the question dialog, one per decision, with your recommendation first.
- Don't start review agents unless he asks.
- The mesh simulator runs in its own session (`meshsimulator-0f`, repo `../meshsimulator`). Ask it by message whether it can run a five-member test. It must not touch the meshtrax checkouts.

## Owner decisions

| Topic | Decision | Date |
|---|---|---|
| Which channels | Private channels only. Never Public, hashtag channels or rooms. | draft spec |
| Position source | The companion radio's GPS. No phone GPS, no new permissions. | 2026-10-31 |
| Group size | Designed for up to about 5 | 2026-10-31 |
| Where positions show | The map, plus a sharing strip in the channel. Never chat rows: no unread count, Reply or React. | 2026-10-31 |
| Consent | Ask every time. No always-approve, because any member can forge the sender ID in a packet. | 2026-10-31 |
| Position in a DM | The existing Telemetry request. No new format. | 2026-10-31 |
| Own track | Opt-in. Kept by distance, default 10 miles, never by age. Small. Kept raw, so it can later be saved as a route. | 2026-10-31 |
| Reach of a one-time reply | The position may go through repeaters. A reply with a trail stays in direct range. | 2026-10-31 |
| Off-grid group mode | Later, in its own PR, after field use | 2026-10-31 |
| Package name | `packages/traxshare` | 2026-11-05 |
| PR shape | This draft PR becomes the feature PR: Steps 2–4, with Martin testing between steps. Step 1 goes first in its own small PR. | 2026-11-05 |
| Order against #210 | Step 1, Step 2 and Step 3's connector part start now. Step 3's screens, settings and coordinate display start after #210 (offline routing and points of interest) merges. | 2026-11-05 |
| Route here | Yes, in Step 3 | 2026-11-05 |

## Steps

### Step 1: two standalone fixes (own small PR, at least one release before Step 3)

Both are bugs today, with or without this feature.

**1A. Message download stalls on channel datagrams.**
- **Problem:** the radio queues every channel datagram it can decrypt (any app, any data type, any channel it holds, Public included) and tells the app a message is waiting (`MeshCore/examples/companion_radio/MyMesh.cpp:601-637`). The app's frame switch has no case for code 27 and lands in `default: debugPrint('Unknown frame code')` (`_handleFrameInner` in [meshcore_connector.dart](../../lib/connector/meshcore_connector.dart), about line 6582).
- **Effect:** `_handleQueuedMessageReceived()` is never called, so the drain waits for its 5 s watchdog (`_queueSyncTimeoutMs`). After `_maxQueueSyncRetries` (3) more timeouts in a row it gives up until the next "message waiting" push. Messages behind the datagrams wait, and the datagrams themselves are lost, since the radio has already removed them.
- **Fix:** add `case respCodeChannelDataRecv:` that calls `_handleQueuedMessageReceived()`, which is safe when no drain is running. Nothing else in Step 1; Step 3 adds the parsing.
- **Test** with `handleFrameForTest`: one datagram then a channel text, which must be handled with no 5 s wait; four datagrams in a row, after which the drain must keep going.

**1B. Off-Grid Repeat refused on the 869 MHz band, but reported as done.**
- **Problem:** `_offGridFrequencyForBaseFrequency` in [settings_screen.dart](../../lib/screens/settings_screen.dart) (about line 2023) returns 433.0, 869.0 or 918.0, and the hidden "Off-Grid 869" preset in [radio_settings.dart](../../lib/models/radio_settings.dart) uses 869.0.
- **Firmware rule:** repeat is allowed only on exact frequencies, 433000, 869495 and 918000 kHz from 1.16 (869000 in 1.13–1.15) (`MyMesh.cpp:1032-1048`). A refused frame changes nothing (`MyMesh.cpp:1439-1440`), but the dialog sends `buildSetRadioParamsFrame` without waiting and reports success.
- **Fix:** ask the radio with CMD 60 (`cmdGetAllowedRepeatFreq`; reply code 26 = `[26]` then pairs of u32 LE lower and upper bounds in kHz; firmware ver code 9 or later, the same gate as repeat). Use the allowed frequency in the radio's band. Wait for the OK or ERR to CMD 11 and show the error instead of success.
- **Note:** CMD 11 sent without its trailing repeat byte turns repeat off.
- **Test:** unit tests for the CMD 60 builder and parser, the band choice and the error path. No over-the-air test on 869 MHz in the US.

### Step 2: `packages/traxshare` (pure Dart)

- **Shape:** model it on `packages/path_graph`: pure Dart, with `drift` and `crypto` as dependencies, an injected database executor and clock, and no connector import. Public API in `lib/traxshare.dart`.
- **CI:** add analyze and test steps to [.github/workflows/flutter_dart.yml](../../.github/workflows/flutter_dart.yml), the same way path_graph and traxmap have them (#210 does this for its own packages).
  - #210 also changes this file, `pubspec.yaml`, `lib/main.dart` and the 17 `app_*.arb` files. If Step 2 or 3a reaches master first, the conflicts are additions side by side. They get resolved when #210 merges master in.
- **Modules** under `lib/src/`:
  - `codec/`: bit writer and reader, zigzag, exp-Golomb, packet encode and decode ([wire format](#wire-format-version-1))
  - `movement/`: the movement gate, derived heading and speed, fix age ([rules](#position-and-movement))
  - `trail/`: window, simplify, quantize, fit to budget ([recipe](#trail-recipe))
  - `gate/`: `isSharableChannel(name, psk)` ([channel gate](#channel-gate))
  - `session/`: request, consent, keepalive and stop state machines
  - `scheduler/`: interval, jitter, heartbeat
  - `db/`: Drift tables and retention ([storage](#storage))
- **Done when:** the package tests listed under [Verification](#verification) pass. Nothing on screen yet.

### Step 3: one-time sharing on private channels

**3a. Connector and service. Can start before #210 merges, which doesn't touch the connector.**
- **Protocol helpers** in [meshcore_protocol.dart](../../lib/connector/meshcore_protocol.dart): `buildSendChannelDataFrame(channelIdx, pathLen, dataType, payload)`, where `pathLen` is `0xFF` for flood or `0` for zero-hop and never an explicit path, plus `parseChannelDataFrame`.
- **Firmware gate:** `supportsChannelData` is firmware ver code 11 or later, following `supportsCompanionRadioStats`.
- **Receiving:**
  - The frame 27 case parses the frame and adds it to a `channelData` stream, like `sensorPushes`. It still always calls `_handleQueuedMessageReceived()`.
  - Each frame carries a live or backlog tag. Backlog means it arrived before `_completedFirstQueueDrain` was set after connecting.
  - Resolve `channel_idx` against the live, verified channel list only (the `_liveChannelByIdKey` pattern). Never use `_findChannelByIndex`, which falls back to an old cached layout. If the slot is unknown or the sync is unverified, drop the frame; positions are perishable.
- **Sending:**
  - Use `_sendAndWaitForAck(frame, expectsGenericAck: true)`, with no retry and never queued. CMD 62 answers OK or ERR, never SENT, and OK only means queued.
  - Show the result in the strip. Errors at 1.18: 6 ILLEGAL_ARG, 2 NOT_FOUND, 3 TABLE_FULL. TABLE_FULL means the radio's packet pool is momentarily empty.
- **Errors, in `_handleErrorFrame`:**
  - Since #226 each pending-reply entry records its `commandCode`, and a failed write already removes its entry.
  - Read the head entry before the contact-table-full check, which today runs first. If the head is CMD 62, skip that event and set a flag that Pathfinder's frame adapter reads, so its "first ERR after a pending discovery" rule ([frame_adapter.dart](../../lib/services/path_graph/frame_adapter.dart), about lines 577–599) doesn't blame a discovery.
  - This is best effort: commands sent without `expectsGenericAck` can still misorder replies.
- **Repeater evidence:** leave `MessageRetryService.noteRepeaterHeard` alone. A relayed flood of ours really does prove a repeater hears this radio.
- **Service:** `TraxShareService` in `lib/services/traxshare/` owns the database ([node scope](#storage)), the position adapter over `connector.selfGps`, own-track recording and sessions. It starts in `main.dart`.
- **Own track:**
  - The opt-in setting and the distance setting live in Settings.
  - While recording, hold a position viewer (`addSelfPositionViewer` / `removeSelfPositionViewer`) so the radio is read every 10 s. Reading the radio is a serial command and sends nothing over the air.
  - Nothing is recorded while disconnected; gaps are expected.

**3b. Screens. Start after #210 merges; rebase this branch onto master first.**
- **Menu:** the channel's ⋮ menu (`PopupMenuButton<String>` in [channel_chat_screen.dart](../../lib/screens/channel_chat_screen.dart), about line 1173) shows **Where is everyone?** only when the [channel gate](#channel-gate) passes and the firmware supports datagrams. Choices: position only, or position and trail.
- **Flow:**
  1. The request goes out. The requester's strip shows it waiting.
  2. A member sees a consent dialog, plus a notification that follows the channel's mute rule (muted: strip only). The dialog:
     - names the claimed sender as unverified, falling back to the hex prefix when no contact matches
     - says the whole channel will see the answer
     - says anyone who has the channel key can read it
  3. Requests are rate limited per sender. Resolve names with `contactByKeyPrefix4` and apply `isSenderBlocked`. **Ignore this sender** is stored by prefix, so senders who aren't contacts can be silenced too.
  4. Approve sends one report, following the [position rules](#position-and-movement).
     - A radio with no GPS says so in the dialog and sends nothing; its user can still see the map.
     - A trail needs the own track turned on. When it's off, the reply is position only and the dialog offers the setting.
- **Sharing strip:** its own widget in the channel body, shaped like `PathfinderMeshBanner`. It is not part of the `??` banner chain, so a disconnect banner doesn't hide it.
  - It shows waiting requests, who answered (with **Show on map**), active sessions and **Stop**.
- **Map:**
  - **Layers:** one `MapMarker` per person with a stable id, a `MapLine` trail, and a generated `MapPolygon` ring only when a position is approximate (accuracy class 1 or above). Faded and ended styles follow the [thresholds](#display-thresholds).
  - **Switch:** a **People sharing** switch in the layers sheet.
    - Since #241 every entry has a picture.
    - The marker switches (Repeaters, Chat nodes, Other nodes, Pins, Guessed) sit under **Nodes** (`_nodeLayers` in map_screen.dart), each pictured by its marker's badge.
    - #210's Places and Parks sit under **Details**, with map thumbnails from `assets/map_layers/`.
    - People sharing draws markers, so it fits under Nodes, with its own badge. Show Martin a render first.
  - **Performance:** feed lines from a cut-down copy per person, at most 200 points, recomputed only when a point is added. The map rebuilds its overlays on every connector notify. #210 adds a rebuild 300 ms after every pan at zoom 12 and above, when it loads the places in view. Map markers are already the main cost on a busy map (Windows profile, 2026-10-31).
  - **Updates:** the map subscribes to `TraxShareService` itself and repaints when a position or style changes. Keep Trax data out of the message pin scan.
  - **Pin sheet:** name, coordinates in the user's coordinate format (#210's setting, traxcoords), age through `DateTimeHelper`, and **Route here**. That opens #210's route panel with the person's name and position as the destination.
    - Reuse what #210's long-press sheet on the map does (`_showShareMarkerAtPositionSheet` in map_screen.dart):
      - `coordFormatOf(settings)` and `positionLines(lat, lon, format)` for the coordinates, with `CopyPositionButton`
      - `_routeHere(name, point, selfPosition)` for Route here, shown when `RoutingService.available`; with no routing data installed, it says so
- **Telemetry:** unchanged on the wire. A reply that carries a GPS position also updates that person's pin.
- **Who can see my location** ([location_sharing_button.dart](../../lib/widgets/location_sharing_button.dart)):
  - Check Trax before the `hasSelfPosition` early return in `positionVisible`.
  - Add a dialog row **Sharing with <channel> · Stop**, and a headline that outranks "Nobody can see your location".
  - **Share my location** off also stops sharing. The row is the main control, because on a radio with default privacy settings that switch already shows off.
- **Settings:** own track on or off, kept distance (presets per unit system; stored in metres; default 16,094 so it shows "10 mi", or "16 km" in metric), and **Delete all sharing data**.
- **Privacy text:** `docs/privacy.md` is Martin's legal text, so draft the changes in the PR for him and don't edit the file. The sentences affected on master `8b42148b`:
  - the data table (line 32 area), for a new row on own and others' tracks
  - device backups (line 41), since the track stays out of them like maps
  - background use (lines 94 and 108), since it now includes sending positions
  - Location messages (line 132), for automatic replies
  - retention (line 140)
- **Store text:** the store lines "No ads, analytics, or tracking" ([app-review-notes.md:142](../app-review-notes.md), [store/microsoft-store-notes.md:208](../store/microsoft-store-notes.md)) and the Play Data safety answers also need his look.

**Routing of each send**

| Send | How |
|---|---|
| One-time request | flood |
| Reply without a trail | flood |
| Reply with a trail | zero-hop if the request was heard directly (`path_len` 0xFF, or `path_len & 63 == 0`), otherwise a position-only flood |
| Timed session: request, keepalive, reports, STOP | zero-hop |

### Step 4: timed sharing, direct range only

- **Choices:** the requester picks an interval (2, 5 or 10 min) and a duration (15, 60 or 240 min; hard cap 240). Everything in a session goes zero-hop, so it reaches direct radio range only, and the screen says so in plain words.
- **Requester reports:** the requester shares too (mask bit 5) and sends a keepalive request (flag b2) every 5 minutes.
- **Consent:** a member is asked once per session.
  - Their timer resets on any packet from the requester for that session, reports included. Sharing pauses after 12.5 minutes of silence.
  - A later packet for the same session resumes within the approved time, with no new prompt.
  - A decline holds for the whole session. A keepalive for an unknown session is a late join and prompts once. STOP from either side.
- **Scheduler:**
  - ±20 % jitter on every send.
  - A stationary heartbeat every 15 minutes, using the movement gate.
  - The effective interval is `max(chosen, N × 20 s)`, with N the senders heard in the session.
  - A trail every 5th report, and no sooner than 10 minutes after the last.
- **Disconnects and app kills:**
  - On disconnect, stop sending but keep the session until it expires. On reconnect, resume if it's the same radio key and the channel is verified; otherwise end.
  - If the app is killed, the session ends and the others time out.
- **Stop button on Android:** the foreground notification gets a Stop button.
  - `BackgroundService` holds the session state, so `start()` puts back the title, text and button, including across BLE↔TCP switches. End with an empty button list.
  - A USB connection runs without the service today, so start it for a session. Messages from the task go to the main isolate through `initCommunicationPort`.
  - Swiping the app away ends the session (`stopWithTask`).
- **Other platforms:** on iOS, promise no background sharing until a device test. On Windows and Linux, in-app only.
- **Help text,** in plain words: these packets share the radio's message queue with channel messages while a phone is away. Five members at 2 minutes is about 2 frames a minute on each away radio. That fills 256 slots in about 2 hours, 128 in about 1 hour and 16 in about 7 minutes, and then the oldest channel messages are lost first.

### Later: off-grid group mode (own PR, after field use)

The group retunes to an allowed off-grid frequency with Off-Grid Repeat on, so every radio repeats for the others. Known needs:
- **Radio settings:**
  - the allowed list from CMD 60
  - a durable snapshot of the radio's settings taken before the session, kept by radio key and checked on every connect, since the radio stays retuned and repeating if the phone dies
  - the repeat byte on every radio-settings write
  - one shared preset for the group
- **Health check:** the `radio_client_repeat` and `radio_frequency` rules must know about an active session.
- **Retune side effects:**
  - clear `_directRepeaters`
  - expect a full contact download on each retune
  - routes carry over between meshes, because each contact has one
  - parked DMs
  - `syncPathGraph` restarting Pathfinder on any settings change (Pathfinder is on for new installs since #221)
- **Airtime and hardware:**
  - airtime grows with the square of the group size
  - test on hardware whether a retune takes effect during receive
  - check battery life with repeat on
- **Naming:** must not clash with the existing **Off-Grid Repeat** setting.

## Firmware facts (companion-v1.18.0)

All lines are in `./MeshCore`.

| Fact | Where |
|---|---|
| **Send:** CMD 62 `[62][channel_idx][path_len][path…][data_type u16 LE][payload]`. `path_len` 0xFF = flood under the radio's default flood scope; 0 = zero-hop. Replies OK or ERR, never SENT; OK means queued. | `examples/companion_radio/MyMesh.cpp:1198-1237`, `src/helpers/BaseChatMesh.cpp:539-568` |
| **Errors:** 6 ILLEGAL_ARG (frame under 4 bytes, bad `path_len`, data_type 0, payload over 165), 2 NOT_FOUND (channel_idx out of range; an empty slot is not refused), 3 TABLE_FULL (packet pool empty, try later). Up to 1.17.1, 166–167 bytes gave TABLE_FULL instead. | `MyMesh.cpp:1198-1237` |
| **Size:** 165 bytes accepted. Keep to 157 or less: a raw packet over 173 bytes never appears in the RX log push (0x88), so bigger packets give no diagnostics. | `src/MeshCore.h:20-21`, `MyMesh.cpp:291-292` |
| **Receive:** frame 27 through the offline queue: `[27][snr×4 i8][0][0][channel_idx][path_len][data_type lo][hi][data_len][payload]`. No sender, no timestamp, no path bytes. `path_len` 0xFF = arrived route-direct (zero-hop here); otherwise a flood, hop count `path_len & 63`. A flood heard from its sender reports 0, not 0xFF. | `MyMesh.cpp:601-637` |
| **Zero-hop** is delivered by every companion in range holding the channel and forwarded by nobody: repeaters and repeating companions forward floods only. No scope, no flash write. | `src/Mesh.cpp:225-251, 344-357, 693-715` |
| **Duplicates:** the packet hash covers type and encrypted payload (path and route ignored), and a 160-entry ring drops repeats for a long time. Every send must differ, which `seq` and `sent_at` guarantee. | `src/Packet.cpp:41-50`, `src/helpers/SimpleMeshTables.h` |
| **Encryption:** AES-128 in ECB mode, no IV, 2-byte MAC with the channel key. Any member can forge another; identical 16-byte blocks encrypt identically. | `src/Utils.cpp:85-145` |
| **Offline queue:** datagrams share it with channel text. When full, the oldest channel frame (text or datagram) is deleted. 256 slots on Heltec V3/V4 BLE builds, 128 on some boards, 16 by default; not reported to the app; lost on reboot. | `MyMesh.cpp:219-246`, `variants/*/platformio.ini` |
| **Version gate:** channel datagrams need FIRMWARE_VER_CODE 11 (companion 1.15). Members on older firmware get nothing. | release tags |
| **data_type:** FF00–FFFF is free for development (use 0xFF54). Before release, one ID in 0100–FEFF is requested by a PR to `docs/number_allocations.md`, after showing the app works. The newest taken value is 0150 (firmware `dev`, November 2026). | `docs/number_allocations.md` |
| **Position:** lat, lon and altitude only; no heading, speed, accuracy or fix flag. Self telemetry gives 0.0001° (about 11 m) and altitude to 0.01 m. On most boards it carries the position whenever GPS is on, and with no fix it repeats the last or stored position. | `src/helpers/sensors/EnvironmentSensorManager.cpp:687-688, 931-946`, `MyMesh.cpp:981-982` |
| **Don't use:** CMD 63 (set default flood scope) rewrites all settings to flash on every call. CMD 13 (reset path) rewrites the contacts file. | `MyMesh.cpp:1989-2005, 1317-1327` |
| **Airtime** at SF7, 62.5 kHz, CR 4/5, 32-symbol preamble: 17- or 29-byte payload = 37 bytes on air, about 214 ms (53 ms at 250 kHz); 157-byte payload = 165 bytes, about 582 ms; 12-byte STOP = 21 bytes, about 162 ms. Payloads pad to 16-byte blocks, so 13, 29, 45 … 157 bytes are the largest sizes at each cost. | `src/Mesh.cpp:540-558`, `src/helpers/radiolib/RadioLibWrappers.h:56` |

## Wire format, version 1

The `data_type` is 0xFF54 during development. Multi-byte numbers are little-endian; the trail bitstream is MSB-first.

### Common header (12 bytes, every packet)

| Offset | Size | Field | Notes |
|---|---|---|---|
| 0 | 1 | version / subtype | high 4 bits version (1), low 4 bits subtype: 1 REQUEST, 2 REPORT, 3 STOP; others reserved |
| 1 | 1 | seq | per sender, +1 on every send, wraps |
| 2 | 4 | sender_prefix | first 4 bytes of the sender's public key. A claim, not proof. |
| 6 | 2 | session | u16, random, chosen by the requester. A one-time request gets a new one too. |
| 8 | 4 | sent_at | u32, Unix seconds from the phone's clock |

On an unknown version, read the common header only, show "<name> has a newer MeshTrax" once per session in the strip, and decode nothing more. Receivers drop repeats of `(sender_prefix, session, seq)`.

### REQUEST (subtype 1, 17 bytes)

| Offset | Size | Field | Notes |
|---|---|---|---|
| 12 | 1 | flags | b0 trail wanted, b1 timed session, b2 keepalive. Reserved, sent as 0: b3 per-point times, b4 per-point altitude, b5 off-grid session. |
| 13 | 1 | interval_code | 0 one-time, 1 = 2 min, 2 = 5 min, 3 = 10 min |
| 14 | 1 | duration_min | 1–240; 0 for one-time |
| 15 | 1 | trail_window | 0.1 km units; 0 = no trail; 161 = 10 miles; at most 25.5 km |
| 16 | 1 | accuracy_wanted | reserved, 0 |

### REPORT (subtype 2, 29 bytes plus the trail)

| Offset | Size | Field | Notes |
|---|---|---|---|
| 12 | 2 | field_mask | bits below |
| 14 | 7 | position | 56-bit value, little-endian: `lat_u << 31 \| lon_u << 5 \| accuracy_class` |
| 21 | 2 | fix_age_s | seconds since the radio's reading last changed; 0xFFFF = 18 hours or more |
| 23 | 1 | heading | `round(degrees × 256 / 360) mod 256` |
| 24 | 1 | speed | 0.5 m/s units; 255 = 127.5 m/s or more |
| 25 | 2 | altitude_m | int16 |
| 27 | 1 | grid_unit_m | metres per trail step; 0 = no trail |
| 28 | 1 | point_count | trail points that follow |
| 29 | n | points | bitstream below; the whole payload stays within 157 bytes, so the trail gets at most 128 |

Position encoding:
- `lat_u = round((lat + 90) × 100000)` (0–18,000,000, 25 bits)
- `lon_u = round((lon + 180) × 100000) mod 36,000,000` (26 bits)
- `accuracy_class` (5 bits):
  - 0 = as the radio reports it
  - n ≥ 1 = within 2^(n−1) m, kept for a possible "approximate position" choice
  - v1 senders send 0; receivers still draw a circle for n ≥ 1.

| Mask bit | Meaning |
|---|---|
| 0 | heading valid |
| 1 | speed valid |
| 2 | altitude valid |
| 3 | fix_age valid |
| 4 | moving |
| 5 | sent by the session's requester |
| 6–7 | reserved |
| 8 | per-point time present (v1: off) |
| 9 | per-point altitude present (v1: off) |
| 10–14 | reserved |
| 15 | an extension block follows the points: u8 length, then bytes; decoders that don't know it skip it |

- **Unused fields:** a field whose mask bit is clear is sent as 0.
- **fix_age:** saturated at 0xFFFF, it would make every report from a parked radio repeat its second cipher block, and ECB shows that to anyone in range. So at 0xFFFF, clear bit 3 and fill the field with random bytes instead.
- **Future changes:** append new header fields and gate them with a mask bit. Append new per-point fields in mask order. Changing an existing encoding bumps the version.

### Trail bitstream

- **Order:** points run newest first.
- **Anchor:** the report's own position, decoded from the 56-bit field, so both sides use exactly the same `lat0` and `lon0`.
- **Deltas:** point 0 is a delta from the anchor; point i is a delta from point i−1.
- **Local frame** in metres: `x = (lon − lon0) × cos(lat0) × 111320`, `y = (lat − lat0) × 111320`.
- **Quantize** each point to integers `X = round(x / grid)` and `Y = round(y / grid)`. Deltas are taken between these integers, so the receiver's running sums give back exactly the sender's points. Convert back to degrees only to draw.
- **Each point:**
  - `dX`, then `dY`: zigzag, then exp-Golomb order 3, in grid units; east and north positive
  - then `dt` if bit 8: exp-Golomb order 4, seconds back in time
  - then `dalt` if bit 9: zigzag plus exp-Golomb order 2, metres
- **Zigzag:** `u = v ≥ 0 ? 2v : −2v − 1`; back: `v = u even ? u / 2 : −(u + 1) / 2`.
- **Exp-Golomb, order k,** for `u ≥ 0`: `q = u >> k`; `m = floor(log2(q + 1))`; write `m` zero bits, then `q + 1` in `m + 1` bits, then the low `k` bits of `u`.
  - Example, k = 3 and u = 100: q = 12, m = 3, written as `000 1101 100`, 10 bits.
  - The earlier draft's "q zero bits" was wrong.
- **Padding:** after the last point, pad with zero bits to a byte boundary. The extension block (bit 15) starts there.

### STOP (subtype 3, 12 bytes)

The header only. From the requester, it ends the session for everyone. From anyone else, it ends only that member's sharing, and the others mark their pin ended.

## Rules

### Time

Tag every frame 27 live or backlog, as described in Step 3a.
- **Live:** fresh whatever `sent_at` says. Its age is local receive time plus `fix_age`, and it may prompt.
- **Backlog:** its age comes from `sent_at`. A backlog request older than 10 minutes, or stamped in the future, is dropped with no prompt.
- **Display:** shown ages never go below 0. When a live frame's `sent_at` is several minutes off local time, show that the sender's clock is off.

### Position and movement

- **What `selfGps.at` is:** the time the phone got the reply, not the time of a fix. The radio can't say whether it has one.
- **fix_age:** record when the lat/lon/alt reading last changed, and send seconds since then as `fix_age` (mask bit 3). Receivers show "position unchanged for N min".
  - Altitude comes in 0.01 m steps, so a live fix should keep changing it. Confirm this on the bench before relying on it.
- **Has a position:** `gpsOn`, and a reading younger than two read periods. The adapter drops 0,0 and stops when GPS goes off.
- **Consent dialog:**
  - Hold a position viewer while it is open, so the radio is read at once, and wait a few seconds for the answer.
  - A reading unchanged since connecting can be a stored position from before a restart. Send it only after the dialog says it may be old.
  - Never gate on `selfPositionIsLive`, which a parked radio never regains.
- **Read interval:** when sharing or recording starts, send `gps_interval:0` the way `setGps` does. Older app versions left some radios at 900 s.
- **Movement gate:** one 0.0001° step is about 11 m north–south and 9 m east–west, so a parked radio near a cell edge looks as if it moves.
  - Keep a new track row, set `moving` and derive heading and speed only after at least 25 m from the last kept point, measured over that displacement and its time.
  - `moving` stays set for 2 minutes after the last kept point.

### Trail recipe

1. Take own-track points back from the newest, by distance only, up to `min(request window, kept-distance setting)`.
2. Simplify in 2D with Douglas–Peucker, always keeping the first and last points.
3. Start at epsilon 15 m with a grid of `max(8, ceil(epsilon / 2))` m. Quantize and delta-encode as above.
4. Until it fits in 128 bytes and 255 points, multiply epsilon by 1.5 and repeat from 2.
5. Log epsilon, point count and bytes for the debug log.

At 10 miles, that is about 57 points.

### Channel gate

`isSharableChannel(name, psk)` lives in `packages/traxshare`, with the Public key constant (`8b3387e9c5cdea6ac9e5edbaa115cd72`). `Channel.isSharable` in [channel.dart](../../lib/models/channel.dart) calls it, so there is one implementation, and the session layer checks it on both send and receive.

It denies:
- the Public key
- an all-zero key
- a blank name
- a key equal to `sha256('#' + name)[:16]`, for the stored name and for its lowercase form, with or without a leading `#` (the same derivation as `Channel.derivePskFromHashtag`)
- any stored name that starts with `#` and is exactly 31 UTF-8 bytes. The radio cuts names to 31 bytes, so a long hashtag can't be re-derived; denying only hides the feature, which is the safe side.

It can't catch a renamed hashtag channel or a key that was shared widely, which is why the dialog says anyone with the key can read the answer. A denied channel's inbound packets get no prompt, reply or storage, and sending on one throws.

### Display thresholds

- **Fade** a pin after `max(2 × interval, 2 × heartbeat if the last report wasn't moving)`.
- **End** it on STOP, at session expiry, or after silence longer than `1.2 × heartbeat + 1 interval`. That is about 20 minutes for a 2-minute session.
- **One-time answers** fade after 10 minutes and stay on the map until dismissed or replaced.

## Storage

- **Location:**
  - Folder `<app support dir>/traxshare/`, one database file per radio. Mark the folder out of backups before opening, the way `MapPacksService.keepOutOfBackups` handles maps.
  - Open with `driftDatabase(name: …, native: DriftNativeOptions(databaseDirectory: …))`. path_graph's default location can't be excluded from backups.
  - Add `<exclude domain="file" path="traxshare/" />` to `android/app/src/main/res/xml/backup_rules.xml` and to both sections of `data_extraction_rules.xml`, next to `maps/`.
  - It is a separate file from the message database, so it isn't in **Export database**.
- **Node scope:**
  - Use the same node-scope value as the message database, and keep the last one in a preference. Open it at start-up, or stay closed if there is none; never open with an empty scope.
  - If `selfPublicKeyHex` changes to another non-empty key, end any session and reopen.
- **Migrations** must survive an interrupted first launch: `createTable`, and add columns only if they're missing (see `app_database.dart`'s `_createIndexIfMissing` and path_graph's `addIfMissing`).
- **Tables:**
  - `own_track(recorded_at, lat, lon, alt_m, dist_m_from_prev)`: raw kept points in order, compressed only when sent. A later "save as route" can turn them into #210's route shape (points plus elevations) without a format change.
  - `people(prefix PK, name_cached, last_lat, last_lon, last_alt_m, last_heading, last_speed, accuracy_class, fix_age_s, last_sent_at, last_seen_at, last_channel_id_key, last_hops, session_state, ignored)`.
  - `people_track(prefix, seq, lat, lon, dist_m_from_prev)`: received trails have no per-point times and each overlaps the last, so a new trail replaces that person's line; position reports since then are appended. Order and retention use `seq`.
- **Retention:**
  - One distance setting (default 16,094 m), walking back from the newest point, for the own track and for each person. Age is never used.
  - With the movement gate, the own track holds about 650 rows, under 40 KB. The last known position survives pruning.
  - **Delete all sharing data** clears the folder; each person can also be deleted from the strip.
- **Keys:** per-channel state is keyed by `(node scope, channel idKey)`, never by slot index or name.

## Verification

**Package (`dart test` in `packages/traxshare`)**
- **Codec:**
  - bit writer and reader with odd lengths
  - exp-Golomb orders 2–4 at edge values and with random values, including the 10-bit example above
  - zigzag; position packing at the poles and the antimeridian
  - a report with no trail is exactly 29 bytes, and no encoded report exceeds 157
  - for 50 random tracks, decoding the encoding gives exactly the sender's quantized points
- **Trail:** GPX fixtures of a city walk, a mountain drive and a straight highway, each logging epsilon, points and bytes.
- **Gate:** every denial above, including `Family` with `sha256('#family')`, an all-zero key and a 31-byte `#` name.
- **Movement:** a reading that flips between two neighbouring cells adds no rows and stays not moving; fix age grows while the reading is frozen.
- **Time:** a backlog request older than 10 minutes is dropped; a live frame from a sender whose clock is off still prompts; ages never show below 0.
- **Sessions** with an injected clock: reports reset the timeout; after a pause, sharing resumes with no prompt; a decline holds; STOP works from each side; the 240-minute cap holds.
- **Retention:** a long track is pruned by distance; a new trail replaces the old line; the last position survives.

**App (`flutter test`)**
- **Connector:**
  - frame 27 keeps the drain going; a foreign `data_type` is ignored
  - an ERR after a datagram reaches neither the contact-full event nor Pathfinder's discovery rule, in both orders
  - channel slots are resolved by identity; the gate holds on send and receive
- **Screens:**
  - the location icon and its new row work with **Share my location** already off
  - the kept distance shows "10 mi" and "16 km"
  - the strip survives a disconnect banner

**Two radios on 920.000 MHz, one with GPS**
- **Delivery:** a zero-hop packet reaches the other companion and F857's RX log shows no retransmission; a one-time flood is forwarded by F857 (ask Martin before moving F857).
- **Stationary radio:** over 30 minutes, every report arrives.
- **Altitude:** keeps changing with a fix and freezes without one, as the position rules need.
- **Step 1A** on a build from before and after the fix.

**Simulator:** ask whether `meshsimulator-0f`'s virtual companion handles CMD 62 and frame 27 and can run a five-member session.

**Martin on phones**
- reporting with the screen off on Android, over a real walk or drive
- trails on the map; **Route here**
- the consent dialog
- the message queue while a phone is away

## Open questions for Martin

1. Do test version bumps stay in the PR, or are they reverted at merge as in #229?
2. The privacy-policy and store wording: drafted in the PR, edited by him.
3. Should the consent dialog offer an approximate position? The format already carries it; v1 sends exact.
4. When to request the data_type allocation upstream, and whether to ask the firmware to drop datagrams before channel text when the queue is full. Both are public requests in another project, so they're his call.
5. iOS background sharing needs a test on his Mac and iPhone.

## What the earlier draft got wrong (don't bring these back)

| Draft | Why not |
|---|---|
| Switch the radio's default flood scope around every report to keep it off repeaters | CMD 63 rewrites all settings to flash on each call, and a crash between the two writes leaves every flood blocked by repeaters. Zero-hop does the job with no state. |
| Run the three commands through "the app's command queue" | There is none; `sendFrame` writes straight to the radio |
| Accuracy, heading and speed from the phone's GPS | Phone GPS is out; the radio gives lat/lon/alt only |
| A relative fix age is enough | Frames wait in the radio's queue with no timestamp |
| Receive `path_len` 0xFF means a neighbour sent it | It means route-direct; a flood heard from its sender reports 0 |
| 166–167 bytes return TABLE_FULL | 1.18 returns ILLEGAL_ARG; TABLE_FULL means the packet pool is empty |
| Exp-Golomb as "q zero bits, then…" | That is unary coding; use the standard code above |
| "Request:" text messages and `path=` fields | Breaks the [message format](../message-format.md) rules, shows raw text on other apps, and identical texts within 5 minutes are merged |
| Repurpose the target icon in the chat bar | No such button exists |
| Always approve favourites | Any member can claim a favourite's prefix |
| Gate Pathfinder input on repeat mode; reset every contact's route | Pathfinder already keeps one graph file per mesh (frequency, bandwidth, spreading factor, coding rate), so a retuned radio gets its own; the DM ladder already falls back to flood |
| Record your own position always, keep everyone's tracks 7 days | Opt-in, by distance only, out of backups |
| A 3 m trail grid, a 50 m accuracy filter, 3D simplification | The radio steps 11 m, gives no accuracy, and altitude isn't on the wire |
