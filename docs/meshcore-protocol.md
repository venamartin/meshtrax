# MeshCore Protocol Reference

> **Purpose:** AI agent reference document. Read this BEFORE opening any `MeshCore/` C++ files.
> All information here is verified directly from the firmware source. Update this file when new
> protocol details are discovered rather than re-reading the firmware files.

---

## 1. Packet Wire Format

Every over-the-air packet has the following structure:

```
[header: 1 byte]
[path_len: 1 byte]           ← encodes BOTH hash count AND hash size
[path_bytes: variable]       ← path_len.count × path_len.hashSize bytes
[payload_len: 1 byte]
[payload: variable]
[transport_codes: 4 bytes]   ← ONLY present when route is TRANSPORT_FLOOD or TRANSPORT_DIRECT
```

### `header` byte layout (Packet.h)
```
bits [1:0]  = ROUTE_TYPE   (2 bits)
bits [5:2]  = PAYLOAD_TYPE (4 bits)
bits [7:6]  = PAYLOAD_VER  (2 bits, currently always 0)
```

### `path_len` byte layout (Packet.h)
```
bits [5:0]  = hash count (0–63 intermediate hops)
bits [7:6]  = (hash_size - 1)   →  0 = 1-byte hashes, 1 = 2-byte hashes
```

Dart encoding: `(hopCount & 0x3F) | ((hashSize - 1) << 6)`  
Dart decoding: `hashSize = (path_len >> 6) + 1`,  `hopCount = path_len & 63`

**Special value:** `path_len = 0xFF` → flood (OUT_PATH_UNKNOWN)

### Path bytes
For a 0-hop direct packet: path bytes are **empty** (zero length). This is valid!  
For an N-hop packet: N × hashSize bytes, one hash per intermediate node.

---

## 2. Route Types

| Constant | Value | Meaning |
|----------|-------|---------|
| `ROUTE_TYPE_TRANSPORT_FLOOD` | `0x00` | Flood + transport codes (scoped) |
| `ROUTE_TYPE_FLOOD` | `0x01` | Unscoped flood, path builds as it propagates |
| `ROUTE_TYPE_DIRECT` | `0x02` | Direct route, path supplied |
| `ROUTE_TYPE_TRANSPORT_DIRECT` | `0x03` | Direct + transport codes |

`isRouteFlood()` = true for TRANSPORT_FLOOD or FLOOD  
`isRouteDirect()` = true for DIRECT or TRANSPORT_DIRECT  
`hasTransportCodes()` = true for TRANSPORT_FLOOD or TRANSPORT_DIRECT

---

## 3. Payload Types

| Constant | Value | Description |
|----------|-------|-------------|
| `PAYLOAD_TYPE_REQ` | `0x00` | Authenticated request (dest/src hashes + MAC) |
| `PAYLOAD_TYPE_RESPONSE` | `0x01` | Response to REQ or ANON_REQ |
| `PAYLOAD_TYPE_TXT_MSG` | `0x02` | Text message (dest/src hashes + MAC) |
| `PAYLOAD_TYPE_ACK` | `0x03` | Simple ACK (4-byte CRC hash) |
| `PAYLOAD_TYPE_ADVERT` | `0x04` | Node advertising its Identity |
| `PAYLOAD_TYPE_GRP_TXT` | `0x05` | Group text message |
| `PAYLOAD_TYPE_GRP_DATA` | `0x06` | Group datagram |
| `PAYLOAD_TYPE_ANON_REQ` | `0x07` | Anonymous request — used for LOGIN |
| `PAYLOAD_TYPE_PATH` | `0x08` | Path return packet (can carry embedded extra payload) |
| `PAYLOAD_TYPE_TRACE` | `0x09` | Path trace (SNR collection) |
| `PAYLOAD_TYPE_MULTIPART` | `0x0A` | Multi-part packet |
| `PAYLOAD_TYPE_CONTROL` | `0x0B` | Control/discovery packet |
| `PAYLOAD_TYPE_RAW_CUSTOM` | `0x0F` | Raw bytes, custom encryption |

---

## 4. BLE Frame Protocol (App ↔ Companion Radio)

Max frame size: **172 bytes**. Byte 0 is always the command or response code.

### 4.1 Commands (App → Companion)

