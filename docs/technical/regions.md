# Regions

> **What this is:** The plan for regions in MeshTrax: what the firmware does with them, what the app will do, and the decisions made so far.
>
> **Who it's for:** developers working on MeshTrax.
>
> **Status:** active plan. Phases 1 to 6 are built on `feat/regions`. All region work lives in that one PR.
 The firmware facts are from MeshCore `dev` (November 2026) and hold for companion and repeater 1.18.0.
>
> New to the terms? See the [glossary](../glossary.md).

## What a region is

A region is a name, such as `sf` or `bayarea`, that a message can carry so that it travels only through the repeaters that serve that area. A message with no region travels everywhere, as all messages do today.

The name never goes on air. The message carries a 2-byte code made from the name and from the message itself, and a repeater passes the message on only when the code matches a region it serves.

## Firmware facts

### The code

- **Key:** the first 16 bytes of SHA-256 of `#` + name. A leading `#` in the name is not doubled. This is the same key a hashtag channel of that name uses.
- **Code:** HMAC-SHA256(key, payload type byte + payload), first 2 bytes, read as a little-endian number. `0000` becomes `0001` and `FFFF` becomes `FFFE`. It sits in the first transport code of a `TRANSPORT_FLOOD` packet. A code of `0000` counts as no region.
- Because the code covers the payload, every message in one region has a different code. Nobody can read the region name off the air without guessing names and checking.

### Names

- **Case matters:** `SF` and `sf` are two different regions with different keys.
- At most 30 bytes. Allowed: `-`, `$`, `#`, digits, and every byte from `A` up, which includes all letters, `_` and non-English letters. Not allowed: spaces, `.`, `,`, `/`, `*`, `:` and most other punctuation.
- **Private regions** (names starting with `$`) need a key store that the firmware hasn't built yet. MeshTrax doesn't offer them.

### Repeaters

- A repeater passes on a message with a region only if it has that region and allows it (`region allowf`). **A repeater that doesn't know the region drops the message.**
- A message with no region is passed on unless the repeater refuses those (`region denyf *`) or limits how far they go (`flood.max.unscoped`).
- Regions can have a parent (`region put sf bayarea`), but that is only for display: a repeater that knows `sf` and not `bayarea` drops a `bayarea` message.
- A repeater answers a flood request (a login, a status) in the region the request came in.
- A repeater lists its regions to anyone who asks it directly (repeater 1.12+). The answer holds the regions it allows, with `*` meaning it passes messages with no region. Each repeater answers at most 4 such questions every 3 minutes, counted across everyone. The answer to Discover doesn't include regions.

### The companion radio

- It has no list of regions and no region per channel.
- It has a **default region**, saved on the radio (commands 63 and 64, firmware version 11+).
- It has a **temporary region** held in memory (command 54: `[54, 0, key x16]` sets it, `[54, 0]` clears it, and `[54, 1]` sends with no region even when a default is set, version 12+). It stays set across a Bluetooth reconnect until the radio reboots.
- Every flood the radio sends uses the temporary region if set, else the default. That includes direct messages, and the delivery receipts and route replies the radio sends on its own. Its adverts use only the default.
- It doesn't report which region an incoming message came in. The raw packet log shows the code, and the app can match it against the names it knows.

### Channel QR codes

The channel QR link `meshcore://channel/add?name=…&secret=…` takes an optional `region_scope` field holding the region name.

## Decisions

Made by the owner on 2026-11-21:

1. **A channel shows a region only when it has its own.** When the radio has a default region, the channel shows nothing; the default appears in Settings → Regions and as "None (radio default: sf)" in the channel's region dialog.
2. **The app asks nearby repeaters for their regions after Discover**, once per repeater per day, only the repeaters that answered.
3. **Names are kept exactly as typed**, like the firmware. When a nearby repeater has the same name with different capitals, the app offers the repeater's spelling.
4. **A channel's region belongs to the channel** (its key), so it is the same on every radio you connect.
5. **Channel QR codes leave the region out** unless "Region in channel QR codes" is switched on in Settings → Regions. Off, a scanned code's region is ignored too.

## The plan

### Phase 1: core

