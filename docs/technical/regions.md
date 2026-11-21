# Regions

> **What this is:** The plan for regions in MeshTrax: what the firmware does with them, what the app will do, and the decisions made so far.
>
> **Who it's for:** developers working on MeshTrax.
>
> **Status:** active plan. Phase 1 is being built on `feat/regions`, and all region work lives in that one PR. The firmware facts are from MeshCore `dev` (November 2026) and hold for companion and repeater 1.18.0.
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

## The plan

### Phase 1: core

- **Region helper:** key, code and name rules in one place, tested against the firmware facts above (`test/regions/region_firmware_facts_test.dart`).
- **Storage:** the app's list of regions, and each channel's region keyed by the channel's identity.
- **Settings → Regions:** the list, Add (a dialog that checks the name rules as you type), Delete (warns when channels use the region and takes it off them), and a Radio default region line that opens a dialog.
- **The channel's region dialog**, from the channel's ⋮ menu and from tapping the region under the channel name: None, Everywhere (only when the radio has a default region), the list of regions, and Manage regions.
- **On screen:** when a channel has its own region, a small pin and the name under the channel name in the chat header, and on its row in Chats. Nothing otherwise.
- **Sending:** every channel send (text, reactions, channel data, retries, queued sends) goes through one place that sets the region, sends, and clears it. No other frame goes to the radio in between, so a direct message can't pick up the channel's region. The app also clears any leftover region when it connects.
- **Old radios:** radios without command 54 don't show any of this.
- **Channel QR codes:** written with `region_scope` when the channel has a region. When a scanned code has one, the region is added and set on the channel.
- **App backup:** includes the region list and the channel regions.

### Phase 2: repeaters tell you their regions

- After Discover, ask each repeater that answered, straight to it, without changing its saved route.
- Show the list in the Nearby repeaters dialog and the repeater's info sheet ("Regions: sf, bayarea, everywhere").
- In Settings → Regions, a "Heard from nearby repeaters" section with + to add.
- In the channel's region dialog, "✓ 3 nearby repeaters" or "⚠ no nearby repeater carries it".
- A health check when nearby repeaters refuse messages with no region.
- When a channel message with a region isn't repeated, the hint says the region may not be carried here.

### Phase 3: region of incoming messages

Match the code in the raw packet log against the known regions and show "Region: sf" on the Packet Path screen. Codes that match nothing mean there are regions you don't know.

### Phase 4 (optional, later)

Edit a repeater's regions when logged in, using its `region` commands.

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