| Code | Constant | Description |
|------|----------|-------------|
| 1 | `CMD_APP_START` | Initialize, get self-info |
| 2 | `CMD_SEND_TXT_MSG` | Send text message |
| 3 | `CMD_SEND_CHANNEL_TXT_MSG` | Send group channel message |
| 4 | `CMD_GET_CONTACTS` | Get all contacts (with optional `since` timestamp) |
| 5 | `CMD_GET_DEVICE_TIME` | Get RTC clock |
| 6 | `CMD_SET_DEVICE_TIME` | Set RTC clock |
| 7 | `CMD_SEND_SELF_ADVERT` | Broadcast self advertisement |
| 8 | `CMD_SET_ADVERT_NAME` | Set node name |
| 9 | `CMD_ADD_UPDATE_CONTACT` | Add/update a contact **including its stored path** |
| 10 | `CMD_SYNC_NEXT_MESSAGE` | Fetch next pending message |
| 11 | `CMD_SET_RADIO_PARAMS` | Set LoRa radio parameters |
| 12 | `CMD_SET_RADIO_TX_POWER` | Set TX power |
| 13 | `CMD_RESET_PATH` | Reset path for a contact |
| 14 | `CMD_SET_ADVERT_LATLON` | Set GPS coordinates |
| 15 | `CMD_REMOVE_CONTACT` | Remove a contact |
| 16 | `CMD_SHARE_CONTACT` | Share contact with another node |
| 17 | `CMD_EXPORT_CONTACT` | Export contact data |
| 18 | `CMD_IMPORT_CONTACT` | Import contact data |
| 19 | `CMD_REBOOT` | Reboot device |
| 20 | `CMD_GET_BATT_AND_STORAGE` | Get battery voltage + storage stats |
| 22 | `CMD_DEVICE_QUERY` | Query device info |
| 26 | `CMD_SEND_LOGIN` | Send login to repeater/room server |
| 27 | `CMD_SEND_STATUS_REQ` | Send status request |
| 29 | `CMD_LOGOUT` | Disconnect/logout from repeater |
| 30 | `CMD_GET_CONTACT_BY_KEY` | Fetch single contact by public key |
| 31 | `CMD_GET_CHANNEL` | Get channel info |
| 32 | `CMD_SET_CHANNEL` | Set channel |
| 36 | `CMD_SEND_TRACE_PATH` | Initiate a path trace |
| 40 | `CMD_GET_CUSTOM_VARS` | Get custom variables |
| 41 | `CMD_SET_CUSTOM_VAR` | Set custom variable |
| 52 | `CMD_SEND_PATH_DISCOVERY_REQ` | Request path discovery |
| 55 | `CMD_SEND_CONTROL_DATA` | Send control/discovery data |
| 56 | `CMD_GET_STATS` | Get stats (second byte = stats type: 0=core, 1=radio, 2=packets) |
| 57 | `CMD_SEND_ANON_REQ` | Send anonymous request |
| 58 | `CMD_SET_AUTOADD_CONFIG` | Set auto-add configuration |
| 59 | `CMD_GET_AUTOADD_CONFIG` | Get auto-add configuration |
| 61 | `CMD_SET_PATH_HASH_MODE` | Set 1-byte or 2-byte path hashes |
| 63 | `CMD_SET_DEFAULT_FLOOD_SCOPE` | Set default flood scope key |
| 64 | `CMD_GET_DEFAULT_FLOOD_SCOPE` | Get default flood scope |

### 4.2 Responses (Companion → App)

| Code | Constant | Description |
|------|----------|-------------|
| 0 | `RESP_CODE_OK` | Generic success |
| 1 | `RESP_CODE_ERR` | Error (second byte = error code) |
| 2 | `RESP_CODE_CONTACTS_START` | First reply to `CMD_GET_CONTACTS` |
| 3 | `RESP_CODE_CONTACT` | Contact data frame (see format below) |
| 4 | `RESP_CODE_END_OF_CONTACTS` | Last reply to `CMD_GET_CONTACTS` |
| 5 | `RESP_CODE_SELF_INFO` | Self info reply to `CMD_APP_START` |
| 6 | `RESP_CODE_SENT` | Message sent (see format below) |
| 7 | `RESP_CODE_CONTACT_MSG_RECV` | Contact message (protocol v<3) |
| 8 | `RESP_CODE_CHANNEL_MSG_RECV` | Channel message (protocol v<3) |
| 9 | `RESP_CODE_CURR_TIME` | Reply to `CMD_GET_DEVICE_TIME` |
| 10 | `RESP_CODE_NO_MORE_MESSAGES` | No more messages to sync |
| 12 | `RESP_CODE_BATT_AND_STORAGE` | Battery + storage data |
| 16 | `RESP_CODE_CONTACT_MSG_RECV_V3` | Contact message (protocol v≥3) |
| 17 | `RESP_CODE_CHANNEL_MSG_RECV_V3` | Channel message (protocol v≥3) |
| 18 | `RESP_CODE_CHANNEL_INFO` | Reply to `CMD_GET_CHANNEL` |
| 25 | `RESP_CODE_AUTOADD_CONFIG` | Auto-add configuration |

### 4.3 Push Codes (Companion → App, unsolicited)

