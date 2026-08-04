# Weighted Graph Path Determination Module for DMs

Status: design phase — no code yet.
Last updated: 2026-08-03.

A self-contained module that learns the local mesh topology from observed
paths and a seeded region graph, and answers one question: *given who hears
me and who hears my contact, what path bytes should this DM use?*

## Requirements

* Store for every contact: text name, public key, position, and a weighted
  list of the last "starting" repeaters that heard them. This includes
  myself/this node — we need to know what repeaters can hear me. Updated from
  the discover button and from the first repeater in a repeated message's
  path.
* The contacts database is the existing one. The module really only consumes
  the "starting" repeater list and possibly the position.
* Generate a "standard format" JSON weighted graph from a utility that grabs
  data from Corescope and puts the file on GitHub (not versioned).
* Even though discovered repeaters live in an app database, the weighted
  graph module is self-contained with its own repeater store — if we move to
  Southern California we load a graph for that area. Independent of the
  discovered contacts.
* The module has its own database for the weighted graph (name, position,
  public key, last heard, neighbors and signal strength, ...).
* Weights adjust as new data arrives.
* Every received message that has a path updates the weighted graph
  (in one direction only).
* Black box. Inputs:
  * any received path from any message (usually channel messages), for graph
    updates
  * a path request, needing only the starting repeater(s) and destination
    repeater(s) — both pulled from the contacts database's weighted lists of
    who hears me and who hears them
* Return is a best path. Ideal is bidirectional; otherwise best for send;
  if nothing is found, flood.

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
  repeater that heard me), a returned ACK, a trace round-trip, or the
  discover button. The existing repeat-echo detection is exactly the hook for
  this.

So the module needs two directed observation types: *ingress* (who hears
them) for contacts, *egress-capable* (who hears me) for self. Mixing "I hear
X" into "X hears me" silently corrupts the graph with plausible-but-unproven
edges — DMs would die with confident one-way paths labeled bidirectional.
Make the two observation directions separate types in the API so call sites
can't confuse them. **This is the riskiest part of the whole design.**

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
* Mixed-width traffic (width is per-packet): a legacy 1-byte observation is
  a prefix of the 2-byte bucket — apply it when exactly one bucket matches
  the prefix, drop it otherwise. A two-line check, not disambiguation
  machinery.
* At 2-byte width the geo radius on Corescope import is just
  belt-and-suspenders (at 1-byte it would be essential — collapsing a whole
  region into 256 buckets would create false edges between far-apart
  same-hash repeaters). Since the import file keeps full pubkeys, the app
  can re-collapse at a different width whenever the mode changes.
* Name/position become best-effort node metadata; multiple claimants render
  as "A | B" like `PathHelper.resolvePathNames` already does.

### 3. Query API takes candidate *lists*, not a single pair

```
findPath({myEgress: [(repeater, weight)...], theirIngress: [(repeater, weight)...]})
```

The best overall route often isn't through the #1 candidate on each side —
my strongest repeater might have no route to theirs, while my #2 → their #2
is two hops. Multi-source/multi-target Dijkstra handles this in one search
(virtual source node with edges to all my candidates weighted by candidate
confidence, same on the destination side). Same algorithm cost, still a
black box — the contacts layer hands over the whole weighted list.

## Return contract

Three-tier return maps to a two-pass search:

1. **Bidirectional pass**: search only the subgraph of edges where *both*
   directions exceed a confidence threshold. Found →
   `PathResult(bytes, bidirectional)`. This is the path an ACK can retrace.
2. **Send-only pass**: full directed graph. Found →
   `PathResult(bytes, sendOnly)` — message likely arrives, ACK may not
   return, so the send pipeline shouldn't retry-storm on missing ACK.
3. **Flood**: no route above minimum confidence, or path exceeds byte/hop
   budget → `PathResult.flood()`. A low-confidence guessed path is *worse*
   than flood (flood is reliable, just noisy) — keep the flood threshold
   aggressive.

Cost function — use the log-reliability form: treat normalized edge weight
as a delivery probability *p*, and set

```
edge cost = −log(p) + τ,   τ = −log(β)
```

Minimizing the sum maximizes end-to-end delivery probability (sums of logs =
products of probabilities), and β is the one tunable knob with a concrete
meaning: *an extra hop hurts exactly as much as multiplying path reliability
by β*. β≈0.9 default (a hop ≈ 10% reliability loss — in LoRa every hop is
airtime and collision risk); β→1 routes purely by signal quality; β→0.5
approaches min-hop routing. This subsumes the earlier `hopPenalty + 1/weight`
sketch (`1/p` is the ETX metric; −log(p) is its principled cousin). Cap paths
at `maxPathSize` (64 bytes → 32 two-byte hops). Prototyped in analyze.py's
interactive HTML as the "Reliability" cost mode with a β slider.

