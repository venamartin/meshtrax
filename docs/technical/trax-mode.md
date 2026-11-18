# TRAX mode: the radio part

> **What this is:** How TRAX mode moves a group's radios off the regular mesh and back: the button, the saved settings, the settings write, Tell the group, the group check and Leave. The TRAX extras (trip mode, the recorder, members asking my radio, position in adverts, SOS through Do Not Disturb) aren't built yet.
>
> **Who it's for:** developers working on MeshTrax.
>
> **Status:** built, not yet field-tested. Its decisions (31 to 34 in the location-sharing plan, #240) are preliminary: the desert field tests decide them. Firmware facts are from MeshCore companion-v1.18.0.
>
> New to the terms? See the [glossary](../glossary.md).

## What it does

Where there are no repeaters, radios reach each other only directly. TRAX mode moves the group's radios to an off-grid frequency with **Off-Grid Repeat** on, so every radio relays for the others. Nobody on the regular mesh hears a radio in TRAX mode, Public included.

- **The button:** the boot print from the notification icon, in the Chats and Map bars before the GPS and location buttons. Grey when off, the logo's orange (`#d23e0b`) when on. It opens the TRAX sheet: what one tap changes, or what is on now with the group check and Leave. Both link to TRAX settings.
- **On:** a radio is in TRAX mode when Off-Grid Repeat is on and its frequency is an off-grid one (`Trax.isOn`). The button shows it whichever phone switched the radio.
- **Code:** `lib/services/trax_service.dart` (the switch, Leave, prompts), `lib/models/trax.dart` (settings, saved radios, presets), `TraxMessage` in `lib/helpers/structured_message.dart`, the widgets `trax_button.dart`, `trax_sheet.dart` and `trax_dialogs.dart`, and `lib/screens/trax_settings_screen.dart`.

## TRAX settings

One set per phone, in the preferences store under `trax_setup`:

- **Preset.** The mesh's own (default): the off-grid frequency nearest the regular one, from the radio's allowed list (CMD 60), with the mesh's bandwidth, spreading factor and coding rate. In the US that is 918.000 MHz, 62.5 kHz, SF7, CR5. **Long range** (picked by hand): the same frequency at 250 kHz and SF11, the firmware's off-grid preset, with about 4 to 5 dB more link margin and 2.5 to 3 times the airtime.
- **Trip channel:** private channels only (`Channel.isPrivate`): not Public, not empty or nameless, and not a hashtag channel, whose key `sha256('#' + name)` anyone can work out. A `#` name cut at the radio's 31-byte limit can't be checked, so it counts as a hashtag channel.
- **Trip ends:** a date and time. Switching needs one in the future.
- **Tell the group:** on by default.

## One tap

`TraxService.start`, in this order:

1. **Save** the radio's frequency, bandwidth, SF, CR, TX power and repeat on the phone, under `trax_radio_<radio public key>`, before anything moves. They survive an app restart and another radio in between. The radio settings dialog's Off-Grid Repeat switch returns to the same place (`rememberNonRepeatRadioState`).
2. **Tell the group** (when on): post the TRAX message on the trip channel, then wait until the radio has sent it. A retune with the message still queued would send it on the new frequency. The app reads `CMD_GET_STATS` core (send queue length, byte 10) and packets (floods sent, bytes 10 to 13) before posting, then every 500 ms until the queue is empty and one more flood has been sent, at most 20 s. Unconfirmed, the switch goes ahead and the sheet says to tell the group another way.
3. **One settings write:** CMD 11 with its repeat byte on. The firmware applies it at once with no reboot (`radio_driver.setParams`) and saves it with `savePrefs`, which also stores the radio's current position as its fallback; so the sheet says to switch at the trailhead, after a GPS fix. A frequency the radio doesn't allow for repeat is refused, and a refused frame changes nothing.
4. **The group check:** one flood advert on the TRAX frequency. Every radio already there relays it. The sheet lists who has been heard there since the switch (adverts heard this run, `getLocalDiscoveredTime`): "3 heard on TRAX: Ana, Bo, Cy". **Check again** sends another advert. Asking a member's radio directly waits for Ask their radio.

### CMD 11 bytes

The firmware reads `[11][freq u32 LE, kHz][bw u32 LE, Hz][sf][cr][repeat]` (`MyMesh.cpp` 1424 to 1459 at the tag). Without the repeat byte, repeat goes off.

| | Bytes |
|---|---|
| Switch, US: 918.000 MHz, 62.5 kHz, SF7, CR5, repeat on | `0B F0 01 0E 00 24 F4 00 00 07 05 01` |
| Leave, back to USA/Canada: 910.525 MHz, 62.5 kHz, SF7, CR5, repeat off | `0B BD E4 0D 00 24 F4 00 00 07 05 00` |

## Tell the group: the TRAX message

Short readable text on the trip channel, MeshTrax only for now, parsed by `StructuredMessage.parse` like `Location:` and `Event:`. Its `TRAX` keyword keeps it out of SMAZ compression. It isn't in the public [message format](../message-format.md) yet.

```
TRAX: on until 2026-11-22 18:00 UTC-8
918.000 MHz 62.5 kHz SF7 CR5
```

```
TRAX: off
```

- **The end** is the sender's wall clock with its offset from UTC: `UTC`, `UTC-8` or `UTC+5:30`. Every phone knows the same instant, and a person reads the sender's local time. Phones show it in their own zone: "Ana switched to TRAX mode until Sunday 18:00. Switch too?"
- **The preset** line is frequency, bandwidth, SF and CR; Off-Grid Repeat is always on in TRAX mode. It is about 66 bytes in all.
- **Read strictly:** a missing end, offset or preset line, an impossible date, or a bandwidth, SF or CR the firmware wouldn't take make it plain text. Extra lines after the preset are kept and shown.
- **Leaving** is sent before the radio moves back, so it goes out on the TRAX frequency to the members still there.

**Receiving:** on a private channel only, and only for a message heard live (not from the radio's backlog), a phone asks, the same question at most once in 10 minutes: "Ana switched to TRAX mode until Sunday 18:00. Switch too?", or "Ana is leaving TRAX mode. Leave too?" It asks only when it fits: switching only when this radio is off TRAX and the end is still ahead, leaving only when it is on. **It never switches by itself:** one tap each, so a forged message can't take radios off the mesh. The message's card in the chat offers the same button while it applies. So does its notification on Android, for a phone in a pocket: **Switch too** or **Leave too** opens the app and asks the same question there, never switching from the notification. That notification has an id of its own per channel, so the chat after it doesn't take the button away, and a button that no longer fits opens the chat instead. iOS shows the notification without a button. Switching from a message uses the message's preset and end, posts nothing (the group has been told), and makes that channel and end this phone's TRAX settings.

## Leave

`TraxService.leave`: with Tell the group and a trip channel, post `TRAX: off` and wait as above (never blocking: without a channel it leaves untold), then write the saved settings back with repeat off, then the TX power if it changed. The saved settings are then deleted. A radio with nothing saved on this phone, because another phone switched it, asks which of the app's regular presets to return to; it picks one only when exactly one preset has this TRAX preset.

## On connect

Once per connection, when the radio has reported its settings:

- **In TRAX mode:** the button shows on. After the trip's end (this phone's switch, else TRAX settings), every connect asks: "Your radio is still in TRAX mode: the regular mesh can't hear you. Leave?" At most once in 10 minutes, so a radio that drops and reconnects doesn't stack the question.
- **Not in TRAX mode** with settings saved for it: something else took it back (another phone, the radio settings dialog), so the saved settings are deleted.

While it is on, Android's foreground notification reads "TRAX mode is on" and "The regular mesh can't hear you. Open MeshTrax to leave."

## At the trip's end

While the phone stays connected in TRAX mode, a timer waits for the trip's end. Then a notification says "Your trip has ended" and "Your radio is still in TRAX mode: the regular mesh can't hear you.", and the same question as at a connect comes over whatever screen is open. The notification has a category of its own, "TRAX mode" (`meshtrax_trax`), at default importance: not the SOS alarm. Tapping it asks the question again while it still fits; a question already open isn't put up twice.

- **A new end** in TRAX settings moves the timer, and while the radio is on it is this radio's end too. Following a member's TRAX message makes their end the timer's.
- **Leaving**, or the radio going away, cancels it. An end already past when it is set brings no notification: the next connect asks.
- **The timer** is a Dart timer. On Android the foreground service holds a wake lock while connected, so it fires on time. iOS suspends the app between radio events, and a suspended app runs no timers: there the notification can come late or not at all, and the question at the next connect remains.

## Side effects handled

- **Later settings writes keep repeat.** `setRadioParams` sends the repeat byte as on when the radio is known to repeat and the caller gave none. The radio settings dialog already sends the switch's state.
- **Health check:** `radio_frequency` and `radio_client_repeat` stay quiet in TRAX mode.
- **Nearby repeaters:** any retune clears them (`noteRadioSettingsSaved`); repeaters heard on the old settings can't hear the radio now.
- **Pathfinder:** it keeps one graph per mesh, keyed by frequency, bandwidth, SF and CR (`MeshId`), so the TRAX preset gets its own graph and Leave reopens the regular one. Between the retune and the reopen, frames and air events are dropped (`_onOtherMesh`), so nothing heard on TRAX lands in the regular graph.
- **Parked DMs:** unchanged. On TRAX, a flood relayed by a member (hop count over 0) wakes them as a repeater would.

## Not built yet (TRAX extras and open items)

- The TRAX extras in TRAX settings: trip mode, the recorder, members can ask my radio (Trip setup's grants, GPS on, `gps_interval:0`, favourites), position in adverts and SOS through Do Not Disturb. None exist yet; Leave will turn off what they turn on.
- Ask their radio, which would let the group check ask silent members one at a time.
- A **Leave** action on the Android notification: the foreground service has no channel from its isolate to the app yet. Tapping the notification opens the app.
- Field tests: whether a retune takes effect during a receive, battery life with repeat on, airtime with five radios relaying, and range with each preset.