| Code | Constant | Description |
|------|----------|-------------|
| `0x80` | `PUSH_CODE_ADVERT` | New advertisement received |
| `0x81` | `PUSH_CODE_PATH_UPDATED` | Contact path was updated |
| `0x82` | `PUSH_CODE_SEND_CONFIRMED` | Message delivery confirmed |
| `0x83` | `PUSH_CODE_MSG_WAITING` | New message waiting |
| `0x84` | `PUSH_CODE_RAW_DATA` | Raw data received |
| `0x85` | `PUSH_CODE_LOGIN_SUCCESS` | Login succeeded |
| `0x86` | `PUSH_CODE_LOGIN_FAIL` | Login failed (wrong password) |
| `0x87` | `PUSH_CODE_STATUS_RESPONSE` | Status response received |
| `0x88` | `PUSH_CODE_LOG_RX_DATA` | Raw packet log data (includes path hashes) |
| `0x89` | `PUSH_CODE_TRACE_DATA` | Trace data |
| `0x8A` | `PUSH_CODE_NEW_ADVERT` | Newly discovered contact advert |
| `0x8E` | `PUSH_CODE_CONTROL_DATA` | Control/discovery data (v8+) |
| `0x8F` | `PUSH_CODE_CONTACT_DELETED` | Contact deleted (overwrite oldest) |
| `0x90` | `PUSH_CODE_CONTACTS_FULL` | Contacts storage full |

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

## 5. Key BLE Frame Formats

### `RESP_CODE_CONTACT` / `PUSH_CODE_NEW_ADVERT` frame (companion → app)
Source: `writeContactRespFrame()` in companion `MyMesh.cpp`:
```
[0]         code (3 = RESP_CODE_CONTACT, 0x8A = PUSH_CODE_NEW_ADVERT, etc.)
[1..32]     pub_key (32 bytes)
[33]        type  (ADV_TYPE_*)
[34]        flags
[35]        out_path_len  ← 0xFF = OUT_PATH_UNKNOWN (no known path)
                          ← 0x00 = 0-hop direct (zero intermediate hops)
                          ← encoded as path_len byte: upper 2 bits = hashSize-1
[36..99]    out_path  (MAX_PATH_SIZE bytes, padded)
[100..131]  name (32 bytes, null-padded)
[132..135]  last_advert_timestamp (uint32 LE)
[136..139]  gps_lat (int32 LE, degrees × 1e6)
[140..143]  gps_lon (int32 LE, degrees × 1e6)
[144..147]  lastmod (uint32 LE, our RTC clock)
```

### `CMD_ADD_UPDATE_CONTACT` (app → companion) = same layout as above starting at byte 1

### `RESP_CODE_SENT` frame (companion → app)
```
[0]  = 6 (RESP_CODE_SENT)
[1]  = 1 if sent via flood, 0 if sent direct
[2..5] = pending_login or tag (4 bytes, matches future ACK/response)
[6..9] = est_timeout (uint32 LE, milliseconds)
```

### `PUSH_CODE_PATH_UPDATED` frame (companion → app)
```
[0]      = 0x81
[1..32]  = pub_key of the contact whose path was updated
```
App response: call `CMD_GET_CONTACT_BY_KEY` to fetch the new path.

### `RESP_CODE_SELF_INFO` frame (companion → app, reply to CMD_APP_START)
```
[0]      = 5
[1]      = ADV_TYPE
[2]      = tx_power_dbm (int8)
[3]      = MAX_LORA_TX_POWER (int8)
[4..35]  = pub_key (32 bytes)
[36..39] = lat (int32 LE, degrees × 1e6)
[40..43] = lon (int32 LE, degrees × 1e6)
[44]     = multi_acks
[45]     = advert_loc_policy
[46]     = telemetry flags (bits[1:0]=base, bits[3:2]=env, bits[5:4]=loc)
[47]     = manual_add_contacts (bit 0: 0=auto-add enabled)
[48..51] = freq_hz (uint32 LE)
[52..55] = bw_hz (uint32 LE)
[56]     = sf (spreading factor)
[57]     = cr (coding rate)
[58+]    = node_name (C string)
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
  uint8_t out_path_len;       // OUT_PATH_UNKNOWN (0xFF) = no known path
  uint8_t out_path[MAX_PATH_SIZE];
  uint32_t last_advert_timestamp;
  uint32_t lastmod;
  int32_t gps_lat, gps_lon;
  uint32_t sync_since;
};
```

**`OUT_PATH_UNKNOWN = 0xFF`** is the sentinel meaning "no known path, must flood."

### Routing decision in `sendLogin()` / `sendTxtMsg()` (BaseChatMesh.cpp)
```cpp
if (recipient.out_path_len == OUT_PATH_UNKNOWN) {
    sendFloodScoped(recipient, pkt);   // no path → scoped flood
} else {
    sendDirect(pkt, recipient.out_path, recipient.out_path_len);  // known path → direct
}
```
**This is the core routing decision.** Setting `CMD_ADD_UPDATE_CONTACT` with a valid `out_path_len` causes the next `CMD_SEND_LOGIN` to use `sendDirect` instead of flood.

### `createPathReturn()` (Mesh.cpp)
Creates a `PAYLOAD_TYPE_PATH` packet containing:
- The **reversed** incoming path (so the recipient can reply directly)
- An optional extra payload embedded inside (e.g., the login response)

Used by repeater after a flood login to teach the companion the return route.

### `onContactPathRecv()` → `onContactPathUpdated()` (BaseChatMesh.cpp)
Called when a `PAYLOAD_TYPE_PATH` packet is received. Updates `contact.out_path` and `contact.out_path_len`. Fires `onContactPathUpdated()` which triggers a `PUSH_CODE_PATH_UPDATED` (0x81) push to the app.