## Weight model

* **Edge weight**: EWMA with time decay — `w = w·λ^Δt + k` per observation.
  Store `(weight, lastObserved, observationCount)` per directed edge; decay
  computed lazily at read time so there's no background job.
* **Seed vs. local**: imported Corescope edges get a *prior* weight scaled
  from their `score`, flagged `source: imported`. Local observations
  dominate quickly — the analyzer's view is region-wide and days-stale; the
  radio's view is ground truth for the local RF neighborhood.
* **ACK round-trips are gold**: a successful direct-DM ACK proves every hop
  in *both* directions in one shot (the ACK retraced the path). Strongest
  single reinforcement signal. `reportSendResult(path, success)` is a
  first-class input alongside `observePath`.
* **Failures**: a failed direct send can't localize which hop broke — apply
  a small penalty across the path's forward edges, let flood-discovery of a
  new path do the real correction. Mirrors what
  `PathRecord.successCount/failureCount/routeWeight` does per whole-path;
  this module generalizes it per-edge.

## Storage & module shape

Self-contained module with its own Drift tables (fits the
channel-core-rebuild direction):

* `graph_nodes`: hashBytes (2 bytes) + region (PK), stride, name(s), lat,
  lon, lastHeard, source (imported/observed/advert), full pubkey as metadata
  when known (enables re-collapse at a different width, e.g. future 4-byte)
* `graph_edges`: fromHash, toHash (composite PK, *directed*), stride,
  weight, lastObserved, obsCount, source, nullable importedScore/avgSnr
* `graph_meta`: import file identity, generatedAt, home position + radius
  used for the geo-scoped collapse — "load Southern California" = swap rows
  where region matches; wipe locally-observed edges on region swap (stale
  cross-region edges are pure noise)

Contact ingress lists live with contacts (per-contact facts, not graph
facts): `contact_ingress(contactPubkey, repeaterHash, weight, lastSeen)` —
self is just another row keyed by my pubkey. Hash-keyed end to end, matching
the graph.

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
  *ACK-grade* bidirectional evidence — seed them as moderate-confidence
  priors in both directions and let local observation (ACK round-trips)
  provide the real directionality signal.
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

Small script (next to analyze.py, sharing its fetch/resolve code) that pulls
the two endpoints, filters to repeaters + rooms, and emits full pubkeys +
positions (the analyzer knows them — keep the file lossless; the *app*
geo-filters by home radius and collapses to hash buckets at import time):

```json
{ "format": "meshtrax-graph-v1", "generated_at": "...", "region": "socal",
  "nodes": [{"pubkey": "...", "name": "...", "lat": 0, "lon": 0, "last_heard": 0}],
  "edges": [{"from": "...", "to": "...", "score": 0.83, "avg_snr": 7.5,
             "bidirectional": true, "weight": 3791}] }
```

Edges carry the analyzer's `bidirectional` flag: `true` expands to two
directed prior-edges at import, `false` to from→to only. `weight`
(observation count) scales prior confidence. Published as a raw file on a GitHub
branch/gist/release asset, app fetches by URL — which also naturally enables
multiple region files.

## Open questions before implementation

1. **Discover button semantics** — existing advert/trace flow, or a new
   active probe? Trace round-trips are the cheapest way to actively confirm
   bidirectionality of a candidate path before trusting it for DMs; decide
   if the module may *request* probes or is strictly passive.
2. **When does findPath run** — every DM send, or only when the firmware's
   own `out_path` for the contact is flood/stale? The firmware maintains its
   own path per contact; this module competes with it via
   `pathOverrideBytes`. Scope v1 to: only propose a path when the contact is
   currently flood, never fight a working firmware path.
3. **Zero-hop case** — if the contact's ingress list and my egress list
   share a repeater, the answer is a single-hop path; if I've heard the
   contact *directly* (empty path), direct beats everything. The API should
   handle both without special-casing at the call site.
4. **Whether `path_history_service` folds in** — its per-contact whole-path
   records overlap heavily with what this module derives. Long-term the
   graph module could subsume it; short-term, keep separate and feed its
   success/failure events in as observations.
5. ~~Which hash width the local mesh actually runs~~ — **DECIDED: 2-byte**,
   and already the operating norm here (possibly 4-byte far future).
   Received paths carry whatever width the *sending* firmware used, so any
   remaining 1-byte traffic from stragglers is absorbed by the prefix rule
   above.
