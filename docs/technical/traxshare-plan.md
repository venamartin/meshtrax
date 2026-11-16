# Location sharing on private channels: plan

> **What this is:** The build plan for sharing positions and short trails among the members of a private channel, over the radios, with no internet. Code name `traxshare`. It replaces an earlier draft spec written without access to the code. Its firmware and app facts were first checked against `./MeshCore` (tag companion-v1.18.0) and MeshTrax master `8b42148b` on 2026-11-05, and everything it takes from #210 against #210's head `9ba6f98`. A read-only audit and a safety review on 2026-11-15/16 rechecked them against master `d774d052` and the same tag ([audit and safety review](#audit-and-safety-review-2026-11-1516)).
>
> **Who it's for:** the developer or AI session building it.
>
> **Status:** active plan. Step 1 shipped as #243 (`af067e22`, v1.10.0); the rest isn't built. The work happens on branch `feat/traxshare` (draft PR). Decisions dated 2026-11-15 and later are preliminary; Martin wants them kept fluid until real-world tests. Items tagged SR-nn or CH-nn come from the 2026-11-15/16 safety review and are proposed (safety review, preliminary).
>
> New to the terms? See the [glossary](../glossary.md). The companion plan for saved routes, code name `traxbook`, is `docs/technical/saved-routes-plan.md` in #242 (branch `feat/saved-routes`).

## The feature in one paragraph

A member of a private channel taps **Where is everyone?** Each member who agrees answers once with their radio's GPS position, and, if they record their track, a short trail of where they've been. Answers show as pins and lines on the map and in a strip at the top of the channel, never as chat messages. A pin offers **Route here** through the offline routing from #210. Later in the plan, a member can start timed sharing for up to 4 hours, reaching people in direct radio range, and each member can turn on trip mode, which shares their position on a timer with no taps until a time they set (preliminary, 2026-11-16). A **TRAX mode** button switches the radio and the app into the group's off-grid setup, where every radio relays for the others (preliminary, 2026-11-16). Nothing goes to a server. Reports carry only the radio's GPS: the phone's own GPS is an opt-in local fallback for your own dot, Route here's start and the recorder, and it is never sent (decision 21, preliminary).

## Safety first (proposed 2026-11-16, preliminary)