### `handleReturnPathRetry()` (BaseChatMesh.cpp)
If a node receives a Flood response but already has a known direct path, it re-sends its path directly to the sender with a 3-second delay. This self-heals cases where the remote side lost the path.

---

## 7. Login Handshake Flow

### When the app has NO saved path (or flood override)
1. App calls `preparePathForContactSend()` → `clearContactPath()` (companion sets `out_path_len = OUT_PATH_UNKNOWN`)
2. App sends `CMD_SEND_LOGIN` → companion calls `sendLogin()` → sees `OUT_PATH_UNKNOWN` → `sendFloodScoped()`
3. Repeater receives `PAYLOAD_TYPE_ANON_REQ` as a Flood packet
4. Repeater calls `handleLoginReq()` → validates password
5. Repeater calls `createPathReturn(sender, secret, packet->path, packet->path_len, PAYLOAD_TYPE_RESPONSE, reply_data, reply_len)` — embeds login response inside a PATH packet
6. Repeater calls `sendFloodReply(path_pkt, ...)` — scoped to the incoming transport region
7. Companion receives `PAYLOAD_TYPE_PATH` → calls `onContactPathRecv()` → stores 2-hop path → fires `PUSH_CODE_PATH_UPDATED` (0x81)
8. Companion also calls `onContactResponse()` with the embedded login response → fires `PUSH_CODE_LOGIN_SUCCESS` (0x85)
9. App receives 0x81 → calls `CMD_GET_CONTACT_BY_KEY` → gets updated contact with stored path
10. All subsequent CLI commands use direct routing

### When the app has a saved direct path (e.g., 0-hop or N-hop)
1. App calls `preparePathForContactSend()` → `setContactPath()` → sends `CMD_ADD_UPDATE_CONTACT` with path bytes and `out_path_len`
2. App sends `CMD_SEND_LOGIN` → companion calls `sendLogin()` → sees valid `out_path_len` → `sendDirect()`
3. Repeater receives `PAYLOAD_TYPE_ANON_REQ` as a Direct packet
4. Repeater calls `handleLoginReq()` → validates password
5. **CRITICAL:** Since `isRouteFlood()` is false and `reply_path_len < 0` (no return path provided), the repeater calls `sendFloodReply()`. This becomes a Global Flood (unscoped) because the direct packet had no transport code.
6. **If `REPEATER_NO_GLOBAL_FLOOD` is set on the repeater**, the global flood is **BLOCKED** → companion never receives the response → timeout!
7. **The firmware fix needed is in `MyMesh.cpp` (reference only — do not modify).**

### Workaround for direct login with NO_GLOBAL_FLOOD repeaters
The app-side workaround is to always use Flood for the initial login handshake (using `preparePathForContactSend` normally without a forced override). After the flood login completes, the repeater sends a PATH packet that establishes the direct path for subsequent CLI commands. See `repeater_login_dialog.dart`.

---

## 8. Regions and Flood Scoping

Regions are the mechanism by which repeater nodes **limit which flood packets they forward**, preventing floods from propagating beyond their intended geographic or logical scope.

### 8.1 Data Model

**`RegionEntry` struct** (RegionMap.h):
```cpp
struct RegionEntry {
  uint16_t id;        // unique region ID (0 = wildcard/root)
  uint16_t parent;    // parent region ID (tree structure)
  uint8_t flags;      // REGION_DENY_FLOOD | REGION_DENY_DIRECT
  char name[31];      // region name (see naming below)
};
```

**Flags:**
- `REGION_DENY_FLOOD = 0x01` — this region does NOT forward flood packets (default for new regions)
- `REGION_DENY_DIRECT = 0x02` — reserved for future use

**Special regions:**
- **Wildcard** (`id=0`, name=`"*"`) — the root region. All packets without a recognized transport code fall into the wildcard. The wildcard's `flags` control global (unscoped) flood behavior.
- **Home region** — the region this repeater is in (used for advert scoping)
- **Default region** — the region used when sending packets by default

**Max regions:** 32 (`MAX_REGION_ENTRIES`)

### 8.2 Region Naming and Transport Key Derivation

Region names determine how transport keys (used for packet scoping) are derived:

| Name prefix | Key derivation method |
|-------------|----------------------|
| `#name` | **Auto hashtag**: SHA256 of `("#" + name)` — no pre-shared key needed |
| `name` (no prefix) | Also treated as auto hashtag internally: SHA256 of `("#" + name)` |
| `$name` | **Private**: requires a pre-shared key loaded from `TransportKeyStore` (file-based) |

`TransportKey` is 16 bytes. `calcTransportCode(packet)` derives a uint16 from the key + packet contents. This is what goes in `packet.transport_codes[0]`.

### 8.3 How Incoming Packets are Classified (Repeater)

On every incoming flood packet, the repeater calls `filterRecvFloodPacket()` (before processing):

