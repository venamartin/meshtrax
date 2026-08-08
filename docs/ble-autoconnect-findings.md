# BLE auto-connect / naming — diagnosis in progress

Branch: `fix/ble-autoconnect-control` (off master @ 1.7.16+25).
All three are diagnosed and fixed; this is the record of why.
Line numbers are from the pre-fix file.

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

**Fix:** the guard now only short-circuits when the request is for the
device already in flight; a *different* id aborts the in-flight attempt
with `disconnect(manual: true)` and proceeds. The scanner grows a Cancel
button in the status bar while connecting (`cancelAutoConnect()`, which
also stops auto-connect for the rest of the process so the adapter-state
listener at `scanner_screen.dart:71` cannot restart it), and an
overflow-menu toggle for the auto-connect setting itself.

Relevant state:
* `autoConnectToLastDevice()` — `:2232`, guarded by
  `_launchAutoConnectAttempted` (once per process) and the
  `autoConnectLastDevice` app setting.
* `suspendBleAutoReconnect()` — `:2273`.
* Setting lives at `app_settings.dart:57` / toggled in
  `app_settings_screen.dart:165`.

## 2. Reconnect after a manual disconnect — CONFIRMED

**Root cause: BLE `connect()`'s catch-all runs the dropped-link path even
when the failure was caused by the user's own disconnect.**

`connect()` sets state to `connected` and *then* — still inside its own
`try` — awaits `_startBleInitialSync()` (`:2149`), which is
`_requestDeviceInfo()` → up to 6s waiting for SELF_INFO → `syncTime()`.
For that whole window the UI already says "connected", so this is
precisely when a user taps Disconnect.

The moment they do, `disconnect(manual: true)` tears down the link and
the in-flight sync's next `sendFrame` throws `Not connected to a MeshCore
device` (`:2451`). That lands in `connect()`'s catch, whose default arm
is `await disconnect(manual: false)` — and `manual: false` **sets
`_manualDisconnect = false`** (`:2347`) and then calls
`_scheduleReconnect()` (`:2441`). The user's intent is erased by the
error their own disconnect caused.

TCP already guards this exact shape with `shouldIgnoreLateTcpConnectError`;
BLE never got the equivalent.

The same arm also fires when another transport or another device takes
over mid-attempt, in which case `disconnect(manual: false)` tears down
the *successor's* connection.

**Fix:** `shouldIgnoreLateBleConnectError` — ignore the error when a
newer attempt owns the connector (`_bleConnectAttempt` counter), when the
active transport is no longer Bluetooth, or when a manual disconnect has
already taken the state to disconnected/disconnecting. Plus two
supersede checks inside `connect()` so a stale attempt that *succeeds*
doesn't clobber the live one's characteristics.

The rest of the mechanism was already correct:

* `disconnect({bool manual = true})` — `:2320`; when `manual` it sets
  `_manualDisconnect = true` and cancels the reconnect timer (`:2342`).
* `_shouldAutoReconnect` — `:2192` — requires `!_manualDisconnect`.
* Every UI disconnect passes manual: `scanner_screen.dart:96`,
  `tcp_screen.dart:74`, `usb_screen.dart:85`, and
  `map_screen.dart:1589` (bare `disconnect()`, whose default is
  `manual: true`).

`_scheduleReconnect()` is called from three places — `:2315`, `:2441`,
and `:7170`. All three are gated on `_shouldAutoReconnect`, so they were
never the problem; clearing the flag underneath them was.

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

The scanner made it worse: both `DeviceTile` and `_connectToDevice`
picked `device.platformName` **first** and only fell back to
`advertisementData.advName` — i.e. they preferred the OS cache over the
name the radio had just broadcast in the advert we were looking at.

**Fix:** we cannot clear Android's GATT cache from Flutter, so demote it
everywhere instead.

* Scanner and `DeviceTile` prefer `advName` (fresh, from this advert)
  and fall back to `platformName`.
* `deviceDisplayName` order becomes `_selfName` → `_deviceDisplayName`
  (ours, from the advert) → `platformName` → `Unknown Device`.
* When SELF_INFO arrives on BLE, adopt the radio's own name as
  `_lastDeviceDisplayName` and persist it, so the next launch's
  auto-connect shows the current name rather than a pre-rename one.