This plan is for life-safety use. These rules come from the read-only safety review of 2026-11-15 ([index](#audit-and-safety-review-2026-11-1516)). They are proposed and preliminary, and the field tests decide them.

**The design setting**
- Remote desert trips, for example Death Valley: no cell service and no repeaters, so radios reach each other directly only; extreme heat; long dirt roads and canyons; and rescue that may be much delayed. NPS: "If you choose to travel on backcountry roads, be aware that rescue is likely to be extremely delayed." ([backcountry roads](https://www.nps.gov/deva/planyourvisit/backcountryroads.htm))
- About 5 people. Every radio has its own GPS. Phones are a mix of Android and iPhone.
- Boards to handle: RAK WisMesh Tag, Heltec V4, RAK 1 W radios (in vehicles) and Seeed T1000-E. Buttons, GPS handling and queue sizes differ by board, and tracker boards refuse `gps_interval` (TSX-02).
- The group is moving to MeshCore, with a PLB or satellite messenger for outside help (decision 7).

**Rules**, with the review's checkers' corrections:
1. **SR-01:** Never show a position without its age and where it came from: on the map label itself, in lists, on a route to a person, in SOS and on map flags.
2. **SR-02:** Call a position live only after this app has seen the radio's reading change (latitude, longitude or altitude) during this connection. Remember it per radio key across restarts, and let the live state expire; on master it never expires within a connection. Everything else is "last known" or "may be old", worded as the fact ("no change seen since 14:02"). Arrival time never makes old data fresh, and an older report never replaces a newer one. The altitude bench test comes first ([open question 10](#open-questions-for-martin)).
3. **SR-03:** Silence, a session ending, a restart or a radio change never ends, hides or deletes a last known position; only age past the retention time (30 days, decision 11) or a person removes it.
4. **SR-04:** Inside the approved time, the approval never lapses by itself. Sending stops while MeshTrax is swiped away, killed or suspended on an iPhone, or the phone is off after a heat shutdown; it resumes as soon as MeshTrax runs again, and the member and the group are told what wasn't shared. Only the radio's own answer (SR-06) covers that gap.
5. **SR-05:** Always tell people plainly when their own sharing or recording has stopped, paused or reached nobody, and why. Never a plain "Sharing" without when you last sent and when the group was last heard.
6. **SR-06:** In radio range, there is a way to find a member that needs neither their phone nor a tap: their radio's own answer to a position request ([Ask their radio](#ask-their-radio-and-trip-setup-decision-15-preliminary-2026-11-16)), set up before the trip. It needs the radio on and in direct range (or relayed in TRAX mode), GPS on, the asker held as a contact and allowed, and the request flooded. The answer can be a stored position.
7. **SR-07:** A call for help repeats until its sender cancels it. It alerts through MeshTrax's mute and, where the user allows, through Do Not Disturb, Focus and the silent switch. It also goes as DMs with receipts, sent once per member until their radio has it and again only after a real move, at most every 15 minutes, because repeated DMs can fill an away radio's queue.
8. **SR-08:** Nothing waits forever for a repeater or an answer that may never come. Where no repeater has been heard, an unanswered DM ends as "Failed · tap to resend" and is resent when the person is heard (decision 20). Every request has an end.
9. **SR-09:** A route never looks more certain than it is. The traxbook plan (#242) holds this rule; here, a route to a person carries the time of the position (CH-33).
10. **SR-10:** Nothing is relied on before its field test, with real radios and both phone types (decision 7). The help text says to carry a PLB or satellite messenger, because MeshCore can't call outside help.

The [field tests](#field-tests-proposed-preliminary) check these rules.

## Start here: working rules

These are how the owner, Martin, runs this repo. A session in a new worktree doesn't see the project's memory, so they're written out here.

**Git**
- `git fetch origin`, then branch from `origin/master`, never from local master. Work in a worktree (`git worktree add ../meshtrax-<topic> <branch>`); other sessions share the main checkout and may switch its branch. Stop processes by PID, never by name.
- Never commit on master. Stage named files only, never `git add -A`.
- Commit locally. Push only when Martin has tested and says so: the repo is public.
- "Ship it" means push, open or update the PR, wait for the `analyze` check, squash-merge, delete the branch, sync master. It counts only when Martin types it in that session, and it never means a store release.

**Test builds for Martin's phone**
- Bump the version (patch and build number) above what is on his phone. Test builds start at build number 205 or higher (2026-11-16). Check `origin/master`'s `pubspec.yaml`, the tags and other open branches first.
- Commit the bump, then build with `./buildapk.sh`, never `flutter build apk`. Hand over `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.
- A worktree lacks three untracked files: copy `buildapk.sh`, `android/key.properties` and `giphy.key` from the main checkout. Never commit `giphy.key`. `pubspec.lock` is tracked since #276: don't copy it, and change versions only in a PR of their own.
- Ask Martin whether the bump stays in the PR. For #229 he had the test bumps reverted before merging.

**Radios**
- Firmware truth is the git-ignored checkout `./MeshCore` in the main repo folder; on the Pi it is `~/code/MeshCore`. Read the tag with `git show companion-v1.18.0:<path>`: the Pi's checkout has an uncommitted experiment in `src/helpers/BaseChatMesh.cpp` that sends no DM ACKs at the default setting, so never build a field radio from it. Comments and docs are not evidence; read the code path.
- Heavy or repeated transmissions go on 920.000 MHz only. On the live mesh (910.525 MHz), send at most a couple of frames.
- Never retune a radio in the US to 869 or 433 MHz. 869 MHz is a cellular band there and 433 MHz needs an amateur licence.
- Ask before touching repeater F857. Bench radios and addresses are in `integration_test/harness/bench_config.dart`.

**Screens and text**
- Plain words on screen. Keep "airtime", "hop", "flood" and "zero-hop" off everyday controls; say what they mean ("people in direct range").
- Every new string goes in all 18 language files (`lib/l10n/app_*.arb`), with no hard-coded text.
- Import Material widgets from `package:material_ui/material_ui.dart`, never `package:flutter/material.dart`.
- Dates and times go through `DateTimeHelper`; distances through `GeoFormat.distanceText` with the user's unit setting; coordinates follow #210's coordinate-format setting (#210 merged in v1.10.0).
- Never name other apps in code, docs, commits or PR text.
- Before an APK with a new screen, render it at phone size (1080×2340 at 2.625) with real fonts and look at it. Widget tests use a block font and hide layout problems.

**Tests**
- Inject clocks. Connector code calls `DateTime.now()`, which `fakeAsync` doesn't move.
- A test with a non-English locale uses `appLocalizationsDelegates` (`lib/l10n/l10n.dart`), not the generated delegates.
- Run `flutter analyze --fatal-infos --fatal-warnings`, as CI does.
- Known Windows-only failures, not caused by a branch: `contact_advert_evidence_test` (timing), traxmap's `style_registry_test` (4) and `gap_fill_provider_test` (2). CI runs the full suite on Ubuntu.
- After `flutter test` or `pub get`, line-ending-only changes appear in `lib/l10n/` and the plugin registrants: `git checkout -- lib/l10n linux macos windows`.
- `build_runner --delete-conflicting-outputs` deletes the checked-in `lib/l10n/*.dart`; restore them from git.
- Multi-line `sed` or `perl` edits fail on this CRLF tree.

**Working with Martin**
- Put open decisions in the question dialog, one per decision, with your recommendation first.
- Decisions from 2026-11-15 on are preliminary ([owner decisions](#owner-decisions)). After a field test, ask again rather than treat an old answer as binding.
- Don't start review agents unless he asks.
- The mesh simulator runs in its own session (`meshsimulator-0f`, repo `../meshsimulator`). Ask it by message whether it can run a five-member test. It must not touch the meshtrax checkouts.

## Owner decisions

Decisions from 2026-11-15 on are preliminary: Martin wants them kept fluid until real-world tests. A number in brackets, such as (8), is his question-dialog number from 2026-11-15/16; [the next section](#preliminary-decisions-alternatives-and-what-decides-them) gives the alternatives and the test that decides each.

| Topic | Decision | Date |
|---|---|---|
| Which channels | Private channels only. Never Public, hashtag channels or rooms. One exception: an SOS may also go to Public (17). | draft spec; SOS 2026-11-16, preliminary |
| Relying on it | The group is moving to MeshCore. A PLB or satellite messenger covers outside help, and each feature's field test comes before anyone relies on it (7). | 2026-11-16, preliminary |
| Position source | Reports carry the radio's GPS. The phone's GPS is an opt-in local fallback for your own dot, Route here's start and the recorder whenever the radio has no live position, and it is never sent (21; was: the radio's GPS only, no new permissions, 2026-10-31, kept as decision 2 on 2026-11-15). | 2026-11-16, preliminary |
| Group size | Designed for up to about 5 | 2026-10-31 |
| Where positions show | The map, plus a sharing strip in the channel. Never chat rows: no unread count, Reply or React. | 2026-10-31 |
| Consent | Ask every time, outside trip mode. Each member can turn on trip mode for one private channel: it answers and shares with no prompt until its end time (8; was: ask every time, no always-approve, 2026-10-31). Nothing is approved per sender, because any member can forge the sender ID in a packet. | 2026-11-16, preliminary |
| Position in a DM | The existing Telemetry request. No new format. Offered on each person as **Ask their radio**, with Trip setup for the trip members (15), whose items live in TRAX settings (31). | 2026-10-31; Ask their radio 2026-11-16, preliminary |
| Own track | The recorder, its own feature: start and stop, no cap, times kept, a list of tracks. This plan's trail and traxbook's "Save my track" read from it (1; was: opt-in, kept by distance, default 10 miles, never by age, 2026-10-31). | 2026-11-16, preliminary |
| Reach of a one-time reply | The position may go through repeaters. A reply with a trail stays in direct range. | 2026-10-31 |
| Sessions | Inside the approved time, sharing stops only at its end time or on Stop (9; was: pause after 12.5 minutes without the requester, end when the app is killed). The 240-minute cap stays for now, with a warning and Renew before the end (12). Out of touch at the end time, a phone keeps sending every 10 minutes until Stop (13). | 2026-11-16, preliminary |
| Pins | A pin never ends on silence (10; was: ended after `1.2 × heartbeat + 1 interval`). | 2026-11-16, preliminary |
| Others' positions and trails | Removed 30 days after they arrived (11; was: 7 days, decision 4, and before that kept by distance, never by age). | 2026-11-16, preliminary |
| Where the data lives | One sharing database per phone, not per radio (14; was: one file per radio). Route here to a person is kept there, never in phone backups or Export database (6a). | 2026-11-16, preliminary |
| TRAX mode | One button switches the radio and the app into the group's off-grid setup and back: the radio's settings are saved on the phone, then the off-grid frequency (918.000 MHz in the US) with the mesh's own bandwidth, spreading factor and coding rate, and Off-Grid Repeat on, plus the trip extras ticked in TRAX settings. The group switches together through Tell the group. Its radio part is its own PR, after the DM fix and the minimal SOS (31–34; was: a minimal off-grid mode with Step 4, decision 19, and before that the full mode later, own PR, after field use, 2026-10-31). | 2026-11-16, preliminary |
| Automatic reports on the regular mesh | Sessions and trip mode stay zero-hop there and never go through repeaters; they flood only on an off-grid frequency. One-time requests and Ask their radio still go through repeaters (30). | 2026-11-16, preliminary |
| Order across the two plans | Location sharing first, through Step 4 and its field tests; traxbook (#242) after, kept in mind meanwhile (35; was: interleaved with this plan's steps). | 2026-11-16, preliminary |
| When a phone is dead | Trip members' adverts update their pins, and Trip setup offers position in adverts for the trip (18). A radio that beacons on its own is not taken for now (28), so a dead phone means a silent member unless someone asks their radio or the member presses its button. | 2026-11-16, preliminary |
| SOS | A minimal SOS on today's SOS message, in its own master PR before Step 3, after the DM fix (16). Its dialog offers "Also send to Public", ticked, first send only (17). | 2026-11-16, preliminary |
| Direct messages | A flood DM is parked only if a repeater was heard in the last 10 minutes, fixed on master first (20; was: parked until a repeater is heard). | 2026-11-16, preliminary |
| Package name | `packages/traxshare` | 2026-11-05 |
| PR shape | This draft PR becomes the feature PR: Steps 2–4, with Martin testing between steps. Step 1 went first in its own small PR (#243). The master safety fixes come first, each in its own PR (20, 16, 29). | 2026-11-05; master fixes 2026-11-16, preliminary |
| Order against #210 | #210 merged in v1.10.0, so nothing waits for it now. | 2026-11-05 |
| Route here | Yes, in Step 3. A route to a person carries the time of the position (CH-33). | 2026-11-05 |
| Names in packets | Every request carries the radio's name. A one-time answer carries it too, and so does a session's first report, then at most one report every 30 minutes. Shown as unverified ([names](#names)). | 2026-11-15 |
| Battery and status | Every report carries the radio's battery, shown as "Radio battery". The screens offer a one-tap status (OK, need help, heading back) and an optional "back by" time (22; was: status in the format, screens open). | 2026-11-16, preliminary |
| Trail fitting | Bisection finds the finest tolerance that fits, in place of the ×1.5 loop | 2026-11-15 |
| Early report on a sharp turn | Try it in Step 4 | 2026-11-15 |
| Search and rescue | "Details for a search" and "Send to this channel" on a person's sheet (23). | 2026-11-16, preliminary |
| Delivery wording | Your own channel texts read "Sent · no sign of who got it" and DMs "Their radio got it", on master now; Who got it moves into Step 4 (24). | 2026-11-16, preliminary |
| Firmware requests | None about the queue's drop order for now (27). | 2026-11-16, preliminary |
| Not taken from other clients | Their formats (also not as a per-channel compatibility mode), always-on flooding beacons (trip mode sends on a timer only while it is on: until its end time, or until Stop when the phone is out of touch then (13); zero-hop unless on an off-grid frequency; 8), phone GPS in reports (21), per-send region scope ([looked at elsewhere](#looked-at-elsewhere-2026-11-15)) | 2026-11-15; trip mode 2026-11-16, preliminary |
| Later, own PRs | The SOS alarm and Beep their radio ([later](#later-after-sharing-works-own-prs)). The off-grid group mode became TRAX mode (31–34), Who got it moves into Step 4 (24), SOS into a master PR (16), and Follow is dropped (55). | 2026-11-16, preliminary |

### Preliminary decisions: alternatives and what decides them

Each row is the current choice, preliminary as of 2026-11-16, under Martin's dialog number. Decisions 3, 5, 6b, 25 and 26 belong to the traxbook plan (#242).

| # | Current choice (preliminary, 2026-11-16) | Alternatives offered | What confirms or changes it |
|---|---|---|---|
| 1 | The recorder is its own feature, built after Step 2; traxbook comes later (35) | Keep recording inside location sharing | Field tests 8 (kill and restart) and 17 (battery) |
| 6a | Route here to a person is kept with the sharing data, out of backups and Export database, and goes with that person's data | Keep it in traxbook's routes table | Field test 15 (a spare radio; Delete all) |
| 7 | Move to MeshCore; a PLB or satellite messenger covers outside help; each feature's field test comes before relying on it | Keep APRS for good; switch only after a park field test | All field tests, 13 (range) first |
| 8 | Trip mode, per member and per private channel | One tap covers a session of up to 72 h; ask every time (2026-10-31) | Field tests 5 (locked iPhone), 12 (what away radios lose) and 17 (a day of trip mode) |
| 9 | Inside the approved time, sharing stops only at its end time or on Stop | Any member's packet keeps it going, but a killed app still ends it; as planned | Field tests 7 (requester loss), 8 (kill and restart) and 9 (walk out of range) |
| 10 | A pin never ends on silence | Off the map after 2 h, kept in a Last heard list; as planned | Field test 9 |
| 11 (changed 4) | 30 days for everything: others' last positions and trail points go 30 days after they arrived. Martin's choice; the review had recommended keeping each last position until deleted by hand. | Until deleted by hand (one row per person kept); 7 days (decision 4) | Field test 15 |
| 12 | Keep 240 minutes; warn 15 minutes before the end with one-tap Renew; trip-mode members rejoin with no tap; v1 reserves longer durations | Up to 72 h now; 240 minutes as is | The Renew drill under [field tests](#field-tests-proposed-preliminary) |
| 13 | Out of touch at the end time, keep sending one report every 10 minutes until Stop; offered as a box, ticked by default | Box unticked; stop at the end time | Let trip mode end with one phone out of range (drills) |
| 14 | One sharing database per phone | Per radio, with the others read-only; per radio | Field test 15 (connect a second radio) |
| 15 | Ask their radio plus Trip setup, members only; Trip setup's items live in TRAX settings (31) | The button only, set up by hand; no | Field test 4, and the drills for three radios back to back and the button |
| 16 | A minimal SOS now, in its own master PR before Step 3, after the DM fix | With Step 3; later, as planned | Field test 11, and the SOS drill under Do Not Disturb and Sleep Focus |
| 17 | The SOS dialog offers "Also send to Public", ticked, first send only: an exception to "Never Public", for SOS only | Offered unticked; never | Field test 11 |
| 18 | Trip members' adverts update their pins; Trip setup offers position in adverts for the trip, with warnings | Adverts update pins only; neither | Field test 18, and the restarted-radio advert drill |
| 19 | A minimal off-grid mode before relying on sharing in desert terrain; it became TRAX mode (31–34) | Only the per-session "also through repeaters" choice; zero-hop only, with the full mode later | Field test 10, and the trailhead check on the off-grid frequency |
| 20 | Fix stuck DMs now, in a master PR: park a flood DM only if a repeater was heard in the last 10 minutes | Give up after 2 minutes; keep as is | Field test 2 |
| 21 (changed 2) | The phone's GPS as an opt-in local fallback, never sent | Only if the iPhone test fails; radio only (decision 2) | Field tests 5 and 17 (locked iPhone; battery and heat) |
| 22 | A one-tap status plus an optional "back by" time | Status only; neither | The back-by drill |
| 23 | Details for a search plus Send to this channel | Search details only; screen only | Field test 16 |
| 24 | The wording now; Who got it in Step 4 | Wording only; as planned | The Who got it drill |
| 27 | No request to the firmware project about the queue's drop order for now | Ask once Step 3 is on air; ask now | Field test 12 |
| 28 | Not taken for now: a radio that beacons its position on its own (a timed advert in firmware, upstream or in a custom ESP32 companion) | Ask upstream and build it in an ESP32 companion; only one of the two | Field tests 4 and 18: what Ask their radio and the button give |
| 29 | Own small master PRs, merged only on "ship it": springs and drinking water, line of sight's "needs an internet connection", route caveat and start gap, your dot after a lost fix. The old-texts fix waits for a review of the earlier message-time fixes. | — | Field tests 1, 3 and 14, and the altitude bench test |
| 30 | On the regular mesh, sessions and trip mode stay zero-hop and never go through repeaters; they flood only on an off-grid frequency, where the group's radios and any repeater the group brings relay them | No automatic reporting at all on the regular mesh; through repeaters with a 10-minute minimum and a warning; as written (any frequency, any interval) | The bench check that F857's RX log shows no retransmission of a session packet, and field tests 10 (line test) and 13 (range day) |
| 31 | One tap switches the radio (settings saved, the off-grid frequency, Off-Grid Repeat on) plus the extras ticked in TRAX settings: trip mode, the recorder, members can ask my radio, position in adverts, SOS through Do Not Disturb; all ticked by default except position in adverts | Radio only; everything always, with no choices | The TRAX drills: start, the group check, Leave |
| 32 | The TRAX preset is the off-grid frequency with the mesh's own bandwidth, spreading factor and coding rate (62.5 kHz / SF7 / CR5 in the US) | Long range (250 kHz / SF11, the firmware's off-grid preset: about 4–5 dB more link margin, 2.5–3 times the airtime); pick per trip | Field test 13 (range day), with long range tried by hand |
| 33 | Tell the group: a TRAX message on the trip channel, and one tap each to follow; never automatic | A trip QR at the trailhead; both; each by hand | The TRAX drills |
| 34 | TRAX mode's radio part is its own PR soon, after the DM fix and the minimal SOS | With Step 4; after sharing's field tests | Field tests 10 (line test) and 13 (range day) |
| 35 | Location sharing first, through Step 4 and its field tests, then traxbook, kept in mind meanwhile | Interleave as planned; traxbook alongside in another session; traxbook first | — |
| 55 | Follow (Route here that keeps re-routing to a moving person) is dropped: the focus and trail view keeps the person centred, and Route here offers one tap when they have moved more than 100 m | Keep it for later, renamed 'Route to a moving person'; keep it as Follow | Field test 19 (drive): whether the one-tap re-route is enough |

## Steps

Items tagged CH-nn are proposed (safety review, preliminary); a decision number is Martin's preliminary choice of 2026-11-16.

### Order of work (preliminary, 2026-11-16)

1. **Master safety fixes,** each its own PR, merged only on "ship it" ([below](#master-safety-fixes-own-prs-before-step-3-preliminary-2026-11-16)): the DM fix (20), then the minimal SOS (16), then 29's items. The old-texts fix waits for a review of the earlier message-time fixes.
2. **TRAX mode's radio part** (31–34), its own PR after the DM fix and the minimal SOS ([below](#trax-mode-decisions-3134-preliminary-2026-11-16)): the button, the saved settings, the retune, Tell the group, the group check, Leave and the reminders.
3. **Ask their radio,** with Trip setup's items in TRAX settings (15, 31): no new format, so it can go in its own PR before Step 3 (CH-03); where it lands is [open question 11](#open-questions-for-martin).
4. **The v1 rules** marked [to settle before Step 2 freezes v1](#to-settle-before-step-2-freezes-v1-proposed-preliminary). Then Step 2 as its own PR, which freezes v1 and unblocks traxbook's R4.
5. **The recorder** (1), with per-phone storage (14) and the phone fallback (21), after the cross-plan rule (audit R-01, decision 6a).
6. **Step 3,** 3a then 3b, with TSX-02 to TSX-06 in 3a.
7. **Step 4,** with trip mode (8) plugged into TRAX mode's extras, and the iPhone gate (CH-08).
8. **The field tests** (CH-24) before anyone relies on these features.
9. **Then traxbook** (#242), kept in mind meanwhile (35): packet subtypes 4 and 5 stay reserved, the extension tags are one list, the recorder keeps times, gaps and each point's source, and other people's positions never go into routes.

Request the `data_type` allocation once Step 3 works on air; one allocation covers both plans.

### Step 1: two standalone fixes (shipped as #243)

Both were bugs with or without this feature. They shipped as #243 (`af067e22`, 2026-11-05) in v1.10.0, so the "one release before Step 3" condition is met. The facts later steps use:

- **1A. Message download stalled on channel datagrams.** The radio queues every channel datagram it can decrypt (any app, any data type, any channel it holds, Public included) and tells the app a message is waiting (`MyMesh.cpp:601-637`). The app had no case for code 27, so the drain waited for its 5 s watchdog. Now `case respCodeChannelDataRecv:` in [meshcore_connector.dart](../../lib/connector/meshcore_connector.dart) (about line 6727) calls `_handleQueuedMessageReceived()`; Step 3a adds the parsing.
- **1B. Off-Grid Repeat refused on the 869 MHz band, but reported as done.** `_offGridFrequencyForBaseFrequency` in [settings_screen.dart](../../lib/screens/settings_screen.dart) (about line 2104) now delegates to `RadioSettings.offGridFrequencyMHz`, which uses the radio's allowed list, and the hidden Off-Grid 869 preset in [radio_settings.dart](../../lib/models/radio_settings.dart) is 869.495. The dialog waits for the radio's answer and shows a refusal.
  - **CMD 60** (`cmdGetAllowedRepeatFreq`): reply code 26 = `[26]` then pairs of u32 LE lower and upper bounds in kHz; firmware ver code 9 or later, the same gate as repeat.
  - **Firmware rule:** repeat is allowed only on 433000, 869495 and 918000 kHz from 1.16 (869000 in 1.13–1.15) (`MyMesh.cpp:1032-1048`). A refused frame changes nothing (`MyMesh.cpp:1439-1440`).
  - **CMD 11** sent without its trailing repeat byte turns repeat off.

### Master safety fixes (own PRs, before Step 3; preliminary 2026-11-16)

Proposed (safety review, preliminary) and chosen by Martin as decisions 20, 16, 29 and 24. Each is a plain master PR, not part of this feature PR, kept small and easy to adjust, and merged only on "ship it". Before each, look over the earlier fixes in its area and their tests: Martin asked for that first for message times, and the same care applies to DM parking and the live dot.

1. **Stuck DMs (20, CH-04).** On master a flood DM that no repeater echoed is parked, only a heard repeater resumes it, and it blocks later DMs to that person until a restart (`message_retry_service.dart`: `_armEchoWatch` about line 671, `_park` 707, `noteRepeaterHeard` 749; one DM in flight per contact, 277). Where there are no repeaters, it is never resent.
   - Park a flood DM only if a repeater was heard in the last 10 minutes; otherwise let the ladder run on to "Failed · tap to resend".
   - Wake a parked DM when anything is decoded from its recipient (an advert, a DM, a path return). With Off-Grid Repeat on, relayed copies (`hopCount > 0`) wake it too. Once traxshare exists, a report carrying the recipient's prefix also wakes it.
   - A new DM to that person sends the parked one first, instead of queueing behind it. Offer Retry on a parked DM.
   - Tests with an injected clock: with no repeater heard, the ladder ends in Failed; once the person is heard, the DM is resent; a second DM isn't blocked. Field test 2.
2. **A minimal SOS (16, 17; CH-05 with its corrections), after 1.** Built on today's `SOS:` message and DMs, with no new format.
   - A received SOS always alerts. It cuts through the channel's mute and the channel-message switch, as a mention does, and stays pinned in the chat and on the map until dismissed.
   - It gets its own notification channel, which may override Do Not Disturb (Trip setup asks the user to allow that), and the iOS time-sensitive level; consider Apple's critical-alerts entitlement ([open question 12](#open-questions-for-martin)). Today it shares the ordinary channel notifications (`meshtrax_channels`, default iOS level), so Do Not Disturb, Focus and the silent switch mute it.
   - The dialog reads the radio first (it holds a position viewer for a few seconds), shows the position's age, and adds "position may be old" when no live fix was seen ([position rules](#position-and-movement)). Today it takes the app's last copy, with no age (`_radioPosition` in `structured_message_dialogs.dart`).
   - While it is active, it goes to the channel again every 2 minutes with the latest position, until the sender cancels; receivers show the repeats as one card that updates. Each "Got it" a receiver taps is shown to the sender, and after the first one the repeats slow to every 5 minutes. Cancel sends "SOS cancelled".
   - It goes as a DM to each trip member once, until "their radio got it", and again only after a move of more than about 100 m, at most every 15 minutes: repeated DMs can fill an away radio's queue, and newer frames are then dropped.
   - The card's main button opens MeshTrax's offline map, and the SOS pin opens a sheet with Route here. Navigate, which opens another maps app, comes second.
   - "Also send to Public" is ticked, shown clearly as ticked, and goes with the first send only, never with the repeats (17). On an off-grid frequency it reaches only the group.
   - The full-screen alarm can wait. In Step 4, an active SOS sets the status to "need help" and sends a report every 2 minutes.
3. **29's items,** each its own small PR:
   - **Springs and drinking water (CH-35, corrected):** in search results and on their sheets (`poi_kinds.dart`), springs carry "May be dry or unsafe: treat before drinking, and don't count on it", and drinking-water taps carry "May be turned off: check before you count on it". NPS: "Springs are rare and should not be considered reliable." ([hiking](https://www.nps.gov/deva/planyourvisit/hiking.htm))
   - **Line of sight offline (CH-36, corrected):** until it reads heights from the contours packs, its screen and its errors say "Line of sight needs an internet connection", including the catch path when the HTTP call itself throws (`line_of_sight_service.dart`).
   - **Route caveat, data date and start gap (CH-17, CH-18; decision 26 in the traxbook plan):** every Dirt and Hiking route shows "MeshTrax doesn't know closures, washouts or which roads need 4x4. Check current conditions before you go." and "Map data from <date>". `parseValhallaRoute` also returns the gap from the requested start to the route's first point (today only `kmShortOfDestination`), the map draws it dotted, and past 100 m the sheet says "Starts 1.5 km from your position, off any mapped path" and adds it to the totals. Once you are more than 100 m from where the route was found, "From your position" becomes "From where you were at 14:02". The engine snaps a start up to 35 km away (`search_cutoff`).
   - **Your dot after a lost fix (CH-07's master part), after a bench test** of whether a parked radio's reading keeps changing with a fix ([open question 10](#open-questions-for-martin)). The blue dot shows only a position seen live, and the live state expires (today `_selfPositionLive` stays set until a disconnect). Otherwise the map shows a grey "Last known · 14:02" pin, and the route sheet says "From your last known position (14:02), may be old". The SOS and My location dialogs use the same test. Expect the dot to stay grey for one poll after every connect.
4. **Delivery wording (24, CH-21):** your own channel text with no repeat heard reads "Sent · no sign of who got it", and a DM's "Delivered" reads "Their radio got it", which doesn't mean their phone has it.
5. **The old-texts fix (TSX-03, CH-10 parts 1 and 4): pending.** A first queue drain that gives up still sets `_completedFirstQueueDrain` (connector, about line 5857, against its own comment at 810-816). The rest of the queue then arrives as live, and `sanitizeSenderTimestamp` re-dates hours-old channel texts to "now". Proposed: only the first drain's NO_MORE_MESSAGES ends the backlog; part 4 is then needed only for frames a later drain left behind, compared with the channel floor snapshotted before this connection's sync, not with the channel's newest message. It waits for a look over the earlier message-time fixes, which Martin asked for first: "People send messages with a companion that doesn't have the time set properly. I am worried we will break something we fixed." Field test 3.

### TRAX mode (decisions 31–34, preliminary 2026-11-16)

One button switches the radio and the app into the group's off-grid setup, where every radio relays for the others, and back. It replaces the minimal off-grid mode (19) and the earlier off-grid group mode notes, under a name that doesn't clash with the existing **Off-Grid Repeat** setting. Its radio part is its own PR, after the DM fix and the minimal SOS (34). It needs none of this feature's code, so texts, DMs, SOS and Ask their radio hop through the group's radios before location sharing exists. Trip mode and the recorder plug in when they're built.

- **The button:** the boot print from the app's notification icon (`ic_notification`), in the Chats and Map app bars before GPS and Who can see my location. Gray when off, the logo's orange when on. While it is on, the Android foreground notification says so, with the same boot print and **Leave**. Tapping the button opens the TRAX sheet: what will change, or what is on now, with the group check and TRAX settings. Render it in light and dark and show Martin before an APK.
- **One tap (31):**
  1. Save the radio's settings (frequency, bandwidth, spreading factor, coding rate, TX power, repeat) on the phone, durably and per radio key. Today the app keeps them only in memory (`rememberedNonRepeatRadioState`, cleared on disconnect).
  2. With Tell the group, post the TRAX message on the trip channel and wait until the radio has sent it.
  3. One radio-settings write (CMD 11, with its repeat byte): the off-grid frequency nearest the regular one from the radio's allowed list (CMD 60; 918.000 MHz in the US), with the mesh's own bandwidth, spreading factor and coding rate (32), and Off-Grid Repeat on. The radio applies it at once, with no reboot, and saves it together with its current position as its fallback (`savePrefs`; `MyMesh.cpp:1424-1459` at the tag), so start TRAX mode at the trailhead, after a fix.
  4. Turn on the extras ticked in TRAX settings: trip mode on the trip channel until the trip's end (Step 4), the recorder, members can ask my radio (Trip setup's grants, GPS on, `gps_interval:0`, favourites), position in adverts, and SOS through Do Not Disturb. All are ticked by default except position in adverts, which anyone in range can read.
  5. **The group check:** send one flood advert on the TRAX frequency, list who has been heard there since the switch, and ask the radios of members not heard within a couple of minutes, one at a time: "4 of 5 on TRAX · Ana not heard".
- **Tell the group (33):** the TRAX message names the end time and the preset, as short readable text, MeshTrax only for now, like `Route:`. A member's phone shows "Ana switched to TRAX mode until Sunday 18:00. Switch too?" Never automatic: one tap each, so a forged message can't take radios off the mesh. Private channels only. Leaving works the same way, sent before the radio moves back: "Ana is leaving TRAX mode. Leave too?"
- **Leave:** write the saved settings back with repeat off, and turn off what TRAX mode turned on (trip mode, the trip grants, position in adverts), asking first. The recorder runs until it is stopped. A radio with no saved settings on this phone, because another phone switched it, asks which regular preset to return to.
- **Reminders:** at the trip's end, a notification. On every connect to a radio still in TRAX mode after that: "Your radio is still in TRAX mode: the regular mesh can't hear you. Leave?"
- **On connect:** a radio found on a TRAX preset shows the button on, whichever phone switched it.
- **Out there:** if a phone dies, its radio stays in TRAX mode and keeps relaying for the others. Radios in vehicles, such as the RAK 1 W boards, become the group's strongest relays. Nobody outside the group hears anything, Public included, so an SOS's Public copy (17) reaches only the group. A member left on the regular frequency is cut off from everyone; the group check and the Last heard list show it.
- **TRAX settings:** the preset (32; a long-range preset, 250 kHz / SF11, can be tried by hand on the range day), the trip channel and its members, the trip's end, and the extras. It holds Trip setup's items ([below](#ask-their-radio-and-trip-setup-decision-15-preliminary-2026-11-16)).
- **Known needs,** from the earlier off-grid group mode notes:
  - Any later radio-settings write while in TRAX mode carries the repeat byte: CMD 11 without it turns repeat off.
  - The health check's `radio_client_repeat` and `radio_frequency` rules show TRAX mode, not a problem.
  - Retune side effects: clear `_directRepeaters`; expect a full contact download; routes carry over between meshes, because each contact has one; parked DMs; `syncPathGraph` restarts Pathfinder on any settings change, and Pathfinder keeps one graph per mesh (frequency, bandwidth, spreading factor, coding rate), so TRAX gets its own.
  - Airtime grows with the square of the group size. Test on hardware whether a retune takes effect during receive, and battery life with repeat on.
- **Tests:** the saved settings survive an app restart and a radio change; Leave restores them exactly; a TRAX message prompts and never retunes by itself; the group check lists who is on TRAX; a radio found on a TRAX preset at connect shows the button on; the health check stays quiet.

### Ask their radio and Trip setup (decision 15, preliminary 2026-11-16)

Trip setup's items now live in [TRAX settings](#trax-mode-decisions-3134-preliminary-2026-11-16) (decision 31): the TRAX button applies them and Leave undoes them. In TRAX mode, Trip setup's Test is the group check (33).

Proposed (safety review, preliminary; CH-03 and D-07 with their corrections). Companion firmware answers a telemetry request by itself with its GPS position (`MyMesh.cpp:639-683`), so this finds a member whose phone is dead, killed or locked, or who can't tap. It uses the existing request, so it needs no new format and can go in its own PR before Step 3 ([open question 11](#open-questions-for-martin)). Radios ship with telemetry denied, and answer only when base telemetry is allowed too ([firmware facts](#firmware-facts-companion-v1180)).

- **Ask <name>'s radio** on each person's sheet, strip row and Last heard row. It is highlighted when they haven't answered within 2 minutes or their pin has faded.
  - It asks twice, about a minute apart. If both readings match, or the altitude is exactly 0, the answer says "may be old: no change in 1 min". An answer with no position says "GPS may be off"; a T1000-E with its GPS off still sends its stored position, which the two readings show as unchanged.
  - Each answer is labelled "where <name>'s radio is · received 14:02", with the radio's voltage and temperature that every answer carries ("radio 3.6 V, 51 °C"). When it hasn't moved for an hour and that member's phone has sent nothing, it adds "may have been left behind".
  - With no answer: "No answer from <name>'s radio: out of range, switched off, or it doesn't allow you."
  - **One at a time:** the asking radio keeps one telemetry request in flight (`MyMesh.cpp:1689-1690`), and the answer to a cleared request arrives as a binary response. Queue the asks, the Test button's too, and accept an answer that arrives as a binary response with a tag this phone sent; today only a telemetry push matches (`repeater_command_service.dart`).
  - **Routing:** flood every try only when no repeater has been heard lately; at home that would send each tap across the whole mesh. Otherwise use the request ladder, which with the fix below ends in floods. A route learned at home through a repeater never gets through where there is none.
  - The answer updates that person's pin as a radio answer, with its time and source (SR-01).
- **Request ladder fix:** in `planRequestAttempts` (connector, about line 4830), when Pathfinder is off or has no routes, end the attempts with floods, as `planAttempts` does. Today every try repeats the contact's stored route.
- **Trip setup** on the private channel, for the trip members only. Each member runs it on their own phone, for their own radio. Run it at the trailhead after the radio shows a live fix: its settings write stores the current position as the radio's fallback, which is otherwise wherever a setting was last saved, possibly home.
  - You pick the member contacts. For each, it shows whether they are a contact on this radio and whether this radio lets them ask. One button allows base and location telemetry "by contact" for exactly those contacts, with a reminder to undo it after the trip.
  - It turns this radio's GPS on, after asking (radios ship with it off), and shows its state.
  - It writes `gps_interval:0` once per radio key where the radio accepts it: a stored 900 s, left by older app versions, makes a live fix look frozen for 15 minutes. Tracker boards such as the T1000-E refuse it (TSX-02) and refresh every second anyway.
  - It marks trip members as favourites, so a full contacts table can't drop them, and flags any member the radio doesn't hold.
  - It offers position in adverts for the trip (decision 18), and turns it off again after the trip. Its warnings: anyone in range can read an advert's position, and after a restart with no fix an advert carries the stored position.
  - It asks Android members to let the SOS notification channel override Do Not Disturb (decision 16).
  - It says that **Share my location** off undoes its grants: that switch writes location deny and no position in adverts.
  - It shows the button warnings from the help text.
  - **Test** asks each member's radio once, one at a time. Once Step 3 is in, it also sends **Where is everyone?** to list who answered, so a member whose MeshTrax can't share yet shows up. In TRAX mode, Test is the group check, and it must reach every member before anyone leaves the trailhead (decisions 19, 33).
  - A spare radio gets the same setup, and the others hold it as a contact (decision 14).
- Privacy cost: during the trip, those members can read your radio's position whenever they ask, and you aren't told.

### Step 2: `packages/traxshare` (pure Dart)

- **First:** settle the items [to settle before Step 2 freezes v1](#to-settle-before-step-2-freezes-v1-proposed-preliminary). Step 2 freezes wire format v1, and traxbook's R4 builds on it.
- **Shape:** model it on `packages/path_graph`: pure Dart, with `drift` and `crypto` as dependencies, an injected database executor and clock, and no connector import. Public API in `lib/traxshare.dart`.
- **CI:** add analyze and test steps to [.github/workflows/flutter_dart.yml](../../.github/workflows/flutter_dart.yml), the same way path_graph and traxmap have them. This branch predates #210 and #271: rebase it onto `origin/master` first.
- **Modules** under `lib/src/`:
  - `codec/`: bit writer and reader, zigzag, exp-Golomb, extension items, packet encode and decode ([wire format](#wire-format-version-1)). Malformed input is rejected without an exception, in bounded time (TSX-09).
  - `movement/`: the live rule, the movement gate, derived heading and speed, fix age ([rules](#position-and-movement))
  - `trail/`: window, simplify, quantize, fit to budget by bisection ([recipe](#trail-recipe))
  - `gate/`: `isSharableChannel(name, psk, …)` ([channel gate](#channel-gate))
  - `session/`: request, consent, keepalive, trip mode and stop state machines, with approvals that survive a restart
  - `scheduler/`: interval, jitter, heartbeat, and the turn and 1 km triggers
  - `db/`: Drift tables and retention ([storage](#storage))
- **Done when:** the package tests listed under [Verification](#verification) pass. Nothing on screen yet.

### The recorder (decision 1, preliminary 2026-11-16)

Its own feature: start and stop, no cap, times kept, and a list of tracks. This plan's trail and traxbook's "Save my track" read from it. Built after Step 2; traxbook comes after this plan (35). Its rules are CH-13 with its correction.

- **Points:** while recording, hold a position viewer (`addSelfPositionViewer` / `removeSelfPositionViewer`), so the radio is read every 10 s; reading the radio is a serial command and sends nothing over the air. A point is kept after 25 m ([movement gate](#position-and-movement)).
- **Write each point to the database as soon as it is kept.** Keep "recording" and the track id in the database: after a crash, heat shutdown or reboot, recording resumes when MeshTrax starts and says "Recording resumed at 14:40 (stopped 14:02–14:40)".
- **Breaks:** a gap is 2 minutes with no reading from the radio (or the phone), not 2 minutes between kept points; the 25 m gate keeps no point while a member rests, so that would split every rest stop. Store a break, with its reason, at every gap and at any jump faster than 60 m/s, and never draw, send or export a line across one. A report's trail starts at the newest break.
- **Stops:** while still, update the last point's "here until" time.
- **No pruning by distance:** a track stays until it is deleted from the list.
- **Nothing before the first live fix** ([position rules](#position-and-movement)). Each point is marked with its source, radio or phone.
- **Sessions and trip mode:** approving a session, or turning on trip mode, starts the recorder if it is off, says so, and leaves it running. When the session or trip ends, remind the member that the recorder it started is still on, since there is no cap.
- **Phone GPS fallback (decision 21, CH-14 with its corrections):** opt-in. Whenever the radio has no live position (disconnected, flat, no fix), the phone's GPS feeds your own dot on the map, marked as the phone's, Route here's start and the recorder. It is never sent: trails and the search GPX are built from radio points only.
  - Costs: battery drain and heat on the phone, where phones already overheat.
  - Android: fine location, `FOREGROUND_SERVICE_LOCATION` and a location service type. The service can't take that type when it restarts from the background (it restarts on BLE–TCP switches) without background location, which Play reviews.
  - iOS: the NSLocation strings, the location background mode and `pausesLocationUpdatesAutomatically = false`; otherwise iOS pauses updates when the member lies still and suspends MeshTrax again. While sharing or recording, this background location session keeps MeshTrax running. Consider coarse accuracy while the radio has a live fix; whether that keeps the app running with no cell service is untested.
  - It adds a location permission and privacy text (Step 3b).
- **Platforms:** on iPhone, recording is promised only once the locked-iPhone test passes (CH-08). On Android, check notifications and battery optimisation before it starts, and start the background service for a recording over USB too (CH-22).
- **Storage:** in the sharing database, out of backups ([storage](#storage)).
- Field tests 8, 9 and 17 check it.

### Step 3: one-time sharing on private channels

**3a. Connector and service.** #210 has merged, so nothing waits for it.
- **Protocol helpers** in [meshcore_protocol.dart](../../lib/connector/meshcore_protocol.dart): `buildSendChannelDataFrame(channelIdx, pathLen, dataType, payload)`, where `pathLen` is `0xFF` for flood or `0` for zero-hop and never an explicit path, plus `parseChannelDataFrame`.
- **Firmware gate:** `supportsChannelData` is firmware ver code 11 or later, following `supportsCompanionRadioStats`.
- **Receiving:**
  - The frame 27 case parses the frame and adds it to a `channelData` stream, like `sensorPushes`. It still always calls `_handleQueuedMessageReceived()`.
  - Each frame carries a live or backlog tag. Backlog ends only with the first drain's NO_MORE_MESSAGES, kept in its own flag, since `_completedFirstQueueDrain` is also set when the first drain gives up (TSX-03, CH-10 part 1; the master fix above, pending).
  - A frame whose `sent_at` is more than 5 minutes older than its arrival counts as backlog for display, whatever the flag says, allowing for the sender's clock offset learned from its frames that arrived promptly. It takes its age from `sent_at` and never prompts (CH-10 part 2).
  - Order, replay and the dedupe window follow the [time rules](#time) (CH-10 part 3, A1, A2).
  - Resolve `channel_idx` against the live, verified channel list only (the `_liveChannelByIdKey` pattern). Never use `_findChannelByIndex`, which falls back to an old cached layout. If the slot is unknown or the sync is unverified, drop the frame; positions are perishable.
- **Sending:**
  - Use `_sendAndWaitForAck(frame, expectsGenericAck: true)`, with no retry and never queued. CMD 62 answers OK or ERR, never SENT, and OK only means queued.
  - `_sendAndWaitForAck` returns only a bool and takes the first OK or ERR of any command (TSX-04). Give each pending-reply entry its own completer, completed with the error code when that entry is popped, and have the CMD 62 send return the code.
  - Show the result in the strip. Errors at 1.18: 6 ILLEGAL_ARG, 2 NOT_FOUND ("channel not on this radio"), 3 TABLE_FULL ("radio busy, try again": the radio's packet pool is momentarily empty).
- **Errors, in `_handleErrorFrame`:**
  - Since #226 each pending-reply entry records its `commandCode`, and a failed write already removes its entry.
  - Read the head entry before the contact-table-full check, which today runs first. If the head is CMD 62, skip that event and set a flag that Pathfinder's frame adapter reads, so its "first ERR after a pending discovery" rule ([frame_adapter.dart](../../lib/services/path_graph/frame_adapter.dart), about lines 577–599) doesn't blame a discovery.
  - This is best effort: commands sent without `expectsGenericAck` can still misorder replies.
  - Send `gps_interval:0` with `expectsGenericAck`, so its own entry takes a tracker board's ERR 6, and never while a CMD 62 is waiting; remember per radio key that it was written or refused (TSX-02). Master's `setGps(true)` sends it untracked today.
- **Repeater evidence:** leave `MessageRetryService.noteRepeaterHeard` alone. A relayed flood of ours really does prove a repeater hears this radio.
- **Service:** `TraxShareService` in `lib/services/traxshare/` owns the sharing database (one per phone, [storage](#storage)), the position adapter over `connector.selfGps` with the phone fallback, and sessions, and it reads trails from [the recorder](#the-recorder-decision-1-preliminary-2026-11-16). It starts in `main.dart`.
- **Background service (TSX-05):** the connector stops `BackgroundService` itself on a USB connect, after a manual disconnect and when a TCP retry gives up (connector, about lines 2295, 4060 and 3748), and `start()` returns early when it already runs. A session would lose its notification, Stop and wake lock. Have the service track its owners (reconnect, session, recording) and stop only when none is left, route every stop through it, update its text and button with `updateService`, and pass localized strings in (`lookupAppLocalizations`). A tapped request notification opens the channel, then the dialog.

**3b. Screens.** Rebase this branch onto master first.
- **Menu:** the channel's ⋮ menu (`PopupMenuButton<String>` in [channel_chat_screen.dart](../../lib/screens/channel_chat_screen.dart), about line 1244) shows **Where is everyone?** only when the [channel gate](#channel-gate) passes and the firmware supports datagrams. Choices: position only, or position and trail. Trip setup sits there too, and trip mode joins it in Step 4. When no repeater has been heard lately, the menu and the strip say "reaches people in direct range" (CH-25).
- **Flow** (CH-25, with audit items A3, A5 and TSX-06):
  1. The request goes out, and the asker's own position report follows it; the dialog says so. The requester's strip shows it waiting. A request ends after 10 minutes (A3).
  2. A member sees a consent dialog, plus a notification that follows the channel's mute rule (muted: strip only). On a channel where this phone shares or is in trip mode, requests always notify, muted or not. On iPhone, ask for notification permission before the first request is sent or answered, and say in the strip when notifications are off. The dialog:
     - names the claimed sender as unverified, following the [name rules](#names): the contact's name, else the name in the request, else the hex prefix
     - says the whole channel will see the answer
     - says anyone who has the channel key can read it
  3. **Limits:** at most one prompt per sender every 2 minutes, plus a per-channel cap, since a key holder can vary the unverified prefix (A5; the cap's number is still to pick). The requester is told when a prompt was held back. Resolve names with `contactByKeyPrefix4`. Deny a request, and drop a report, when the prefix resolves to a contact that `isContactBlocked`, when the resolved or claimed name `isSenderBlocked`, or when the prefix is ignored (TSX-06). **Ignore this sender** is stored by prefix, so senders who aren't contacts can be silenced too. It and a decline can be undone from the strip, and ignored prefixes are listed next to blocked contacts in App settings.
  4. Approve sends one report, following the [position rules](#position-and-movement). It goes out twice, about 10 s apart, as the same bytes: radios that got the first copy drop the second.
     - A radio with no GPS says so in the dialog and sends nothing; its user can still see the map.
     - A trail needs a recorded track. When the recorder is off, the reply is position only and the dialog offers to start it.
- **Sharing strip:** its own widget in the channel body, shaped like `PathfinderMeshBanner`. It is not part of the `??` banner chain, so a disconnect banner doesn't hide it.
  - It shows waiting requests, who answered (with **Show on map**), active sessions and **Stop**. Each trip member shows as "answered N min ago" or "no answer yet · last heard N min ago · Ask their radio" (CH-25).
  - It always shows "Last sent 14:02 · group last heard 14:05" (CH-09). When the last send is older than two intervals, or nobody has been heard for 12.5 minutes, the line turns into a warning with the reason: radio disconnected; nobody heard for 13 min, you may be out of range; your radio's GPS is off; phone was locked; MeshTrax was closed. After a restart it says "Not shared from 14:02 to 14:40". Never a plain "Sharing". The same line goes on the "Sharing with <channel>" row, the recorder and the Android notification.
  - **Last heard list** (CH-06, decision 10): every trip member and anyone heard on this channel, longest silent first. Each row shows when they were last heard and how long ago, distance and bearing from me, moving or "not moving since", radio battery, status, "overdue by N min" past a back-by time, whether it came direct or relayed, the source (report, radio answer or advert), and Ask their radio.
- **Map:**
  - **Layers:** one `MapMarker` per person with a stable id, a `MapLine` trail, and a generated `MapPolygon` ring only when a position is approximate (accuracy class 1 or above). Every label carries its age ("Ana · 23 min", then the clock time after an hour, then the date after a day), and pins step through live, faded and grey styles ([thresholds](#display-thresholds)).
  - **The layers sheet (D1–D3):** Nodes already holds five tiles, one row on a phone (`_nodeLayers` in map_screen.dart), and Details six, so add a "Trax" section for **People sharing** (and traxbook's Routes). Say whether the map's filter button, shown only while a node layer is on (`_nodesShown`), covers people, and add legend entries, since the legend's entries are fixed in code (`showMapLegend`). Since #241 every entry has a picture; show Martin a render first.
  - **Contact pins (CH-29, decision 18):** when a person has a sharing pin, hide their contact pin or label it "advert position · <age>". A trip member's advert, matched by key, updates their pin and Last heard row with the advert's own time, labelled "sent from the radio". Its master part: next to a contact's position, show the time of the advert that carried it, not "Last seen".
  - **Performance:** feed lines from a cut-down copy per person, at most 200 points, recomputed only when a point is added. The map rebuilds its overlays on every connector notify, and since #210 also 300 ms after every pan at zoom 12 and above. Map markers are already the main cost on a busy map (Windows profile, 2026-10-31).
  - **Updates:** the map subscribes to `TraxShareService` itself and repaints when a position or style changes. Keep Trax data out of the message pin scan.
  - **Focus and trail view (Martin, 2026-11-16, preliminary):** this is how the group's earlier APRS app behaved on all its desert trips.
    - By default the map follows me, and my own track line shows behind my dot as I drive, drawn live from [the recorder](#the-recorder-decision-1-preliminary-2026-11-16). It is as long as the trail setting: at 10 miles it trails ten miles behind me, like a snake.
    - Other people's trails are hidden until I tap them.
    - Tap another person: the map centres on them and keeps them centred as their reports come in. Their trail shows; mine hides.
    - Tap myself: the map moves with me again. My trail shows; theirs hides.
    - **Center on my location:** the map moves with me, but the trail of whoever I last tapped stays. That way I can follow someone's trail behind them while seeing where I am.
    - Panning by hand stops the following. Tapping myself or **Center on my location** makes the map move with me again.
    - Following someone whose last report is old centres on their last known position. Their pin is grey with its age ([thresholds](#display-thresholds)), and nothing moves until a new report arrives.
    - Trail length: one report carries only the last stretch, a few miles ([trail recipe](#trail-recipe)). The longer trail builds up from repeated reports while we're in range. Stored trail points last 30 days (decision 11).
  - **Pin sheet:** name ([name rules](#names)), coordinates in the user's coordinate format (#210's setting, traxcoords), age through `DateTimeHelper`, "Radio battery" and the status when the report carries them, "Accuracy unknown: the radio's GPS reports none" (CH-38), "Reports come from <name>'s phone and stop when it stops" (CH-27), Ask their radio, Details for a search, and **Route here**. A trail says "drawn to within about N m" (2 × `grid_unit_m`), and with a "trail since" item, "since 11:40" (CH-38).
    - Reuse what #210's long-press sheet on the map does (`_showShareMarkerAtPositionSheet` in map_screen.dart):
      - `coordFormatOf(settings)` and `positionLines(lat, lon, format)` for the coordinates, with `CopyPositionButton`
      - `_routeHere(name, point, selfPosition)` for Route here, shown when `RoutingService.available` and `offeredAt(point)` (map_screen.dart, about lines 1745–1748; audit C5); elsewhere it is hidden
    - `_showPointSheet` drops a red pin (`sheet-pin`) on the point, which would sit on top of the person's own marker (D4): give it a way to leave the pin out.
  - **Route here** (decision 6a, CH-33): it opens the route sheet (`route_sheet.dart`, since #271) with the person's name, position and report time as the destination: "To Ana's position at 14:02 (35 min ago)". When a newer report puts her more than 100 m from the route's end, it offers "Ana has moved 1.2 km since (14:40). Route to her new position": one tap, never automatic. The route is kept with the sharing data: it survives closing the app, is never in phone backups or Export database, and goes with that person's data (30 days, or Delete all sharing data). Its start stays fixed: once you are more than 100 m from it, it reads "From where you were at 14:02", as the master route fix does (29, CH-18).
  - **Details for a search** (decision 23, CH-16): the last position in decimal degrees and in UTM/MGRS, WGS84; the fix time as date, clock time and time zone (receive time minus fix age, or `sent_at` minus fix age for backlog); heading and speed when moving, otherwise "not moving since"; radio battery, status, direct or relayed, and the source; the trail and later positions with their receive times, and optionally my own recorded track, radio points only. **Share** sends this as text plus a GPX file through the share sheet, after a warning.
    - **Send to this channel** posts the existing `Location:` message, labelled "<name>, heard 14:02", to the same private channel only. Its dialog says that this copies the position into every receiving phone's message database, which goes into phone backups and Export database. traxbook still has no "Save a shared trail" (6b).
- **Telemetry:** unchanged on the wire. A reply that carries a GPS position also updates that person's pin, labelled as from their radio.
- **Who can see my location** ([location_sharing_button.dart](../../lib/widgets/location_sharing_button.dart)):
  - Check Trax before the `hasSelfPosition` early return in `positionVisible`.
  - Add a dialog row **Sharing with <channel> · Stop**, with the "Last sent · group last heard" line, and a headline that outranks "Nobody can see your location".
  - **Share my location** off also stops sharing and trip mode, and undoes Trip setup's grants, since it writes location deny and no position in adverts. The row is the main control, because on a radio with default privacy settings that switch already shows off.
- **Settings:** the most of your track a report may send (presets per unit system; stored in metres; default 16,094 so it shows "10 mi", or "16 km" in metric), the phone GPS fallback, and **Delete all sharing data**, which asks first and lists who you'd lose ([storage](#storage)).
- **Privacy text:** `docs/privacy.md` is Martin's legal text, so draft the changes in the PR for him and don't edit the file. The sentences affected on master `d774d052`:
  - the data table (line 32 area), for a new row on own and others' tracks
  - device backups (line 43, which now names Time Machine), since sharing data stays out of them like maps
  - background use (lines 97 and 125), since it now includes sending positions
  - Location messages (line 149), for automatic replies and Send to this channel
  - retention (line 157): others' positions and trails are kept up to 30 days, and a route to a person goes with them
  - the macOS section (lines 101–113)
  - the phone GPS fallback makes lines 79, 99 and 121 untrue (the phone's GPS is never read; iOS never asks for location; Android location only for scanning) and adds its permissions
  - what others can see: in trip mode, anyone with the channel key, without asking you, until its end time; after Trip setup, the trip members, by asking your radio; with position in adverts, anyone in range; a back-by time goes to the channel; and a member who stops sharing stays on the others' phones at their last position until it ages out
- **Store text:** the store lines "No ads, analytics, or tracking" ([app-review-notes.md:142](../app-review-notes.md), [store/microsoft-store-notes.md:208](../store/microsoft-store-notes.md)) and the Play Data safety answers, location included, also need his look.

**Routing of each send**

| Send | How |
|---|---|
| One-time request | flood |
| Reply without a trail | flood |
| Reply with a trail | zero-hop if the request was heard directly (`path_len` 0xFF, or `path_len & 63 == 0`), otherwise a position-only flood |
| Timed session and trip mode: request, keepalive, reports, STOP | zero-hop; flood only when this radio is on an off-grid repeat frequency (CMD 60's list), as in TRAX mode, where the group's radios, and any repeater the group brings on that frequency, relay them (decision 19, CH-15). On the regular mesh they never go through repeaters, so there is no "also through repeaters" choice (decision 30). |

### Step 4: timed sharing and trip mode

- **Choices (decision 12):** the requester picks an interval (2, 5 or 10 min) and a duration (15, 60 or 240 min). The 240-minute cap stays for now, and v1 reserves `duration_min` values above 240. The requester is warned 15 minutes before the end, with a one-tap **Renew**; trip-mode members rejoin with no tap. A session goes zero-hop, so it reaches direct radio range only, except on an off-grid frequency, where the group's radios relay it (routing table above; never through the regular mesh's repeaters, decision 30), and the screen says so in plain words.
- **Requester reports:** the requester shares too (mask bit 5) and sends a keepalive request (flag b2) every 5 minutes.
- **Consent (decision 9, CH-02 with its corrections):** a member is asked once per session.
  - Within the approved time, sharing never stops by itself. Any packet of the session from anyone in it resets a member's silence timer. After 12.5 minutes with nothing heard, reports slow to one every 10 minutes (±20 %), and go back to the chosen interval when anyone is heard.
  - Each approval (channel, session, interval, approved-until time, any decline) is stored in the sharing database. After an app kill, a crash or a phone restart, sharing resumes when MeshTrax next starts, with no prompt, and the strip says what wasn't shared. After a heat shutdown that means once the phone is on and MeshTrax is opened, and the start dialog says so. Swiping MeshTrax away stops sending until it is opened again (`stopWithTask`), but the approval stands.
  - Only STOP or the end time ends it. Any key holder can forge or mis-send the requester's STOP, which still ends everyone's session; trip-mode beacons carry on after it. A replayed packet can't stretch sharing past the approved end (A2).
  - A decline holds for the whole session and can be undone from the strip. A keepalive for an unknown session is a late join and prompts once. STOP from either side.
- **Out of touch at the end (decision 13):** at the end time, if this phone hasn't heard anyone in the group for 30 minutes, it keeps sending one report every 10 minutes until Stop, and shows "Still sharing: <channel> hasn't been heard since 16:40 · Stop". It is offered as a box, ticked by default, when trip mode or a session starts: "If I'm out of touch with the group when this ends, keep sharing until I stop it." Privacy cost: sharing can run past the end time while separated.
- **Trip mode (decision 8, CH-01 with its corrections):**
  - In a private channel's sharing menu, each member turns it on for themselves, with an end time they pick (up to 7 days) and Stop. A reminder comes an hour before it ends, with Extend.
  - While it is on, this phone answers **Where is everyone?** and joins sessions on that channel with no prompt, with a silent notice for each automatic answer. It sends its own position with no request, as REPORTs under its own session id with mask bit 5: every 5 minutes while moving and every 10 while still, with the turn and 1 km triggers. It starts the recorder, and shows "Sharing with <channel> until <time>" in the strip, on the location icon and in the Android notification.
  - Require a trip channel with a fresh key, or warn when more people than the trip members are heard on it.
  - Its dialog says that an automatic answer to a request with a trail sends your recent track with no prompt, and that until the end time anyone holding the channel key can see your position without asking you.
  - Costs: about 0.36 % airtime for five people moving, or about 0.48 % with a trail every 5th report. A radio whose phone is away (dead, off or in a car) queues the others' beacons and loses the group's older channel texts within about 20 minutes on a 16-slot queue, or about 5 hours on 256 slots. Drivers send up to three times as often with the 1 km trigger.
  - On iPhone, it works only once the locked-iPhone test (CH-08) passes.
  - Receivers show REPORTs for a session they never joined, so a trip-mode beacon needs no REQUEST ([to settle](#to-settle-before-step-2-freezes-v1-proposed-preliminary)).
- **Scheduler:**
  - ±20 % jitter on every send.
  - A stationary heartbeat every 15 minutes, using the movement gate.
  - The effective interval is `max(chosen, N × 20 s)`, with N the senders heard in the session.
  - A trail every 5th report, and no sooner than 10 minutes after the last.
  - **To try:** an early report when the heading derived from kept points turns by 35° or more (the corner rule of APRS smart beaconing), so trails follow bends with fewer reports. At most one between two scheduled reports, and never sooner than `max(1 min, N × 20 s)` after the last. Keep it only if a real drive shows better trails: the derived heading is coarse, since a point is kept only every 25 m.
  - **1 km trigger (CH-30):** an early report after moving 1 km since the last one, never sooner than `max(1 min, N × 20 s)`, and **Send my position now** in the strip during a session or trip mode. Tune both on a real drive (field test 19).
- **Status and back by (decision 22, CH-31):** a one-tap status (OK, need help, heading back). "Need help" rides in every report until it is cleared, a change sends a report at once, and receivers alert as for an SOS. An optional "back by" time goes as an extension item, and the Last heard list shows "overdue by N min" once it passes. Privacy cost: your planned return time goes to the channel.
- **Who got it (decision 24, CH-21):** moved here from Later. While sharing, a report also carries the 16-bit hashes of the last few channel messages its sender heard, as an extension item. They are the same hashes as reactions (`ReactionHelper.computeReactionHash`). The sender of a channel message then sees which members got it, with no extra packets.
- **Phone heat and battery (CH-27):** read the phone's thermal state (iOS `ProcessInfo.thermalState`, Android `PowerManager.getCurrentThermalStatus`) and its battery; this needs a small native or plugin addition, since pubspec has no battery or thermal package. At iOS "serious", Android "severe" or 15 % battery, warn: "Your phone is hot (or low). MeshTrax may stop sharing and recording. Shade it." Reports then set mask bit 13, shown on the pin as "Phone hot or low: may go quiet".
- **Disconnects:** on disconnect, stop sending but keep the session until it expires. On reconnect, resume if it's the same radio key and the channel is verified; otherwise end.
- **Android:** the foreground notification gets a Stop button and the "Last sent · group last heard" line.
  - `BackgroundService` holds the session state, so `start()` puts back the title, text and button, including across BLE↔TCP switches; with TSX-05's owners (Step 3a) the connector no longer stops it under a session. End with an empty button list.
  - A USB connection runs without the service today, so start it for a session or a recording. Messages from the task go to the main isolate through `initCommunicationPort`.
  - Before a session, trip mode or a recording starts, check `notificationsAllowed()` and `BatterySleepService.shouldWarn()`. If either fails, say what won't work, with a button to the setting (CH-22). With notifications refused on Android 13 and later, Stop and requests are hidden.
- **iPhone (CH-08 with its corrections):**
  - The locked-iPhone device test (question 5) is a gate before any field use: reports, keepalives as requester, consent notifications and recorder points, with the phone locked in a pack for 2 hours, alone and near other radios.
  - Turn on Core Bluetooth state restoration: `FlutterBluePlus.setOptions(restoreState: true)` before any other Bluetooth call. iOS then relaunches MeshTrax for the radio after a memory kill, though never after a force quit, and the connector must re-attach to the restored connection (untested).
  - Until the test passes, an iPhone says when sharing, trip mode or recording starts: "On iPhone, the group may not see you while the screen is locked. Your radio can still answer Ask radio." Reports sent from the background set mask bit 13 ("this phone may go quiet").
  - With the phone GPS fallback on, a background location session keeps MeshTrax running while sharing or recording ([the recorder](#the-recorder-decision-1-preliminary-2026-11-16)).
- **macOS, Windows and Linux:** in-app only (audit A8 added macOS).
- **TRAX mode (decisions 19, 31–34, CH-15 with its corrections):** its radio part ships earlier, in its own PR ([TRAX mode](#trax-mode-decisions-3134-preliminary-2026-11-16)). In Step 4, sessions and trip mode flood while it is on (routing table above), the strip says "positions are relayed by the group's radios", and trip mode joins TRAX settings' extras.
  - Load: about 4.8 % airtime for five people at 2 minutes, and about 6.3 % with flooded trails, against about 1 % zero-hop.
  - One radio left on the regular frequency is silent to everyone, so the group check must reach every member before anyone leaves the trailhead.
  - On the off-grid frequency nobody outside the group hears anything, Public included.
- **Help text,** in plain words (proposed, preliminary):
  - These packets share the radio's message queue with channel messages while a phone is away. Five members at 2 minutes is about 2 frames a minute on each away radio. That fills 256 slots in about 2 hours, 128 in about 1 hour and 16 in about 7 minutes, and then the oldest channel messages are lost first.
  - "To reach someone whose phone may be off, send a direct message: their radio keeps it until it restarts or its queue fills with direct messages. Channel messages can be deleted from an away radio's queue, leaving no trace." (CH-32; decision 27 sends no queue request upstream for now.)
  - "Carry a PLB or satellite messenger: MeshCore can't call outside help." A phone's own satellite emergency feature is a layer on top of a PLB, not a replacement: it needs open sky and doesn't reach the group.
  - **The radio's button:** "Press the button twice, quickly, and only once. Never hold it: 3 seconds switches the radio off. Four presses switch its GPS off, and three turn the buzzer off or on. After a restart, leave the radio under open sky for a few minutes before pressing." That is the original UI (T1000-E, WisMesh Tag). On screen boards the Advert, GPS and Shutdown pages sit a few presses apart, and a long press acts on the page shown.
  - "If everyone's GPS stops updating at the same time, the signal may be jammed by a test: use map and compass, and treat every position as old." Published FAA notices for GPS tests centred on China Lake covered all of Death Valley National Park in 2025 ([example](https://www.faasafety.gov/files/notices/2025/Feb/CHLKCA_25-05_GPS_Flight_Advisory.pdf)), so check them before leaving home. With the live rule, every pin then shows that no change has been seen since the fix was lost.
  - "Keep your radio on you, out of parked cars and off dashboards, and don't charge it hot. Ask their radio finds the radio, not you." A T1000-E operates up to 60 °C and charges only at 0–45 °C ([Seeed](https://wiki.seeedstudio.com/t1000_e_intro/)).
  - "Everyone on the same MeshTrax version before a trip."

### Later: after sharing works (own PRs)

Ideas from [looking at other clients](#looked-at-elsewhere-2026-11-15) and the safety review, each in its own PR once Steps 3 and 4 are in use:
- **The SOS alarm:** a full-screen alarm on the receivers, on top of the minimal SOS, which moved to a [master PR](#master-safety-fixes-own-prs-before-step-3-preliminary-2026-11-16) (decision 16).
- **Beep their radio** (an idea, not decided): on the original UI, a DM to a radio with no phone connected plays a tone, so searchers close by can follow it and a conscious member learns someone is near. A short DM, at most one every 15 s for 2 minutes, since each DM stays in that radio's queue. Members would leave the buzzer on (a triple press silences it).
- **Who got it** moved into Step 4 (decision 24).

## Firmware facts (companion-v1.18.0)

All lines are in `./MeshCore` (on the Pi, `~/code/MeshCore`), read at the tag with `git show companion-v1.18.0:<path>`.

| Fact | Where |
|---|---|
| **Send:** CMD 62 `[62][channel_idx][path_len][path…][data_type u16 LE][payload]`. `path_len` 0xFF = flood under the radio's default flood scope; 0 = zero-hop. Replies OK or ERR, never SENT; OK means queued. | `examples/companion_radio/MyMesh.cpp:1198-1237`, `src/helpers/BaseChatMesh.cpp:539-568` |
| **Errors:** 6 ILLEGAL_ARG (frame under 4 bytes, bad `path_len`, data_type 0, payload over 165), 2 NOT_FOUND (channel_idx out of range; an empty slot is not refused), 3 TABLE_FULL (packet pool empty, try later). From 1.16.0 to 1.17.1, 166–167 bytes gave TABLE_FULL instead. Companion 1.15.0 takes at most 163 bytes and answers 6 above that, which is harmless at 157. | `MyMesh.cpp:1198-1237`; at 1.15.0, `src/helpers/BaseSerialInterface.h` (`MAX_FRAME_SIZE 172`) |
| **Size:** 165 bytes accepted (163 on 1.15.0). Keep to 157 or less: a raw packet over 173 bytes never appears in the RX log push (0x88), so bigger packets give no diagnostics. That holds at the sender; relayed copies grow by their path bytes. | `src/MeshCore.h:20-21`, `MyMesh.cpp:291-292` |
| **Receive:** frame 27 through the offline queue: `[27][snr×4 i8][0][0][channel_idx][path_len][data_type lo][hi][data_len][payload]`. No sender, no timestamp, no path bytes. `path_len` 0xFF = arrived route-direct (zero-hop here); otherwise a flood, hop count `path_len & 63`. A flood heard from its sender reports hop count 0 (`path_len & 63 == 0`); on meshes with 2- or 3-byte path hashes the byte is 0x40 or 0x80. | `MyMesh.cpp:601-637`, `src/Packet.h:83` |
| **Zero-hop** is delivered by every companion in range holding the channel and forwarded by nobody: repeaters and repeating companions forward floods only. No scope, no flash write. | `src/Mesh.cpp:225-251, 344-357, 693-715` |
| **Duplicates:** the packet hash covers type and encrypted payload (path and route ignored), and a 160-entry ring drops repeats. The ring lives in RAM only, so a reboot clears it, and how long it holds a hash depends on traffic. Every send must differ, which `seq` and `sent_at` guarantee. | `src/Packet.cpp:41-50`, `src/helpers/SimpleMeshTables.h` |
| **Encryption:** AES-128 in ECB mode, no IV, 2-byte MAC with the channel key. Any member can forge another; identical 16-byte blocks encrypt identically. | `src/Utils.cpp:85-145` |
| **Offline queue:** datagrams share it with channel text. When it is full, the oldest channel frame (text or datagram) is deleted, never a DM; with no channel frame left, the new frame is dropped. 256 slots on most BLE builds (Heltec V3 and V4, T1000-E, WisMesh Tag, RAK3401), 128 on some boards, 16 by default and on most USB builds; not reported to the app; lost on reboot. | `MyMesh.cpp:219-246`, `variants/*/platformio.ini` |
| **Version gate:** channel datagrams need FIRMWARE_VER_CODE 11 (companion 1.15). Members on older firmware get nothing. | release tags |
| **data_type:** FF00–FFFF is free for development (use 0xFF54). Before release, one ID in 0100–FEFF is requested by a PR to `docs/number_allocations.md`, after showing the app works. The newest taken value is 0150 (firmware `dev`, November 2026). | `docs/number_allocations.md` |
| **Position:** lat, lon and altitude only; no heading, speed, accuracy or fix flag. Self telemetry gives 0.0001° (about 11 m) and altitude to 0.01 m. On most boards it carries the position whenever GPS is on, and with no fix it repeats the last or stored position. | `src/helpers/sensors/EnvironmentSensorManager.cpp:687-688, 931-946`, `MyMesh.cpp:981-982` |
| **No timed advert:** stock companions never advert on a timer, at the tag or on upstream `dev` (checked 2026-11-15): `adv_int` is commented out, and the loop sends nothing on a timer. `advert()` goes zero-hop, only from a button or the app, and carries a position only with position in adverts on (`advert_loc_policy`, default 0). | `NodePrefs.h:11, 33, 195-196`, `MyMesh.cpp:2414-2449` |
| **Telemetry answer:** the radio answers a contact's telemetry request by itself, with its battery voltage, the MCU temperature where the board has a sensor, and its position when location is allowed. It answers only when base telemetry is allowed too, and radios ship with both denied. Most boards add the position only while GPS is on; a T1000-E adds its stored position even with GPS off. | `MyMesh.cpp:639-683` (base bit :666), `NodePrefs.h:26-27`, `EnvironmentSensorManager.cpp:687`, `variants/t1000-e/target.cpp:110-113` |
| **One telemetry request in flight:** a new telemetry, status, login, binary or path request clears the asking radio's wait, and the answer to a cleared request reaches the app as a binary response. | `MyMesh.cpp:1680-1690, 737-775` |
| **GPS and its interval:** GPS ships off. Only boards with the common sensor manager (WisMesh Tag, Heltec V4, RAK3401, RAK4631) accept `gps_interval`; tracker boards with their own GPS code, such as the T1000-E, answer ERR 6. Each accepted write rewrites the prefs file, the radio never reports the value, and a stored value is applied again at every boot. | `MyMesh.cpp:926, 1873-1888`, `EnvironmentSensorManager.cpp:740-742`, `variants/t1000-e/target.cpp:148-157`, `MyMesh.h:206-210` |
| **Buttons, original UI** (T1000-E, WisMesh Tag): double press = advert, triple = buzzer off or on (saved), four presses = GPS off or on, long press (3 s) = off, after the first 8 s. The newer UI (Heltec V4) has Advert, GPS and Shutdown pages, and a long press acts on the page shown. | `examples/companion_radio/ui-orig/UITask.cpp:551-633`, `ui-orig/Button.h:8-9`, `ui-new/UITask.cpp` |
| **After a restart:** a radio reports its stored position, saved at its last settings save, with altitude 0, until a fix. On a board with no clock chip, such as the T1000-E, its clock starts at 15 May 2024 until a GPS fix sets it, so radios that heard it before drop its adverts as replays until then. | `MyMesh.h:197-200`, `MyMesh.cpp:980-982`, `src/helpers/SensorManager.h:17`, `src/helpers/ArduinoHelpers.h:11`, `MicroNMEALocationProvider.h:245-249`, `BaseChatMesh.cpp:133` |
| **Contacts table:** when it is full and auto-add may overwrite, it drops the oldest non-favourite contact. | `BaseChatMesh.cpp:88-105`, `MyMesh.cpp:143-147` |
| **Repeat:** a companion forwards only with repeat on, and repeat is allowed only on 433000, 869495 and 918000 kHz (869000 in 1.13–1.15). | `MyMesh.cpp:487-489, 1032-1048` |
| **Don't use:** CMD 63 (set default flood scope) rewrites all settings to flash on every call. CMD 13 (reset path) rewrites the contacts file. | `MyMesh.cpp:1989-2005, 1317-1327` |
| **Flood scope:** a channel flood goes under the radio's default scope (CMD 63) unless CMD 54 has set an override in RAM: `[54][0][16-byte key]` sets it, `[54][0]` clears it, `[54][1]` sends unscoped (ver code 12+). The override lasts until it is cleared or the radio reboots. A repeater forwards a scoped flood only when it has that region. | `MyMesh.cpp:514-525, 1978-1988`, `examples/simple_repeater/MyMesh.cpp:434-442, 557-567` |
| **Airtime** at SF7, 62.5 kHz, CR 4/5, 32-symbol preamble: 17- or 29-byte payload = 37 bytes on air, about 214 ms (53 ms at 250 kHz), for zero-hop or an unscoped flood; a scoped flood adds 4 transport-code bytes, 41 bytes and about 224 ms. A 157-byte payload = 165 bytes, about 582 ms; 12-byte STOP = 21 bytes, about 162 ms. Payloads pad to 16-byte blocks, so 13, 29, 45 … 157 bytes are the largest sizes at each cost. | `src/Mesh.cpp:540-558`, `src/helpers/radiolib/RadioLibWrappers.h:56` |
| **Upstream `dev`, not released:** it reworks GPS (`gps_period`, `gps_first_fix`) and adds a `gps` CLI reply, "no fix" or "N sats X ago", that could tell a stored position from a live fix. Recheck at the next companion release. | audit, 2026-11-15 |

## Wire format, version 1

The `data_type` is 0xFF54 during development. Multi-byte numbers are little-endian; the trail bitstream is MSB-first.

### To settle before Step 2 freezes v1 (proposed, preliminary)

Each needs its meaning on the wire before Step 2: after v1 freezes, each would cost a version bump, and older receivers would show such positions as fresh (CH-23).
- **Mask bits** (CH-23): 11 "may be old: no GPS fix seen" ([position rules](#position-and-movement)); 12 "not moving", with the minutes since the member last moved in the speed byte (CH-26), an exception to the rule that a field whose bit is clear is sent as 0; 13 "this phone may go quiet": hot, low battery, or an iPhone in the background (CH-08, CH-27). Bit 14 stays reserved.
- **A clear bit 3** means "age unknown", never "just now".
- **`duration_min`** values above 240 are reserved for longer sessions (decision 12).
- **Beacons without a request:** receivers show REPORTs for a session they never joined, so a trip-mode beacon needs no REQUEST.
- **One extension tag list for the whole format** (R-04): today tag 1 is the sender's name here but the route's name in traxbook's ROUTE_PART. Proposed: 1 the sender's radio name, 2 a route's name. Still to number: Who got it, "back by", "trail since" (CH-38), and the app's feature level, carried in the first report so the strip can say "<name>'s MeshTrax can't share yet".
- **Unknown subtypes** (R-05): a frame with a known version and an unknown subtype is dropped quietly after the header, with no strip notice and no session or people update. Subtypes 4 ROUTE_PART and 5 PARTS_REQUEST stay free for traxbook's R4.
- **Ordering and replay** (A1, A2): per sender, a report never replaces one with a newer `sent_at` (2 s slack). `seq` is compared with 8-bit serial-number arithmetic, since it wraps within a long session (about 290 packets in 4 hours). The dedupe set holds `(sender_prefix, session, seq)` for 30 minutes, and `people_track` is ordered by a local arrival counter. Still open: whether to drop a session packet that arrives by flood when its session is zero-hop, since a captured zero-hop packet can be re-sent as a flood, while off-grid sessions flood on purpose.
- **The channel gate** (TSX-01, [below](#channel-gate)).
- **Antimeridian** (A6): the trail's local frame wraps `lon − lon0` into ±180°, so a trail across 180° doesn't encode a jump of about 38,000 km.
- **Still open (A10):** filling `fix_age` with random bytes at 0xFFFF covers only a frozen reading. With a live fix, `fix_age` keeps resetting to small values, so the second cipher block can repeat much sooner.

### Common header (12 bytes, every packet)

| Offset | Size | Field | Notes |
|---|---|---|---|
| 0 | 1 | version / subtype | high 4 bits version (1), low 4 bits subtype: 1 REQUEST, 2 REPORT, 3 STOP; others reserved |
| 1 | 1 | seq | per sender, +1 on every send, wraps |
| 2 | 4 | sender_prefix | first 4 bytes of the sender's public key. A claim, not proof. |
| 6 | 2 | session | u16, random, chosen by the requester. A one-time request gets a new one too. |
| 8 | 4 | sent_at | u32, Unix seconds from the phone's clock |

On an unknown version, read the common header only, show "<name> has a newer MeshTrax" once per session in the strip, and decode nothing more. Receivers drop repeats of `(sender_prefix, session, seq)`, for 30 minutes ([to settle](#to-settle-before-step-2-freezes-v1-proposed-preliminary)).

### REQUEST (subtype 1, 18 bytes plus the name)

| Offset | Size | Field | Notes |
|---|---|---|---|
| 12 | 1 | flags | b0 trail wanted, b1 timed session, b2 keepalive. Reserved, sent as 0: b3 per-point times, b4 per-point altitude, b5 off-grid session. |
| 13 | 1 | interval_code | 0 one-time, 1 = 2 min, 2 = 5 min, 3 = 10 min |
| 14 | 1 | duration_min | 1–240; 0 for one-time; values above 240 reserved for longer sessions |
| 15 | 1 | trail_window | 0.1 km units; 0 = no trail; 161 = 10 miles; at most 25.5 km |
| 16 | 1 | accuracy_wanted | reserved, 0 |
| 17 | 1 | name_len | 0–20 |
| 18 | n | name | the requester's radio name (`connector.selfName`), UTF-8, cut at a character boundary to 20 bytes. Up to 11 bytes, the request still costs what 17 bytes did. |

### REPORT (subtype 2, 29 bytes, plus the trail and extensions)

| Offset | Size | Field | Notes |
|---|---|---|---|
| 12 | 2 | field_mask | bits below |
| 14 | 7 | position | 56-bit value, little-endian: `lat_u << 31 \| lon_u << 5 \| accuracy_class` |
| 21 | 2 | fix_age_s | seconds since the radio's reading last changed; 0xFFFF = 18 hours or more |
| 23 | 1 | heading | `round(degrees × 256 / 360) mod 256` |
| 24 | 1 | speed | 0.5 m/s units; 255 = 127.5 m/s or more |
| 25 | 2 | altitude_m | int16 |
| 27 | 1 | battery | the radio's battery in percent, 0–100, shown as "Radio battery": the latest `connector.batteryPercent`, which applies the radio's battery type setting |
| 28 | 1 | status | 0 none, 1 OK, 2 need help, 3 heading back; others reserved. The screens offer it (decision 22). |
| 29 | 1 | grid_unit_m | with mask bit 10 only: metres per trail step |
| 30 | 1 | point_count | with mask bit 10 only: trail points that follow |
| 31 | n | points | with mask bit 10 only: bitstream below. The whole payload, extension block included, stays within 157 bytes, so the points get at most 126. |

The battery and status take the two bytes a report without a trail used to spend on an empty grid and count. So a report without a trail stays at 29 bytes, the largest size at its airtime cost ([airtime](#firmware-facts-companion-v1180)). One more byte there would cost a whole extra 16-byte block.

Position encoding:
- `lat_u = round((lat + 90) × 100000)` (0–18,000,000, 25 bits)
- `lon_u = round((lon + 180) × 100000) mod 36,000,000` (26 bits)
- `accuracy_class` (5 bits):
  - 0 = as the radio reports it
  - n ≥ 1 = within 2^(n−1) m, kept for a possible "approximate position" choice
  - v1 senders send 0; receivers still draw a circle for n ≥ 1.

| Mask bit | Meaning |
|---|---|
| 0 | heading valid, set only while moving |
| 1 | speed valid, set only while moving |
| 2 | altitude valid |
| 3 | fix_age valid; clear means "age unknown" |
| 4 | moving |
| 5 | sent by the session's requester |
| 6 | battery valid |
| 7 | status valid |
| 8 | per-point time present (v1: off) |
| 9 | per-point altitude present (v1: off) |
| 10 | a trail follows: grid_unit_m, point_count and the points |
| 11 | proposed: may be old, no GPS fix seen ([to settle](#to-settle-before-step-2-freezes-v1-proposed-preliminary)) |
| 12 | proposed: not moving; the speed byte holds the minutes since the last move |
| 13 | proposed: this phone may go quiet |
| 14 | reserved |
| 15 | an extension block follows: u8 length, then items. It starts after the points, or at offset 29 when there is no trail. |

- **Unused fields:** a field whose mask bit is clear is sent as 0, except the speed byte under bit 12 (proposed).
- **fix_age:** saturated at 0xFFFF, it would make every report from a parked radio repeat its second cipher block, and ECB shows that to anyone in range. So at 0xFFFF, clear bit 3, fill the field with random bytes instead, and set bit 11 (proposed). This covers only a frozen reading (A10, open).
- **Extension items:** each is `[tag u8][len u8][value]`, and receivers skip tags they don't know.
  - Tag 1 is the sender's radio name, UTF-8, cut at a character boundary to 20 bytes. It goes in every one-time answer and in a session's first report, then in at most one report every 30 minutes.
  - On a report without a trail, a name of up to 13 bytes costs one more 16-byte block.
- **Future changes:** add a field as an extension item, from the one tag list. Append new per-point fields in mask order. Changing an existing encoding bumps the version.

### Trail bitstream

- **Order:** points run newest first.
- **Anchor:** the report's own position, decoded from the 56-bit field, so both sides use exactly the same `lat0` and `lon0`.
- **Deltas:** point 0 is a delta from the anchor; point i is a delta from point i−1.
- **Local frame** in metres: `x = (lon − lon0) × cos(lat0) × 111320`, `y = (lat − lat0) × 111320`, with `lon − lon0` wrapped into ±180° (A6, proposed).
- **Quantize** each point to integers `X = round(x / grid)` and `Y = round(y / grid)`. Deltas are taken between these integers, so the receiver's running sums give back exactly the sender's points. Convert back to degrees only to draw.
- **Each point:**
  - `dX`, then `dY`: zigzag, then exp-Golomb order 3, in grid units; east and north positive
  - then `dt` if bit 8: exp-Golomb order 4, seconds back in time
  - then `dalt` if bit 9: zigzag plus exp-Golomb order 2, metres
- **Zigzag:** `u = v ≥ 0 ? 2v : −2v − 1`; back: `v = u even ? u / 2 : −(u + 1) / 2`.
- **Exp-Golomb, order k,** for `u ≥ 0`: `q = u >> k`; `m = floor(log2(q + 1))`; write `m` zero bits, then `q + 1` in `m + 1` bits, then the low `k` bits of `u`.
  - Example, k = 3 and u = 100: q = 12, m = 3, written as `000 1101 100`, 10 bits.
  - The earlier draft's "q zero bits" was wrong.
- **Padding:** after the last point, pad with zero bits to a byte boundary. The extension block (bit 15), if any, starts there.

### STOP (subtype 3, 12 bytes)

The header only. From the requester, it ends the session for everyone. From anyone else, it ends only that member's sharing, and the others relabel their pin as stopped; it stays on the map ([thresholds](#display-thresholds)).

## Rules

### Time

Tag every frame 27 live or backlog, as described in Step 3a.
- **Live:** its age is local receive time plus `fix_age`, and it may prompt. A live frame whose `sent_at` is more than 5 minutes older than its arrival, allowing for the sender's clock offset learned from its frames that arrived promptly, counts as backlog for display and never prompts (CH-10).
- **Backlog:** its age comes from `sent_at`. A backlog request older than 10 minutes, or stamped in the future, is dropped with no prompt.
- **Order:** per sender, a report never replaces one with a newer `sent_at` (2 s slack); seq and the dedupe window follow the [wire rules](#to-settle-before-step-2-freezes-v1-proposed-preliminary) (A1).
- **Display (CH-28):** never clamp an age silently: a time more than 2 minutes in the future shows "time unknown". Before saying a sender's clock is off, compare this phone with its own radio's clock, once the radio has had a live fix this connection; a radio with a fix sets its clock from GPS every 30 minutes. If they differ by more than 2 minutes, say "this phone's clock is N min off" and correct `sent_at` by that amount. Don't offer to set a radio that has a live fix from the phone's clock.

### Position and movement

- **What `selfGps.at` is:** the time the phone got the reply, not the time of a fix. The radio can't say whether it has one.
- **Live (CH-07, corrected):** a position counts as live only after this app has seen the radio's reading change (lat, lon or altitude) during this connection. Keep the last reading, and when it first appeared, per radio key in the sharing database, so an app restart doesn't reset `fix_age`. A reading whose altitude is exactly 0 and never changes means "no fix since the radio started". The live state expires when the reading stops changing; how soon waits for the bench test.
  - Until a change is seen, and also at 0xFFFF, set mask bit 11. Receivers draw such a pin grey, with "no change seen since 14:02"; a clear bit 3 means "age unknown", never "just now".
  - The same test decides radio answers, your own dot (a master fix) and the recorder, which records nothing before the first change.
  - If a parked radio's reading froze even with a fix, this would grey every parked member, so the bench test ([open question 10](#open-questions-for-martin)) comes first. Altitudes below sea level decode correctly, so the altitude-0 rule holds on a valley floor below sea level.
- **fix_age:** record when the lat/lon/alt reading last changed, and send seconds since then as `fix_age` (mask bit 3). Receivers show "no change seen since 14:02".
  - Altitude comes in 0.01 m steps, so a live fix should keep changing it. Confirm this on the bench before relying on it.
- **Has a position:** `gpsOn`, and a reading younger than two read periods. The adapter drops 0,0 and stops when GPS goes off.
- **Consent dialog:**
  - Hold a position viewer while it is open, so the radio is read at once, and wait a few seconds for the answer.
  - A reading unchanged since connecting can be a stored position from before a restart. Send it only after the dialog says it may be old.
  - Never gate on `selfPositionIsLive`, which a parked radio never regains.
- **Read interval (TSX-02, TSX-10):** when sharing or recording starts, write `gps_interval:0` the way `setGps` does, but once per radio key (remembered in app settings), with `expectsGenericAck`, and skip radios that refuse it. Older app versions left some radios at 900 s, which the radio applies again at every boot, and the radio never reports the value.
- **Movement gate:** one 0.0001° step is about 11 m north–south and 9 m east–west, so a parked radio near a cell edge looks as if it moves.
  - Keep a new track row, set `moving` and derive heading and speed only after at least 25 m from the last kept point, measured over that displacement and its time.
  - `moving` stays set for 2 minutes after the last kept point.
  - **Not moving (CH-26):** set heading and speed (bits 0–1) only while moving. In a report sent while not moving, set bit 12 and put the minutes since the last kept point in the speed byte (255 = 254 or more). Receivers show "Not moved since 12:40 (80 min)" on the pin and in the Last heard list, with no alert.

### Trail recipe

1. Take recorded points back from the newest, by distance only, up to `min(request window, the trail setting)`. Never cross a break, and use radio points only.
2. Simplify in 2D with Douglas–Peucker, always keeping the first and last points.
3. Start at epsilon 15 m with a grid of `max(8, ceil(epsilon / 2))` m. Quantize and delta-encode as above.
4. Fit the room left: at most 126 bytes, less any extension block, and 255 points.
   - If 15 m doesn't fit, double epsilon until it does.
   - Then bisect between the last epsilon that failed and the first that fit, to within 1 m, repeating from step 2 with each epsilon tried.
   - Keep the finest that fits, as `SvgWriter.fit` in [svg_drawing.dart](../../lib/helpers/svg_drawing.dart) does for drawings.
5. Log epsilon, point count and bytes for the debug log.

At 10 miles, that is about 57 points.

The [track compression review](#track-compression-review-2026-11-12) measured the earlier ×1.5 loop and proposed two changes. Bisection was adopted on 2026-11-15. A graded tolerance is still open (question 7).

### Channel gate

`isSharableChannel(name, psk, …)` lives in `packages/traxshare`, with the Public key constant (`8b3387e9c5cdea6ac9e5edbaa115cd72`). `Channel.isSharable` in [channel.dart](../../lib/models/channel.dart) calls it, so there is one implementation, and the session layer checks it on both send and receive.

It denies:
- the Public key
- an all-zero key
- a blank name
- a key equal to `sha256('#' + name)[:16]`, for the stored name and for its lowercase form, with or without a leading `#` (the same derivation as `Channel.derivePskFromHashtag`)
- any stored name that starts with `#` and is at the radio's 31-byte limit, or ends in U+FFFD (TSX-01). The radio keeps 31 bytes, and the cut falls on a byte, so a cut inside a 2-, 3- or 4-byte character leaves a stored name of 31–33 bytes ending in "�" whose key can't be re-derived. Pass the stored byte length in, so any `#` name at the limit is denied; denying only hides the feature, which is the safe side.

It can't catch a renamed hashtag channel or a key that was shared widely, which is why the dialog says anyone with the key can read the answer. A denied channel's inbound packets get no prompt, reply or storage, and sending on one throws. Separately, master's hashtag field counts characters, not bytes (`maxLength: 31` in `new_chat_screen.dart`, with `#` added in front); a 30-byte `Utf8LengthLimitingTextInputFormatter` there would stop MeshTrax making such names.

### Names

Requests carry the requester's radio name and reports carry the sender's ([name item](#report-subtype-2-29-bytes-plus-the-trail-and-extensions)), so people who aren't contacts show by name. Everywhere a person is named (the consent dialog, the strip, the pin sheet):
1. A contact's name, when the sender prefix matches one (`contactByKeyPrefix4`).
2. Otherwise the name from the packet, marked unverified, since any member can claim any name, as with the prefix.
3. Otherwise the hex prefix.

The last name from a packet is kept in `people.name_cached`, so later reports without it still show it.

### Display thresholds

Decision 10, with CH-06 and its correction:
- **A pin never disappears on its own.** STOP and the end of a session change its label, not its presence. Only the user removes it, or age past the retention time (30 days, decision 11).
- **Fade** after `2 × interval` when the last report said moving, and after `1.2 × heartbeat + interval` when it said not moving. The old `2 × heartbeat` fade for a parked member came after the pin had already ended (TSX-07).
- **Grey** after `2.4 × heartbeat + interval`, about 38 minutes for a 2-minute session, labelled "last heard 14:02 (2 h 10 min) · may be out of range". Heartbeats come every 12–18 minutes with jitter, so one lost heartbeat means 24–36 minutes of silence.
- **One-time answers** fade after 10 minutes and stay on the map until dismissed or replaced.
- Every label carries its age (SR-01).

## Storage

- **Location:**
  - Folder `<app support dir>/traxshare/`, one database per phone, not per radio (decision 14, CH-12), so a spare radio still sees everyone's last positions, the routes to people and your own tracks.
  - Mark the folder out of backups before every open, the way `MapPacksService.keepOutOfBackups` handles maps (iCloud and Time Machine). That method is `@visibleForTesting` and logs as Maps, so calling it from traxshare fails `--fatal-warnings`: move it into a shared helper with a neutral log message (TSX-11).
  - Open with `driftDatabase(name: …, native: DriftNativeOptions(databaseDirectory: …))`. path_graph's default location can't be excluded from backups.
  - Add `<exclude domain="file" path="traxshare/" />` to `android/app/src/main/res/xml/backup_rules.xml` and to both sections of `data_extraction_rules.xml`, next to `maps/`.
  - It is a separate file from the message database, so it isn't in **Export database**.
- **Keys:** people by (a hash of the channel's idKey, prefix), so the key itself isn't stored here, and sessions by (channel, session); never by slot index or name. On a radio key change (`selfPublicKeyHex` changes to another non-empty key), end any session, but keep people, trails, the routes to people and recorded tracks.
- **Migrations** must survive an interrupted first launch: `createTable`, and add columns only if they're missing (see `app_database.dart`'s `_createIndexIfMissing` and path_graph's `addIfMissing`).
- **Tables** (proposed):
  - The recorder's tracks and points: each point has `recorded_at`, lat, lon, `alt_m`, its source (radio or phone) and "here until", and a break has its reason. Raw kept points in order, compressed only when sent. traxbook's "Save my track" turns them into its route shape, keeping the breaks.
  - `people(channel_hash, prefix, name_cached, last_lat, last_lon, last_alt_m, last_heading, last_speed, accuracy_class, fix_age_s, last_battery, last_status, last_sent_at, last_seen_at, last_source, last_hops, ignored)`, keyed by (channel_hash, prefix).
  - `people_track(channel_hash, prefix, arrival, lat, lon, received_at, dist_m_from_prev)`: received trails have no per-point times and each overlaps the last, so a new trail replaces that person's line; position reports since then are appended. Order and retention use the local `arrival` counter, never `seq`, which wraps (A1).
  - `sessions(channel_hash, session, requester_prefix, role, state, interval, approved_until, declined)` (TSX-08): each approval survives a restart (decision 9), and the old `people.session_state` gets a meaning per channel and session. `answers(channel_hash, session, prefix, sent_at)` feeds the strip.
  - The route to a person (decision 6a): destination name, position and report time, start, path type and the found line.
- **Retention (decision 11):** others' last positions and trail points go 30 days after they arrived, and a route to a person goes with that person's data. This is Martin's choice; the review had recommended keeping each person's last position until it is deleted by hand (CH-11).
  - Your own recorded tracks have no cap; they go when you delete them from the list. The movement gate keeps about 40 points per km.
  - **Delete all sharing data** clears others' data, sessions and the routes to people. It asks first and lists who you'd lose, with when each was last heard (proposed). It closes the database before deleting, since Windows can't delete open files, and marks the new folder out of backups again before reopening (TSX-11). Each person can also be deleted from the strip.

## Verification

**Package (`dart test` in `packages/traxshare`)**
- **Codec:**
  - bit writer and reader with odd lengths
  - exp-Golomb orders 2–4 at edge values and with random values, including the 10-bit example above
  - zigzag; position packing at the poles and the antimeridian; a trail across the antimeridian (A6)
  - a report with no trail is exactly 29 bytes, battery and status included, and no encoded report exceeds 157, a trail and a 20-byte name included
  - a name is cut at a character boundary at 20 bytes; a request with an 11-byte name is 29 bytes; unknown extension tags are skipped
  - for 50 random tracks, decoding the encoding gives exactly the sender's quantized points
  - **fuzz (TSX-09):** random and truncated payloads reach the decoder with no exception and in bounded time: a truncated header or report, a `point_count` larger than the bits present, a run of zero bits to the end in exp-Golomb, an extension block whose length runs past the end, a `name_len` over 20 or over the bytes left, an unknown subtype (dropped after the header, R-05), and a `data_len` that doesn't match the frame
- **Trail:** GPX fixtures of a city walk, a mountain drive and a straight highway, each logging epsilon, points and bytes. Bisection keeps a tolerance at least as fine as a scan in 1 m steps. A trail never crosses a break.
- **Gate:** every denial above, including `Family` with `sha256('#family')`, an all-zero key, a 31-byte `#` name, and names cut inside a 2-byte and a 3-byte character (TSX-01).
- **Movement:** a reading that flips between two neighbouring cells adds no rows and stays not moving; fix age grows while the reading is frozen; bit 11 stays set until a change is seen, also after an app restart; heading and speed are cleared while not moving, with bit 12 set.
- **Time:** a backlog request older than 10 minutes is dropped; a live frame from a sender whose clock offset was learned from earlier frames still prompts; any other live frame whose `sent_at` is more than 5 minutes old counts as backlog; report n+1 arriving before n keeps the newer; a session past seq 255 stays in order; a repeat inside 30 minutes is dropped; a time 2 minutes in the future shows "time unknown".
- **Sessions** with an injected clock: a packet from any member resets the silence timer; with no packets for 60 minutes, slow reports go on; a packet from any member brings back the interval; an approval survives a restart; a decline holds and can be undone; STOP works from each side; the 240-minute cap holds; out of touch at the end, reports go on every 10 minutes; a trip-mode beacon shows with no request.
- **Retention:** others' data goes after 30 days; a new trail replaces the old line; recorded tracks are never pruned.

**App (`flutter test`)**
- **Connector:**
  - frame 27 keeps the drain going; a foreign `data_type` is ignored
  - an ERR after a datagram reaches neither the contact-full event nor Pathfinder's discovery rule, in both orders
  - channel slots are resolved by identity; the gate holds on send and receive
  - the first drain times out and the rest of the queue arrives later, still tagged backlog (TSX-03)
  - `gps_interval` gets ERR 6 while a report is pending, and the report keeps its own result (TSX-02); CMD 62's error codes reach the strip (TSX-04)
  - the background service stays up under a session through a USB connect and a manual disconnect (TSX-05)
  - three Ask their radio requests in a row each show their answer, one of them arriving as a binary response
- **Screens:**
  - the location icon and its new row work with **Share my location** already off
  - the trail setting shows "10 mi" and "16 km"
  - the strip survives a disconnect banner
  - a blocked contact and an ignored prefix get no prompt, pin or storage (TSX-06)
  - fade and grey for parked and moving members (TSX-07)
  - a person active on two channels (TSX-08)
- **Storage:** an interrupted first launch; the backup exclusion call on iOS and macOS, through a mock of the method channel; Delete all closes the database first (TSX-11).

**Two radios on 920.000 MHz, one with GPS**
- **Delivery:** a zero-hop packet reaches the other companion and F857's RX log shows no retransmission; a one-time flood is forwarded by F857 (ask Martin before moving F857).
- **Stationary radio:** over 30 minutes, every report arrives.
- **Altitude:** keeps changing with a fix and freezes without one, as the position rules need. This bench test gates the live rule and the "your dot" master fix (open question 10).
- **Step 1A** on a build from before and after the fix.

**Simulator:** ask whether `meshsimulator-0f`'s virtual companion handles CMD 62 and frame 27 and can run a five-member session.

**Martin on phones**
- reporting with the screen off on Android, over a real walk or drive
- a Samsung and a Pixel lying still with the screen off for 2 hours, and one run with Extreme Battery Saver on (CH-22)
- trails on the map; **Route here**
- the consent dialog
- the message queue while a phone is away

### Field tests (proposed, preliminary)

From the safety review (CH-24), with its checkers' corrections. They are the gate before anyone relies on these features: among them the locked-iPhone test (5), the Android lying-still test (6) and an 8-hour battery run on each phone type (17). Run them with real radios carried as in normal use, on both phone types, against written pass criteria. Tests 2 and 11 need only the master fixes.

1. **Radio with no fix (bench):** first check whether the altitude keeps changing while a radio with a fix is parked, and write `gps_interval:0`, or a radio left at 900 s looks frozen. Restart a GPS radio indoors and read its self telemetry: expect altitude 0.00 and the stored position. Reports carry "may be old", receivers draw a grey pin, the blue dot becomes the grey "Last known" pin, and SOS says "may be old". Outdoors, the flag clears within a minute of a fix.
2. **DM with no repeater (bench):** ask before moving the bench repeater. Switch radio B off and send it a DM from A. Switch B on and have it send something, then send a second DM. Today both stay stuck; after the DM fix the first is resent or fails with tap to resend, and the second goes out.
3. **Backlog (bench):** keep a radio away from its phone for an hour while others share and post. Reconnect while the radio is busy, so the first drain times out. Every position shows its real age, and a 90-minute-old channel text shows its sent time and "arrived late".
4. **Ask their radio:** close member X's MeshTrax, then switch X's phone off, then try with a locked iPhone. Member Y asks X's radio at 50 m, at 1–2 km in open desert and at a canyon mouth, logging the answer time and the position error. Repeat with Pathfinder off, with a contact whose route was learned through a repeater at home, and with X's radio deep in a pack with no fix for 30 minutes (expect "may be old").
5. **Locked iPhone:** lock two iPhones in packs for 2 hours in a 2-minute session with an Android requester. Count reports received against those expected, and recorder points. Then make an iPhone the requester. Then push MeshTrax out of memory with large apps and check that iOS relaunches it and it reconnects (state restoration; never after a force quit). Then run trip mode with the phone locked for 3 hours, asking every 30 minutes.
6. **Android lying still:** a Samsung and a Pixel on a table, screens off, for 2 hours in a 5-minute session: every report arrives. Repeat with notifications refused and battery optimisation on (the warning comes before the start), and once with Extreme Battery Saver.
7. **Requester loss:** in a 60-minute session, switch the requester's phone off for 20 minutes. The others keep seeing each other at the chosen interval, and when the phone comes back every pin returns with no taps.
8. **Kill and restart:** kill MeshTrax 30 minutes into a session and reopen it, then restart the phone and reopen it. Sharing and recording resume with no prompt, the strip says what wasn't shared, and the track shows two marked gaps.
9. **Walk out of range:** one member walks out of range for 45 minutes and comes back, with a third radio left along the route logging reports. Slow reports keep coming about every 10 minutes, the walker's phone warns once at about 13 minutes, the grey pin and Last heard row keep the last position and time through the session's end and an app restart, and the group sees the walker within one interval of their return.
10. **Line test:** three radios in a line, the ends out of each other's range; start a session at one end. The far end keeps sharing to the middle, and the middle uses "Send to this channel". Repeat with all three in TRAX mode (the ends then see each other), and with a repeater on a vehicle roof on the TRAX frequency. Log radio battery over the day.
11. **SOS:** send an SOS from the edge of range to phones with the channel muted and the screens locked, Android and iPhone, in airplane mode with Bluetooth on. Every phone alerts, the sender sees which radios got the DM copies, and a member who walks into range gets the next repeat. The card's main button opens MeshTrax's offline map, and one more tap gives Route here.
12. **Queue:** with a 16-slot radio's phone off, send it 20 positions, 5 channel texts and 1 DM. On reconnect the DM is there and most of the texts are gone, as the help text says. Note each radio model's queue size.
13. **Range day:** at the same spots (valley floor, a canyon, a ridge), 1–10 km apart, with radios carried as in real use, log who hears whom, with and without Off-Grid Repeat, and with a vehicle repeater if the group has one. Where the group still carries APRS, log both. Include an afternoon of normal summer use; never heat a phone on purpose.
14. **Routes on desert park data:** in the traxbook plan (#242); the route caveat, data date and start gap are master fixes here.
15. **Retention and spare radio:** on a test phone, move the clock 31 days ahead: positions and trails older than 30 days are gone, and Delete all lists people first. Connect a second radio: the Last heard list, the route to a person and your own track are all still there.
16. **Search details drill:** produce the details for a member heard an hour ago, and read them to someone writing on paper: two coordinate formats, date, time and time zone, direction of travel, and the trail.
17. **Battery:** 8 hours with the screen off, the recorder on and a 5-minute session (and one day of trip mode), on one Android phone and one iPhone, logging phone and radio battery and the radio's temperature every hour, plus a full day of a radio with GPS on. Then one hour with the map on screen.
18. **Radio button:** switch a phone off, then double-press its radio (original UI) or use the Advert page, with position in adverts on. The others see the position and its time. Repeat on each board model the group carries.
19. **Drive:** drive a dirt road and a paved road with 5- and 10-minute sessions, with and without the 1 km trigger, and compare the gaps between received reports.
20. **Clocks:** with networks off, set one phone 10 minutes fast. Check what each phone shows for the other's reports, and that the phone whose radio has a fix flags its own clock.

**Drills**, from the checkers' missing items:
- **Button drill:** on each board model, practise the double press, and on a bench radio check what four presses and a 3 s hold do.
- **SOS under Do Not Disturb and Sleep Focus:** an Android phone in Do Not Disturb, and an iPhone in Sleep Focus with the silent switch on, each alert for an SOS.
- **Three radios back to back:** ask three members' radios in quick succession; all three answers show.
- **A restarted radio's advert:** before its first fix, radios that heard it before drop the advert as a replay, and others see its stored position; after the fix, everyone sees the live one.
- **TRAX drills:** start TRAX mode with Tell the group: every member's phone prompts, no radio moves without a tap, and the group check lists everyone on TRAX before anyone leaves the trailhead. Restart one phone, and move another to a spare radio, mid-trip: the button still shows on. Leave with Tell the group: every radio returns to its saved settings, and a radio with no saved settings on that phone asks which preset to return to.
- **Single decisions:** let trip mode end with one phone out of range: it keeps reporting every 10 minutes until Stop (13). Run a session to 15 minutes before its end: the Renew warning comes, and trip-mode members rejoin with no tap (12). Set "back by" 10 minutes ahead and stay silent: the others see "overdue" (22). Send a channel text with one member out of range: the sender sees who got it (24).

## Track compression review (2026-11-12)

Martin drafted a text encoding for "a position plus the track that led there" in one message, and asked for a quick look at how tracks can be compressed for MeshCore's packet size. This is that look. **Nothing here is decided:** it is input for the later review of this plan and of the saved-routes plan (#242), which uses the same codec.

Its numbers use the report as it was on 2026-11-12, with 128 bytes for a trail. Since 2026-11-15 a trail gets 126, less any extension block.

### The draft

- **Simplify** with Douglas–Peucker at a tolerance in metres, 10 m as the baseline. Optionally smooth first (a 5-point moving average), because GPS jitter at low speed is otherwise kept as points.
- **Newest first:** the first point is the current position, and a message cut short keeps the newest part.
- **Encode** as a Google Encoded Polyline at precision 4 (0.0001°, about 11 m), in one text message of about 150 characters, behind a prefix that names the precision: `T4:<polyline>`.
- **Next step it names:** a graded tolerance, fine near the current position and coarser further back. Not tested there.

Its test vectors hold. A Python encoder written for this review gives, for Google's example `(38.5, -120.2), (40.7, -120.95), (43.252, -126.453)`:

```
precision 5   _p~iF~ps|U_ulLnnqC_mqNvxq`@
precision 4   o}nV~sjhA_~i@vsM_zp@jnjB
```

### Against this plan

Both simplify with Douglas–Peucker, run newest first from the current position, and take differences between rounded values. They differ in the carrier and in the code.

| | The draft | This plan |
|---|---|---|
| Carrier | a text message | a channel datagram (CMD 62, frame 27) |
| Where it works | DMs and channels, on any firmware | private channels, firmware ver code 11 (companion 1.15) or newer |
| On other apps and older MeshTrax builds | raw text in the chat, counted as unread | nothing |
| Room | 158 bytes in a DM, about 125–140 in a channel ([byte budget](../message-format.md#byte-budget)) | 157 bytes, 128 of them for the trail |
| Step | 0.0001° (11 m north–south). The next choice is 0.001°, 111 m. | any whole number of metres (`grid_unit_m`) |
| Code | 5 bits per character, so 8 bits on air for a small difference | exp-Golomb, order 3: 4 bits for a small difference |
| Longer tracks | none: one message | #242's ROUTE_PART, up to 16 parts |

### Measured

**The lines:** two road lines from OpenStreetMap, fetched from the public OSRM demo server: a 37.8 km mountain highway with switchbacks (US 550 between Ouray and Silverton, 1,604 points) and a 76 km mountain road (Going-to-the-Sun Road, 1,852 points). They are map lines, not GPS recordings, so they have no jitter. No recorded track was at hand.

**The method:** both codes were given the same Douglas–Peucker output, newest first. "Worst error" is the largest distance from any source point to the decoded line, so it includes the rounding.

The whole 37.8 km line at one tolerance:

| Tolerance | Points | Polyline text, precision 4 | This plan's code, with its 7-byte anchor (grid) | Text ÷ binary |
|---|---|---|---|---|
| 10 m | 239 | 563 chars | 387 bytes (8 m) | 1.5 |
| 15 m | 181 | 467 | 320 (8 m) | 1.5 |
| 30 m | 114 | 340 | 196 (15 m) | 1.7 |
| 50 m | 81 | 261 | 135 (25 m) | 1.9 |
| 100 m | 47 | 166 | 76 (50 m) | 2.2 |
| 200 m | 26 | 101 | 44 (100 m) | 2.3 |

- **The other line** gives the same ratios: 1.5 at 10 m, 2.0 at 50 m, 2.3 at 200 m.
- **Per point:** the text takes 2.4–2.6 characters at 10 m and 3.9 at 200 m. This plan's code takes 11–15 bits at every tolerance.
- **Why the ratio grows:** this plan's grid grows with the tolerance, and the polyline stays at 11 m steps.
- **Rounding:** at a 10 m tolerance the worst error was 14 m as text and 13 m on an 8 m grid. With the grid at half the tolerance, rounding added up to 18% to the worst error at the larger tolerances.
- **A byte code** (zigzag and 7-bit varints in 10 m units, the way TWKB and Protocol Buffers write numbers) falls between the two: 479 bytes for the points at 10 m, against 380 for this plan's code and 563 characters of text.

What fits in one message:

| | Text: 150 characters, `T4:` included | This plan: 128 bytes of trail |
|---|---|---|
| The newest part at 10 m | 12.7–13.5 km, 51–53 points | 15.4–17.0 km, 69–72 points |
| The newest part at 15 m | 13.7–14.2 km, 48–52 points | 17.9–20.3 km, 66 points |
| The newest 10 miles | 19–24 m, 46–48 points, worst error 23–26 m | 15 m, 55–62 points in 107–117 bytes, worst error 16–17 m |
| All 37.8 km | 125 m, 40 points | 49 m, 80 points |
| All 76 km | 229 m, 36 points | 90 m, 77 points. With step 4 of the recipe as written: 114 m, 64 points. |

- **"About 57 points at 10 miles"** holds for these road lines.
- **In a channel** the text has 125–140 bytes, not 150, so it holds less than the table shows.
- **A recorded trail is harder.** The draft's test track is a GPS-recorded 39.5 km loop with switchbacks (1,245 points). Douglas–Peucker kept 398 points at 10 m, 247 at 20 m, 197 at 30 m, 134 at 50 m, 76 at 100 m and 39 at 200 m. That is about 10 points per km at 10 m, against 5–6 for the road lines.
  - As text, the loop fit one message at 200 m, or its newest 7.1 km at 10 m.
  - This plan's 128 bytes hold about 75 points at 13–14 bits each. On such a trail that would be about the newest 8 km at 10 m, and the recipe would stop at 34 m or 51 m for a 10-mile window. These are estimates from the draft's point counts: that track was not run through this code.

**Step 4 of the recipe wastes room.** On the 76 km line the ×1.5 loop stopped at 114 m with 21 of the 128 bytes unused. Bisecting between the last tolerance that failed and the first that fit gave 90 m and 13 more points. On the other line the loop happened to stop 1 byte under the limit. MeshTrax already bisects this way for drawings: `SvgWriter.fit` in [svg_drawing.dart](../../lib/helpers/svg_drawing.dart) finds the finest simplification whose message fits.

**Graded tolerance,** the draft's next step, tried here as Douglas–Peucker in which a point is kept when its distance from the line exceeds the tolerance at its own distance back along the track: 15 m for the newest 2 km, then a straight ramp to the far end, on a 16 m grid, in 128 bytes.

| Trail | One tolerance | Graded |
|---|---|---|
| 37.8 km line, its newest 25.5 km | 28 m. Worst error 30 m, and 24 m within the newest 2 km. | Ramp to 37 m. Worst error 38 m, and 9 m within the newest 2 km. |
| 37.8 km line, all of it | 49 m. Worst error 49 m, and 24 m within the newest 2 km. | Ramp to 159 m. Worst error 115 m, and 9 m within the newest 2 km. |
| 76 km line, its newest 25.5 km | 20 m. Worst error 23 m, and 13 m within the newest 2 km. | Ramp to 19 m. No gain: this end of the road is nearly straight. |
| 76 km line, all of it | 90 m. Worst error 100 m, and 37 m within the newest 2 km. | Ramp to 524 m. Worst error 315 m, and 13 m within the newest 2 km. |

- **It works as the draft expects:** the newest 2 km stay as exact as a short trail, and the far end pays. The price is small inside a trail window and large for a long history in one report.
- **The grid matters.** There is one grid per report. On an 8 m grid the far points cost more bits, and the ramp in the first row had to reach 100 m (worst error 75 m). A graded trail wants a grid near 16 m.
- **No format change:** `grid_unit_m` is already in the report, and the receiver needs nothing new.

**The code's details.** On both lines, at 15 m and at 50 m:
- order 4 was 3–5% smaller than order 3, and order 2 was 4–8% larger
- coding the change in the difference (a constant-velocity prediction, as in the draft's binary alternative) ranged from 8% smaller to 2% larger

That is too little to change the format on road lines. Recorded tracks have shorter steps and may point the other way.

**Smoothing** was not measured. The draft smooths because jitter became points at 10 m. Here the radio's positions come in 11 m steps and the movement gate keeps a point only every 25 m, so the recipe's 15 m start is above the step. A tolerance under 11 m would keep the steps themselves as points, so 15 m should stay the floor.

### What the review suggests

For the later review, in order of value:

1. **Keep the datagram and this code for channels.** The same points take 1.5 to 2.3 times as many bytes as text, and a datagram stays out of the chat on every app.
2. **Recipe step 4:** find the finest tolerance that fits by bisection, the way drawings do, in place of the ×1.5 loop. Adopted on 2026-11-15.
3. **Graded tolerance** as an option of the recipe (15 m for the newest 2 km, a ramp beyond, a 16 m grid). Try it on recorded tracks before deciding.
4. **If a text form is wanted** (DMs, older firmware, other apps), there are two ways, and the choice is a product one:
   - the polyline as drafted. Many tools decode it, and it is a second codec to keep.
   - this plan's bytes in Base64url behind a prefix. One codec for both carriers; a 150-character message holds 110 bytes, about 60 points against the polyline's 36–53.
5. **Fixtures:** add a GPS-recorded twisty trail to the GPX fixtures in [Verification](#verification), and fixed vectors (points in, bytes out), as the draft has for the polyline, so a second implementation can be checked.
6. **Leave** order 3 and plain differences as they are.

### Looked at and set aside

| Method | What it is | Why not |
|---|---|---|
| Google Encoded Polyline | Text, 5 bits per character. The precision is not in the string. | The draft's choice: see above |
| HERE Flexible Polyline | The same idea with a header that stores the precision and an optional third value such as height. Its alphabet is `A–Z a–z 0–9 - _`. MIT licence, with a Dart implementation. | Same size as the polyline. The better pick if a polyline is used: no backslash or backtick to escape, and no need for a prefix to name the precision. |
| TWKB | Binary: a precision in the header, differences, zigzag, byte varints, optional height | Byte-aligned, so about a quarter larger than this plan's code |
| Base64, Base85 or Base91 around binary | Text armour at 6, 6.4 and about 6.5 bits per character | Only needed for a text carrier: see suggestion 4 |
| Waypoints and the receiver's router | #242's `Route:` message | The smallest form of a planned route. It can't carry a recorded track. |
| OpenLR | A standard for the same idea: a few reference points, each with a road class, a form of way and a bearing, matched against the receiver's own map | Needs those attributes and a matcher at both ends |
| gzip or zstd on the GPX file | General compression of the XML | A track point is about 100 bytes of XML. Even at ten to one that is 10 bytes a point, against under 2. |
| Other simplifiers: Visvalingam–Whyatt (by area), opening window (one pass), TD-TR and SQUISH (use time) | | Douglas–Peucker bounds the distance, which is what "within 15 m" means. The time-aware ones matter only with per-point times. Published comparisons disagree on which has the lowest error. Not measured here. |
| Arithmetic coding of the differences | An adaptive code in place of exp-Golomb | Not measured. At about 100 bytes it has little to learn from. |

### Sources

- [Encoded Polyline Algorithm Format](https://developers.google.com/maps/documentation/utilities/polylinealgorithm) (Google)
- [Flexible Polyline](https://github.com/heremaps/flexible-polyline) (HERE)
- [TWKB specification](https://github.com/TWKB/Specification/blob/master/twkb.md)
- [OpenLR](https://en.wikipedia.org/wiki/OpenLR)
- [Extensive Comparison of Trajectory Simplification Algorithms](https://studenttheses.uu.nl/handle/20.500.12932/25654) (Utrecht University thesis; abstract only)
- [Batch Simplification Algorithm for Trajectories over Road Networks](https://mdpi.com/2220-9964/12/10/399/xml) (abstract only)

## Looked at elsewhere (2026-11-15)

Martin asked what other open-source MeshCore clients and firmware do for position sharing, as input rather than a change of plan. Seven were read in their code:
- a team-awareness client, and the firmware for its standalone devices
- a group-tracking app
- a plugin and a bridge for a team-awareness map app
- a firmware with live location sharing
- a road-events format

Nothing was copied. Their licences run from MIT to GPL and non-commercial.

**What they do**
- **Carriers:** channel datagrams (three formats: one on a registered type, one in the development range, one on an unregistered type in the range meant for registration), channel text behind a prefix (two), and telemetry requests (one).
- **Pacing:** on while enabled, though one ends sessions after 1–12 hours. They use APRS-style smart beaconing (every 90 s moving, 10 minutes still, early on a 35° turn or after 75 m, never under 30 s), a timer of 60–120 s, or a distance and time gate.
- **Routing:** every beacon floods. Some can keep floods to a region.
- **Trails:** where kept at all, each receiver builds them from successive beacons. None sends a trail.
- **Position source:** the phone's GPS in the phone apps, with the radio as a fallback in some. The firmware uses the radio's own GPS.

**What it confirms here**
- **seq and sent_at:**
  - **Parked members fade out.** The datagram format with neither seq nor a time loses parked members to the firmware's duplicate filter (`src/Mesh.cpp:225-247`). A member whose position comes from the radio stops being heard, and fades out while still beaconing.
  - **Old positions look fresh.** At least four of them time a position by its arrival, so a position that waited in a radio's queue shows as live. One format keeps a timestamp for exactly that reason ("the companion's offline queue can delay datagrams by hours"), and its code then ignores it.
  - **Parking shows.** While someone is parked, that format's first cipher block repeats.
  - The [common header](#common-header-12-bytes-every-packet) and the [time rules](#time) avoid all three.
- **Zero-hop sessions:** five people moving at 90 s make about 3 floods a minute, each repeated by every repeater, for as long as sharing is on. Each one also lands in every away radio's queue. None adapts the rate to the group's size.
- **The channel gate:** only one derives hashtag keys as this plan's [gate](#channel-gate) does. The others check for a leading `#`, refuse the first slot, or check nothing.
- **A registered data type,** as planned.

**Taken:** names, battery and status, bisection, and a turn report to try ([owner decisions](#owner-decisions)). Who got it moved into Step 4 (decision 24) and SOS into a master PR (decision 16); Follow was dropped (decision 55); all preliminary.

**Not taken**
- **Their formats,** also not as a per-channel compatibility mode:
  - most carry no seq or time
  - one sits on an unregistered type with no version field
  - a mode named for another app goes against the rule on naming other apps
  - the apps a "compatible" label would suggest can't read that format anyway
- **Wasteful choices:** always-on flooding beacons (trip mode, decision 8, sends on a timer only while it is on: until its end time, or until Stop when the phone is out of touch then, decision 13; zero-hop unless on an off-grid frequency), positions to 1 cm (8 bytes for precision the radio's GPS doesn't have), and the sender's name in every packet.
- **Per-send region scope with CMD 54.** It is safe for flash: it only sets the scope in the radio's RAM ([flood scope](#firmware-facts-companion-v1180)). But it adds nothing and risks a lot:
  - A channel flood already goes under the radio's default scope.
  - A repeater forwards a scoped flood only when it has that region.
  - An app that dies between set and clear leaves every flood scoped until the next clear or a reboot.

## Audit and safety review (2026-11-15/16)

On 2026-11-15 Martin asked for an audit of this plan and the traxbook plan. A safety review for life-safety use followed the same day, and he answered them in the question dialog as decisions 1–30. Decisions 31–35 (TRAX mode, and the order of the two plans) followed the same day. All are preliminary. Both were read-only, against master `d774d052` and MeshCore tag companion-v1.18.0: nothing was changed in either repo or on GitHub, and the app was not run. The notes, with their evidence and scripts, are kept locally in the gitignored `build/trax-audit/` (`verification-2026-11-15.md`, `safety-review-2026-11-15.md`); a `flutter clean` deletes that folder. The review's lens findings (LM, SW, REACH, DEV, APRS) are merged into its CH items there.

Where each ID went:

| ID | Where it went |
|---|---|
| A1, A2 | Ordering, replay, the seq wrap and the dedupe window: [to settle before Step 2](#to-settle-before-step-2-freezes-v1-proposed-preliminary), [time](#time), [storage](#storage) |
| A3 | The request's lifetime, 10 minutes: Step 3b flow (CH-25) |
| A4 | One report for several requests: not taken. It works only when the requests want the same content and the report's routing reaches every requester, judged by receive time. |
| A5 | The rate limit, one prompt per sender every 2 minutes plus a per-channel cap: Step 3b flow |
| A6 | The antimeridian: to settle before Step 2, trail bitstream, package tests |
| A7 | `gps_interval` writes, corrected by TSX-10: [position and movement](#position-and-movement) |
| A8 | macOS: Step 4 |
| A9 | A scoped flood is 41 bytes, about 224 ms: [firmware facts](#firmware-facts-companion-v1180) |
| A10 | The second cipher block repeats with a live fix: to settle before Step 2, still open |
| B1–B11, C1–C4 | traxbook's data, backups, photos and routing engine: the traxbook plan (#242) |
| C5 | Route here is gated on `offeredAt`: Step 3b pin sheet |
| D1–D4 | The layers sheet's "Trax" section, the filter button, legend entries and the point sheet's pin: Step 3b map |
| D5, D6, D7 | 18 language files; `material_ui` and `appLocalizationsDelegates`; #210 merged: working rules, owner decisions |
| D8 | Line references, updated throughout (connector 6807, channel chat 1244, settings 2104; privacy.md 43, 97, 125, 149, 157) |
| D9 | companion-v1.18.0 is still the newest tag, and `dev` changes none of CMD 62, frame 27 or the queue: firmware facts |
| D10 | The frame 27 case and `_handleErrorFrame`'s order on master: Step 1, Step 3a |
| D11 | `SvgWriter.fit`, not `SvgDrawing.fit`: trail recipe, track compression review |
| TSX-01 | Cut hashtag names: [channel gate](#channel-gate) |
| TSX-02 | Tracker boards refuse `gps_interval`: Step 3a errors, position and movement, Trip setup, firmware facts |
| TSX-03 | Frames after a failed first drain tagged live: master safety fixes (pending), Step 3a |
| TSX-04 | Error codes per command: Step 3a sending |
| TSX-05 | The connector stops the background service: Step 3a, Step 4 Android |
| TSX-06 | Blocked contacts, ignore and undo: Step 3b flow |
| TSX-07 | Pin thresholds: [display thresholds](#display-thresholds), with CH-06's correction |
| TSX-08 | Session state per channel and session: storage (sessions and answers tables) |
| TSX-09 | Hostile and malformed packets: verification (fuzz) |
| TSX-10 | An audit error, corrected: write `gps_interval` once per radio key (position and movement) |
| TSX-11 | The backup helper and Delete all: storage |
| TSX-12 | Hop count 0 and 163 bytes on 1.15.0: firmware facts; Step 1 shipped; `pubspec.lock` in the working rules |
| R-01 | Others' positions in traxbook: decision 6a, Step 3b Route here, storage |
| R-02 | traxbook's saved-route mode: Route here uses its fixed start |
| R-03, R-06 to R-12 | The traxbook plan (#242) |
| R-04, R-05 | One tag list, unknown subtypes: to settle before Step 2 |
| Master bugs | Cut hashtag names: channel gate. `setGps(true)` untracked: Step 3a. The stale comment at connector 810-812: master safety fixes, item 5 |
| SR-01 to SR-10 | [Safety first](#safety-first-proposed-2026-11-16-preliminary), with the checkers' corrections; SR-03 follows decision 11 and SR-10 decision 7 |
| D-01 to D-20 | The review's questions, answered as dialog decisions: D-01 → 7, D-02 → 8, D-03 → 9, D-04 → 12, D-05 → 10, D-06 → 11, D-07 → 15, D-08 → 16, D-09 → 22, D-10 → 20, D-11 → 21, D-12 → 19, D-13 → 23, D-14 → 14, D-15 → 24, D-16 → 25, D-17 → 18, D-18 → 27, D-19 → 26, D-20 → 17 |
| CH-01 | Trip mode: Step 4 (decision 8) |
| CH-02 | Sessions stop only at the end time or on Stop: Step 4 consent (decision 9) |
| CH-03 | Ask their radio and Trip setup (decision 15) |
| CH-04 | Stuck DMs: master safety fixes (decision 20) |
| CH-05 | A minimal SOS: master safety fixes (decisions 16, 17) |
| CH-06 | Pins never end, Last heard list: display thresholds, Step 3b strip (decision 10) |
| CH-07 | The live rule: position and movement; its master part, the dot: master safety fixes (decision 29) |
| CH-08 | The locked-iPhone gate: Step 4 iPhone, open question 5 |
| CH-09 | "Last sent · group last heard": Step 3b strip |
| CH-10 | Parts 1 and 4: master safety fixes (pending); parts 2 and 3: Step 3a and time |
| CH-11 | Keep last positions until deleted: not taken as written; decision 11 chose 30 days for everything |
| CH-12 | One database per phone: storage (decision 14) |
| CH-13 | The recorder (decision 1) |
| CH-14 | The phone GPS fallback: the recorder (decision 21) |
| CH-15 | Relays: TRAX mode, Step 4 and the routing table (decisions 19, 30 and 31–34) |
| CH-16 | Details for a search, Send to this channel: Step 3b (decision 23) |
| CH-17, CH-18 | Route caveat, data date, start gap: master safety fixes (decision 29) and the traxbook plan (decision 26) |
| CH-19, CH-20, CH-34, CH-37, CH-39 | The traxbook plan (#242) |
| CH-21 | Delivery wording: master safety fixes; Who got it: Step 4 (decision 24) |
| CH-22 | Android checks and phone tests: Step 4 Android, Martin on phones |
| CH-23 | The v1 meanings: to settle before Step 2 |
| CH-24 | The release gate: field tests; its help-text line about APRS is left out (decision 7) |
| CH-25 | One-time requests: Step 3b menu, flow and strip |
| CH-26 | Not moving: position and movement |
| CH-27 | "Radio battery", phone heat: Step 3b pin sheet, Step 4 |
| CH-28 | Clocks: time |
| CH-29 | Adverts: Step 3b contact pins (decision 18) |
| CH-30 | The 1 km trigger and Send my position now: Step 4 scheduler |
| CH-31 | Status and back by: Step 4 (decision 22) |
| CH-32 | DMs in the help text: Step 4 (decision 27) |
| CH-33 | Route here with the position's time: Step 3b (decision 6a) |
| CH-35, CH-36 | Springs, drinking water, line of sight: master safety fixes (decision 29) |
| CH-38 | Accuracy and trail labels: Step 3b pin sheet; "trail since" to settle before Step 2 |
| Field tests 1–20 | [Field tests](#field-tests-proposed-preliminary). Test 13 logs APRS only where the group still carries it (decision 7); test 15 moved to 30 days (decision 11). |
| Missing: button traps | Help text, Trip setup, drills |
| Missing: fallback position | Trip setup at the trailhead; firmware facts |
| Missing: `gps_interval` left at 900 s | Trip setup; position and movement |
| Missing: GPS off | Ask their radio's label |
| Missing: a full contacts table | Trip setup marks favourites |
| Missing: one telemetry request at a time | Ask their radio; firmware facts |
| Missing: SOS sound | The minimal SOS; drills |
| Missing: radio heat | Ask their radio shows voltage and temperature; help text; field test 17 |
| Missing: GPS interference tests | Help text |
| Missing: a radio left behind | Ask their radio's label |
| Missing: phones' satellite SOS | Help text |
| Missing: mixed app versions | Feature level, to settle before Step 2; Trip setup's Test; help text |
| Missing: sharing that ends while out of touch | Decision 13, Step 4 |
| Missing: hiking times | The traxbook plan |
| Missing: beep their radio | Later, as an idea |
| Operational advice, facts to ask | Left in the notes: they are trip advice and questions about the group; the help text takes what belongs in the app |

## Open questions for Martin

1. Do test version bumps stay in the PR, or are they reverted at merge as in #229?
2. The privacy-policy and store wording: drafted in the PR, edited by him.
3. Should the consent dialog offer an approximate position? The format already carries it; v1 sends exact.
4. **Answered (decision 27, preliminary):** no request to the firmware project about the queue's drop order for now; the help text says to use DMs. Requesting the `data_type` allocation upstream is still his call, as a public request in another project; the audit suggests doing it once Step 3 works on air, with one allocation for both plans.
5. **Now a gate (CH-08):** the iOS background test on his Mac and iPhone must pass before anyone relies on sharing, trip mode or the recorder on an iPhone.
6. From the [track compression review](#track-compression-review-2026-11-12): is the draft's text form (`T4:`) meant to replace the datagrams, or to add a way in for DMs, older firmware and other apps?
7. Graded tolerance: is a coarser far end a fair price for a finer near end, and how far back counts as near? The draft says about 2 km.
8. Are per-point times or heights wanted in a trail? The format reserves both (mask bits 8 and 9), and each takes room from the points. A "trail since" item, the age of the trail's oldest point, is a smaller step (CH-38).
9. **Answered (decision 22, preliminary):** the screens offer the status (OK, need help, heading back), plus an optional "back by" time.
10. The bench test: does a parked radio's reading keep changing with a fix, its altitude in 0.01 m steps? It decides the live rule, how soon the live state expires, and the "your dot after a lost fix" master fix (decision 29).
11. Where do Ask their radio and Trip setup (decision 15) land: in their own PR before Step 3, as CH-03 proposes, or with Step 3b?
12. SOS on iPhone: should MeshTrax apply for Apple's critical-alerts entitlement, which sounds even on silent? The time-sensitive level needs only a capability.

## What the earlier draft got wrong (don't bring these back)

| Draft | Why not |
|---|---|
| Switch the radio's default flood scope around every report to keep it off repeaters | CMD 63 rewrites all settings to flash on each call, and a crash between the two writes leaves every flood blocked by repeaters. Zero-hop does the job with no state. |
| Run the three commands through "the app's command queue" | There is none; `sendFrame` writes straight to the radio |
| Accuracy, heading and speed from the phone's GPS | Reports never carry the phone's GPS (decision 21 makes it a local fallback only); the radio gives lat/lon/alt only |
| A relative fix age is enough | Frames wait in the radio's queue with no timestamp |
| Receive `path_len` 0xFF means a neighbour sent it | It means route-direct; a flood heard from its sender reports hop count 0 (`path_len & 63 == 0`) |
| 166–167 bytes return TABLE_FULL | 1.18 returns ILLEGAL_ARG; TABLE_FULL means the packet pool is empty |
| Exp-Golomb as "q zero bits, then…" | That is unary coding; use the standard code above |
| "Request:" text messages and `path=` fields | Breaks the [message format](../message-format.md) rules, shows raw text on other apps, and identical texts within 5 minutes are merged |
| Repurpose the target icon in the chat bar | No such button exists |
| Always approve favourites | Any member can claim a favourite's prefix |
| Gate Pathfinder input on repeat mode; reset every contact's route | Pathfinder already keeps one graph file per mesh (frequency, bandwidth, spreading factor, coding rate), so a retuned radio gets its own; the DM ladder already falls back to flood |
| Record your own position always, keep everyone's tracks 7 days | The recorder starts and stops by hand or with a session (decision 1), others' data goes after 30 days (decision 11), both preliminary, and all of it stays out of backups |
| A 3 m trail grid, a 50 m accuracy filter, 3D simplification | The radio steps 11 m, gives no accuracy, and altitude isn't on the wire |