```cpp
bool MyMesh::filterRecvFloodPacket(mesh::Packet* pkt) {
  if (pkt->getRouteType() == ROUTE_TYPE_TRANSPORT_FLOOD) {
    // scoped flood: match transport code against known regions
    recv_pkt_region = region_map.findMatch(pkt, REGION_DENY_FLOOD);
  } else if (pkt->getRouteType() == ROUTE_TYPE_FLOOD) {
    // unscoped (global) flood: use wildcard if wildcard allows it
    if (region_map.getWildcard().flags & REGION_DENY_FLOOD) {
      recv_pkt_region = NULL;   // ← global flood BLOCKED
    } else {
      recv_pkt_region = &region_map.getWildcard();
    }
  } else {
    recv_pkt_region = NULL;  // Direct packets have no region
  }
  return false;  // don't filter, just classify
}
```

`recv_pkt_region` is then used in `allowPacketForward()` and `sendFloodReply()`.

### 8.4 Packet Forwarding Decision

`allowPacketForward()` is the gate for all retransmission:
```cpp
bool MyMesh::allowPacketForward(const mesh::Packet* packet) {
  if (_prefs.disable_fwd) return false;            // forwarding disabled
  if (flood hop count >= flood_max) return false;  // hop limit
  if (ROUTE_TYPE_FLOOD && hops >= flood_max_unscoped) return false;
  if (isRouteFlood() && recv_pkt_region == NULL) return false;  // ← NO REGION = DROPPED
  // loop detection checks...
  return true;
}
```

**Key insight:** If `recv_pkt_region == NULL`, the packet is **always dropped** — even if `REPEATER_NO_GLOBAL_FLOOD` is not a thing per se. The wildcard `REGION_DENY_FLOOD` flag IS the global flood block.

> **This is why Direct login fails with many repeater configurations:**  
> Direct packets (`ROUTE_TYPE_DIRECT`) set `recv_pkt_region = NULL`. When the repeater tries to reply with `sendFloodReply()`, it calls `sendFlood()` (unscoped) because there's no region for a direct packet. The wildcard has `REGION_DENY_FLOOD` set → the flood is dropped → no reply reaches the companion.

### 8.5 Sending a Scoped Reply (Repeater)

The repeater's `sendFloodReply()` uses the incoming packet's region to scope its reply:

```cpp
void MyMesh::sendFloodReply(Packet* packet, unsigned long delay, uint8_t hash_size) {
  if (recv_pkt_region && !recv_pkt_region->isWildcard()) {
    // use same transport key as the incoming request
    TransportKey scope;
    region_map.getTransportKeysFor(*recv_pkt_region, &scope, 1);
    sendFloodScoped(scope, packet, delay, hash_size);  // ROUTE_TYPE_TRANSPORT_FLOOD
  } else {
    sendFlood(packet, delay, hash_size);  // unscoped (global) flood
  }
}
```

So a **scoped flood reply** (`ROUTE_TYPE_TRANSPORT_FLOOD`) is only sent when the incoming packet had a recognized transport code matching a known region. Otherwise, the reply is a global flood which may be blocked by the wildcard's `REGION_DENY_FLOOD`.

### 8.6 Companion Radio sendFloodScoped

In `BaseChatMesh` (which the companion radio uses), `sendFloodScoped` is:
```cpp
void BaseChatMesh::sendFloodScoped(const ContactInfo& recipient, Packet* pkt, ...) {
  sendFlood(pkt, delay);   // ← always unscoped!
}
```

**The companion always sends unscoped (global) floods.** It has no concept of regions. The companion relies on the network's repeaters to have appropriate regions configured to carry its traffic.

### 8.7 Wildcard Region and REGION_DENY_FLOOD

The wildcard region (`id=0`) is the catch-all for unscoped packets. Its flags control global flood behavior:
- `wildcard.flags = 0` → global floods **allowed** (repeater forwards all unscoped traffic)
- `wildcard.flags = REGION_DENY_FLOOD (0x01)` → global floods **blocked** (this is `REPEATER_NO_GLOBAL_FLOOD`)

When the app UI shows a repeater "has `NO_GLOBAL_FLOOD`" — this means `wildcard.flags & REGION_DENY_FLOOD` is set on that repeater.

### 8.8 Region Tree / Hierarchy

Regions form a tree under the wildcard root. A packet matching a child region is only forwarded through repeaters that know the transport key for that region. Parent regions don't automatically unlock children — each region has its own transport key.

Example hierarchy:
```
* (wildcard — global)
└── California (regional)
    ├── NorCal
    └── SoCal
        └── Interlaken (local)
```

Each node in the tree gets its own transport key. A repeater configured with only the "Interlaken" key will forward Interlaken-scoped floods but not California-scoped floods.

### 8.9 Source Files for Regions

| File | Contents |
|------|---------|
| `MeshCore/src/helpers/RegionMap.h` | `RegionEntry` struct, `RegionMap` class, `REGION_DENY_FLOOD` |
| `MeshCore/src/helpers/RegionMap.cpp` | `findMatch()`, `getTransportKeysFor()`, key derivation logic |
| `MeshCore/src/helpers/TransportKeyStore.h` | `TransportKey` struct, `calcTransportCode()` |
| `MeshCore/examples/simple_repeater/MyMesh.cpp` | `filterRecvFloodPacket()`, `allowPacketForward()`, `sendFloodReply()` |