- **Region helper:** key, code and name rules in one place, tested against the firmware facts above (`test/regions/region_firmware_facts_test.dart`).
- **Storage:** the app's list of regions, and each channel's region keyed by the channel's identity.
- **Settings → Regions:** the list, Add (a dialog that checks the name rules as you type), Delete (warns when channels use the region and takes it off them), and a Radio default region line that opens a dialog.
- **The channel's region dialog**, from the channel's ⋮ menu and from tapping the region under the channel name: None, Everywhere (only when the radio has a default region), the list of regions, and Manage regions.
- **On screen:** when a channel has its own region, a small pin and the name under the channel name in the chat header, and on its row in Chats. Nothing otherwise.
- **Sending:** every channel send (text, reactions, channel data, retries, queued sends) goes through one place that sets the region, sends, and clears it. No other frame goes to the radio in between, so a direct message can't pick up the channel's region. The app also clears any leftover region when it connects.
- **Old radios:** radios without command 54 don't show any of this.
- **Channel QR codes:** only while "Region in channel QR codes" is on (off by default): written with `region_scope` when the channel has a region, and a scanned code's region is added and set on the channel.
- **App backup:** includes the region list and the channel regions.

### Phase 2: repeaters tell you their regions

Built. The owner, 2026-11-22: only after a Discover the user starts (never an automatic one).

**Asking** (`lib/services/nearby_regions_asker.dart`): when a Discover the user started closes, each repeater that answered it is asked, one at a time, with `CMD_SEND_ANON_REQ` and sub-type `ANON_REQ_TYPE_REGIONS`, its answer coming back zero-hop. The firmware sets the rules:

- The question must arrive DIRECT. A repeater with a route on the radio is asked on that route. One without is asked on a zero-hop route, which the app writes the way it writes any request's route (`sendOnRoute`); it just answered a zero-hop Discover, so that route is true.
- A repeater not saved on the radio is skipped: asking one makes the radio add a nameless contact for it.
- Each repeater is asked at most once a day (it answers 4 such questions every 3 minutes, from anyone). An answer counts for 7 days.
- The radio keeps one pending request, so the questions go one after another.

**Showing** (`RegionService` keeps the answers, outside the app backup):

- The Nearby repeaters dialog: a line under each repeater that answered, such as "Regions: sf, and messages with no region".
- The channel's Region dialog: under each region, "✓ 3 nearby repeaters" or "⚠ No nearby repeater carries it".
- Settings → Regions: a "Heard from nearby repeaters" section, with + to add a name to your list. Add region offers the spelling repeaters use when yours differs only in capitals.
- Two health check findings: nearby repeaters that refuse messages with no region, and a channel whose region no nearby repeater carries.
- Not built: a hint on a channel message that wasn't repeated.

### Phase 3: region of incoming messages

Built. The app reads the region code (first transport code) of every channel text in the radio's packet log, and keeps it on the message. It matches it against the names it knows: your regions, the radio's default, and the names nearby repeaters said they carry. The Packet Path screen shows "Region: sf", or "One you don't know (code 1A2B)". A message the radio handed over before its packet was logged has no region, and a code can't be matched later, since the packet itself isn't kept.

### Phase 4: manage a repeater's regions when logged in

Asked for by the owner on 2026-11-21: an easy way to set up the regions of a repeater you run, with no command line.

**Where:** a **Regions** entry in the repeater's management tools (beside Status, Command line, Neighbors and Settings), shown only when logged in as admin. It is built on the repeater's `region` commands, sent the way the Command line screen sends them.

**The screen:**

- **Messages with no region:** a switch (`region allowf *` / `region denyf *`). Turning it off asks first: everyone nearby who doesn't use a region stops being repeated.
- **The repeater's regions:** each with a switch for "Repeats messages in this region" (`region allowf` / `region denyf`), indented under its parent. Tapping a region offers: change its parent (`region put <name> <parent>`; the firmware turns repeating back on when it moves a region, so the screen sends `region denyf` again if it was off), or remove it
 (`region remove`; the firmware refuses while it has child regions, and the screen says so).
