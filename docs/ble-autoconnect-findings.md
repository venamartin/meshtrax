# BLE auto-connect / naming — diagnosis in progress

Branch: `fix/ble-autoconnect-control` (off master @ 1.7.16+25).
Nothing implemented yet. Written before a context compaction so the
line-level detail does not have to be re-derived.

Three reported problems:

1. Auto-connect cannot be cancelled; selecting another device while it
   is trying does nothing.
2. Disconnecting immediately auto-reconnects; a manual disconnect should
   turn auto-connect OFF.
3. The companion name sometimes comes back stale after a rename.

---

## 1. Selecting another device during auto-connect — CONFIRMED

`lib/connector/meshcore_connector.dart:1533`, in `connect()`:

```dart
if (_state == MeshCoreConnectionState.connecting ||
    _state == MeshCoreConnectionState.connected) {
  return;                       // silently
}
```

While the launch auto-connect is in flight the state is `connecting`, so
tapping a different device returns immediately — no connect, no error,
no feedback. This is the *same bug class* as the USB picker fix in PR
#72, where `connectUsb` was silently refused mid-attempt; that was
solved by `suspendBleAutoReconnect()` (`:2273`), which cancels the
reconnect timer, sets `_manualDisconnect = true`, and aborts an
in-flight BLE attempt.

**Fix shape:** a BLE connect request for a *different* device id should
abort the in-flight attempt and proceed, rather than returning. Plus a
visible cancel affordance on the scanner while auto-connecting —
`scanner_screen.dart:71` fires `autoConnectToLastDevice()` and the UI
shows no way out of it.

Relevant state:
* `autoConnectToLastDevice()` — `:2232`, guarded by
  `_launchAutoConnectAttempted` (once per process) and the
  `autoConnectLastDevice` app setting.
* `suspendBleAutoReconnect()` — `:2273`.
* Setting lives at `app_settings.dart:57` / toggled in
  `app_settings_screen.dart:165`.

## 2. Reconnect after a manual disconnect — NOT YET EXPLAINED

On paper this is already blocked:

* `disconnect({bool manual = true})` — `:2320`; when `manual` it sets
  `_manualDisconnect = true` and cancels the reconnect timer (`:2342`).
* `_shouldAutoReconnect` — `:2192` — requires `!_manualDisconnect`.
* Every UI disconnect passes manual: `scanner_screen.dart:96`,
  `tcp_screen.dart:74`, `usb_screen.dart:85`, and
  `map_screen.dart:1589` (bare `disconnect()`, whose default is
  `manual: true`).

`_scheduleReconnect()` is called from three places — `:2315`, `:2441`,
and `:7170`. `:7170` is the unexpected-drop teardown and is gated
correctly.

**NEXT STEP: read `:2441` and its enclosing function** — most likely the
flutter_blue_plus `connectionState` listener. Hypothesis to test: the
stack's own disconnected event arrives *after* our manual disconnect
completes and re-enters a path that clears `_manualDisconnect`, or the
flag is reset by one of `:1301`, `:1405`, `:1559` (all
`_manualDisconnect = false` on a connect attempt) racing the teardown.
Do not write a fix before confirming which.

## 3. Stale companion name — ANSWERED

`deviceDisplayName` — `:436` — resolves in priority order:

1. `_selfName` — parsed from the device-info frame at `:4476`. The
   companion's real, current name.
2. `_device?.platformName` — **Android's cached BLE name.** The OS
   caches the GATT device name and does not refresh it when the device
   renames itself. This is the stale value.
3. `_deviceDisplayName` — our own cache from the scan, persisted as
   `_lastDeviceDisplayName` (`:1552`–`:1558`).

So the correct name only appears once SELF_INFO arrives. Before that —
in the scanner list and for the whole of connecting — the user sees
Android's cached name. That is why it is intermittent: it depends
whether you look before or after the handshake.

**Fix shape (design decision needed):** we cannot clear Android's GATT
cache from Flutter. Options: prefer our own `_lastDeviceDisplayName`
over `platformName` once we have ever learned a `_selfName` for that
device id; or cache `selfName` per device id and show that in the
scanner list. Worth deciding with the user rather than guessing.