---

## 9. Text Message Format (Companion → Repeater CLI)

`CMD_SEND_TXT_MSG` frame (app → companion):
```
[0]       = 2 (CMD_SEND_TXT_MSG)
[1]       = txt_type byte: bits[7:2] = flags/attempt, bits[1:0] = type
            • type 0 = TXT_TYPE_PLAIN (requires ACK)
            • type 1 = TXT_TYPE_CLI_DATA (no ACK expected)
[2]       = attempt number (0=first, 3=force flood)
[3..6]    = timestamp (uint32 LE)
[7..12]   = pub_key_prefix (6 bytes, first 6 bytes of destination pub_key)
[13+]     = text content
```

CLI data type (`TXT_TYPE_CLI_DATA`): used for repeater CLI commands. Response comes as another `TXT_TYPE_CLI_DATA` message from the repeater, then a `PUSH_CODE_SEND_CONFIRMED` (no ACK).

---

## 10. Group Text Format

`PAYLOAD_TYPE_GRP_TXT` packet payload:
```
[0]         channel_hash (1 byte)
[1..2]      MAC (2 bytes)
[3+]        encrypted data:
              [0..3]  timestamp (uint32 LE)
              [4]     txt_type
              [5+]    text as "sender: message"
```
Sender identity is NOT in the payload. Use `PUSH_CODE_LOG_RX_DATA` path bytes (origin hash) to identify sender.

---

## 11. ADV_TYPE Constants

| Value | Meaning |
|-------|---------|
| 1 | `ADV_TYPE_CHAT` — regular chat node |
| 2 | `ADV_TYPE_REPEATER` — repeater node |
| 3 | `ADV_TYPE_ROOM` — room server |
| 4 | `ADV_TYPE_SENSOR` — sensor node |

---

## 12. Timeout Calculations (Companion)

```
base_millis = 500
flood_timeout = base_millis × airtime × FLOOD_SEND_TIMEOUT_FACTOR (16.0)
direct_timeout = base_millis + (hopCount × (airtime × DIRECT_SEND_PERHOP_FACTOR (6.0) + DIRECT_SEND_PERHOP_EXTRA_MILLIS (250)))
```

---

## 13. App-Side Path Resolution (`resolvePathSelection`)

Priority order:
1. If `contact.pathOverride != null`:
   - `< 0` → force flood
   - `>= 0` → use `pathOverrideBytes` with `pathOverride` hops (direct)
2. If `forceFlood` or `contact.pathLength < 0` → flood
3. If `autoSelection` provided → use auto-selected path
4. Fall through to `contact.path` / `contact.pathLength` from device

**Important:** After a flood login, the device sends `PUSH_CODE_PATH_UPDATED` (0x81) → app calls `CMD_GET_CONTACT_BY_KEY` → updates `contact.pathLength` and `contact.path`. Subsequent sends use this device path automatically (since `pathOverride` is null). This is what makes CLI commands go direct after the first flood login.

---

## 14. Key Source Files (Reference Only — Do Not Modify)

| File | What to find there |
|------|-------------|
| `MeshCore/src/Packet.h` | All ROUTE_TYPE_*, PAYLOAD_TYPE_* constants; path_len encoding |
| `MeshCore/src/Mesh.h` | All createXxx(), sendXxx() method signatures |
| `MeshCore/src/Mesh.cpp` | onRecvPacket() — full routing dispatch logic |
| `MeshCore/src/helpers/ContactInfo.h` | ContactInfo struct, OUT_PATH_UNKNOWN |
| `MeshCore/src/helpers/BaseChatMesh.cpp` | sendLogin(), sendTxtMsg(), onPeerDataRecv(), onContactPathRecv(), handleReturnPathRetry() |
| `MeshCore/src/helpers/RegionMap.h/.cpp` | RegionEntry, RegionMap, transport key derivation |
| `MeshCore/src/helpers/TransportKeyStore.h` | TransportKey, calcTransportCode() |
| `MeshCore/examples/companion_radio/MyMesh.cpp` | All CMD_* / RESP_* / PUSH_* constants; writeContactRespFrame(); sendFloodScoped() with scope keys |
| `MeshCore/examples/simple_repeater/MyMesh.cpp` | onAnonDataRecv(), filterRecvFloodPacket(), allowPacketForward(), sendFloodReply() |

---

## 15. V3 Message Frame Formats (CMD_SYNC_NEXT_MESSAGE replies)

The app sends `CMD_SYNC_NEXT_MESSAGE` (10) repeatedly until `RESP_CODE_NO_MORE_MESSAGES` (10). The companion replies with the queued message frames. Protocol v≥3 frames have a 4-byte header prefix.