- **Add region:** a name (same rules and checks as the app's Add region), an optional parent, and a list of the app's own regions to tick in one go (`region put`; a new region is repeated straight away).
- **The repeater's own region:** the region its adverts and its flood replies use when it can't tell the asker's (`region default <name>` / `region default <null>`). The firmware turns flood on for it.
- **Saving:** each change is followed by `region save`, so nothing is lost if the repeater restarts. (`region default` saves itself.)
- **Reading:** `region` gives the tree, with `F` marking regions it repeats and `^` the home region. The reply is cut at 160 bytes, so a long list is read with `region list allowed` and `region list denied` as well, and the screen says when the list may be incomplete.

**Firmware:** repeater 1.15+ has every command above; an older repeater gets a message saying so.
 `region home` only changes a mark in the listing today, so the screen leaves it out.

**Tests:** a fake repeater answering the `region` commands as the firmware does (including the 160-byte cut and "Err - not empty"), and the screen at phone size.

**Built:** `lib/models/repeater_regions.dart` reads the replies, `lib/services/repeater_regions_controller.dart` runs the commands (a refusal partway through a batch still saves what went through), and `lib/screens/repeater_regions_screen.dart` is the screen. A repeater too old for `region list` (it answers `Err - ??`, `??` or `Unknown command`) gets a message saying it needs 1.15 or newer, rather than a hidden entry, since the app doesn't know a repeater's version before asking. The entry shows for repeaters only, not room servers.



### Phase 5: Nearby only

Asked for by the owner on 2026-11-21: a channel whose messages don't go through repeaters at all. It is a choice in the channel's Region dialog, "Nearby only (no repeaters)", shown under the channel name as "Nearby only" with its own icon (people close together; regions use a hexagon).

**Firmware:** MeshCore has no hop limit a sender sets on a channel message. It does have zero hop: a packet sent DIRECT with an empty path. Every radio in range opens a zero-hop channel text like any other (`Mesh::onRecvPacket`, the `PAYLOAD_TYPE_GRP_TXT` case), and nobody passes it on: `routeRecvPacket` forwards floods only, and a DIRECT packet goes only to the next hop in its path. A "nowhere" region would not do: older repeaters and companions with repeat on pass region messages on.

**How it's sent:** the radio has no zero-hop channel send, so the app builds the channel text exactly as the radio does (`BaseChatMesh::sendGroupMessage`: timestamp, a 0, `name: text` cut at 160 bytes, sealed with the channel key behind its 1-byte hash) and hands it over with `CMD_SEND_RAW_PACKET` (companion firmware 13+, `lib/helpers/channel_packet.dart`). A test checks its hash against traxheard's, which matched real heard copies. Older firmware doesn't offer the choice; a channel already set to it sends normally there.

**No retries:** the radio's OK settles the message as Sent. There is no wait for a repeat, no "one more send", no retry when no repeat is heard, and no observer check.

### Phase 6: observers per region

Asked for by the owner on 2026-11-21: the observer check (traxheard) must know whether a region has observers, and leave a region's channels alone when it has none. A message in a region only travels through that region's repeaters, so observers that hear the radio may never hear it, and with no ear the app would send it once more every time.

**No server says which regions its observers cover**, so the app learns it from its own sends (`lib/services/heard_service.dart`):

- An ear proves observers hear this radio **in that message's region** only (the proof is kept per radio and region).
- A send in a region nobody has learned yet is checked as usual. **3 unheard sends in a row** there, and the region counts as having no observer for a day: its channels get no observer check and no resend after one repeater.
- After the day, one send is checked again: an ear clears it, no ear means another quiet day.
- Nothing shows on screen (owner's choice). Picking another observer server starts over. "Nearby only" channels are never checked.

## Pitfalls

- A name longer than 30 bytes is cut by the frame builder without a word, and the cut name no longer matches its key. Refuse such names when they are added.
- The radio's own delivery receipts and route replies sent while a channel send is in progress go out in the channel's region. The time between setting and clearing is a few milliseconds and can't be made shorter from the app.
- The temporary region survives a Bluetooth reconnect, so a crash between setting and clearing leaves it set. Hence the clear on connect.
- Asking repeaters for their regions uses part of their shared allowance of 4 questions every 3 minutes. Ask once and keep the answer.

## Bench check

On 920.000 MHz only, never on the mesh frequency:

1. Add a test region to the bench repeater.
2. Send in that region from the first radio and check the code in the second radio's packet log against the test values.
3. Check that the repeater passes on the allowed region and drops an unknown one.
