# Weighted Graph Path Determination Module for DMs

Status: **implementation underway** — design complete; Phase 0 (the
`packages/path_graph` module) and most of Phase 1 (the `test/path_lab`
harness) are built and running against real hardware on branch
`feat/path-graph-package` (draft PR #71, held unmerged through the
verification campaign). See `docs/path-graph-implementation.md` for the
phase plan and "Implementation status" below for what exists and what
the bench has already corrected.
Last updated: 2026-08-05.

## In plain language

MeshCore radios can't talk directly over long distances — messages hop
from repeater to repeater, like a bucket brigade. To send someone a
direct message, your radio needs to know a working chain of repeaters
between you and them. Today that knowledge is poor: the radio often
guesses wrong or gives up and "floods" — shouting the message through
every repeater in the region, which works but is slow and noisy for
everyone.

This module fixes that by *listening*. Every message that travels the
mesh carries a stamp of which repeaters it passed through — so just by
hearing normal traffic (channel chatter, repeater announcements, other
people's messages), the app can quietly build a living map: which
repeaters can hear each other, how strong those links are, which
repeaters can hear *you* right now, and which ones can hear each of your
contacts. Repeaters even announce themselves every day or two, so the
map refreshes itself.

When you send a DM, the module picks the best route from that map
automatically. If the route fails, it retries smartly — a different
route, then a free "who's around me?" check, then the flood as a last
resort — and it learns from every attempt, success or failure. Drive
across town and it notices your nearest repeater changed. Move to a new
region and it starts learning from scratch (or loads a community-made
starter map). All the user ever sees is a path choice on each
conversation — **Auto** (the default, this module), Direct, Flood, or
Manual — and messages that simply find their way.

---

A self-contained module that learns the local mesh topology from observed
paths and a seeded region graph, and answers one question: *given who hears
me and who hears my contact, what path bytes should this DM use?*

## Decision log

* **2026-08-03** — Hash-native identity, no pubkey resolution (§ hard
  problem 2). Width: **2-byte** (4-byte far future). Module self-contained
  with its own DB. Export file stays lossless (full pubkeys); app collapses
  at import.
* **2026-08-04** — **Discover in the toolset**: zero-hop CONTROL, never
  retransmitted (`Mesh.cpp` ~69) → negligible network demand. Return
  contract: **bidirectional or flood — no send-only tier**. **ACK role:
  delivery signal + ingress harvesting only** — no per-edge credit from
  bare confirmations. Ingress lists: own table in the module DB (contact
  store is rebuilt on radio sync). No separate repeater DB — `graph_nodes`
  is it. Phone GPS: yes (`geolocator`; Android permission already declared,
  iOS needs `NSLocationWhenInUseUsageDescription`); radio node position is
  the fallback. β default **0.95**, user-visible setting (bench runs 0.99).
* **2026-08-05** — **Last-hop prior**: "I hear X" admitted as a weighted
  guess in a separate `inferred` evidence tier — candidate selection only,
  never graph evidence. **Fresh evidence dominance**: ladder-triggered
  probe results supersede tallies (slash ~×0.2, reseed from Discover
  SNR / flood `path[0]`). **Mobility**: egress decays in minutes,
  position-tagged, Discover-before-send when stale-or-moved. Channel
  attribution policy (no pubkey in `GRP_TXT`): pubkey-confirmed > unique
  name match > skip.
* **2026-08-05 (review)** — three independent adversarial reviews;
  corrections adopted: **p defined** via attempt-counted Beta estimator
  (passive sightings are traffic, not probability); **edge trust tiers**
  (unauthenticated path bytes); **epoch-limited, floored slash**; **mobile
  ladder collapse** (concurrent Discover, skip alt-path step);
  **scoped-flood caveat**; **path discovery adopted**
  (`CMD_SEND_PATH_DISCOVERY_REQ`/0x8D — the remote probe that already
  exists); **uplink SNR** from discover response byte 1 (via 0x8E);
  **imported bidirectional priors clear the threshold**; **infrastructure
  decay floor**; Discover response rate-limit (4/2 min) acknowledged;
  data-source reality: full paths are live-RX-log-only.
* **2026-08-05 (post-review override)** — **passive channel paths are
  first-class graph builders**, all multi-heard variants included
  (union-of-edges-per-message dedup); passive evidence **counts toward
  the bidirectional threshold** at reduced confidence; edge trust is
  rate-capping against fabrication, never exclusion of organic traffic.
  **No-import bootstrap** is a supported path (listen → Discover → flood
  handshake); observed graph data is one continuous store — region tags
  govern imported rows only, road trips need no region ceremony.
  **Fabrication defense dropped for v1** — near-zero real-world risk on a
  cooperative mesh; only parse hygiene against accidental garbage remains.
* **2026-08-05 (isolation)** — **push-in, never read-out**: the module
  reads no app store; `known_contacts` mirror fed by `ingestContact` with
  a full PK→name refresh on companion connect (PKs stable, names mutate);
  `findPath` always by PK (no PK = can't DM anyway — names matter only
  for observation-side attribution); `setRadioIdentity` push at
  device-info. **Offline observation loss accepted**: usually connected;
  unconnected paths are simply lost, no backlog recovery.
* **2026-08-05 (final open questions)** — **all five resolved**: traces
  manual-only from the map tab (module visualized there; trace results
  feed back as proven evidence); **findPath runs on every DM send** (the
  firmware's path data is poor; app specifies the path per-send — module
  is the path authority); **zero-hop first-class** (direct receptions →
  "direct" pseudo-candidate, empty path wins while fresh);
  **`path_history_service` removed entirely** — all in-app path
  generation goes; the module is the sole source of truth (salvage: hook
  points as migration map, Laplace estimator validated, tripTimeMs into
  `reportSendResult`, map path-drawing reused, per-contact flood stats;
  `timeout_prediction_service` + `DeliveryObservation` stay — timeout
  estimation, not path generation); uplink SNR confirmed in Discover
  response byte 1. Design phase complete — no open questions remain.
* **2026-08-05 (final)** — **2-byte-only ingest**: 1-byte paths never
  enter the module (up-conversion is corrupting guesswork; drops are
  counted). Output for 1-byte targets = truncate each hop to its first
  byte (lossless — the 1-byte hash is the 2-byte hash's first byte).
  **Removal methodology**: rename/delete `PathHistoryService` and lean on
  the compiler to enumerate every buried path-selection site.
* **2026-08-05 (consistency pass)** — full-document conflict check.
  Fixed: `PathResult.direct()` added to the return contract and
  `findPath` signature (zero-hop was a decided exception the contract
  never stated); delivery-evidence rule precisely scoped (outcomes DO
  update forward-edge attempt counts — only the ACK's unknowable return
  route contributes nothing); Discover self-budgeted to ~1 per 2-min
  epoch with proactive-vs-failure-episode semantics split (only
  failure-episode Discovers slash); stale 0x8D/ACK-round-trip references
  corrected; `graph_nodes` PK is hashBytes alone (region demoted to
  metadata so observed+imported nodes never fragment); 3-byte ingest
  truncates losslessly to 2-byte buckets; Requirements bullets annotated
  where superseded.
* **2026-08-05 (UI model)** — send-path choice is exactly four modes for
  DMs and repeater/room logins: **Auto (default, module) | Direct |
  Flood | Manual**. The choice is the complete setting — module supplies
  paths only in Auto and never writes the mode, dissolving the
  override-provenance problem; non-Auto sends still feed observations.
  **ONE shared dialog** replaces the current three implementations
  spread across ten call sites.
* **2026-08-05 (storage & import)** — separate Drift file
  (`path_graph.db`, own class/schema version); memory-resident working
  set, debounced transactional flush. **Import layering**: prior layer
  (replaceable per region) vs local evidence layer (never touched by
  imports); s/n store local evidence only, prior combined at read — so
  re-imports are idempotent and no import ever deletes learned data.
* **2026-08-05 (exchange format)** — the import/export file is
  **node-link JSON** (D3/NetworkX convention: `nodes`/`links`,
  `source`/`target`) with a `format: meshtrax-graph-v1` profile marker
  and graph-level metadata; chosen over JGF/GraphSON for tooling reach.
  Unknown fields are preserved by convention → our extensions never
  break consumers.
* **2026-08-05 (edge quality)** — weights combine **frequency** (traffic
  EWMA — scales prior confidence + tie-breaks) and **signal strength**
  (Corescope `avg_snr` on the import layer; trace per-hop SNR as local
  `measuredSnr` — the only middle-hop SNR source) into the prior `q₀`;
  attempt-counted `s/n` overrides both. Frequency and SNR propose;
  delivery disposes.
* **2026-08-05 (adverts)** — repeater flood adverts confirmed as passive
  graph maintenance (firmware-verified): default 47 h interval, standard
  flood path accumulation (8-hop advert cap), Ed25519-signed full-pubkey
  payload → `ingestNode` at top attribution even when the path is 1-byte
  and dropped. Advert parsing is the priority `_parseRawPacket`
  extension. Cleartext path bytes on undecryptable packets harvest edges
  at `anonymous` grade.
* **2026-08-05 (implementation)** — Phase 0 package + Phase 1 harness
  **built** (branch `feat/path-graph-package`, draft PR #71 held
  unmerged; 50 tests). Bench-driven corrections: egress half-life
  45 min with proven-tier 4× slower decay; Discover stores measured dB
  both directions (uplink = ctl payload byte 1, downlink = frame byte 1;
  30 s response window) and first-hop cost blends measured quality
  70/tally 30; trace needs random uint32 tags (packet dedup) and has no
  firmware rate limiter; `observeTrace` + `findPathToRepeater` +
  `findAlternatives` + `updateConfig` added to the API; `lastHopHeard`
  flag on `observePath`. Separate app fix PR #72 (USB picker suspends
  BLE auto-reconnect).
* **2026-08-05 (position policy)** — position is **optional, opt-in, and
  three-sourced**: Off/manual (default — zero permissions, home position
  by map tap), radio position (companion GPS/user-set node position when
  present — not guaranteed), phone GPS (explicit opt-in, while-in-use,
  foreground-only). App-store risk managed by the no-permission default;
  the module degrades gracefully to time-only staleness without any
  position source.

## Requirements

*(Rewritten 2026-08-05 to reflect all decisions; original bullets from
2026-08-03 are traceable through the decision log.)*

* **Learn the mesh map by listening.** Every packet the radio hears that
  carries a route stamp updates a weighted map of repeater-to-repeater
  links — channel chatter, other people's messages, and especially the
  repeater announcements that arrive every day or two (those also refresh
  each repeater's name and position). Each observation counts in the
  direction it actually proves, and every distinct route of a
  multiply-heard message counts. Only 2-byte-or-wider route stamps are
  used; 1-byte ones are ignored (but tallied, so we notice if we're
  ignoring a lot).
* **Know who hears me, and who hears them.** Keep a weighted, fresh-first
  list of the repeaters that can hear this radio (fast-changing —
  possibly driving), and one per contact of the repeaters that hear them
  (changing at their pace). Track how trustworthy each entry is: proven
  (a response, a delivery, an echo) versus a good guess from received
  traffic.
* **Be a true black box.** Own database; never reads any app storage.
  Everything it knows arrives through explicit inputs: observed routes,
  Discover results, send outcomes (with trip time), repeater
  announcements, contact name refreshes on connect, an optional region
  import, and the connected radio's identity. One question answered:
  *best path to this contact?* — by public key only.
* **Answer with one of three things**: nothing-in-between (zero-hop
  direct, when we've heard the contact ourselves recently); a repeater
  path — only ever over links proven to work in *both* directions; or
  flood, the honest fallback when no proven route exists.
* **Be the only path authority, on every send.** DMs and repeater/room
  logins get their path from this module every time (the firmware's own
  path memory is unreliable). All older in-app path machinery is removed,
  not wrapped.
* **Weigh links by use, signal, and results.** How often a link is seen
  in use, how strong it measures (imported survey data and manual
  traces), and — overriding both — whether our own messages actually get
  through on it.
* **Fail smart, learn from everything.** On failure: try an alternative
  route, then a free local "who's around me?" check, then flood — which
  delivers *and* re-teaches the map in one shot. Fresh probe results
  outrank stale history (within sane limits), and every outcome — even on
  user-forced paths — feeds the map.
* **Support a community starter map.** A utility generates a
  standard-format JSON graph (node-link, readable by common tools) from
  Corescope and publishes it on GitHub. Importing one layers it *under*
  local knowledge as a head start — an import never deletes anything the
  radio learned itself, and regions can be added, refreshed, or removed
  freely.
* **Work on the move.** Built for DMs while driving: the who-hears-me
  list ages in minutes, refreshes cheaply, and can be position-aware —
  but position is strictly optional (off/manual by default, radio's own
  position, or phone GPS only by explicit opt-in) and everything degrades
  gracefully without it.
* **One simple choice for the user.** A single shared dialog everywhere a
  path matters, with four modes: **Auto** (this module — the default),
  Direct, Flood, or Manual entry. The map tab can draw the chosen route
  and trace it on demand; trace results feed back into the map. User
  controls exist to clear learned data and remove imported regions.

## The three hard problems

### 1. Direction semantics — be ruthless about what each observation proves

A received path proves exactly one direction per hop pair. If a channel
message arrives with path `[A, B, C]`, that proves: sender→A (A hears the
sender), A→B, B→C, and C→me (I hear C). It proves *nothing* about me→C or
B→A. Subtle consequence for the contact ingress lists:

* **Their "starting repeater" list**: `path[0]` of anything they sent. Solid.
* **My "heard by" list**: a received message's last hop only proves *I hear
  C*, not *C hears me*. Evidence that a repeater hears **me** comes only
  from: my own message echoed back (repeat-echo — `path[0]` of the echo is a
  repeater that heard me), a *delivered* direct send (delivery proves every
  forward hop, including that hop 1 heard me — the ACK's own route proves
  nothing, see ACK role), a trace round-trip, or a Discover response. The
  existing repeat-echo detection is exactly the hook for this.

So the module needs two directed observation types: *ingress* (who hears
them) for contacts, *egress-capable* (who hears me) for self. Mixing "I hear
X" into "X hears me" silently corrupts the graph with plausible-but-unproven
edges — DMs would die with confident one-way paths labeled bidirectional.
Make the two observation directions separate types in the API so call sites
can't confuse them. **This is the riskiest part of the whole design.**

**The last-hop prior (decided 2026-08-05)**: "I hear X" *is* allowed as a
weighted guess — RF links are roughly reciprocal (path loss and antenna gain
are symmetric; the repeater's quieter noise floor usually makes the uplink
the easier direction), so the last hop of received paths, weighted by
frequency × recency (× RX SNR when available), is a useful prior for "X can
hear me." Discipline: it lives in a separate evidence tier
(`inferred` vs `proven`), is used **only** to weight egress candidates fed
to `findPath`, and never creates a graph edge or counts toward the
bidirectional threshold. The ladder validates it for free: a successful
direct send through an inferred first hop proves that repeater heard us →
upgrade to proven; a failure decays it and Discover re-checks it.

*Why the tally survives asymmetric hubs*: a high-site repeater (e.g. 1000)
is heard directly now and then but can't hear us back. Its own statistics
betray it — received paths mostly end `…, 1000, A277` (votes for **A277**,
plus a `1000 → A277` graph edge each time) and only rarely `…, 1000`.
Counting **final position only** promotes the doorstep repeater and starves
the hub automatically. Two reinforcing signals: a repeater appearing far
more often *penultimate* than *final* shows the hub signature → explicit
demotion factor; and direct receptions from a distant hub are usually
weak-SNR while the doorstep is strong. Bonus: the same observations that
rank A277 as egress also teach the graph the outbound route it anchors
(A277 → 1000 → onward).

### 2. Hash identity — DECIDED: hash-native, no pubkey resolution

Region-wide the 1-byte hash space is so heavily overlapped that resolving
hashes to full pubkeys is almost useless, so the module doesn't try. The
graph is keyed by the hash bytes themselves — which is exactly what the wire
routes on: firmware repeats a packet when the next path slot matches its own
hash, and a send path is literally a list of hash bytes. A graph node is
"whatever repeats as this hash around here," which is precisely the mesh's
own view. Consequences:

* No resolution step, no shadow edges, no geographic/adjacency
  disambiguation machinery. Observations apply directly, and `findPath`
  output is already in wire format.
* Distinct repeaters sharing a hash merge into one node. Locally that's
  uncommon and mirrors real routing behavior anyway — both would repeat the
  packet.
* **Width — DECIDED: 2-byte** (possibly 4-byte in the far future). 65,536
  buckets; overlap essentially disappears — a 2-byte hash derived from a
  Corescope pubkey is near-unique. MeshTrax already supports variable widths
  end to end: the wire `path_len` byte encodes hash size in bits [7:6] per
  packet (`docs/meshcore-protocol.md`), device info byte 81 (fw v10+) sets
  `connector.pathHashByteWidth`, and every stored record
  (`Contact.pathHashSize`, `ChannelMessage.pathHashSize`) carries its width.
  Note for the 4-byte future: the path_len width field can encode up to
  4 bytes (size bits value 3), but the device-info parser currently clamps
  mode to 0–2 (`meshcore_connector.dart`, byte 81) — a small firmware + app
  bump, and the graph re-collapses from stored pubkeys.
* Path budget at 2-byte width: 64-byte path field ÷ 2 = 32 hops max.
  A non-issue — practical routes are far shorter.
* **Ingest is 2-byte-or-wider ONLY (decided 2026-08-05)**: 1-byte paths
  are never fed to the module — up-converting a 1-byte hop to a 2-byte
  bucket is guesswork that would corrupt the data. The module rejects
  stride < 2 at the door (`observePath` enforces it); a counter tracks
  how much 1-byte traffic is being dropped so we know if the local mesh
  regresses. **Output down-conversion is free**: a 2-byte hash is the
  pubkey's first two bytes, so its first byte IS the 1-byte hash — when
  the user sends to a 1-byte target, the app truncates each hop of the
  returned path to its first byte. Lossless in that direction, always
  correct.
* At 2-byte width the geo radius on Corescope import is just
  belt-and-suspenders (at 1-byte it would be essential — collapsing a whole
  region into 256 buckets would create false edges between far-apart
  same-hash repeaters). Since the import file keeps full pubkeys, the app
  can re-collapse at a different width whenever the mode changes.
* Name/position become best-effort node metadata; multiple claimants render
  as "A | B" like `PathHelper.resolvePathNames` already does.
* Path entries aren't guaranteed to be repeaters — a companion with
  `client_repeat` enabled forwards and appends its hash too
  (review-verified). Hash-native tolerates it; just expect nodes with no
  advert/import metadata.

### 3. Query works on candidate *lists*, not a single pair

Since the ingress/egress tables live inside the module (see Storage), the
public call is just:

```
findPath(contactPubkey) → PathResult
```

Internally it expands both sides to weighted candidate lists —
`myEgress [(repeater, weight)...] × theirIngress [(repeater, weight)...]` —
because the best overall route often isn't through the #1 candidate on
either side: my strongest repeater might have no route to theirs, while my
#2 → their #2 is two hops. Multi-source/multi-target Dijkstra handles this
in one search (virtual source node with edges to all my candidates weighted
by candidate confidence, same on the destination side). This is also what
makes "use the highest-SNR Discover responder" safe: SNR weights the
candidates, but a loud dead-end loses to a slightly quieter repeater that
actually has a bidirectional route to their doorstep.

## Return contract

**DECIDED (2026-08-04): bidirectional or flood — no send-only tier.**

1. **Zero-hop direct** (deliberate exception to the bidirectional rule,
   per resolved question 3): fresh direct-reception evidence for the
   contact → `PathResult.direct()` (empty path). No edges exist to test
   bidirectionally — the uplink is a reciprocity guess validated by the
   ACK at the cost of one retry. Wins automatically while the evidence
   is fresh (zero edges = zero cost).
2. **Bidirectional pass**: search only the subgraph of edges where *both*
   directions exceed a confidence threshold. Found →
   `PathResult(bytes, bidirectional)` — a path the ACK can retrace, and the
   only kind whose success/failure signal is trustworthy.
3. **Flood**: no bidirectional route above threshold, or path exceeds the
   byte/hop budget → `PathResult.flood()`. A one-way or low-confidence
   guessed path is *worse* than flood: the message might arrive but the ACK
   can't reliably get back, so every send looks failed and poisons the
   retry ladder. Flood is reliable, just noisy — and every flood handshake
   feeds both directions of fresh evidence into the graph, growing the
   bidirectional subgraph and reducing future flooding. The module
   bootstraps itself toward quiet operation.

Cost function — use the log-reliability form: treat normalized edge weight
as a delivery probability *p*, and set

```
edge cost = −log(p) + τ,   τ = −log(β)
```

Minimizing the sum maximizes end-to-end delivery probability (sums of logs =
products of probabilities), and β is the one tunable knob with a concrete
meaning: *an extra hop hurts exactly as much as multiplying path reliability
by β*. Default β≈0.95, exposed as a user setting (bench preference runs
0.99 — extra hops are cheap when they buy signal quality); β→1 routes
purely by signal quality; β→0.5 approaches min-hop routing. This subsumes the earlier `hopPenalty + 1/weight`
sketch (`1/p` is the ETX metric; −log(p) is its principled cousin). Cap paths
at `maxPathSize` (64 bytes → 32 two-byte hops). Prototyped in analyze.py's
interactive HTML as the "Reliability" cost mode with a β slider.

## Probe toolset & send escalation

Four probes, verified against firmware (MeshCore checkout; corrected by
independent review 2026-08-05):

| Probe | Reach | Network cost | What it teaches |
|---|---|---|---|
| **Discover** | direct RF range only | ~free on air — zero-hop CONTROL, never retransmitted (`Mesh.cpp:69-75`). **But responses are rate-limited: 4 per 2 min per repeater, shared across ALL requesters** (`discover_limiter`), and arrive over a **~30 s window** (randomized anti-collision delay, `getRetransmitDelay×4`) | **Measures the first hop in BOTH directions** (bench-corrected layout: the 0x8E frame is `[code][our RX snr][rssi][path_len][ctl payload…]`; **uplink SNR = ctl payload byte 1** — how well they heard US; **downlink = frame byte 1** — how well we heard them). Both dB values are stored on the egress entry (EWMA over repeat probes). No response ≠ absent — may be limiter-exhausted. |
| **Path discovery** (`CMD_SEND_PATH_DISCOVERY_REQ`) | network (one flood REQ + flooded response) | ~2 floods | **The remote probe we thought didn't exist.** Firmware pushes 0x8D with BOTH proven paths: out_path (us→them) *and* in_path (them→us — its `path[0]` is their doorstep). MeshTrax doesn't send the command or handle 0x8D yet — small connector work. |
| **Trace** | the named path only | ~2×hops packets, rest of mesh silent. **No rate limiter** (firmware-verified — unlike Discover); the only gates are `disable_fwd`, next-hop match, and packet dedup — so every trace needs a **random uint32 tag** (same tag + path = byte-identical packet, silently dropped by `hasSeen`; a seconds-timestamp tag breaks rapid re-traces — bug found on the bench, also present in `path_trace_map.dart`) | whether one specific route works end-to-end + per-hop SNR (snr[i] = how well hop i heard the *previous* transmission, so snr[0] proves my first hop heard ME). A **round-trip trace fills both directions of every link with the same rule** — the fastest way to mint a bidirectional corridor. **TRACE path bytes are SNRs, not hashes — never feed them to `observePath`; feed `observeTrace` instead.** |
| **Flood DM** | network *as configured* | every forwarding repeater retransmits once. **Scoped flooding is real**: with a transport/region code set, only matching repeaters forward; repeaters may deny unscoped floods (`REGION_DENY_FLOOD`); advert floods default-cap at 8 hops | full route both ways via the flooded path-return — and delivers the message. "Flood always works" is configuration-dependent; the module must know whether sends were scoped. |

Escalation ladder for a DM send (flood is the last resort, and the cheap
local check runs before spending it):

1. Send on the best path from `findPath` (egress × ingress candidates).
   **Mobile collapse (review fix)**: if egress evidence is stale-or-moved,
   fire the Discover *concurrently* with this send and skip step 2 —
   while driving, "my first hop went stale" is the common failure, and the
   alternative-path retry re-fails for the same reason while burning a
   ~10 s timeout.
2. No ACK → retry once on the best *alternative* path (edge-penalty rerun,
   avoids the links that may have just failed). Stationary regime only.
3. Still nothing → **Discover**: if the chosen first-hop repeater doesn't
   respond, treat it as *suspect, not absent* (rate limiter) — refresh
   from whoever did respond and retry direct. An **empty** Discover result
   is *no information* (fade or limiter), never a supersede event.
4. **Flood the DM itself** — delivers *and* re-teaches the graph, egress,
   the contact's ingress, and the firmware out_path in one exchange
   (subject to the scoped-flooding caveat). When fresh both-way paths are
   wanted *without* message urgency, use **path discovery** instead.

Discover also runs on connect and as egress-list maintenance — but
**budgeted**: repeaters share a 4-responses-per-2-minutes limiter across
all requesters, so the module self-caps at roughly one Discover per
~2-minute epoch (pre-send, maintenance, and ladder uses all draw from the
same budget). The app already has the request plumbing
(`buildRepeaterDiscoveryFrame` / `ctlTypeNodeDiscoverReq`; responses ride
the 0x8E `pushCodeControlData` handler). **Proactive vs failure
semantics**: a proactive Discover (pre-send, maintenance) is an ordinary
proven-evidence refresh — add/update responders, no slash; only a
Discover run inside a *failure episode* is a supersede event.

**Fresh evidence dominance (decided 2026-08-05)**: the tallies and priors
exist to *get started*; ladder-triggered probe results are *authoritative*.
A failure cycle means the world changed, so history is suspect — a fresh
measurement must dominate, not merely out-average, stale weight. Supersede
events:

* **Discover ran** (after direct failures) → responders become the egress
  list ranked by **uplink SNR** (response byte 1 — firmware reports the
  level at which the repeater heard our request; two-line parse fix in the
  0x8E `pushCodeControlData` handler); pre-existing entries slashed,
  surviving as tie-breakers.
* **Flood handshake or path discovery completed** → `path[0]` of the
  flooded return becomes the contact's dominant ingress entry, same slash
  for their older entries; the return's hop chain is the fresh route
  anchor.
* **Slash discipline (review fix)**: the slash is an *epoch* operation —
  at most once per failure episode (~2 min), floored (`proven` entries
  keep ≥0.3× pre-slash weight, so three bad minutes can't annihilate good
  state), never triggered by an empty probe result, and position-tagged
  entries recorded far from the current position are exempt (they
  describe another place — the distance gate already expresses that).

Two regimes fall out: **quiet** — passive tallies and aged proven entries
route everything at zero probe cost; **reset** — after failures, one
Discover + one flood yield a complete fresh picture (my doorstep by SNR,
their doorstep by `path[0]`, and the route between them), and ranking
rebuilds around those anchors until they fail or age in turn.

### Mobility (primary use case: DMs while driving)

Movement invalidates **exactly one hop**: the repeater↔repeater graph is
infrastructure (stable), the contact's ingress moves at *their* pace — only
my own egress list has a minutes-scale shelf life. Conveniently it's the
smallest table and pairs with the cheapest probe. Adjustments:

* **Asymmetric decay (bench-corrected 2026-08-05)**: egress ages on a
  minutes scale, contact ingress on hours — but the original 10-minute
  egress half-life **evaporated bench evidence between tests** (a
  repeater that routed fine returned FLOOD(noEvidence) 40 quiet minutes
  later). Corrected: **45-minute half-life**, and **proven egress
  (Discover / delivered send / trace) decays 4× slower than an inferred
  last-hop guess** — a measurement outlives a guess. Movement, not the
  clock, is the real invalidator; position gating covers that when a
  position source exists.
* **Position-tag egress entries** (phone GPS already in scope): each
  observation stamped with where it was made; weight collapses with
  distance from the recording position — staleness becomes a measured
  fact, not a time guess.
* **Discover-with-send when stale-or-moved**: egress evidence older than
  ~N minutes or GPS moved > ~X km → fire a Discover *concurrently with*
  the DM (never delaying the send; matches the ladder's mobile collapse),
  subject to the ~one-per-2-min budget.
* **Contact mobility inference**: churn in a contact's `path[0]` tally
  means they're mobile too → shorten their ingress decay and bias toward
  flood sooner for that contact.
* **v2: location-keyed egress cache** — position-tagged entries let the
  module re-activate old evidence when re-entering an area ("on this
  stretch of highway, A277 hears me") instead of rediscovering every
  drive. The v1 position tag is what makes this possible later.

### Learning who hears the *receiver* (their ingress)

The mirror problem: our flood reaching them via repeater C only proves
*they hear C*, not that C hears them — so how do we ever learn a repeater
that can carry their ACK out? **The firmware already solves this**
(`BaseChatMesh.cpp` ~235): a node receiving a **flood** DM does *not* ACK
along the reversed inbound path — it floods back a `createPathReturn`
(inbound path + ACK bundled, `sendFloodScoped`). That flooded return
carries two independently proven paths:

* **Payload path** — the route our flood took *to* them, every hop proven
  sender→receiver. Becomes our out_path for direct sends.
* **Packet path** — the route the return flooded *back*, every hop proven
  receiver→sender. Its `path[0]` is a repeater that *literally heard the
  receiver transmit* — right-direction ingress evidence, free with every
  flood exchange.

So their ingress list fills passively from `path[0]` of anything they
originate (channel messages, DMs, adverts, flooded ACK/path-returns), gets
refreshed by every flood handshake, and is proven wholesale by any completed
direct round-trip. Codified rule: **never** derive "hears them" evidence
from the last hop of our *outbound* route — that's the wrong direction.

**Attribution (channel traffic has no pubkey)**: a `GRP_TXT` payload is
just `name: message` under the channel PSK — sender identity is a display
name only, and names aren't unique. Split by what needs identity:
graph-edge updates and the sender-side last-hop tally need **none** (the
hop chain is true whoever sent it — always applied). Only the
`sender → path[0]` ingress attribution needs identity, ranked:
(a) pubkey-confirmed traffic (DMs — src hash + successful decrypt with the
contact's shared secret; path-returns; adverts) → full weight;
(b) channel message whose name matches exactly **one** current contact →
reduced weight; (c) ambiguous or unknown name → skip attribution entirely
(path still feeds the graph). Wrong-name damage is bounded and
self-healing: at worst one failed direct attempt, then the flood handshake
writes the correct pubkey-confirmed ingress, and EWMA decay ages out the
bad entry. Name matching follows the existing mention/reply resolution
pattern (MC1 interop) and runs against the contact list at receive time —
renames just stop reinforcing old entries.

~~No remote probe of their neighborhood exists~~ — **refuted by review**:
`CMD_SEND_PATH_DISCOVERY_REQ` is exactly that probe (see Probe toolset) —
one flood pair returns both proven paths, their doorstep included. The
MeshTrax-to-MeshTrax egress-hint exchange stays a non-v1 idea, now
lower-value. Bonus firmware behavior (review-verified): on receiving the
flooded path-return the sender fires a *reciprocal* path-return DIRECT
along the fresh route — an immediate free test of it. And the stored flood
path is **first-arrival, not best** ("first packet wins") — worth
remembering when judging firmware-chosen out_paths.

## Weight model

* **"p" must be defined (review fix — highest-leverage correction)**: an
  EWMA of passive sightings is a *traffic* tally, not a delivery
  probability — passive observation only ever sees successes (a packet
  that died on an edge never reaches us to be counted), so it measures
  chattiness and would route into congested corridors. Keep two
  quantities per edge: **calibrated p** from attempt-counted evidence only
  (our own sends via `reportSendResult`, traces, flood/path-discovery
  handshakes), estimated with Beta pseudocounts `p = (s+s₀)/(n+n₀)` where
  the imported score maps into the prior (`s₀ = score·n₀`) — this makes
  seed and local evidence commensurable by construction; and a
  **traffic/recency term** from passive sightings, used only for
  candidate ranking and tie-breaks, never as p. Virtual candidate edges
  cost `−log(q)` (q = the candidate's calibrated first-hop estimate); no
  τ on virtual edges.
* **Edge quality inputs (decided 2026-08-05): frequency + signal
  strength feed the prior; attempt counts override it.** Three signals
  per edge, by trustworthiness: (1) attempt-counted success `s/n` —
  ground truth, dominates when present; (2) **SNR** — Corescope
  `avg_snr` on the import layer, and **trace per-hop SNR** on the local
  layer (`measuredSnr` EWMA — a map-tab trace is the *only* source of
  middle-hop SNR; our RX SNR only measures the final hop to us; a
  round-trip trace gives it per direction); (3) **frequency** — the
  traffic EWMA ("B→C→A happens a LOT"). Combination: prior quality
  `q₀ = f(importedScore, avg_snr, measuredSnr)` (monotone dB→[0,1] map,
  calibrated at implementation), traffic frequency scales the prior's
  *confidence* (n₀) and breaks ties between near-equal routes, and the
  read-time blend stays `p = (s + q₀·n₀)/(n + n₀)`. Frequency and SNR
  propose; delivery disposes.
* **Passive channel paths are first-class (decided 2026-08-05, overriding
  the review's stricter cap)**: every received flood — including **every
  path variant** of a multi-heard flood (the app already merges
  `pathVariants`) — builds the graph. Each variant is an independently
  real transmission chain: hearing `[A,B,C]` and `[A,B,D]` for one
  message proves both branches, and the set of last hops across variants
  yields multiple doorstep candidates from a single message. Dedup rule:
  per message, apply the *union* of edges across variants once each
  (variants share early hops). Chatty channels also prove backbone edges
  in **both** directions organically — traffic flows both ways through
  the trunk — so passive evidence **counts toward the bidirectional
  threshold** at reduced per-observation confidence.
* **Repeater adverts are the graph's heartbeat (verified 2026-08-05)**:
  repeaters flood-advert on a default **47 h** interval
  (`flood_advert_interval`, simple_repeater default; user-configurable in
  hours) and the advert floods like any packet — each forwarder appends
  its hash, so the path proves `R → path[0]` (**the advertising
  repeater's own doorstep**) plus every subsequent trunk edge
  (hop-capped: `flood_max_advert` default 8). The payload is full pubkey
  + timestamp + **Ed25519 signature** (firmware-verified before
  forwarding) + name/position — the only self-authenticated packet on
  the mesh, and the identity is width-independent: a 1-byte-mode
  repeater's advert path is dropped (counted) but its payload still
  feeds `ingestNode` fully. At ~470 regional repeaters this is ~10
  adverts/hour refreshing infrastructure edges + verified identities
  passively. Zero-hop *local* adverts (minutes-scale interval) carry no
  path but are direct-reception evidence when heard. And broader:
  **path bytes are cleartext on every packet** — even undecryptable
  stranger DMs teach edges at `anonymous` attribution.
  **Lopsidedness caveat**: every advert proves its chain in ONE
  direction only — passive listening alone builds a directed skeleton,
  and the bidirectional subgraph (the only thing `findPath` routes on)
  is the intersection of two independently-fed halves. Bidirectionality
  comes from: the import (both directions seeded at once — its enduring
  value), genuinely two-way traffic on busy corridors, and our own
  handshakes/probes. Adverts supply freshness and coverage, never
  bidirectionality by themselves.
* **Fabrication defense — dropped for v1 (decided 2026-08-05)**: path
  bytes are technically unauthenticated, but on a cooperative hobbyist
  mesh the chance of deliberate path fabrication is near zero — no
  rate-capping machinery. What stays is cheap hygiene against
  *accidental* garbage (corrupt frames, mis-strided legacy parses):
  validate path structure before `observePath`, drop malformed frames,
  and let staleness GC sweep never-again-seen nodes. Self-involved
  evidence (own handshakes, delivered sends, traces, echoes) still
  carries the highest confidence simply because it's attempt-counted —
  not as a security measure. If the threat model ever changes, the
  evidence-tier plumbing is the natural place to hang rate caps.
* **Bootstrap — with or without an import (review fix, extended)**:
  imported `bidirectional: true` priors clear the bidirectional threshold
  at seed confidence. **No import needed though** (Watsonville→Arizona
  case): in a fresh region the sequence is listen (adverts + channel
  traffic build the directed skeleton within hours; *busy two-way*
  corridors also accrue bidirectionality — quiet spurs stay one-sided
  until probed) → Discover (doorsteps) → first DMs flood (handshakes
  mint fully bidirectional corridors on demand). Early
  direct paths will be suboptimal — that's fine; the ladder prices a
  wrong guess at one retry before flood. Infrastructure
  (repeater↔repeater) edges get a **decay floor** — topology is stable,
  only confidence fades; rate-limited proactive path-discovery probes may
  convert forward-only corridors instead of waiting for failures. Road
  trips need no region ceremony: the region tag governs *imported* rows
  only; observed data is one continuous store (2-byte hashes make
  cross-region aliasing negligible; position tags handle locality).
* **Edge weight (traffic term)**: EWMA with time decay — `w = w·λ^Δt + k`
  per observation. Store `(weight, lastObserved, observationCount)` per
  directed edge; decay computed lazily at read time so there's no
  background job. Δt uses **arrival time** (ArrivalClock discipline —
  never wire timestamps; sender clocks lie).
* **Seed vs. local**: imported Corescope edges get a *prior* weight scaled
  from their `score`, flagged `source: imported`. Local observations
  dominate quickly — the analyzer's view is region-wide and days-stale; the
  radio's view is ground truth for the local RF neighborhood.
* **ACK role — DECIDED: ingress harvesting only.** Firmware-verified: an
  ACK for a flood DM comes back inside the *flooded* path-return; an ACK
  for a direct DM goes down the receiver's *stored out_path*
  (`BaseChatMesh.sendAckTo`), which is not necessarily our send path
  reversed — and direct packets strip hops in transit, so we can't see the
  route it took. So the module draws **no per-edge credit from the ACK
  itself**. The ACK is (a) the delivery signal driving the send escalation
  ladder, and (b) — in the flood case — attached to a flooded path-return
  whose packet path is a normal `observePath` input: its `path[0]` is a
  repeater that heard the receiver (contact ingress), and its hop chain is
  reverse-direction edge evidence. Precisely scoped: **delivery outcomes
  DO update forward-direction attempt counts** on the exact path sent
  (delivery proves every forward hop — this is where calibrated p's
  (s, n) come from, and why success upgrades the first hop to proven
  egress); what contributes *nothing* is the ACK's own return route
  (unknowable) — reverse-direction edges come only from observed paths.
  `reportSendResult(path, success)` remains a first-class input, feeding
  the p-estimator, the escalation ladder, and the failure penalty below.
* **Failures**: a failed direct send can't localize which hop broke — apply
  a small penalty across the path's forward edges, let flood-discovery of a
  new path do the real correction. Mirrors what
  `PathRecord.successCount/failureCount/routeWeight` does per whole-path;
  this module generalizes it per-edge.

## Module API & integration hooks

**Isolation invariant (decided 2026-08-05): push-in, never read-out.** The
module never reads any app store; everything it knows arrived through the
inputs below — this list is the *complete* inventory of what the module
will ever know. Internal copies (contact names, repeater metadata) are
caches of pushed events, never a second source of truth. Consequences:

* `findPath` is **always by contact pubkey** — the app can't send a DM
  without the PK anyway, so the request side never needs a name. Names are
  only needed on the *observation* side (channel-message attribution
  against the module's own mirror).
* On companion connect, the app pushes a full **PK → current-name refresh**
  (`ingestContact` for every synced contact) — PKs are stable, names
  mutate; the refresh keeps attribution current when people rename.
* The contact mirror is derived — the app never needs to delete from it;
  staleness GC prunes rows for contacts that stop being refreshed, and
  re-adding a contact restores everything.

The whole public surface — everything else is internal:

* `observePath(pathBytes, stride, origin, rxSnr?, position?)` — any
  received path: channel messages, DMs, adverts, and **both** paths of a
  flooded path-return (payload path = forward-proven, packet path =
  reverse-proven). `origin` carries attribution quality:
  `pubkeyConfirmed(contact)` | `uniqueName(contact)` | `anonymous`.
  **Rejects stride < 2** (2-byte-only ingest rule) — dropped observations
  are counted, not silently ignored. `lastHopHeard` flag (implementation
  refinement, 2026-08-05): true only for paths physically received over
  RF — their final hop is a repeater *I heard* and feeds the last-hop
  egress prior; payload-embedded paths (path-return contents, firmware
  out_paths) pass false, since their final hop proves nothing about my
  RX.
* `observeDiscoverResults([(repeaterHash, uplinkSnr, rxSnr)...],
  position?, failureEpisode)` — proven egress refresh carrying the
  measured dB in **both directions** (uplink = they heard us, rx = we
  heard them; stored per entry, EWMA over repeat probes, and the
  first-hop candidate cost blends measured quality 70% with the tally
  30% — a strong new responder outranks a weak favourite). Acts as the
  supersede/slash event only when `failureEpisode` is true.
* `observeTrace(hops, snrs)` — trace results as a first-class input
  (implemented 2026-08-05): snr[i] is how well hop i heard the previous
  transmission, so snr[0] upgrades my first hop to proven egress, each
  hop pair gets `measuredSnr` (EWMA) plus an attempt-counted success,
  and a round-trip path fills both directions with no special case.
* `reportSendResult(pathBytes, success, {tripTimeMs?})` — drives the
  escalation ladder and the failure penalty; success upgrades the first
  hop to proven egress; trip time kept as tiebreaker and forwarded signal
  (timeout prediction stays outside the module).
* `ingestNode(hashBytes, {name?, pubkey?, lat?, lon?})` — repeater adverts
  enrich node metadata.
* `ingestContact(contactPubkey, name, {position?})` — feeds the module's
  contact mirror; called per contact on companion connect (the PK→name
  refresh) and on add/rename.
* `setRadioIdentity(selfPubkey, stride)` — at device-info time; scopes
  egress rows and observation stride to the connected radio.
* `importGraph(json, homePosition, radiusKm)` — region seed.
* `findPath(contactPubkey)` → `PathResult.direct()` (zero-hop) |
  `PathResult(bytes, estDelivery)` | `PathResult.flood(reason)` — the
  flood reason (`noEvidence` / `noBidirectionalRoute` / …) feeds the
  why-this-path UI.
* `findPathToRepeater(repeaterHash)` — added 2026-08-05: the target is
  the node itself (repeater/room login, map tap); a repeater that is
  also my doorstep yields a single-hop path.
* `findAlternatives(contactPubkey)` / `findAlternativesToRepeater(hash)`
  — up to k genuinely divergent routes via edge penalties (the retry
  ladder's alternative step and the UI's route picker).
* `updateConfig(config)` — live retune (the β slider); affects routing
  immediately, never touches stored evidence.
* `snapshot()` / `egressCandidates()` / `ingressCandidates(pk)` /
  `counters` — read-only views for UI, debug, and the harness.

App-side hooks required (connector/service level — corrected by review):

* **Path discovery**: implement `CMD_SEND_PATH_DISCOVERY_REQ` + the 0x8D
  `pushCodePathDiscoveryResponse` handler (constant declared, currently
  handled nowhere) — one probe delivers BOTH proven paths, covering most
  of the frame-level path-return need below.
* **Passive path-return frames**: `PUSH_CODE_PATH_UPDATED` (0x81) carries
  only the pubkey — for handshakes we didn't initiate, the reverse path is
  recoverable only from the raw RX log (path bytes are cleartext even when
  the payload isn't decryptable app-side).
* **Discover responses** ride `pushCodeControlData` **0x8E** (not 0x8D as
  previously written); parse response **byte 1 = uplink SNR** — currently
  skipped by the app.
* **Repeat-echo events**: exist for channel sends only
  (`_mergeChannelRepeat`, fed by pre-dedup raw RX logging); DM flood echo
  detection is new work.
* **Per-message paths — data-source reality (review)**: full path bytes
  exist ONLY in live RX-log traffic while connected; synced/backlogged
  messages carry a hop count with **empty pathBytes**, and the RX-log
  parser currently early-returns for everything except GRP_TXT.
  **Accepted (2026-08-05): offline observation loss is fine** — the phone
  is connected most of the time; when it isn't, those paths are simply
  lost and no backlog-recovery work is planned. Remaining implementation
  work: extend `_parseRawPacket` beyond GRP_TXT — **priority order:
  ADVERT (self-authenticated full pubkey + name/position + path, the
  richest passive packet), then PATH returns, then remaining types for
  anonymous edge harvesting** (path bytes are cleartext even on
  undecryptable payloads); channel-sync and RX-log parsers currently
  skip SNR bytes — extract them.
* **Send outcomes** from the retry pipeline (`message_retry_service`).
* **Position (optional — decided 2026-08-05)**: position is an
  enhancement, never a requirement; the module runs fully without it
  (distance gating degrades to time-only staleness). App-settings
  selector with three sources:
  1. **Off / manual** (default) — no permission requested (nothing for
     app-store review to flag); home position for the import radius via
     map tap or typed coordinates.
  2. **Radio position** — the companion's own GPS or user-set node
     position when available (no phone permission; it's where the
     antenna actually is). Not guaranteed — many companions have no GPS.
  3. **Phone GPS** — explicit opt-in, while-in-use only (`geolocator`,
     coarse/low-power), clear purpose string; foreground-only per the
     background-scope decision, keeping it in the least-scrutinized
     permission tier.

## Storage & module shape

**Persistence mechanics (decided 2026-08-05)**: a separate Drift database
file (`path_graph.db`, own `PathGraphDatabase` class, schema version 1,
additive migrations) — NOT tables inside `AppDatabase`. Drift 2.34 +
`drift_flutter` are already in the app; follow `AppDatabase`'s house
patterns (typed tables, indexes, ArrivalClock timestamp discipline).
Memory is the working store: the full graph (~500 nodes / 3k edges, a few
hundred KB) loads into an in-memory adjacency map at init; observations,
lazy decay, and Dijkstra all run in memory (sub-ms at this scale, no
isolate). Drift is the durability layer: dirty rows flush in one
transaction on a ~30 s debounce, on app-background, and on disconnect.
Independent wipeability ("clear learned data" = file delete), decoupled
migrations, and the future-package boundary all fall out of the separate
file. Web target: Drift needs wasm/IndexedDB setup — decide at
implementation whether web gets the module in v1 (its RX-log data source
may not exist there anyway).

Self-contained module with its own Drift tables (fits the
channel-core-rebuild direction):

* `graph_nodes`: hashBytes (2 bytes, **sole PK** — region is metadata on
  imported rows, not part of identity, so an observed node and an
  imported node with the same hash are ONE node and edges never
  fragment), name(s), lat, lon, lastHeard, source
  (imported/observed/advert), region?, full pubkey as metadata when known
  (enables re-collapse at a different width, e.g. future 4-byte). Wider
  observed hashes (3-byte) truncate losslessly into their 2-byte bucket
  at ingest (prefix property).
* `graph_edges`: fromHash, toHash (composite PK, *directed*; index on
  fromHash for adjacency expansion), attempt counts `s`/`n`
  (**local evidence only** — the prior is NOT baked in), trafficWeight
  (EWMA, passive sightings), lastObserved (arrival time), obsCount,
  source, nullable importedScore/avgSnr (import layer), nullable
  measuredSnr (local layer — trace-fed EWMA). Calibrated p combines
  layers at read: `p = (s + q₀·n₀)/(n + n₀)` where
  `q₀ = f(importedScore, avg_snr, measuredSnr)` uses *current* prior
  values — so replacing the prior never contaminates or subtracts from
  live counters.
* `graph_meta`: import file identity, generatedAt, home position + radius
  used for the geo-scoped collapse — "load Southern California" = swap
  *imported* rows where region matches. Locally-observed rows persist
  across imports (decided 2026-08-05: one continuous store — at 2-byte
  width a distant region's edges are real, just far away; Dijkstra never
  routes through them, and staleness GC prunes them eventually)

**Import semantics (decided 2026-08-05): imports never touch local
knowledge — two layers, combined at read.** The *prior layer*
(importedScore, import-sourced metadata) is owned by imports and freely
replaceable per region; the *local evidence layer* (s/n counts, traffic
EWMA, ingress/egress, position tags) is owned by observation and only
staleness GC or the user's "clear learned data" ever deletes it.
Consequences: re-importing a region = replace that region's prior rows,
idempotent, local counters untouched; importing a new region = additive
(old region's priors may stay — harmless — with an optional "remove
imported region" action); node metadata precedence = signed advert >
import > anonymous observation (import fills blanks, never overwrites
advert-sourced fields); ingress/egress/known_contacts are untouchable by
imports by construction (the file contains no such data). The import
screen therefore needs no destructive-action warning — the two delete
actions ("remove imported region", "clear learned data") are separate,
explicit buttons.

Contact ingress lists are per-contact facts but live in the *module's* DB
as their own table — `contact_ingress(contactPubkey, repeaterHash, weight,
lastSeen, evidence, observedLat?, observedLon?, uplinkSnr?, downlinkSnr?)`,
self as just another row keyed by my pubkey; the nullable position stamp
(phone GPS at observation time, mainly for self rows) powers the mobility
distance-gating, and the SNR pair (added 2026-08-05) holds the
Discover-measured first-hop link in both directions.
`evidence` is `proven` (Discover response, repeat-echo, observed reverse
path, successful direct send through it) or `inferred` (last-hop prior) —
inferred rows weight candidate selection but never feed the graph.
Hash-keyed end to end, matching the graph.

* `known_contacts(contactPubkey PK, name, lastKnownLat?, lastKnownLon?,
  lastRefreshed)` — the module's own contact mirror, fed exclusively by
  `ingestContact` (full refresh on companion connect + add/rename events).
  Used for channel-message name attribution; derived data, pruned by
  staleness GC, never read from the app's contact store (isolation
  invariant).

Nice consequence of hash-native: path observations alone *can* create
nodes — a hash seen in a path is a node. The imported JSON and locally
received repeater adverts (pushed in via an explicit `ingestNode()` input)
only enrich nodes with name/position metadata. "Independent" means *own
storage, no reads from the contacts/discovered DB*, not *ignores local
adverts*.

## Corescope source data (empirical, 2026-08-03 snapshot)

From a saved `neighbor-graph.json` (753 nodes, 2,867 edges):

* Nodes carry full 64-hex pubkeys, name, role, neighbor_count. Positions are
  **not** in this file — they come from the separate `nodes` endpoint.
* Edges carry `weight` (observation count), `score` (0.10–1.00, median
  0.505), `avg_snr`, and a **`bidirectional` boolean**. Import rule: `true`
  seeds both directed prior edges, `false` seeds source→target only.
  **Caveat (verified 2026-08-03): all 2,866 edges in the live feed are
  `bidirectional: true`** — either the analyzer only publishes
  both-ways-confirmed links, or the flag is vestigial. Keep the import rule
  (it's correct either way), but do NOT treat imported edges as
  locally-verified bidirectional evidence — seed them as
  moderate-confidence priors in both directions and let local observation
  (flood handshakes, path discovery, traces) provide the real
  directionality signal.
* Hash-width validation: 250/256 one-byte prefixes in use region-wide, 221
  colliding (88% ambiguous — 1-byte confirmed near-useless at region
  scale). Two-byte: only 4 collisions among 749 distinct prefixes
  (near-unique, and the collision pairs are the geo radius's job).
* 228 edges (~8%) have a `prefix:XX` endpoint the analyzer never resolved
  to a pubkey — observed widths: 183 × 1-byte, 38 × 2-byte, 7 × 3-byte
  (the mesh already carries mixed-width traffic). Export decision: keep the
  2- and 3-byte prefix edges (a hash *is* our node key, they map cleanly),
  drop the 1-byte ones as too ambiguous.

## Corescope export utility

**Built: `tools/generate_graph.py`** (2026-08-05; `tools/analyze.py` lives
beside it). Known Corescope instances are a `SOURCES` list in the file —
one entry per region, no args generates all. Pulls the two endpoints,
filters to repeaters + rooms, and emits full pubkeys + positions (the
analyzer knows them — keep the file lossless; the *app* geo-filters by
home radius and collapses to hash buckets at import time). Prefix-edge
endpoints: 1-byte always dropped; 2/3-byte resolved when exactly one kept
pubkey matches, else dropped — all drops counted and reported. Verified:
NetworkX `node_link_graph()` loads the output natively with all custom
fields intact.

**Format (decided 2026-08-05): node-link JSON** — the D3 / NetworkX
convention (`directed`/`multigraph`/`graph`/`nodes`/`links`,
`source`/`target` by id) with our `format` profile marker on top. Chosen
over JGF (formal spec, little tooling) and GraphSON (property-graph
overkill): NetworkX loads it natively (`node_link_graph()` → free
centrality/community analysis for anyone curious), D3 renders it, and
both conventions ignore-and-preserve unknown fields, so all our custom
bits ride along without breaking anything. Full pubkey is the node `id`
(the lossless-file rule). A GeoJSON companion export can be a later
analyze.py flag for GIS tooling.

**The source data is UNDIRECTED — verified 2026-08-07.** Corescope
publishes exactly one entry per node pair with a single `avg_snr`; a
scan of the live feed found **zero** edges appearing in both directions,
and the per-edge `bidirectional` flag is `true` on all 2,866 of them
(i.e. it carries no information). So there is **no per-direction SNR**
in the import: A→B and B→A necessarily receive the *same* number.
Declaring `directed: true` and duplicating that value would misrepresent
one measurement as two, so the export declares **`directed: false`**
plus `snr_directionality: "symmetric"`, and the app expands each link
into two directed priors at import while treating the SNR as a
*symmetric estimate*. This is exactly why locally measured SNR (trace
per-hop, Discover uplink/downlink) outranks the imported value in
`priorQuality` — local measurement is the only true per-direction dB
the module ever gets. Import accepts both shapes: `directed: false`
seeds both ways; `directed: true` seeds source→target only and expects
a reverse entry of its own.

```json
{ "format": "meshtrax-graph-v1",
  "directed": false, "multigraph": false,
  "graph": { "generated_at": "...", "region": "socal",
             "source": "corescope", "hash_width": 2,
             "snr_directionality": "symmetric" },
  "nodes": [ { "id": "<64-hex pubkey>", "name": "...",
               "lat": 0, "lon": 0, "last_heard": 0 } ],
  "links": [ { "source": "<pubkey>", "target": "<pubkey>",
               "score": 0.83, "avg_snr": 7.5,
               "bidirectional": true, "weight": 3791 } ] }
```

`weight` (observation count) scales prior confidence. The legacy
per-edge `bidirectional` flag is still honoured when a document
declares `directed: true`, but Corescope sets it unconditionally, so
`directed: false` is the accurate declaration for its data. Published as a raw file on a GitHub
branch/gist/release asset, app fetches by URL — which also naturally enables
multiple region files.

## Implementation status (2026-08-05)

Branch `feat/path-graph-package`, draft **PR #71 — held unmerged**
through the verification campaign (user directive). Phases per
`docs/path-graph-implementation.md`.

**Phase 0 — the package: BUILT.** `packages/path_graph/` — pure Dart,
`drift` only, injected `QueryExecutor`, compiler-enforced isolation
(cannot import the app), 50 tests under bare `dart test`. Everything in
the Module API section above is implemented: graph store with
load/debounced-flush, two-layer estimator, evidence tiers with hub
demotion and slash discipline, bidirectional multi-source Dijkstra,
alternatives, trace ingestion, layered idempotent import, live config.

**Phase 1 — path_lab harness: BUILT, in active bench use.**
`test/path_lab/` (`flutter run -d windows -t test/path_lab/main.dart`,
zero `lib/` changes) — frame adapter owning ALL wire parsing (adverts →
`ingestNode`/`ingestContact` + attributed path; anonymous edge harvest
with payload-fingerprint variant dedup; discover responses; trace
responses), USB serial connect, live counters, seed import, Discover
with 30 s window, findPath for contacts AND repeaters with selectable
alternatives, β slider, round-trip Trace, self-diagnosing flood
verdicts.

**Bench findings so far** (each one corrected the design or code — the
verification phase doing its job):
1. **Egress decay too aggressive** — 10-min half-life evaporated
   evidence between tests; now 45 min with proven-tier decaying 4×
   slower (§ Mobility).
2. **Discover response layout** — my first parse read the RX-SNR byte
   as the message type (0 responders next to a live repeater); corrected
   against the connector's own handler, and the exchange now stores
   measured dB in BOTH directions (§ Probe toolset).
3. **Trace tags must be random** — repeater packet dedup silently drops
   byte-identical re-traces; seconds-resolution tags break rapid
   re-tracing (same latent bug exists in `path_trace_map.dart` —
   deferred app fix, noted in memory).
4. **`lastHopHeard` API flag** — payload-embedded paths must not feed
   the last-hop egress prior (§ Module API).
5. **Windows main-app finding** (separate branch, PR #72): BLE
   auto-reconnect pins state to `connecting` and silently blocks
   `connectUsb`; opening the USB picker now suspends it.

**Remaining before the Phase 2 gate**: staleness GC + growth caps,
replay-corpus recorder (harness observation log → offline regression
suite), package CI lines, `CMD_SEND_PATH_DISCOVERY_REQ`/0x8D path
discovery, then the verification campaign itself (coverage / ACK-rate /
freshness / trace-honesty / 1-byte-share metrics with the go/no-go
gate). Details in TODO below.

## TODO

### DECIDED 2026-08-07: drop Corescope edges; the file becomes a TRUE directed graph

Verified on the live export: 1,388 links, **zero** with a reverse
entry, one `avg_snr` per pair. Reporting the same number for A→B and
B→A does not merely omit information — on a medium that is genuinely
asymmetric (different TX power, antenna, and noise floor at each end)
it **asserts something false**, and it then clears our bidirectional
routing threshold on the strength of that assertion. That is the worst
possible combination: bad data with routing authority. Scrapped.

**What replaces it**: the module's own observations, exported. Every
received path proves one direction and only that direction; every
trace hop measures one direction; a round-trip trace measures both,
separately. That is a real weighted directed graph, collected by the
radio that will route on it.

**Format `meshtrax-graph-v2` — one entry per direction, no symmetry
anywhere:**

```json
{ "format": "meshtrax-graph-v2",
  "directed": true, "multigraph": false,
  "graph": { "generated_at": "...", "collector": "meshtrax 1.7.x",
             "region_hint": "bayarea", "hash_width": 2 },
  "nodes": [ { "id": "A277", "pubkey": "<64-hex, when known>",
               "name": "...", "lat": 0, "lon": 0, "last_heard": "..." } ],
  "links": [ { "source": "A277", "target": "1312",
               "observations": 47,
               "measured_snr": 6.5,
               "trace_confirmed": true,
               "delivered": 3, "attempts": 4,
               "last_observed": "..." } ] }
```

Rules that keep it honest:

* **A→B and B→A are separate entries** with independent values. If we
  have only measured one direction, only that entry carries
  `measured_snr`; the other is absent or null. **Never** copy a value
  across directions.
* **`measured_snr` means measured** — from a trace hop (or Discover,
  for a first hop), in that direction. No inferred, averaged, or
  imported values in this field.
* **No `score`** — that was Corescope's opaque metric. Confidence comes
  from `observations` plus `delivered`/`attempts`, which are things we
  actually counted.
* **No `bidirectional` flag.** Bidirectionality is derivable: both
  entries exist. A flag would just be another chance to lie.
* Node `id` is the 2-byte routing hash; `pubkey` rides along when known
  (adverts and imports supply it). Open tension for merge: hash is the
  routing identity but pubkey is the safer *merge* identity, since two
  collectors in different regions could hold different repeaters under
  one hash. Settle when merge is built.

**Corescope's remaining role, if any**: its *node* data (pubkey, name,
position) is not directional and is therefore not wrong — it could
survive as an optional gazetteer for map labels. But adverts supply the
same thing, self-authenticated, within ~47 h. Recommendation: retire
`tools/generate_graph.py` from the routing path entirely; if we keep a
Corescope tool at all it emits **nodes only, no links**, and is clearly
labelled as labels-not-topology. `tools/analyze.py` stays — as a
*viewer*, now pointed at our own exported graph.

**Code consequences to implement**: `importGraph` must stop seeding
both directions from one symmetric link (that path exists today);
imported edges must not clear the bidirectional threshold on symmetric
evidence; add `exportGraph()` emitting v2 under the
repeater-topology-only privacy filter.

### Export & the app as primary collector (decided 2026-08-07)

**The app is the observer.** It is already connected and running, and —
unlike a fixed collector — it *travels*, which is an advantage: a
stationary listener samples one neighborhood deeply, a phone samples
many. Travelling to a region with no Corescope instance (Europe,
hypothetically) is the no-import bootstrap case working as designed:
listen → adverts fill names/positions → Discover finds the doorstep →
first flood handshakes mint corridors. A dedicated always-on Python/Pi
collector keeps one real advantage (24/7 uptime without a phone
battery) and stays a possible later addition, but it is **not** the
plan — no second implementation of the observation pipeline.

**Export filter — FIRM RULE: repeater topology only.** An exported
graph contains `graph_nodes` + `graph_edges` and nothing else:

* **Exported** — repeater hashes, names, positions, directed edges with
  their observation counts, trace-measured per-direction SNR, and
  whether a link is trace-confirmed. This is public infrastructure;
  sharing it is the point.
* **NEVER exported** — `contact_ingress` (which includes
  position-tagged records of where *I* was when a repeater heard me: a
  drive log), `known_contacts` (an address book), and any per-contact
  ingress list (who talks to whom, and through where). None of this
  belongs in a file that gets emailed or handed over on a USB stick.

The rule is simple to state and simple to audit: **if a row is about a
person, it does not leave the device; if it is about a repeater, it
may.** Convenient consequence — repeater topology is also exactly what
a future merge wants, so the privacy filter and the merge payload are
the same set.

**Merge deferred (2026-08-07)** until real single-collector data
exists: how many edges one listener accumulates, what fraction become
bidirectional without probing, and how skewed observation counts are
all decide the merge rules (notably whether *distinct-observer count*
must replace summed counts, since counts are observer-relative).
Nothing is wasted by waiting — a directed graph with trace-filled SNR
is what a merge would consume either way; merge only adds provenance.

### How much is the Corescope import actually worth? (open, 2026-08-07)

Raised on the bench and worth settling with data rather than argument.
After the undirected-SNR finding above, the honest inventory is:

* **Still valuable**: node identities (pubkey/name/position) for hash
  buckets, and a topology skeleton for a region you have never
  visited (the Watsonville→Arizona case) — the one thing local
  listening cannot give you on arrival.
* **Weak**: the SNR is a single symmetric number, the `score` is the
  analyzer's metric rather than a delivery probability calibrated to
  *our* radio, it says nothing about our egress (the hop that matters
  most and changes most), and repeater **adverts supersede the node
  metadata within ~47 h of listening** — so most of the import's value
  is a head start on something we get free.
* **The sharp edge**: the design currently lets imported priors *clear
  the bidirectional threshold*, so a purely imported corridor is
  routable with **no local evidence at all**. That is third-party
  hearsay carrying real routing weight. The original justification was
  "otherwise day-1 is all-flood" — but flooding on day one is honest,
  and it is what teaches the graph anyway.

**Reachability is the natural filter (2026-08-07).** To *route* through
edge A→B you must first reach A; to *trace* it you must reach A and get
back. So the traceable set and the routable set are nearly identical —
**anything we cannot trace, we could never route through anyway**.
Consequences: (a) there is no "coverage gap" to engineer around, since
the gap is exactly the part that could never be acted on; (b) a
*survey* of the regional backbone (systematically tracing high-degree
edges) is the wrong shape for this module — **demand-driven** tracing
of the corridors `findPath` actually proposes measures the same useful
set at a fraction of the airtime; (c) imported edges we cannot reach
are pure storage cost, never routing influence. Caveat: reachability
is not permanent — driving somewhere makes new edges reachable, which
is precisely the new-region case that remains the import's job.

**Worth asking CoreScope before spending airtime**: its SNR most likely
originates from each repeater's own neighbor table, and those readings
*are* inherently directional ("I heard X at N dB"). If the raw
database/API retains them before the export collapses them, per-
direction SNR already exists and costs one question rather than a
trace campaign. Also unverified: the exact meaning of the per-edge
`bidirectional` flag — though its being `true` on all 2,866 edges is
itself evidence that it discriminates nothing.

**Proposed (not yet decided)**: demote the import from foundation to
accelerant. Make "imported priors may be routed on" a **setting,
default OFF** — imports always contribute node metadata and cold-start
skeleton, but routing requires locally-observed or probed evidence
unless the user opts in. Then **let the verification campaign decide**:
compare ACK rate on imported-only corridors vs locally-proven ones. If
imported corridors underperform, the setting stays off and Corescope
becomes a names-and-positions convenience plus a new-region map.
Requires the harness to label *why* a route was chosen (imported-only
vs locally proven) so the comparison is measurable.

### Staleness / retention — manual + automatic (decided 2026-08-05)

Nothing is ever deleted today: decay makes old evidence weigh nothing,
but the rows persist forever, so months of driving accrete nodes and
edges (including junk minted from corrupt frames), and position-tagged
egress rows are effectively a drive log. Retention is therefore a
**user-facing setting with two halves**:

* **Manual — "Clear learned data"** button. Wipes the *local evidence
  layer* only: observed nodes/edges, ingress/egress rows, position
  tags, counters. Imported priors survive (they are removed separately
  by "remove imported region"), so a user can reset what the radio
  learned without losing the community starter map. Confirm-on-tap; it
  is the privacy escape hatch as much as a debugging tool.
**What decays and what does NOT (clarified 2026-08-05).** Repeaters are
fixed infrastructure — a link between two towers does not get worse
because nobody used it this week. So **repeater↔repeater link quality
never decays** in the implementation, and must not: `calibratedP` is
built from attempt counts and the SNR/import prior, none of which are
time-scaled. The only time-decayed quantities are (a) the passive
**traffic** term, which merely scales prior *confidence* (n₀) and
breaks ties — a quiet link keeps its quality, it just stops
accumulating extra trust — and (b) the **ingress/egress doorstep
lists**, which are genuinely perishable because *people* move even
though repeaters don't. That asymmetry is the whole point of the
design's "movement invalidates exactly one hop" observation.

* **Automatic — a retention policy setting**, default on. Simplest
  shape that covers the real needs: *"forget unused data older than
  N days"* (default ~30, with an Off option for people who want a
  permanent map). A periodic sweep — cheap, run on connect and daily —
  deletes:
  * edges with **no attempt counts and no import provenance** whose
    traffic has decayed to ε and whose `lastObserved` is older than
    N days — i.e. hearsay we never confirmed and haven't seen since.
    **Infrastructure is protected**: an edge with `s/n` attempt counts
    (we sent through it, traced it, or a handshake proved it) or an
    imported prior is *never* aged out by idleness alone; a tower link
    you last used in spring is still a tower link. Those only go via
    an explicit "clear learned data" / "remove imported region", or a
    much longer safety horizon (≥1 year) if one is wanted at all;
  * nodes left with no edges and no advert/import metadata (hashes
    minted once by a corrupt frame);
  * ingress/egress rows past the same age gate;
  * **position tags on a shorter, separate clock** (default ~7 days) —
    the coordinate is only useful for recent distance-gating, and it is
    the most sensitive thing stored. Ageing out the tag must NOT delete
    the evidence row itself; it just drops the position column.
* **Growth caps as a backstop**: max nodes/edges per region; when
  exceeded, evict the lowest decayed-weight `source: observed` rows
  first. Imported rows and rows with attempt counts are evicted last.
* **Surface the numbers**: the settings screen shows current row counts
  and what the last sweep removed — the same counters the harness
  already displays. Silent deletion of a user's learned map would be
  the wrong kind of surprise.

## Independent review outcomes (2026-08-05)

Three adversarial reviews ran against this document: firmware verification
(every protocol claim checked against MeshCore source), routing-theory
attack, and completeness audit against the actual app code. **Verified
intact**: direction semantics, flood-handshake mechanics, ACK routing,
hash-width support, 64-byte path budget, out_path = payload path.
Corrections are folded into the sections above (probe table, slash
discipline, mobile ladder collapse, p definition, edge trust, bootstrap,
hooks). Accepted findings still to fold in at implementation planning:

* **Integration ownership**: the module becomes `MessageRetryService`'s
  path-selection strategy — one ladder, not two (the retry service already
  rotates paths and forces flood on last attempt; two ladders would
  fight). `reportSendResult` and the existing `recordPathResult` are one
  event fanned out. `pathOverrideBytes` needs provenance: user > module,
  UI-labeled, module never overwrites a user value; note a write also
  programs the radio (`setContactPath`).
* **Multi-radio scoping**: graph + contact ingress shared per region;
  egress rows (proven AND inferred) keyed by radio pubkey; observation
  stride from the observing radio; module learns current-radio identity
  at device-info time (matches the existing `nodeScope` store discipline).
* **Import contract**: reject unknown `format`, cap download (~5 MB) and
  node/edge counts, validate coordinates/pubkeys, transactional
  all-or-nothing import, imported weight can never exceed prior tier.
* **Growth/GC/privacy**: node/edge caps per region; periodic sweep of
  decayed rows; position-tagged egress retained ≤ N days (**it is a drive
  log** — privacy); a user-facing "clear learned data" action. Observed
  ingress/egress rows persist across import swaps (continuous-store
  decision) — staleness GC and position gating handle relocation.
* **Persistence**: in-memory graph with debounced batch flush (~30 s) —
  per-packet Drift upserts would be hundreds of writes/min; separate
  Drift database file with its own schema version and additive
  migrations.
* **Counters/observability**: observations applied vs dropped-as-1-byte
  (the 2-byte-only ingest rule must be measurable — a high drop rate
  means the local mesh regressed to 1-byte and passive learning is
  starving), attribution-tier counts in `graph_meta`;
  `PathGraph`-tagged AppDebugLog entries for every findPath decision
  (candidates + tiers + chosen path or flood-reason), observation, and
  supersede event; debug-screen dump of graph/ingress state.
* **v1 UI — DECIDED path-mode model**: for every DM (and repeater/room
  login), the user chooses exactly one of four modes, defaulting to
  **Auto**:
  1. **Auto** (default) — the module decides per send (bidirectional
     path, zero-hop direct, or flood).
  2. **Direct** — force empty path (user knows the contact is in RF
     range).
  3. **Flood** — force flood.
  4. **Manual** — user-entered hop list (existing `parsePathHex` entry).

  This four-way choice *is* the complete setting — it dissolves the
  override-provenance problem: the module never writes the user's mode;
  it supplies a path at send time only in Auto. In Direct/Flood/Manual
  the module still observes and records outcomes (`reportSendResult` +
  `observePath`) — a working manual path is free proven evidence.

  **ONE dialog (decided 2026-08-05)**: a single shared path-mode widget
  used by every call site. Verified current spread: THREE separate
  implementations (`PathSelectionDialog` manual entry,
  `PathManagementDialog` history/management, an inline picker in
  `chat_screen`) invoked from TEN call sites (chat, map, path-trace map,
  neighbors, telemetry, room login, repeater login, repeater
  cli/settings/status screens). All collapse into one `PathModeDialog`:
  four radio modes with the manual hop-entry form embedded as Manual's
  detail. `PathManagementDialog` dies with `path_history_service`; the
  ten call sites all invoke the one widget.
  Remaining UI surfaces: β setting; **location source setting** (Off/
  manual default | radio position | phone GPS opt-in — see Position in
  the hooks list); import screen (URL, file identity, generatedAt,
  wrong-region warning, map-tap home position); "why this path / why
  flood" tap-through; **map tab integration** — draw the module's path
  for a selected contact, with a manual trace trigger whose results feed
  back as proven evidence (traces are user-initiated only).
* **Testing**: unit-pure — cost-function properties (β=1 → pure
  reliability; each hop multiplies path score by exactly β), multi-source
  Dijkstra incl. the loud-dead-end case, decay/slash math, tier gating as
  *property tests* (inferred never creates edges or crosses the
  bidirectional threshold), prefix rule, import collapse with the 4 known
  2-byte collisions, region swap. Bench (two radios + repeater F857):
  edge-direction assert from a channel message; cold-start
  flood→learn→direct cycle; ladder ordering on repeater loss; backlog
  reconnect behavior.
* **Background scope (v1)**: observe only while foregrounded/connected;
  position stamps from last-known coarse fix with an explicit
  "position unknown/stale" state that falls back to time-only staleness
  (iOS when-in-use gives no background fixes); background learning out of
  scope.
* ~~Cold-start dormancy~~ — **dissolved** by the findPath-every-send
  decision: the module is never dormant, and `reportSendResult` flows on
  every DM.
* **Name-collision cap**: `uniqueName`-tier ingress rows capped to a
  minority weight share per contact and never outranking a live `proven`
  row — sustained name-collision poisoning becomes a bounded nuisance,
  not a downgrade-to-flood DoS.
* **Hub demotion guard**: the penultimate-vs-final demotion is vetoed by
  live `proven` evidence for that repeater — a doorstep that is *also* a
  transit hub must not be punished for its transit traffic.

## Open questions — ALL RESOLVED (2026-08-05)

1. **Trace policy — DECIDED: manual only, from the map tab.** The module
   never fires traces on its own. The map tab integrates with the module
   to *visualize* its paths, and the map's existing trace mechanism can
   probe a shown path on user demand; trace results feed back into the
   module as top-grade proven evidence (per-hop, both directions).
2. **When does findPath run — DECIDED: every DM send.** The
   firmware/companion's own path data is poor, and the app can specify
   the path per-DM at send time (it tells the firmware). The module is
   the path authority for app-initiated DMs: bidirectional route or
   flood, every send. This also dissolves the review's "cold-start
   dormancy" concern — the module is always exercised and
   `reportSendResult` always flows.
3. **Zero-hop — DECIDED: first-class.** Direct receptions of the contact
   (hop count 0) are recorded as a "direct" pseudo-candidate in their
   ingress data; an empty path naturally wins the cost race (zero edges)
   while that evidence is fresh. Hiking-together / no-repeater-in-range
   is a primary scenario. Direction caveat stands: hearing them proves
   the downlink, the uplink is a reciprocity guess until their ACK — the
   ladder validates at the cost of one retry.
4. **`path_history_service` — DECIDED: remove entirely** (it is broken and
   confusing; all in-app path generation is removed — the module is the
   sole source of truth). Salvage findings from reading the code
   (2026-08-05):
   * **Hook points = migration map.** Every PHS call site is where a
     module input belongs: `_handlePathUpdated` (0x81 + contact sync) →
     `observePath` of the firmware-learned out_path (forward-proven);
     `_recordPathResult` (ACK/timeout) → `reportSendResult`;
     `recordFloodPathAttribution` → the flood-handshake ingress harvest;
     the `selectPathForAttempt` retry callback → `findPath`.
   * **Its reliability formula validates our estimator**:
     `(success+1)/(attempts+2)` is the Laplace/Beta pseudocount form the
     review prescribed for calibrated p — already proven in production,
     just at whole-path granularity.
   * **Trip time**: PHS tracked `tripTimeMs`; the module should too —
     `reportSendResult` carries it (tiebreaker + feeds
     `timeout_prediction_service`, which is NOT path generation and
     stays, along with `DeliveryObservation`).
   * **Map drawing survives**: `map_screen` already draws PHS paths —
     the map-tab integration reuses that rendering with the module as
     data source.
   * **Per-contact flood stats** (success/failure/lastTrip) are worth
     keeping in the module — feeds "why flood" UI and contact mobility
     inference.
   * Why it failed (validates the rebuild): whole-path records can't
     generalize, failed paths are deleted with their information,
     cross-contact repeater knowledge never shared, and half the file is
     async deferred-load machinery forced by per-contact JSON-prefs
     storage — a class of complexity the module's single Drift DB
     eliminates.
   * Removal inventory: service + `path_history.dart` +
     `path_selection.dart`, ~8 connector call sites, retry-service
     callback, main.dart provider, `path_management_dialog` +
     `chat_screen` picker + `map_screen` data source, StorageService
     path-history keys (one-time stored-JSON cleanup), and
     `chat_pathHistoryFull` l10n strings (~20 locales).
   * **Removal methodology (decided)**: path selection is buried all over
     the app — don't hunt by grep. **Rename/delete the service first and
     lean on the compiler**: `flutter analyze` enumerates every burial
     site mechanically; the error list is the checklist. Grep only for
     dynamic/string-keyed remnants (storage keys, l10n) afterward.
5. **Uplink SNR in Discover responses — ANSWERED by review: yes.**
   Response byte 1 is the SNR at which the repeater heard our request;
   arrives via 0x8E `pushCodeControlData`; the app currently skips the
   byte. Parse it.