### `RESP_CODE_CONTACT_MSG_RECV_V3` (code 16) — contact text/CLI message
```
[0]      = 16 (RESP_CODE_CONTACT_MSG_RECV_V3)
[1]      = SNR × 4 (int8, e.g. -12 dB → -48)
[2]      = reserved1 (0)
[3]      = reserved2 (0)
[4..9]   = sender pub_key prefix (6 bytes, first 6 of their 32-byte pub_key)
[10]     = path_len byte  ← 0xFF if packet was Direct (no path info)
                          ← encoded path_len byte if flood (upper 2 bits = hashSize-1, lower 6 = hop count)
[11]     = txt_type:
            0 = TXT_TYPE_PLAIN (normal chat)
            1 = TXT_TYPE_CLI_DATA (CLI response from repeater)
            2 = TXT_TYPE_SIGNED_PLAIN (signed message)
[12..15] = sender_timestamp (uint32 LE, sender's RTC)
[16+]    = text (null-not-terminated, runs to end of frame)
           • For TXT_TYPE_SIGNED_PLAIN: [16..19] = extra 4-byte sender prefix, [20+] = text
```

### `RESP_CODE_CHANNEL_MSG_RECV_V3` (code 17) — group channel message
```
[0]      = 17 (RESP_CODE_CHANNEL_MSG_RECV_V3)
[1]      = SNR × 4 (int8)
[2]      = reserved1 (0)
[3]      = reserved2 (0)
[4]      = channel_idx (0-based index into the companion's channel list)
[5]      = path_len byte  ← same encoding as above; 0xFF if Direct
[6]      = txt_type (always TXT_TYPE_PLAIN for channel messages)
[7..10]  = timestamp (uint32 LE)
[11+]    = text as "sender: message" (the firmware pre-formats it this way)
```

**Note:** The PUSH_CODE_MSG_WAITING (0x83) is a one-byte tickle frame. After receiving it, the app polls with `CMD_SYNC_NEXT_MESSAGE` to get the actual queued message.

**Note (V1 frames):** `RESP_CODE_CONTACT_MSG_RECV` (7) and `RESP_CODE_CHANNEL_MSG_RECV` (8) have the same layout but WITHOUT the 4-byte SNR+reserved header prefix. The byte offsets shift back by 3.

---

## 16. PUSH_CODE_LOG_RX_DATA Frame (0x88)

This push is sent for every received LoRa packet (even before decoding). It includes the raw wire bytes which contain the path hashes.

```
[0]      = 0x88 (PUSH_CODE_LOG_RX_DATA)
[1]      = SNR × 4 (int8)
[2]      = RSSI (int8, in dBm)
[3+]     = raw packet bytes (the wire-format packet, see section 1)
```

**The `raw` bytes contain the path field** which is the list of intermediate node hashes in order of traversal. The **first** path hash byte is the hash of the originating node. For group messages where sender identity is not in the payload, comparing this first hash byte against known contact pub_key prefixes can identify the sender.

Wire format of the raw bytes (section 1):
- Byte 0 = `header` (route type + payload type)
- Byte 1 = `path_len` byte (hashSize + hopCount)
- Next N bytes = path hashes (each PATH_HASH_SIZE bytes, flooded packets accumulate these)
- Remaining = encrypted payload

---

## 17. Companion sendFloodScoped — Default Scope Key

In the companion radio (unlike `BaseChatMesh`), `sendFloodScoped` IS implemented and uses a configurable default scope key:

```cpp
void MyMesh::sendFloodScoped(const ContactInfo& recipient, Packet* pkt, ...) {
  if (send_unscoped) {
    sendFlood(pkt, ...);   // app explicitly requested unscoped
  } else {
    TransportKey default_scope;
    memcpy(&default_scope.key, _prefs.default_scope_key, 16);
    auto scope = send_scope.isNull() ? &default_scope : &send_scope;
    sendFloodScoped(*scope, pkt, delay);   // uses ROUTE_TYPE_TRANSPORT_FLOOD
  }
}
```

The companion maintains:
- `_prefs.default_scope_key` — a 16-byte key, set via `CMD_SET_DEFAULT_FLOOD_SCOPE` (63)
- `send_scope` — a per-send override key (cleared after each send)
- `send_unscoped` — if true, forces unscoped regardless

**Practical implication:** If the user has set a default scope key on their companion radio, ALL their messages (including login attempts) go out scoped to that key. The repeater must have a matching region for that key, or the packets won't be forwarded. This can cause "mysterious" failures where flood packets are dropped by repeaters even when `REGION_DENY_FLOOD` is not set on the wildcard — the transport code simply doesn't match any known region.

The app can query the current default scope via `CMD_GET_DEFAULT_FLOOD_SCOPE` (64).

---

## 18. Known Bugs and Gotchas (Do Not Re-introduce)

These are issues that have been previously debugged and fixed. Check here before making related changes.

