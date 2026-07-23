# Phase 3d Cut Plan — Database as the Single Source of Truth

**Principle (owner-directed):** a received message is inserted into the database;
the database notifies; the UI updates. Nothing else holds message state. Data can
only be lost by an explicit overwrite or delete. JSON remains only for
export/import/interchange.

**What this kills:** the in-memory bucket layer — `_channelMessages`
(Map<slotIndex, List>) and `_conversations` (Map<pubkey, List>) — a second,
unmanaged database with no schema, no ordering, no constraints, mutated from
~30 sites. Every display bug of 21–23 July (vanishing, reverting, misordering,
self-unread, stale chats-list order) traces to it.

---

## 1. New foundations (schema v3, additive)

| Addition | Purpose |
|---|---|
| `packetHash` column on both message tables (promoted from payload, indexed) | Repeat/echo dedup by SQL lookup instead of in-memory scan |
| `ChannelReadMarks(nodeScope, idKey, lastReadMs)` | Unread = watched `COUNT(*) WHERE ts > lastRead AND NOT own` |
| `ContactReadMarks(nodeScope, contactKey, lastReadMs)` | Same for DMs |
| Store watch API: `watchChannelMessages(idKey, {limit})`, `watchConversation(contactKey, {limit})`, `watchChannelSummaries()`, `watchUnreadCounts()` | Drift `.watch()` — the Room-style notification hook |
| Ingest newness: `INSERT OR IGNORE` + rows-affected | Atomic "is this new?" — replaces `_findChannelRepeatIndex` memory scan; drives unread + notifications exactly once |

## 2. Channel-side cut list (meshcore_connector.dart)

| Site (approx line) | Today | Verdict |
|---|---|---|
| 186 `_channelMessages` declaration | The shadow DB | **DELETE** |
| 661–688 `getChannelMessages` + fallback chain (live/prev-cache/index) | Display resolution via slots | **DELETE** — display is keyed by idKey via watched query; slots matter only at ingest |
| 742 `_repersistIfDirty`, 700 `_unpersistedBuckets` | Persist-retry bookkeeping | **DELETE** — ingest writes the row immediately |
| 750 `_persistChannelMessages` | Whole-bucket upsert | **DELETE** — replaced by single-row upsert at ingest |
| 792 iterate-all-buckets persist | Bulk safety net | **DELETE** |
| 907–942 `_loadChannelMessages` (window + merge) | DB→memory load, unsorted merge (**source of the misorder screenshots**) | **DELETE** |
| 944–967 `loadOlderMessages` | Manual pagination splice | **REPLACE** — raise the watched query's LIMIT |
| 3308 reaction path (send) | Mutates bucket, persists list | **REPLACE** — find target row by hash (SQL), update row |
| 3371 / 3995 status updates (ack, timeout, retry) | Mutate list entry, persist list | **REPLACE** — single-row upsert by messageId |
| 4095 / 4115 `setChannel`/`deleteChannel` bucket resets | Bucket hygiene | **DELETE** (store purge on channel delete stays — explicit user intent) |
| 4381 node-switch wipe of buckets | Cross-node hygiene | **DELETE** — queries are nodeScope-bound; switching radios switches the query, nothing to wipe |
| 5660 flush-pending iteration, 5775–5790 adopt/flush | Buffer for unverified slots, then file | **KEEP protocol, REPLACE filing** — buffer stays (slot→identity unknown until CHANNEL_INFO); flush = upsert rows |
| 6376+ `_addChannelMessage` (sanitizer, reply-link, repeat-merge, sorted insert) | The 140-line ingest-into-memory | **REWRITE as ~30-line ingest**: resolve identity → sanitize stamp → `INSERT OR IGNORE` (new?) / row-update (repeat) → read-mark/notify if new && !fromSelf |
| 7542 `clearMessagesForChannel` | Bucket clear + store clear | **KEEP store clear, DELETE bucket line** |

## 3. DM-side cut list (13 `_conversations` sites)

Identical pattern: map + `_loadedConversationKeys` **DELETE**; `getMessages` →
`watchConversation`; receive/status/reaction → row upserts; `deleteMessage` /
`clearMessagesForContact` already row-targeted (Phase 3c) — unchanged.
Bonus: `_conversations.clear()` on disconnect (the DM-flicker) becomes moot.

## 4. Consumers

| Consumer | Today | Becomes |
|---|---|---|
| `channel_chat_screen` | reads `getChannelMessages` on notifyListeners | StreamBuilder on `watchChannelMessages(idKey, limit)`; pagination = limit bump; reply-lookup = query |
| `chats_screen` | sorts by `messages.last.timestamp` (**finding #4 bug**) | watched summary query: `MAX(timestamp)`, last text, unread count per idKey — SQL ordering |
| `chat_screen` (DM) | reads `getMessages` | StreamBuilder on `watchConversation` |
| `new_chat_screen`, `map_screen` | one-shot reads | one-shot store loads (unchanged shape) |
| Unread (Channel.unreadCount + unread_store) | mutable counters, prefs JSON | **DELETE** — watched COUNT vs read-marks; `markChannelRead` = upsert read-mark |
| Notifications | fired from memory-dedup verdict | fired at ingest on DB-confirmed-new && !fromSelf |

## 5. Verdicts on recent patches (the git-log audit)

| Commit | Verdict |
|---|---|
| Identity keying, buffering, handshake reorder, dup guards, health check, pending-force-resync, discovery 30s | **SURVIVE** — protocol layer, untouched by 3d |
| a350851 upsert-only stores (3c) | **SURVIVES** — is the foundation |
| 2cebaa2 display continuity | Channel-LIST half **survives** (the channel list stays connector state); getChannelMessages fallback half **deleted with the layer** |
| 6aa08ce CME snapshot in `loadAllChannelMessages` | Function itself **deleted** (no bulk load into memory) |
| de1f44a sorted inserts | **Deleted with the layer** (SQL ORDER BY replaces it); self-echo rule survives as the ingest predicate |

## 6. Sequencing & validation

1. Schema v3 + store watch API + unit tests
2. Connector ingest rewrite (channels), consumers switched, bucket layer deleted
3. Bench harness helpers moved to the same store APIs; full 22-scenario suite + D10 + 4h monitor
4. Same cut for DMs; suite re-run
5. Phase 3b: contact/discovery caches, cached channels → tables
6. JSON slop purge: stores keep only one-time legacy import; PrefsManager = settings only

**Rule for the whole phase: no compatibility shims.** Call sites move to the new
API; the old API is deleted in the same commit.
