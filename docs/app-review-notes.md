# App Review notes

Paste-ready text for App Store Connect review forms. Keeping it here means it
does not have to be rewritten for every submission.

## App Review Information → Notes

Use for both Beta App Review (external TestFlight) and App Store review. This
is the main defense against a Guideline 4.2 (minimum functionality) rejection:
a reviewer without a LoRa radio sees an empty scanner screen, and these notes
are what tells them that is correct behaviour.

```
MeshTrax is a client application for MeshCore LoRa mesh-networking radios
(https://meshcore.co.uk/). It is a companion app: it requires a physical
MeshCore device, connected over Bluetooth LE or USB serial, to do anything
beyond its initial screen.

Without hardware, the app launches to a scanner screen that lists no devices.
This is correct behaviour, not a crash or an incomplete feature. Bluetooth
permission is requested on first launch so the app can scan for these devices.

Camera and photo library permissions are used only to scan QR codes for
joining communities and channels.

There is no account system, no login, and no server component — all
communication is directly between the phone and the LoRa device over
Bluetooth/USB, and then over the LoRa mesh.

Source code: https://github.com/venamartin/meshtrax
```

If possible, attach a short screen recording of the app connected to a real
MeshCore device — it materially reduces the rejection risk.

## Beta App Description (TestFlight → Test Information)

```
MeshTrax is an open-source client for MeshCore LoRa mesh networking devices.
Connect to a MeshCore device over Bluetooth LE or USB serial to send and
receive messages across the mesh, manage contacts and channels, view nodes on
a map, and administer repeaters.
```

## Privacy Policy URL

```
https://github.com/venamartin/meshtrax/blob/master/docs/privacy.md
```

## Export compliance

Not settled — do not answer from memory. The app implements its own AES-128
ECB + HMAC-SHA256 over MeshCore channel payloads (`_decryptPayload` in
`lib/connector/meshcore_connector.dart`), which is not covered by Apple's
TLS/OS-provided/auth-only exemptions. See the "Export compliance" section in
[../TESTFLIGHT_GUIDE.md](../TESTFLIGHT_GUIDE.md) before answering the
questionnaire, and leave `ITSAppUsesNonExemptEncryption` unset in
`ios/Runner/Info.plist` until the question is resolved with someone qualified.