### Bug: 0-hop path tap silently did nothing
**File:** `lib/widgets/path_management_dialog.dart`  
**Symptom:** Tapping a "0 hops" entry in Path Management showed "path details not available" snackbar and left path as Flood.  
**Root cause:** Guard `if (path.pathBytes.isEmpty)` blocked 0-hop paths because they have empty path bytes (no intermediate nodes).  
**Fix:** Changed guard to `if (path.hopCount > 0 && path.pathBytes.isEmpty)` — only reject multi-hop records with missing bytes.

### Bug: Forced-flood regression in login dialog
**File:** `lib/widgets/repeater_login_dialog.dart`  
**Symptom:** Even after setting a direct path, login always flooded.  
**Root cause:** Login dialog was overriding `setContactPath` to force `pathLen: -1` (flood) before every login attempt.  
**Fix:** Reverted to `preparePathForContactSend(repeater)` which correctly reads the contact's saved path override and pushes it to the companion before login.

### Bug: `lastModified` compile error
**File:** `lib/connector/meshcore_connector.dart`  
**Symptom:** Build error: `The getter 'lastModified' isn't defined for the type 'Contact'`  
**Root cause:** Contact model uses `lastSeen` not `lastModified`.  
**Fix:** Replace `contact.lastModified` with `contact.lastSeen` in `buildUpdateContactPathFrame` calls.

### Gotcha: Direct login fails with many repeaters
**Symptom:** Direct mode login times out; flood mode works.  
**Root cause:** When the login packet arrives as DIRECT at the repeater, `recv_pkt_region = NULL`. The repeater calls `sendFloodReply()` → falls back to global flood → blocked by wildcard `REGION_DENY_FLOOD`.  
**Workaround:** Use `preparePathForContactSend` (which uses flood if no direct path is stored) for the initial login. After flood login succeeds, the companion stores the direct path and subsequent CLI commands go direct.  
**Do NOT:** Force the login to use direct mode via `setContactPath` before login — it will time out.

### Gotcha: setPathOverride with pathLen=0 and empty pathBytes
When setting a 0-hop override, `pathBytes` is an empty `Uint8List` (not null). The condition `pathBytes != null` is satisfied, so `setContactPath` IS called. However, the in-memory update logs `bytesLen: null` because `copyWith` stores null for empty lists — this is cosmetic, the device receives the correct frame.

### Gotcha: Companion sendFloodScoped vs BaseChatMesh sendFloodScoped
`BaseChatMesh::sendFloodScoped` is a plain `sendFlood()` (no scoping). The companion radio overrides this with a real scoped implementation using `default_scope_key`. If messages mysteriously fail to reach repeaters, check whether the companion has a scope key set that doesn't match any region on the repeaters.

---

## 19. App Architecture Overview

Key service classes and their responsibilities:

| Class | File | Responsibility |
|-------|------|---------------|
| `MeshCoreConnector` | `lib/connector/meshcore_connector.dart` | BLE/USB transport, frame encode/decode, contact state, all protocol commands |
| `PathHistoryService` | `lib/services/path_history_service.dart` | Tracks per-contact path ACK history, flood stats, recent paths |
| `RetryService` | `lib/services/retry_service.dart` | Automatic message retry with path rotation |
| `AppSettingsService` | `lib/services/app_settings_service.dart` | Persisted user preferences |
| `ContactStore` | `lib/services/contact_store.dart` | Persistent contact storage |
| `PathSelectionDialog` | `lib/widgets/path_selection_dialog.dart` | UI for manually specifying a path |
| `PathManagementDialog` | `lib/widgets/path_management_dialog.dart` | UI for choosing from recent ACK paths |
| `RepeaterLoginDialog` | `lib/widgets/repeater_login_dialog.dart` | Login handshake, retry loop, timeout logic |

### Key connector methods for path management:
- `preparePathForContactSend(contact)` → pushes the right path to companion before sending; returns `PathSelection`
- `setContactPath(contact, pathBytes, hopCount)` → sends `CMD_ADD_UPDATE_CONTACT` with path bytes
- `clearContactPath(contact)` → sets `out_path_len = OUT_PATH_UNKNOWN` on companion
- `setPathOverride(contact, pathLen, pathBytes)` → stores app-level override, optionally syncs to device
- `resolvePathSelection(contact)` → returns the current effective path without pushing to device

### Contact model fields relevant to routing:
| Field | Meaning |
|-------|---------|
| `contact.pathLength` | Device-reported path length (from last `CMD_GET_CONTACT_BY_KEY`) |
| `contact.path` | Device-reported path bytes |
| `contact.pathOverride` | App-level override: null=auto, -1=force flood, ≥0=direct with N hops |
| `contact.pathOverrideBytes` | Path bytes for the override |
| `contact.pathHashSize` | Hash size in bytes (1 or 2) — comes from the contact's `out_path_len` upper bits |

### TXT_TYPE constants (bits[1:0] of the txt_type byte):
| Value | Constant | Meaning |
|-------|----------|---------|
| 0 | `TXT_TYPE_PLAIN` | Normal chat message (ACK required) |
| 1 | `TXT_TYPE_CLI_DATA` | CLI command/response (no ACK) |
| 2 | `TXT_TYPE_SIGNED_PLAIN` | Signed message (includes sender prefix) |
