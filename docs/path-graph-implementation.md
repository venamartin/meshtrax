# Path Graph Module — Implementation Plan

Status: plan approved pending review — no code yet.
Design reference: `docs/path-graph-design.md` (design complete, all
questions resolved).
Created: 2026-08-05.

## Guiding structure

Three layers; only the middle one ever moves:

```
raw frames (MeshCoreConnector.receivedFrames — already exists)
        │
   FRAME ADAPTER — all low-level packet parsing lives here.
        │            During verification: inside path_lab.
        │            At integration: moves into the connector, unchanged.
        │
 typed module inputs (observePath / ingestNode / observeDiscoverResults /
        │             reportSendResult / ingestContact / importGraph / ...)
        │
   path_graph PACKAGE — pure Dart + Drift. Never parses wire bytes.
                        Never moves, never rewritten.
```

The verification phase (Phase 0–2) **touches no MeshTrax app code**: the
harness subscribes to the existing raw frame stream and does its own
parsing. If verification fails the go/no-go gate, the app is untouched
and we stop.

## Phase 0 — the package (pure logic, no GUI, no radio)

Deliverable: `packages/path_graph/` — a standalone Dart package the app
will later import unchanged (one `path:` dependency line at Phase 3).

**Package decision (2026-08-05): true separate pubspec, pure Dart.**
The isolation invariant becomes compiler-enforced: the package cannot
import `package:meshtrax` (dependency cycle — refused), and the app sees
only the exported API. No Flutter dependency → tests run under bare
`dart test` (fast, no widget binding). Dependencies: `drift` and nothing
else — the package takes an injected `QueryExecutor` (app passes
`drift_flutter`'s for `path_graph.db`; tests pass
`NativeDatabase.memory()`), keeping platform glue out entirely. CI gains
two lines: `dart analyze` + `dart test` in the package (the app's
`flutter analyze` won't cover it). A separate git repo was considered
and rejected for now — too much friction while the API may still flex;
the monorepo package keeps extraction a folder-copy away.

* Drift database (`path_graph.db`): `graph_nodes`, `graph_edges`
  (s/n + trafficWeight + measuredSnr), `contact_ingress`,
  `known_contacts`, `graph_meta` (+ counters). Own schema v1.
* In-memory adjacency working set; debounced flush; lazy decay
  (ArrivalClock-style arrival timestamps only).
* The full API surface from the design doc — nothing more:
  `observePath`, `observeDiscoverResults`, `reportSendResult`,
  `ingestNode`, `ingestContact`, `setRadioIdentity`, `importGraph`,
  `findPath` → direct | bidirectional path | flood (+ a read-only
  `snapshot()` for UI/debug rendering).
* Evidence machinery: proven/inferred tiers, last-hop prior with hub
  demotion (+ proven veto), calibrated p via Beta pseudocounts with the
  two-layer prior (`q₀` from importedScore/avg_snr/measuredSnr,
  traffic-scaled n₀), epoch-limited floored slash, mobility decay with
  optional position gating.
* Search: multi-source/multi-target Dijkstra on the bidirectional
  subgraph, `−log(p) + τ` cost, alternatives via edge penalties,
  32-hop budget, 2-byte-only ingest with drop counters.
* **Unit tests** (the design doc's testing list): cost-function
  properties (β=1 → pure reliability; each hop multiplies path score by
  β), loud-dead-end candidate case, decay/slash math, tier gating as
  property tests (inferred never creates edges nor crosses the
  bidirectional threshold), import layering idempotence, region
  add/remove, GC.
* **Offline corpus tests**: import `tools/generate_graph.py` output;
  replay a recorded frame-observation log (captured in Phase 1) through
  the API and assert graph state. The corpus becomes a permanent
  regression suite.

## Phase 1 — path_lab (the harness GUI)

Deliverable: `test/path_lab/` — run with
`flutter run -d windows -t test/path_lab/main.dart`. Never ships.
Imports `package:meshtrax` (connector, map widgets) and
`package:path_graph`. **Zero modifications to lib/.**

* **Frame adapter** (`test/path_lab/adapter/`): subscribes to
  `receivedFrames`; parses ADVERT (full pubkey + name/position + path),
  GRP_TXT paths (incl. variants), control-data discover responses
  (uplink SNR byte), path-returns (payload + packet paths), contact
  frames → feeds typed module inputs. Also: send-outcome taps and an
  observation recorder (writes the replay corpus for Phase 0 tests).
  This code is written to connector standards — it migrates verbatim in
  Phase 3.
* **GUI** — the interactive HTML page, live:
  * flutter_map view (reuse the app's map/tile setup): nodes colored by
    role/quality, edges by score, bidirectional vs one-way styling.
  * findPath panel: pick contact (or any two nodes), show result +
    alternatives + est. delivery + why-flood reason.
  * Live feed: observations/min, drop counters (1-byte share!),
    graph size, bidirectional-subgraph fraction.
  * Buttons: **Discover** (with uplink SNR results), **Trace** a shown
    path (map-tab mechanism; results feed `measuredSnr`), **Import**
    (load meshtrax-graph-*.json), **Send test DM** via chosen path
    (drives `reportSendResult`).
* Runs against the two-radio bench (COM + BLE + repeater F857) and
  against the live Bay Area mesh from home.

## Phase 2 — verification campaign (the "worth it" gate)

Metrics, defined before running:

1. **Coverage**: after import + 24–48 h passive listening on the live
   mesh, fraction of `findPath` calls to real contacts returning a
   route vs flood. This empirically tests the "bidirectional subgraph
   too sparse" risk — the one design concern that review couldn't
   settle on paper.
2. **Correctness**: ACK rate on module-chosen paths vs flood baseline
   (bench + live mesh).
3. **Freshness**: cold-start time-to-first-usable-path; behavior on the
   drive-around scenario (egress churn, Discover-with-send).
4. **Honesty**: trace module-chosen paths; compare predicted quality vs
   measured per-hop SNR.
5. **Environment**: 1-byte drop share of local traffic (a finding about
   the neighborhood, not the module).

**Go/no-go**: if coverage is near-zero after honest tuning, or module
paths lose to flood on ACK rate, stop — the app is untouched. Otherwise
proceed to Phase 3.

## Phase 3 — app integration (only after the gate passes)

1. **Adapter migration**: move `test/path_lab/adapter/` parsing into
   the connector (RX-log parse extension, discover SNR byte, 0x8D
   path-discovery handler, `CMD_SEND_PATH_DISCOVERY_REQ`).
2. **Module wiring**: app instantiates `path_graph`; pushes
   `ingestContact` refresh on connect, `setRadioIdentity` at
   device-info, send outcomes from the retry pipeline.
3. **Demolition** (design doc, resolved question 4): rename
   `PathHistoryService` → lean on `flutter analyze` to enumerate every
   buried path-selection site; remove the service, `path_history.dart`,
   `path_selection.dart`, storage keys (one-time cleanup), l10n
   strings. `timeout_prediction_service` + `DeliveryObservation` stay.
4. **One ladder**: module becomes `MessageRetryService`'s
   path-selection strategy (findPath every attempt; alternative on
   retry; Discover-with-send mobile collapse; flood last).
5. **One dialog**: `PathModeDialog` (Auto default | Direct | Flood |
   Manual) replaces the three implementations at all ten call sites;
   manual hop-entry form reused from `PathSelectionDialog`.
6. **Map tab**: draw module path for selected contact (reuse existing
   path drawing); manual trace trigger feeds back.
7. **Settings/UI**: β slider, location-source selector (off/manual
   default | radio | phone opt-in), import screen (URL, identity,
   map-tap home position), "clear learned data" / "remove imported
   region", why-this-path tap-through.
8. **Observability**: `PathGraph`-tagged AppDebugLog decision/
   observation/supersede entries; debug screen state dump.

## Phase 4 — hardening & release

* Bench integration suite (from the design doc): edge-direction assert,
  cold-start flood→learn→direct, ladder ordering on repeater loss,
  reconnect behavior.
* GC/caps enforcement pass; import contract validation (size caps,
  format rejection); privacy retention for position tags.
* Version bump, release notes (the layperson abstract is the draft).

## Explicit non-goals for v1

Background observation (foreground only), web target module support
(decide separately), location-keyed egress cache (v2), fabrication
defense (dropped), MeshTrax-to-MeshTrax egress-hint exchange.
