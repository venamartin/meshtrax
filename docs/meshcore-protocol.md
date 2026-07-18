# MeshCore Protocol Reference

> **Purpose:** Reference for humans and AI agents working on MeshTrax. Read this BEFORE opening
> any `MeshCore/` C++ files. Everything here is verified directly against the firmware source in
> `./MeshCore` (companion radio `FIRMWARE_VER_CODE 13`, v1.16.0). When you discover new protocol
> details, update this file instead of leaving the knowledge in a chat log.
>
> **Last full verification:** 2026-07-12, against `MeshCore/examples/companion_radio/MyMesh.cpp`
> and `MeshCore/src/`.

There are **two distinct protocols** described here — don't mix them up:

1. **The radio wire format** (§1–§3): what LoRa packets look like in the air, node to node.
2. **The serial frame protocol** (§4–§5): what the app exchanges with the companion radio over
   BLE/USB. One frame = one command or one response; byte 0 is always the command/response code.

**Contents**
- [1. Radio Packet Wire Format](#1-radio-packet-wire-format)
- [2. Route Types](#2-route-types)
- [3. Payload Types](#3-payload-types)
- [4. Serial Frame Protocol (App ↔ Companion Radio)](#4-serial-frame-protocol-app--companion-radio)
- [5. Frame Layouts (verified byte-by-byte)](#5-frame-layouts-verified-byte-by-byte)
- [6. Path Mechanics](#6-path-mechanics-firmware-level)
- [7. Login Handshake Flow](#7-login-handshake-flow)
- [8. Regions and Flood Scoping](#8-regions-and-flood-scoping)
- [9. Size Limits and Timeouts](#9-size-limits-and-timeouts)
- [10. App-Side Path Resolution](#10-app-side-path-resolution-resolvepathselection)
- [11. App Architecture Overview](#11-app-architecture-overview)
- [12. Known Bugs and Gotchas](#12-known-bugs-and-gotchas-do-not-re-introduce)
- [13. Key Source Files](#13-key-source-files-reference-only--do-not-modify)

---

## 1. Radio Packet Wire Format

Every over-the-air packet has this structure:

```
[header: 1 byte]
[path_len: 1 byte]           ← encodes BOTH hop count AND hash size (see below)
[path_bytes: variable]       ← hopCount × hashSize bytes
[payload_len: 1 byte]
[payload: variable]
[transport_codes: 4 bytes]   ← ONLY present when route is TRANSPORT_FLOOD or TRANSPORT_DIRECT
```

### The `header` byte (`Packet.h`)
```
bits [1:0]  = ROUTE_TYPE   (2 bits)
bits [5:2]  = PAYLOAD_TYPE (4 bits)
bits [7:6]  = PAYLOAD_VER  (2 bits, currently always 0)
```

### The `path_len` byte (`Packet.h`) — this encoding appears everywhere

The same byte encoding is used on air, in the `ContactInfo.out_path_len` field, and in serial
frames that carry a path. **It is the single source of truth for hop count** — never derive the
hop count by scanning path bytes.

```
bits [5:0]  = hop count (0–63 intermediate hops)
bits [7:6]  = hash_size - 1   →  0 = 1-byte hashes, 1 = 2-byte, 2 = 3-byte
```

Firmware (`Packet.h`): `getPathHashCount() = path_len & 63`, `getPathHashSize() = (path_len >> 6) + 1`.
Dart (`meshcore_protocol.dart`): `extractPathHopCount()`, `extractPathHashSize()`, `encodePathLenByte()`.

**Special value:** `path_len = 0xFF` = `OUT_PATH_UNKNOWN` → no known path, must flood.

A 0-hop direct packet has `path_len = 0x00` and **zero path bytes — this is valid**. An N-hop
packet carries N × hashSize path bytes, one hash per intermediate node, in traversal order.

---

## 2. Route Types

| Constant | Value | Meaning |
|----------|-------|---------|
| `ROUTE_TYPE_TRANSPORT_FLOOD` | `0x00` | Flood + transport codes (scoped) |
| `ROUTE_TYPE_FLOOD` | `0x01` | Unscoped flood, path builds up as it propagates |
| `ROUTE_TYPE_DIRECT` | `0x02` | Direct route, path supplied by sender |
| `ROUTE_TYPE_TRANSPORT_DIRECT` | `0x03` | Direct + transport codes |

`isRouteFlood()` = TRANSPORT_FLOOD or FLOOD · `isRouteDirect()` = DIRECT or TRANSPORT_DIRECT ·
`hasTransportCodes()` = TRANSPORT_FLOOD or TRANSPORT_DIRECT

---

## 3. Payload Types

| Constant | Value | Description |
|----------|-------|-------------|
| `PAYLOAD_TYPE_REQ` | `0x00` | Authenticated request (dest/src hashes + MAC) |
| `PAYLOAD_TYPE_RESPONSE` | `0x01` | Response to REQ or ANON_REQ |
| `PAYLOAD_TYPE_TXT_MSG` | `0x02` | Text message (dest/src hashes + MAC) |
| `PAYLOAD_TYPE_ACK` | `0x03` | Simple ACK (4-byte hash) |
| `PAYLOAD_TYPE_ADVERT` | `0x04` | Node advertising its identity |
| `PAYLOAD_TYPE_GRP_TXT` | `0x05` | Group text message (channel hash + MAC) |
| `PAYLOAD_TYPE_GRP_DATA` | `0x06` | Group datagram (data_type u16 + len + blob) |
| `PAYLOAD_TYPE_ANON_REQ` | `0x07` | Anonymous request — used for LOGIN |
| `PAYLOAD_TYPE_PATH` | `0x08` | Path return packet (can embed an extra payload) |
| `PAYLOAD_TYPE_TRACE` | `0x09` | Path trace (SNR collection per hop) |
| `PAYLOAD_TYPE_MULTIPART` | `0x0A` | Multi-part packet |
| `PAYLOAD_TYPE_CONTROL` | `0x0B` | Control/discovery packet |
| `PAYLOAD_TYPE_RAW_CUSTOM` | `0x0F` | Raw bytes, custom encryption |

---

## 4. Serial Frame Protocol (App ↔ Companion Radio)

Max frame size: **176 bytes** (`MAX_FRAME_SIZE` in `BaseSerialInterface.h` — was 172 before
transport codes added 4 bytes). Byte 0 is always the command or response code. Lengths below
include the command byte.

The app declares which protocol version it speaks via `CMD_DEVICE_QUERY` byte 1
(`app_target_ver` in firmware). **MeshTrax sends 3**, which selects the V3 message frames
(codes 16/17) over the legacy ones (codes 7/8).

### 4.1 Commands (App → Companion)

Commands implemented by MeshTrax are **bold**. `✗` = firmware replies `RESP_CODE_DISABLED` or
"unsupported" in the default build.

| Code | Constant | Frame after cmd byte | Notes |
|------|----------|----------------------|-------|
| 1 | **`CMD_APP_START`** | `[app_ver][reserved x6][app_name…]` | Reply: SELF_INFO. Bytes 1–7 are ignored/reserved |
| 2 | **`CMD_SEND_TXT_MSG`** | `[txt_type][attempt][timestamp x4][pubkey_prefix x6][text…]` | Min len 14. Reply: SENT or ERR |
| 3 | **`CMD_SEND_CHANNEL_TXT_MSG`** | `[txt_type][channel_idx][timestamp x4][text…]` | **No null terminator** — every byte after the header counts as text and is transmitted |
| 4 | **`CMD_GET_CONTACTS`** | `[since x4]?` | Optional `since` filters by `lastmod`. Replies: CONTACTS_START, CONTACT…, END_OF_CONTACTS |
| 5 | **`CMD_GET_DEVICE_TIME`** | — | Reply: CURR_TIME |
| 6 | **`CMD_SET_DEVICE_TIME`** | `[epoch_secs x4]` | Rejected if earlier than current RTC |
| 7 | **`CMD_SEND_SELF_ADVERT`** | `[flood]?` | 1 = scoped flood, 0/absent = zero hop |
| 8 | **`CMD_SET_ADVERT_NAME`** | `[name…]` | No terminator needed; frame length delimits |
| 9 | **`CMD_ADD_UPDATE_CONTACT`** | see §5 contact frame | Also how the app **sets a contact's stored path** |
| 10 | **`CMD_SYNC_NEXT_MESSAGE`** | — | Reply: one queued message frame, or NO_MORE_MESSAGES |
| 11 | **`CMD_SET_RADIO_PARAMS`** | `[freq_hz x4][bw_hz x4][sf][cr][repeat]?` | `repeat` = client repeat, fw v9+. Valid: freq 150k–2.5M kHz, sf 5–12, cr 5–8, bw 7k–500k Hz |
| 12 | **`CMD_SET_RADIO_TX_POWER`** | `[dbm int8]` | −9 … MAX_LORA_TX_POWER |
| 13 | **`CMD_RESET_PATH`** | `[pub_key x32]` | Sets contact's `out_path_len = 0xFF` (flood) |
| 14 | **`CMD_SET_ADVERT_LATLON`** | `[lat x4][lon x4][alt x4]?` | int32 LE, degrees × 1e6 |
| 15 | **`CMD_REMOVE_CONTACT`** | `[pub_key x32]` | |
| 16 | **`CMD_SHARE_CONTACT`** | `[pub_key x32]` | Broadcasts contact zero-hop |
| 17 | **`CMD_EXPORT_CONTACT`** | `[pub_key x32]?` | Empty = export SELF as advert packet |
| 18 | **`CMD_IMPORT_CONTACT`** | `[advert_packet…]` | Min len 98 (needs pubkey + signature) |
| 19 | **`CMD_REBOOT`** | `"reboot"` | Literal ASCII guard string |
| 20 | **`CMD_GET_BATT_AND_STORAGE`** | — | Reply: BATT_AND_STORAGE |
| 21 | `CMD_SET_TUNING_PARAMS` | `[rx_delay x4][airtime_factor x4]` | Values ×1000 |
| 22 | **`CMD_DEVICE_QUERY`** | `[app_target_ver]` | Reply: DEVICE_INFO. Sets protocol version for message frames |
| 23 | `CMD_EXPORT_PRIVATE_KEY` ✗ | — | Disabled unless built with `ENABLE_PRIVATE_KEY_EXPORT` |
| 24 | `CMD_IMPORT_PRIVATE_KEY` ✗ | `[key x64]` | Disabled unless built with `ENABLE_PRIVATE_KEY_IMPORT` |
| 25 | `CMD_SEND_RAW_DATA` | `[path_len][path…][payload x4+]` | Direct only |
| 26 | **`CMD_SEND_LOGIN`** | `[pub_key x32][password…]` | Reply: SENT, then push LOGIN_SUCCESS/FAIL |
| 27 | **`CMD_SEND_STATUS_REQ`** | `[pub_key x32]` | Reply: SENT, then push STATUS_RESPONSE |
| 28 | `CMD_HAS_CONNECTION` | `[pub_key x32]` | OK if keep-alive connection active |
| 29 | **`CMD_LOGOUT`** | `[pub_key x32]` | Stops keep-alive connection |
| 30 | **`CMD_GET_CONTACT_BY_KEY`** | `[pub_key x32]` | Reply: CONTACT frame |
| 31 | **`CMD_GET_CHANNEL`** | `[channel_idx]` | Reply: CHANNEL_INFO |
| 32 | **`CMD_SET_CHANNEL`** | `[channel_idx][name x32][psk x16]` | Only 128-bit PSKs; 32-byte PSK frames are rejected |
| 33–35 | `CMD_SIGN_START/DATA/FINISH` | | Multi-frame Ed25519 signing of up to 8 KB |
| 36 | **`CMD_SEND_TRACE_PATH`** | `[tag x4][auth x4][flags][path…]` | `flags & 0x03` = hash width − 1. Path must be non-empty |
| 37 | `CMD_SET_DEVICE_PIN` | `[pin x4]` | 0 or 100000–999999 |
| 38 | **`CMD_SET_OTHER_PARAMS`** | `[manual_add][telem_modes][adv_loc_policy][multi_acks]` | `telem_modes`: base bits[1:0], loc bits[3:2], env bits[5:4] |
| 39 | **`CMD_SEND_TELEMETRY_REQ`** | `[reserved x3][pub_key x32]?` | **Without pubkey the frame must be EXACTLY 4 bytes** (self telemetry, pushed back as 0x8B) |
| 40 | **`CMD_GET_CUSTOM_VARS`** | — | Reply: CUSTOM_VARS, `"name:value,name:value"` text |
| 41 | **`CMD_SET_CUSTOM_VAR`** | `["name:value"]` | Must contain `:` |
| 42 | `CMD_GET_ADVERT_PATH` | `[reserved][pub_key x32]` | Reply: ADVERT_PATH (recently-heard cache) |
| 43 | `CMD_GET_TUNING_PARAMS` | — | Reply: TUNING_PARAMS |
| 50 | **`CMD_SEND_BINARY_REQ`** | `[pub_key x32][req_data x1+]` | First req_data byte = REQ_TYPE_*. Reply: SENT + push BINARY_RESPONSE |
| 51 | `CMD_FACTORY_RESET` | `"reset"` | Formats filesystem and reboots |
| 52 | `CMD_SEND_PATH_DISCOVERY_REQ` | `[0][pub_key x32]` | Forced-flood telemetry req; reply via push 0x8D |
| 54 | `CMD_SET_FLOOD_SCOPE_KEY` | `[0][key x16]?` or `[1]` | `[0]` + key sets per-send scope, `[0]` alone clears, `[1]` forces unscoped (v12+) |
| 55 | **`CMD_SEND_CONTROL_DATA`** | `[ctl_payload…]` | Payload byte 0 must have high bit set. Sent zero-hop |
| 56 | **`CMD_GET_STATS`** | `[stats_type]` | 0 = core, 1 = radio, 2 = packets |
| 57 | `CMD_SEND_ANON_REQ` | `[pub_key x32][data…]` | fw v13+: works for non-contacts too |
| 58 | **`CMD_SET_AUTOADD_CONFIG`** | `[flags][max_hops]?` | Flags: see §5 auto-add |
| 59 | **`CMD_GET_AUTOADD_CONFIG`** | — | Reply: AUTOADD_CONFIG |
| 60 | `CMD_GET_ALLOWED_REPEAT_FREQ` | — | Reply: list of `[lower x4][upper x4]` kHz ranges |
| 61 | **`CMD_SET_PATH_HASH_MODE`** | `[0][mode]` | mode 0–2 → (mode+1)-byte path hashes on air |
| 62 | `CMD_SEND_CHANNEL_DATA` | `[channel_idx][path_len][path…][data_type x2][payload…]` | `path_len = 0xFF` for flood |
| 63 | **`CMD_SET_DEFAULT_FLOOD_SCOPE`** | `[name x31][key x16]` or empty | Empty payload clears the default scope |
| 64 | **`CMD_GET_DEFAULT_FLOOD_SCOPE`** | — | Reply: DEFAULT_FLOOD_SCOPE |
| 65 | `CMD_SEND_RAW_PACKET` | `[priority][raw_packet…]` | Injects a pre-built wire packet |

### 4.2 Responses (Companion → App)

| Code | Constant | Description |
|------|----------|-------------|
| 0 | `RESP_CODE_OK` | Generic success (1 byte) |
| 1 | `RESP_CODE_ERR` | Error; byte 1 = error code (§4.4) |
| 2 | `RESP_CODE_CONTACTS_START` | `[count x4]` — total contacts (NOT filtered count) |
| 3 | `RESP_CODE_CONTACT` | Contact frame (§5) |
| 4 | `RESP_CODE_END_OF_CONTACTS` | `[most_recent_lastmod x4]` — use as next `since` |
| 5 | `RESP_CODE_SELF_INFO` | Reply to APP_START (§5) |
| 6 | `RESP_CODE_SENT` | Message accepted for transmission (§5) |
| 7 | `RESP_CODE_CONTACT_MSG_RECV` | Contact message (protocol v<3) |
| 8 | `RESP_CODE_CHANNEL_MSG_RECV` | Channel message (protocol v<3) |
| 9 | `RESP_CODE_CURR_TIME` | `[epoch_secs x4]` |
| 10 | `RESP_CODE_NO_MORE_MESSAGES` | Sync queue empty |
| 11 | `RESP_CODE_EXPORT_CONTACT` | `[advert_packet…]` |
| 12 | `RESP_CODE_BATT_AND_STORAGE` | `[mV x2][used_kb x4][total_kb x4]` |
| 13 | `RESP_CODE_DEVICE_INFO` | Reply to DEVICE_QUERY (§5) |
| 14 | `RESP_CODE_PRIVATE_KEY` | `[key x64]` (only if export enabled) |
| 15 | `RESP_CODE_DISABLED` | Command compiled out of this firmware build |
| 16 | `RESP_CODE_CONTACT_MSG_RECV_V3` | Contact message (protocol v≥3) (§5) |
| 17 | `RESP_CODE_CHANNEL_MSG_RECV_V3` | Channel message (protocol v≥3) (§5) |
| 18 | `RESP_CODE_CHANNEL_INFO` | `[channel_idx][name x32][psk x16]` |
| 19 | `RESP_CODE_SIGN_START` | `[reserved][max_len x4]` |
| 20 | `RESP_CODE_SIGNATURE` | `[signature x64]` |
| 21 | `RESP_CODE_CUSTOM_VARS` | `"name:value,name:value"` text |
| 22 | `RESP_CODE_ADVERT_PATH` | `[recv_timestamp x4][path_len][path…]` |
| 23 | `RESP_CODE_TUNING_PARAMS` | `[rx_delay x4][airtime_factor x4]` (×1000) |
| 24 | `RESP_CODE_STATS` | Byte 1 = stats type; layouts in §5 |
| 25 | `RESP_CODE_AUTOADD_CONFIG` | `[flags][max_hops]` |
| 27 | `RESP_CODE_CHANNEL_DATA_RECV` | `[snr][res][res][channel_idx][path_len][data_type x2][data_len][data…]` |
| 28 | `RESP_CODE_DEFAULT_FLOOD_SCOPE` | `[name x31][key x16]`, or 1 byte if unset |

### 4.3 Push Codes (Companion → App, unsolicited)

| Code | Constant | Layout after code byte |
|------|----------|------------------------|
| `0x80` | `PUSH_CODE_ADVERT` | `[pub_key x32]` — advert from an existing contact |
| `0x81` | `PUSH_CODE_PATH_UPDATED` | `[pub_key x32]` — re-fetch via GET_CONTACT_BY_KEY |
| `0x82` | `PUSH_CODE_SEND_CONFIRMED` | `[ack_hash x4][trip_time_ms x4]` |
| `0x83` | `PUSH_CODE_MSG_WAITING` | (1 byte) — poll with SYNC_NEXT_MESSAGE |
| `0x84` | `PUSH_CODE_RAW_DATA` | `[snr×4 i8][rssi i8][0xFF][payload…]` |
| `0x85` | `PUSH_CODE_LOGIN_SUCCESS` | `[permissions][pubkey_prefix x6]` + new form: `[server_timestamp x4][acl_perms][fw_ver_level]` |
| `0x86` | `PUSH_CODE_LOGIN_FAIL` | `[reserved][pubkey_prefix x6]` |
| `0x87` | `PUSH_CODE_STATUS_RESPONSE` | `[reserved][pubkey_prefix x6][status_data…]` |
| `0x88` | `PUSH_CODE_LOG_RX_DATA` | `[snr×4 i8][rssi i8][raw wire packet…]` (§5) |
| `0x89` | `PUSH_CODE_TRACE_DATA` | `[reserved][path_len][flags][tag x4][auth x4][hashes…][snrs…][final_snr]` |
| `0x8A` | `PUSH_CODE_NEW_ADVERT` | Full contact frame (§5) — newly discovered node |
| `0x8B` | `PUSH_CODE_TELEMETRY_RESPONSE` | `[reserved][pubkey_prefix x6][CayenneLPP data…]` |
| `0x8C` | `PUSH_CODE_BINARY_RESPONSE` | `[reserved][tag x4][data…]` — match tag to RESP_CODE_SENT |
| `0x8D` | `PUSH_CODE_PATH_DISCOVERY_RESPONSE` | `[reserved][pubkey_prefix x6][out_path_len][out_path…][in_path_len][in_path…]` |
| `0x8E` | `PUSH_CODE_CONTROL_DATA` | `[snr×4 i8][rssi i8][path_len][control payload…]` |
| `0x8F` | `PUSH_CODE_CONTACT_DELETED` | `[pub_key x32]` — evicted by overwrite-oldest |
| `0x90` | `PUSH_CODE_CONTACTS_FULL` | (1 byte) |

### 4.4 Error Codes (byte 1 after RESP_CODE_ERR)

| Code | Constant |
|------|----------|
| 1 | `ERR_CODE_UNSUPPORTED_CMD` |
| 2 | `ERR_CODE_NOT_FOUND` |
| 3 | `ERR_CODE_TABLE_FULL` |
| 4 | `ERR_CODE_BAD_STATE` |
| 5 | `ERR_CODE_FILE_IO_ERROR` |
| 6 | `ERR_CODE_ILLEGAL_ARG` |

---

## 5. Frame Layouts (verified byte-by-byte)

### Contact frame — `RESP_CODE_CONTACT` (3), `PUSH_CODE_NEW_ADVERT` (0x8A)
Source: `writeContactRespFrame()`. `CMD_ADD_UPDATE_CONTACT` (9) uses the **same layout** with the
cmd byte at [0]; on write, lat/lon and lastmod are optional trailing fields.
```
[0]         code
[1..32]     pub_key (32 bytes)
[33]        type  (ADV_TYPE_*)
[34]        flags (bit0 favourite; bit1 telem base; bit2 telem loc; bit3 telem env)
[35]        out_path_len  ← path_len byte encoding (§1). 0xFF = no path, 0x00 = 0-hop direct.
                            AUTHORITATIVE hop count = low 6 bits. Do not scan path bytes.
[36..99]    out_path (64 bytes, zero-padded)
[100..131]  name (32 bytes, null-padded)
[132..135]  last_advert_timestamp (uint32 LE)
[136..139]  gps_lat (int32 LE, degrees × 1e6)
[140..143]  gps_lon (int32 LE, degrees × 1e6)
[144..147]  lastmod (uint32 LE, device RTC)
```
Total: 148 bytes.

### `CMD_SEND_TXT_MSG` (2) — also used for repeater CLI commands
```
[0]       = 2
[1]       = txt_type: 0 = TXT_TYPE_PLAIN (ACK expected), 1 = TXT_TYPE_CLI_DATA (no ACK),
            2 = TXT_TYPE_SIGNED_PLAIN
[2]       = attempt (0–3; the on-air payload only keeps 2 bits)
[3..6]    = timestamp (uint32 LE, epoch secs) — for CLI the firmware substitutes its own RTC
[7..12]   = destination pub_key prefix (first 6 bytes)
[13+]     = text (a trailing null is tolerated: firmware re-terminates and uses strlen)
```

### `RESP_CODE_SENT` (6)
```
[0]    = 6
[1]    = 1 if sent via flood, 0 if direct
[2..5] = tag (uint32 LE): expected ACK hash for text msgs, or request tag for
         status/telemetry/binary/trace requests — match against pushes 0x82/0x87/0x8B/0x8C
[6..9] = est_timeout (uint32 LE, ms) — how long to wait before considering it lost
```

### `RESP_CODE_SELF_INFO` (5) — reply to CMD_APP_START
```
[0]      = 5
[1]      = ADV_TYPE (always 1/chat for companion)
[2]      = tx_power_dbm (int8)
[3]      = MAX_LORA_TX_POWER (int8)
[4..35]  = pub_key (32 bytes)
[36..39] = lat (int32 LE, degrees × 1e6)
[40..43] = lon (int32 LE, degrees × 1e6)
[44]     = multi_acks
[45]     = advert_loc_policy (0 = none, 1 = share)
[46]     = telemetry modes, packed (env << 4) | (loc << 2) | base
           each 2-bit field: 0 = deny, 1 = allow-per-contact-flags, 2 = allow-all
[47]     = manual_add_contacts (bit 0 set = auto-add disabled)
[48..51] = freq (uint32 LE, kHz × 1000 i.e. Hz)
[52..55] = bw (uint32 LE, Hz)
[56]     = sf
[57]     = cr
[58+]    = node_name (runs to end of frame)
```

### `RESP_CODE_DEVICE_INFO` (13) — reply to CMD_DEVICE_QUERY
```
[0]      = 13
[1]      = FIRMWARE_VER_CODE (13 for v1.16.0)
[2]      = max contacts ÷ 2
[3]      = max group channels
[4..7]   = ble_pin (uint32 LE, 0 = unset)
[8..19]  = firmware build date (12 bytes, null-padded)
[20..59] = manufacturer/board name (40 bytes, null-padded)
[60..79] = firmware version string (20 bytes, null-padded)
[80]     = client_repeat (fw v9+)
[81]     = path_hash_mode (fw v10+): 0–2 → (mode+1)-byte path hashes
```

### Message sync frames — replies to `CMD_SYNC_NEXT_MESSAGE` (10)

The app polls SYNC_NEXT_MESSAGE (usually after a `PUSH_CODE_MSG_WAITING` tickle) until it gets
`RESP_CODE_NO_MORE_MESSAGES` (10).

`RESP_CODE_CONTACT_MSG_RECV_V3` (16) — contact text / CLI response / signed message:
```
[0]      = 16
[1]      = SNR × 4 (int8)
[2..3]   = reserved (0)
[4..9]   = sender pub_key prefix (6 bytes)
[10]     = path_len byte (§1 encoding) — 0xFF if the packet arrived Direct
[11]     = txt_type (0 plain, 1 CLI data, 2 signed)
[12..15] = sender_timestamp (uint32 LE)
[16+]    = text — NOT null-terminated, runs to end of frame
           For txt_type 2 (signed): [16..19] = 4-byte sender pubkey prefix, text at [20+]
```

`RESP_CODE_CHANNEL_MSG_RECV_V3` (17) — group channel message:
```
[0]      = 17
[1]      = SNR × 4 (int8)
[2..3]   = reserved (0)
[4]      = channel_idx
[5]      = path_len byte — 0xFF if Direct
[6]      = txt_type (always 0 for channel messages)
[7..10]  = timestamp (uint32 LE)
[11+]    = text as "sender: message" (firmware pre-formats), runs to end of frame
```

Legacy v<3 frames (codes 7 and 8) are identical minus the 3-byte SNR+reserved prefix — all
offsets shift back by 3.

### `RESP_CODE_STATS` (24) — reply to CMD_GET_STATS
```
type 0 (core):    [code][0][battery_mv x2][uptime_secs x4][err_flags x2][tx_queue_len]
type 1 (radio):   [code][1][noise_floor i16][last_rssi i8][last_snr×4 i8][tx_air_secs x4][rx_air_secs x4]
type 2 (packets): [code][2][recv x4][sent x4][sent_flood x4][sent_direct x4]
                           [recv_flood x4][recv_direct x4][recv_errors x4]
```

### `PUSH_CODE_LOG_RX_DATA` (0x88) — raw RX log

Sent for every received LoRa packet (when RX logging is on). Bytes [3+] are the raw wire packet
(§1 format), which includes the path hashes. The **first** path hash is the originating node —
for group messages (whose payload has no sender identity), match it against contact pub_key
prefixes to identify the sender.

### Node discovery via `CMD_SEND_CONTROL_DATA` (55)

Control payload for a repeater discovery sweep (what `buildRepeaterDiscoveryFrame` sends):
```
[0] = 0x80 (CTL_TYPE_NODE_DISCOVER_REQ; bit 0 = prefix_only)
[1] = node type filter bits (1 << ADV_TYPE_*, e.g. 0x04 = repeaters)
[2..5] = tag (uint32 LE, random)
[6..9] = since (uint32 LE, optional — 0 = all)
```
Responders send `CTL_TYPE_NODE_DISCOVER_RESP` (0x90 | node_type) which arrives as push 0x8E:
`[0x90|type][snr×4][tag x4][pub_key x32]`.

### Group text on-air payload (`PAYLOAD_TYPE_GRP_TXT`)
```
[0]     channel_hash (1 byte)
[1..2]  MAC (2 bytes)
[3+]    encrypted: [timestamp x4][txt_type][text "sender: message"]
```

### Auto-add config flags (CMD 58 / RESP 25)
```
bit 0 (0x01) = overwrite oldest non-favourite when contacts full
bit 1 (0x02) = auto-add Chat        bit 2 (0x04) = auto-add Repeater
bit 3 (0x08) = auto-add Room server bit 4 (0x10) = auto-add Sensor
```

---

## 6. Path Mechanics (Firmware-Level)

### `ContactInfo` struct (firmware internal)
```cpp
struct ContactInfo {
  mesh::Identity id;          // public key
  char name[32];
  uint8_t type;               // ADV_TYPE_*
  uint8_t flags;
  uint8_t out_path_len;       // path_len byte encoding; OUT_PATH_UNKNOWN (0xFF) = no path
  uint8_t out_path[MAX_PATH_SIZE];
  uint32_t last_advert_timestamp;
  uint32_t lastmod;
  int32_t gps_lat, gps_lon;
  uint32_t sync_since;
};
```

### The core routing decision (`BaseChatMesh.cpp`, `sendMessage()` / `sendLogin()`)
```cpp
if (recipient.out_path_len == OUT_PATH_UNKNOWN) {
    sendFloodScoped(recipient, pkt);   // no path → scoped flood
} else {
    sendDirect(pkt, recipient.out_path, recipient.out_path_len);  // known path → direct
}
```
Setting a valid `out_path_len` via `CMD_ADD_UPDATE_CONTACT` makes the next send go direct
instead of flooding.

### How paths get learned
- `createPathReturn()` (Mesh.cpp) builds a `PAYLOAD_TYPE_PATH` packet containing the **reversed**
  incoming path plus an optional embedded payload (e.g. the login response). Repeaters send this
  after a flood login to teach the companion the return route.
- `onContactPathRecv()` (BaseChatMesh.cpp) receives it, updates `contact.out_path/out_path_len`,
  and fires `PUSH_CODE_PATH_UPDATED` (0x81) to the app.
- `handleReturnPathRetry()`: if a node receives a flood response but already knows a direct path,
  it re-sends its path directly after ~3 s — self-heals a remote side that lost the path.
- The companion also caches paths from adverts of non-contact nodes in a 16-entry "recently
  heard" table, queryable via `CMD_GET_ADVERT_PATH` (42).

### ADV_TYPE constants
| Value | Meaning |
|-------|---------|
| 0 | `ADV_TYPE_NONE` — transient/anon entry, never saved |
| 1 | `ADV_TYPE_CHAT` | 2 | `ADV_TYPE_REPEATER` |
| 3 | `ADV_TYPE_ROOM` | 4 | `ADV_TYPE_SENSOR` |

---

## 7. Login Handshake Flow

### When the app has NO saved path (or flood override)
1. App calls `preparePathForContactSend()` → `clearContactPath()` (companion sets `out_path_len = 0xFF`)
2. App sends `CMD_SEND_LOGIN` → companion sees `OUT_PATH_UNKNOWN` → `sendFloodScoped()`
3. Repeater receives `PAYLOAD_TYPE_ANON_REQ` as a flood packet, validates password
4. Repeater embeds the login response in a `PAYLOAD_TYPE_PATH` packet (`createPathReturn`) and
   sends it via `sendFloodReply()` scoped to the incoming transport region
5. Companion stores the returned path → fires `PUSH_CODE_PATH_UPDATED` (0x81), and delivers the
   embedded response → fires `PUSH_CODE_LOGIN_SUCCESS` (0x85)
6. App reacts to 0x81 with `CMD_GET_CONTACT_BY_KEY` → subsequent CLI commands go direct

### When the app has a saved direct path
1. App pushes the path via `CMD_ADD_UPDATE_CONTACT`, then sends `CMD_SEND_LOGIN` → `sendDirect()`
2. Repeater receives the login as a **Direct** packet → `recv_pkt_region = NULL` (§8.3)
3. Its reply falls back to a **global (unscoped) flood** — which is **blocked** if the repeater's
   wildcard region has `REGION_DENY_FLOOD` set → the companion never hears back → timeout

**Workaround:** always let the initial login flood (`preparePathForContactSend` without a forced
override). The flood login teaches both sides the path; later CLI traffic goes direct. See
`repeater_login_dialog.dart`. Do NOT force direct mode for login.

---

## 8. Regions and Flood Scoping

Regions let repeaters **limit which flood packets they forward**, so floods stay within their
intended geographic or logical scope.

### 8.1 Data model

```cpp
struct RegionEntry {        // RegionMap.h, max 32 entries
  uint16_t id;              // unique region ID (0 = wildcard/root)
  uint16_t parent;          // parent region ID (tree structure)
  uint8_t flags;            // REGION_DENY_FLOOD (0x01) | REGION_DENY_DIRECT (0x02, reserved)
  char name[31];
};
```

- **Wildcard** (`id = 0`, name `"*"`) — the root. Packets without a recognized transport code fall
  here. Its `REGION_DENY_FLOOD` flag is the "no global flood" switch.
- **Home region** — where this repeater lives (used for advert scoping).
- **Default region** — used when sending by default.

### 8.2 Region names → transport keys

| Name prefix | Key derivation |
|-------------|----------------|
| `#name` (or bare `name`) | Auto hashtag: SHA256 of `"#" + name` — no pre-shared key needed |
| `$name` | Private: pre-shared key loaded from `TransportKeyStore` (file-based) |

`TransportKey` is 16 bytes. `calcTransportCode(packet)` derives a uint16 from key + packet
contents; that goes in `packet.transport_codes[0]`.

### 8.3 Incoming packet classification (repeater)

`filterRecvFloodPacket()` runs on every incoming flood packet:
- `TRANSPORT_FLOOD` → match transport code against known regions → `recv_pkt_region`
- `FLOOD` (unscoped) → wildcard region, **unless** wildcard has `REGION_DENY_FLOOD` → `NULL`
- Direct packets → always `NULL` (no region)

### 8.4 Forwarding decision

`allowPacketForward()` drops a flood packet when: forwarding is disabled, the hop limit is
reached, or **`recv_pkt_region == NULL`**. That last rule is the global-flood block: the wildcard
`REGION_DENY_FLOOD` flag IS "REPEATER_NO_GLOBAL_FLOOD".

> **Why direct login fails on many repeaters:** a Direct packet has no region. When the repeater
> replies with `sendFloodReply()`, there's no region to scope to, so it sends an unscoped global
> flood — which neighbouring repeaters (and itself) drop if their wildcard denies floods.

### 8.5 Scoped replies (repeater)

`sendFloodReply()` re-uses the incoming packet's region key (`ROUTE_TYPE_TRANSPORT_FLOOD`) when
one was recognized; otherwise it falls back to an unscoped flood.

### 8.6 Companion-side scoping

The companion radio's `sendFloodScoped()` (MyMesh.cpp override, **not** the no-op in
`BaseChatMesh`) works like this:
- `send_unscoped` set (via `CMD_SET_FLOOD_SCOPE_KEY [1]`, v12+) → plain unscoped flood
- otherwise use `send_scope` (per-send override via `CMD_SET_FLOOD_SCOPE_KEY [0][key]`) if set,
  else `_prefs.default_scope_key` (set via `CMD_SET_DEFAULT_FLOOD_SCOPE`, 63)
- a null (all-zero) key → unscoped flood

**Practical implication:** if the user set a default scope key on their companion, ALL their
traffic (including logins) goes out scoped to that key. Repeaters without a matching region
silently drop it — flood failures with no obvious cause. Query the scope with
`CMD_GET_DEFAULT_FLOOD_SCOPE` (64).

### 8.7 Region hierarchy

Regions form a tree under the wildcard. Each node has its **own** transport key — parent keys do
not unlock children.
```
* (wildcard — global)
└── California
    ├── NorCal
    └── SoCal
        └── Interlaken (local)
```
A repeater configured only with the "Interlaken" key forwards Interlaken-scoped floods but not
California-scoped ones.

---

## 9. Size Limits and Timeouts

### Size constants (`MeshCore.h`, `BaseSerialInterface.h`, `BaseChatMesh.h`)

| Constant | Value | Meaning |
|----------|-------|---------|
| `MAX_FRAME_SIZE` | 176 | Serial frame size, including code byte |
| `MAX_PACKET_PAYLOAD` | 184 | On-air payload size |
| `MAX_PATH_SIZE` | 64 | Path buffer, bytes |
| `MAX_TEXT_LEN` | 160 | Max message text (10 × CIPHER_BLOCK_SIZE) |
| `PUB_KEY_SIZE` | 32 | |
| `SIGNATURE_SIZE` | 64 | |
| Contact name | 32 | Including null terminator |

Message length in practice: direct messages max **160 bytes** of UTF-8; channel messages max
**160 − (senderNameLen + 2)** because the firmware prepends `"name: "` inside the encrypted
payload. The Dart helpers `maxContactMessageBytes()` / `maxChannelMessageBytes()` implement this.

### Send timeout formulas (companion `MyMesh.cpp` + `BaseChatMesh`)

```
flood_timeout  = 500 + 16 × airtime_ms
direct_timeout = 500 + (airtime_ms × 6 + 250) × (hopCount + 1)
```
(`SEND_TIMEOUT_BASE_MILLIS 500`, `FLOOD_SEND_TIMEOUT_FACTOR 16`, `DIRECT_SEND_PERHOP_FACTOR 6`,
`DIRECT_SEND_PERHOP_EXTRA_MILLIS 250`.) The firmware reports its own estimate in
`RESP_CODE_SENT[6..9]` — prefer that over recomputing. Dart's `calculateMessageTimeout()`
mirrors the same formula for pre-send UI estimates.

---

## 10. App-Side Path Resolution (`resolvePathSelection`)

Priority order:
1. `contact.pathOverride != null`:
   - `< 0` → force flood
   - `>= 0` → use `pathOverrideBytes` with `pathOverride` hops (direct)
2. `forceFlood` or `contact.pathLength < 0` → flood
3. `autoSelection` provided → use auto-selected path
4. Fall through to `contact.path` / `contact.pathLength` from the device

**Important:** after a flood login the device pushes 0x81 → the app calls
`CMD_GET_CONTACT_BY_KEY` → `contact.pathLength`/`contact.path` update. Because `pathOverride` is
null, subsequent sends automatically use the new device path — this is what makes CLI commands go
direct after the first flood login.

---

## 11. App Architecture Overview

| Class | File | Responsibility |
|-------|------|---------------|
| `MeshCoreConnector` | `lib/connector/meshcore_connector.dart` | BLE/USB transport, frame encode/decode, contact state, all protocol commands |
| protocol helpers | `lib/connector/meshcore_protocol.dart` | All frame builders/parsers and protocol constants (verified against firmware) |
| `PathHistoryService` | `lib/services/path_history_service.dart` | Per-contact path ACK history, flood stats, recent paths |
| `RetryService` | `lib/services/retry_service.dart` | Automatic message retry with path rotation |
| `AppSettingsService` | `lib/services/app_settings_service.dart` | Persisted user preferences |
| `ContactStore` | `lib/services/contact_store.dart` | Persistent contact storage |
| `PathSelectionDialog` | `lib/widgets/path_selection_dialog.dart` | UI for manually specifying a path |
| `PathManagementDialog` | `lib/widgets/path_management_dialog.dart` | UI for choosing from recent ACK paths |
| `RepeaterLoginDialog` | `lib/widgets/repeater_login_dialog.dart` | Login handshake, retry loop, timeout logic |

### Key connector methods for path management
- `preparePathForContactSend(contact)` → pushes the right path to the companion before sending
- `setContactPath(contact, pathBytes, hopCount)` → `CMD_ADD_UPDATE_CONTACT` with path bytes
- `clearContactPath(contact)` → sets `out_path_len = 0xFF` on the companion
- `setPathOverride(contact, pathLen, pathBytes)` → app-level override, optionally synced to device
- `resolvePathSelection(contact)` → current effective path without pushing to device

### Contact model fields relevant to routing
| Field | Meaning |
|-------|---------|
| `contact.pathLength` | Hop count decoded from the device's `out_path_len` byte (−1 = flood) |
| `contact.path` | Device-reported path bytes, sliced to hopCount × hashSize |
| `contact.pathHashSize` | Hash width (1–3 bytes), from `out_path_len` upper bits |
| `contact.pathOverride` | App override: null = auto, −1 = force flood, ≥0 = direct with N hops |
| `contact.pathOverrideBytes` | Path bytes for the override |

---

## 12. Known Bugs and Gotchas (Do Not Re-introduce)

Previously debugged issues. Check here before touching related code.

### Bug (fixed 2026-07): contact hop count derived by scanning path bytes
**File:** `lib/models/contact.dart`
**Symptom:** contacts with valid stored paths showed as "Direct"/0 hops; pathLen tests failed.
**Root cause:** `Contact.fromFrame` re-derived the hop count via `PathHelper.getHopCount`, which
stops at the first hop byte equal to 0x00 — but the firmware's `path_len` byte (low 6 bits) is
the sole source of truth (§1).
**Fix:** use `extractPathHopCount(pathLenByte)` directly. Never scan path bytes for a count.

### Bug (fixed 2026-07): self-telemetry frame was 5 bytes, firmware wants exactly 4
**File:** `lib/connector/meshcore_protocol.dart` (`buildSendTelemetryReq`)
The firmware's self-telemetry branch requires `len == 4` exactly (`[39][reserved x3]`). The
builder wrote 4 reserved bytes → 5-byte frame → `ERR_CODE_UNSUPPORTED_CMD`. Always 3 reserved
bytes; the optional 32-byte pubkey follows for remote requests.

### Bug (fixed 2026-07): channel messages transmitted a trailing null byte
**File:** `lib/connector/meshcore_protocol.dart` (`buildSendChannelTextMsgFrame`)
For `CMD_SEND_CHANNEL_TXT_MSG` the firmware treats **every byte after the 7-byte header as text**
(`sendGroupMessage(..., len - 7)`) — a trailing null gets encrypted and sent over the air.
Do not append a terminator. (`CMD_SEND_TXT_MSG` is different: the firmware re-terminates and
uses `strlen`, so a trailing null there is merely tolerated.)

### Bug (fixed 2026-07): bogus `msg*Offset` constants / dead `Message.fromFrame`
Removed. They described a `[code][pubkey x32][timestamp][flags][text]` layout that never existed
in the companion firmware. The real layouts are in §5. If you need to parse contact messages,
use `parseContactMessageText()` or the connector's sync-message handling.

### Bug: 0-hop path tap silently did nothing
**File:** `lib/widgets/path_management_dialog.dart`
0-hop paths have **empty path bytes** (valid!). Guard must be
`if (path.hopCount > 0 && path.pathBytes.isEmpty)`, not `if (path.pathBytes.isEmpty)`.

### Bug: forced-flood regression in login dialog
**File:** `lib/widgets/repeater_login_dialog.dart`
Login dialog once forced `pathLen: -1` before every login, so logins always flooded even with a
stored direct path. Use `preparePathForContactSend(repeater)`, which respects the saved override.

### Gotcha: direct login times out on many repeaters
Direct packets have no region → the repeater's reply becomes an unscoped global flood → blocked
by wildcard `REGION_DENY_FLOOD` (§7, §8.4). Let the initial login flood; do NOT force direct.

### Gotcha: 0-hop override logs `bytesLen: null`
Setting a 0-hop override stores an empty (not null) `Uint8List`; `copyWith` logs null for empty
lists. Cosmetic only — the device receives the correct frame.

### Gotcha: companion scope key can silently kill floods
If the companion has a default scope key set, all its floods are scoped (§8.6). Repeaters without
a matching region drop them even when global floods are allowed. Check
`CMD_GET_DEFAULT_FLOOD_SCOPE` when floods mysteriously vanish.

---

## 13. Key Source Files (Reference Only — Do Not Modify)

| File | What to find there |
|------|-------------|
| `MeshCore/src/Packet.h` | ROUTE_TYPE_*, PAYLOAD_TYPE_*, the path_len byte encoding |
| `MeshCore/src/MeshCore.h` | Size constants (MAX_PACKET_PAYLOAD, MAX_PATH_SIZE, …) |
| `MeshCore/src/Mesh.h` / `Mesh.cpp` | createXxx()/sendXxx() signatures; onRecvPacket() routing dispatch |
| `MeshCore/src/helpers/ContactInfo.h` | ContactInfo struct, OUT_PATH_UNKNOWN |
| `MeshCore/src/helpers/BaseChatMesh.h/.cpp` | MAX_TEXT_LEN, sendMessage(), sendGroupMessage(), onContactPathRecv(), handleReturnPathRetry() |
| `MeshCore/src/helpers/BaseSerialInterface.h` | MAX_FRAME_SIZE (176) |
| `MeshCore/src/helpers/RegionMap.h/.cpp` | RegionEntry, RegionMap, transport key derivation |
| `MeshCore/src/helpers/TransportKeyStore.h` | TransportKey, calcTransportCode() |
| `MeshCore/examples/companion_radio/MyMesh.cpp` | **The serial protocol**: all CMD_/RESP_/PUSH_ constants and `handleCmdFrame()` — every frame layout in §4–§5 comes from here |
| `MeshCore/examples/companion_radio/MyMesh.h` | FIRMWARE_VER_CODE, REQ_TYPE_* |
| `MeshCore/examples/companion_radio/NodePrefs.h` | TELEM_MODE_*, ADVERT_LOC_* |
| `MeshCore/examples/simple_repeater/MyMesh.cpp` | Repeater side: login handling, filterRecvFloodPacket(), allowPacketForward(), sendFloodReply(), node discovery, REQ_TYPE_GET_ACCESS_LIST (0x05) / GET_NEIGHBOURS (0x06) |
