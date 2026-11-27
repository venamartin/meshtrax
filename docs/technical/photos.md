# Photos: how they work

> **What this is:** How MeshTrax sends a photo over MeshCore and rebuilds it on the other phone: the packet format, the photo model and its runtime, the memory and safety checks, the rules on MeshCore frequencies, and how to check a change. The user's side is in [Photos](../photos.md).
>
> **Who it's for:** developers and the AI-assisted sessions working on MeshTrax. The feature arrived as one pull request without its earlier history, so this file is the record of how it works and why.
>
> **Status:** built. Sent over the air between an iPhone and an Android, both ways. Firmware facts are from MeshCore 75b04ef; those behind [Hearing it passed on](#hearing-it-passed-on), from its dev branch at ae28381.
>
> New to the terms? See the [glossary](../glossary.md).

## In one paragraph

The sender's phone blurs any faces in a 512 × 512 photo, then codes it with the AEIC-SE image codec at its `ft8` level: about 400 bytes. traxpix cuts that into 2 to 6 channel-data packets of up to 157 bytes and, if the sender turns on **Repair packet**, adds one XOR repair packet. The photo goes into the sender's chat at once, and the chat sends its packets one at a time as MeshCore channel data, type `0x0172`, as a flood like a channel message, or zero hop. Each packet follows a channel message's rules before the next goes: the chat waits for repeaters to pass it on, observers are asked about it where they are used, and one that wasn't carried goes again with its retry byte bumped, a new packet to every repeater. The receiving phone puts the packets back together, decodes the bitstream into the model's latents, and a decoder built on SD-Turbo draws a picture from them. A safety classifier checks every picture before it is shown. Full screen, the user can enlarge it 4× with a small Real-ESRGAN model. Everything runs on the phone, on the CPU, with Google's LiteRT 2.3.0.

## Where the code is

| Part | Where | What it does |
|---|---|---|
| Packet format | `packages/traxpix` (pure Dart) | `photo_chunks.dart`: the packet format, a photo into packets and packets into a photo, the repair packet and the retry byte. Nothing in traxpix sends, receives or keeps time. `photo_extras.dart`: a photo's extras, the sender's tag and position. `subject_only.dart`: the square around a tapped subject, the black around it, and where a picture's subject is. `face_cover.dart`: finding and covering faces. `image_codec_entropy.dart`, `rans_coder.dart`, `rans_coders.dart`, `entropy_tables.dart`: the entropy coding between latents and bitstream. |
| Model runtime | `packages/traxpix_litert` (Flutter plugin) | `litert_api.dart`: LiteRT's C API through FFI. `litert_codec_backend.dart`: runs the models. `image_codec_session.dart`: one worker isolate per job. `image_codec_bundle.dart`, `image_codec_files.dart`: the files and their hosted SHA-256 pins. `image_codec_memory.dart`: memory checks. `tap_segmenter.dart`: the tap model's input. `image_safety.dart`: the classifier and its thresholds. Platform folders: the LiteRT binaries. |
| Radio side | `lib/services/photo_mesh.dart`, `photo_reassembler.dart`, `photo_repeats.dart`; `lib/connector/meshcore_connector.dart` (`sendChannelPackets`) | `photo_mesh.dart` hands the chat a photo's packets, files photos in their channel's chat, and decides whether the phone can do photos at all. `photo_reassembler.dart` collects received packets into photos, for 20 minutes. `photo_repeats.dart` keeps what the sender heard of each packet of its own photo, for its row. The connector sends the packets as it sends channel texts, under the same rules. `lib/services/channel_requests.dart` and `lib/models/channel_request.dart` carry the requests for lost packets ([Channel requests](channel-requests.md)). |
| Photos kept | `lib/services/photo_store.dart` | The records, the coded bytes, the rebuilt pictures, and the one-at-a-time queue for rebuilds and enlargements. |
| Model download | `lib/services/photo_model_downloads.dart` | Downloads the model through the map downloader. |
| Rules | `lib/services/photo_rules.dart` | Where the MeshCore-frequency rules apply, the time limits, the gap between packets, what the sender is asked. |
| Saving | `lib/services/photo_save.dart` | Draws the "AI reconstructed" mark and the footprint into a copy and saves it. |
| Reports | `lib/services/photo_reports.dart`, `lib/services/report_inbox.dart` | Photo reports, kept on the phone until the report inbox has them. |
| Screens | `lib/screens/photo_send_screen.dart`, `lib/widgets/photo_message_card.dart` (chat bubble and full-screen viewer), `photo_receiving_strip.dart` (photos coming in, and Ask for the rest), `photo_settings_section.dart`, `photo_ai_mark.dart`, `photo_footprint_mark.dart`, `photo_report_dialog.dart`, `lib/screens/photo_licences_screen.dart` | The user's side. |
| Native | `ios/Runner/AppDelegate.swift`, `android/.../MainActivity.kt`, `macos/Runner/MainFlutterWindow.swift` | `meshtrax/storage`: the phone's memory (iOS), free space, saving to the photo library. |

## Sending

1. **Pick and crop.** The photo is cropped square and scaled to 512 × 512 RGB. With **Subject only** or **Auto crop**, the sender taps what matters first and the square can run past the photo, black past its edges (see [Subject only and Auto crop](#subject-only-and-auto-crop)); Subject only makes everything outside the outline black before the check.
2. **Check.** The classifier checks the original. A flagged photo is never coded or sent.
3. **Faces.** With **Blur faces** on (the default for each photo), MediaPipe's BlazeFace models find the faces (`face_cover.dart`, see [Faces](#faces)) and each is blurred and pulled towards grey, or under a flat tone when it's under 32 px. The AI rebuilds faces badly, so it would make them up.
4. **Code.** The send side of the entropy network (`aeic_side_ft8.tflite`) turns the picture into latents, and the rANS coder writes them as a bitstream of 208 to 796 bytes, about 400 on average.
5. **Preview.** The phone rebuilds the bitstream exactly as a receiver will and checks that too, with the sender's margin (see [Safety](#safety)), so the sender sees what the others will get and they won't refuse it. If the blurred photo's rebuild doesn't pass, the faces go under dark grey instead and it's coded and checked again. If the memory isn't there, it says so, the original takes the margin instead, and the photo can still be sent. A tap on the preview opens it in the photo viewer (`PhotoViewerScreen.preview`): zoom, and Enhance 4× from the preview's picture (`PhotoStore.enlargePng`), with no Save or menu.
6. **Tag and position.** The sender may type a tag, up to 24 characters and 64 UTF-8 bytes, and turn on **Include location**, off for each new photo, at about 10 km, 600 m, 40 m or 2 m (3 to 6 bytes, 40 m to start). The position is the radio's, from its GPS or the one set in the app. Both go ahead of the bitstream as extras (`photoPayload`; see [The packet format](#the-packet-format)). The receiver shows them as text, so the AI can never change them.
7. **Packets.** The payload is cut into blobs of up to 157 bytes, each with its retry byte at 0 (`buildImageChunks`), then the XOR repair blob is added if **Repair packet** is on. That switch is off for a new user and keeps the last choice (pref `photo_repair_packet`).
8. **Route.** Each blob goes to the radio as `CMD_SEND_CHANNEL_DATA` (62), with path length `0xFF` for a flood or `0` for zero hop. A flood goes through the radio's own scoped flood (`sendGroupData` → `sendFloodScoped`), the same call as a channel text, so it takes the radio's region. Where the connector puts a channel's sends in a region, or sends a Nearby only channel zero hop, channel data is included, so a photo follows its channel as text does. A Nearby only channel's photo is zero hop throughout (`PhotoMesh.sendPhoto`, the send screen): the switch shows on and can't be changed, the confirmation says zero hop, the gap is the zero-hop one, and only the 10-minute limit applies.
9. **Chat first.** On **Send** the photo is filed in the chat as the sender's own, with the preview as its picture, and the send screen closes (`PhotoMesh.sendPhoto`). The chat then sends its packets (`MeshCoreConnector.sendChannelPackets`), after any photo of the sender's still going, so the sender is back in the chat at once. A line under the photo says what it's doing (`PhotoMesh.sending`): "Waiting to send", "Packet 2 of 4", "Packet 2 of 4 again", "Packet 2 of 4: asking observers". The line goes once the last packet is done with, and the photo shows the checks a channel message does.
10. **Pacing.** One packet at a time, each handed over no sooner than the gap after the one before (see [The gap between packets](#the-gap-between-packets)) and, as a text is, once the radio has heard nothing for 3 s (`_waitForRadioQuiet`), so an SOS or a message sent meanwhile goes first.
11. **Heard passed on.** Through repeaters, the sender's radio hears its own packets again only as a repeater's copies (see [Hearing it passed on](#hearing-it-passed-on)). Each packet goes again on a channel message's terms before the next goes.
12. **Not taken.** A packet the radio refuses, or doesn't answer for, ends the photo: its row turns red, and the line under it says why ("Not sent: the radio didn't answer"). Nothing after it goes.

## Hearing it passed on

The firmware gives a channel datagram no ACK, but the sender can still tell whether it got out: the radio logs every packet it hears (`PUSH_CODE_LOG_RX_DATA`, in `Dispatcher::checkRecv` before any check), and its own flood comes back only as a repeater's copy, with that repeater in the path. The connector opens each logged channel datagram with the channel's key (`_handleRawGroupData`). A copy of a packet the chat is sending, or still listening for, is matched to it by its bytes, all but the retry count (`_ownChannelPacketCopy`, `samePhotoPacket`): two senders can share the sender prefix and image id, so only a copy of the packet as sent counts. Everything else goes on to `PhotoMesh` as a received packet (`onRawChannelData`).

- **A channel text's rules, written once.** The chat sends a photo's packets as it sends a text (`sendChannelPackets`): it waits for the radio to be quiet, hands the packet over, and once the radio has it (its OK) waits `channelRepeatWait`, 30 s, for a repeat (`_startWaitForRepeatTimer`). The same code decides for both:
  - A copy through two repeaters or more, counting every repeater in every copy's path, or any copy while observers can't vouch for this radio: it's out, and the next packet goes.
  - Only one repeater, or only car repeaters, where a text only one repeater carried could go once more (`mayResendAfterOneRepeater`: Check sends with observers on, an observer heard this radio in the channel's region in the last day, the region isn't quiet, and fewer than 3 such sends in a row went unheard): it keeps waiting, for a second repeater or an observer. Neither by the end of the wait: it goes once more, a miss unless an observer hears the photo by the last ask, and the next packet goes.
  - An observer heard it (`confirmChannelSendHeard`): it's on air, and the next packet goes.
  - Nothing by the end of the wait: it goes again, up to **Max Channel Message Retries** times (0 to 3, 1 by default), each waited for in turn. At 0 nothing goes again, on any rule.
  - No OK from the radio within 30 s: it goes again on the same count, or the photo fails. A refusal fails the photo at once.
  - Zero hop and Nearby only channels send nothing again; nothing passes them on.
- **Again, as a new packet.** Channel data carries no timestamp (`BaseChatMesh::sendGroupData` seals only data type, length and blob), and a packet's hash covers its payload, not its path (`Packet::calculatePacketHash`). A packet sent again as it first went would be the same packet, and every repeater that passed the first on would drop it as already seen (`SimpleMeshTables`); a channel text's retry is stamped anew for that reason. A photo packet sent again gets its retry byte bumped (`photoPacketAgain`: 1 the first time again, then 2, 3): the encrypted data differs, so to the mesh it is a new packet, which every repeater passes on, and the observers are asked about it by its own hash. A receiver takes it as the packet it repeats (see [Receiving](#receiving)). It goes only within three quarters of the receivers' 20-minute window (`photoReceiveWindow`) from the photo's first packet.
- **Car repeaters.** As for channel texts (#356), a copy counts as passed on only when its path holds a repeater that isn't marked "Moves" or "Moves with me" in Pathfinder (`isCarRepeater`; with Pathfinder off, every repeater counts). For the rules above, a copy only car repeaters carried counts as one repeater, as for a text. A car repeater's copy still shows in the row's repeats and in Packet Path.
- **Pathfinder.** The first repeater of a heard copy heard this radio directly, which Pathfinder hears of as it does of a channel text's echo (`onOwnEchoHeard`), once per photo per first repeater, and only for a copy of the packet as sent. It never hears that a packet wasn't passed on: from photos that would be noise.
- **In the chat.** The row waits (`MeshCoreConnector.waitForRepeats`) from when it's filed until a text's wait for its repeat after the last packet is done with. It shows Delivered once a repeater was heard passing on every packet a receiver needs: all data packets, or all but one and the repair packet. Otherwise it ends Sent with the amber check, whose long-press says how many packets were passed on when any were. The copies heard and their paths go on the row as a text's echoes do (`recordOwnRepeats`), so Packet Path lists the repeaters; the count goes in the record as `packetsPassedOn`.
- **Observers.** With **Check sends with observers** on, each packet is asked about as a channel text is after each send (traxheard's `HeardChecker`, at 10, 25 and 60 seconds), by its own hash, from when it goes (the connector's `onChannelPacketSent`, then `HeardService.trackPhotoPacket`), in the channel's region, under the photo's chat row id. A Nearby only channel's photo isn't asked about, as its texts aren't. A packet's hash is known before it goes (`channelDataPacketHash`: payload type 6 and the sealed data type, length and blob, as the radio seals them); one sent again has its own, asked about with the first. On an observer server's own channel data, 50 of 50 packets were filed under exactly that hash. An observer's sighting of any packet gives the row its ear, Packet Path lists the observers, and the amber check goes, as for a text.
- **What it can't tell.** A copy shows only that the first repeater carried the packet, not who further on got it; observers, where there are any, show more. A packet counted as not passed on may have been passed on unheard, and goes again all the same, as a text does. In a region a second repeater's copy fits the raw log only up to 2-byte codes (see [The packet format](#the-packet-format)), so the repeats and paths shown can be fewer than were heard.

## The packet format

Each packet is one MeshCore `PAYLOAD_TYPE_GRP_DATA` with data type `0x0172`, one of the block 0170–017F that MeshTrax asked for in MeshCore's `docs/number_allocations.md` (meshcore-dev/MeshCore#3925); `0x0171` is TRAX's. A blob is at most 157 bytes:

```
  off  size  field
  0    2     sender prefix: the first 2 bytes of the sender's public key,
             in every packet, since the firmware gives no sender identity
             with channel data
  2    1     image id, per photo
  3    1     idx << 4 | total: packet index 0..15, data packets 1..15;
             idx == total is the repair packet
  4    1     retry: low 4 bits, how many copies of the packet went before
             this one (0 the first time), sent again by the chat or as
             asked for; high 4 bits, flags, 0 so far, which a receiver
             ignores when it doesn't know them
  5    ...   body
```

- **MeshTrax 1.12.0** sent photos as `0x0170`: the same packets without the retry byte. Later releases neither send nor read `0x0170`, and 1.12.0 doesn't read `0x0172`, so neither shows the other's photos. `0x0170` can take another use a few weeks after the first release that stopped reading it.
- **The retry byte** costs one byte of picture per packet. Its spare bits are room for per-packet flags a receiver may ignore; anything a receiver must understand goes in the version bits of packet 0's metadata byte instead, so an older phone says "needs a newer MeshTrax" rather than misreading the photo.
- **Chunk 0's body** starts with the metadata byte, `extras(1) | version(3) | resolution(2) | rate(2)`. Rate code 2 is `ft8`, the only quality; codes 0, 1 and 3 are refused, never guessed at. Resolution code 0 is 512. The format version is 0, and any other is refused: it's kept for a change no earlier release could skip. The extras bit says the payload starts with extras. Chunk 0 then carries 150 bytes of payload, the others 151.
- **Extras** are items, each a type byte (`another follows(1) | must understand(1) | number(6)`), a length byte and its data; the bitstream is everything after the last. Item 1 is the tag, in UTF-8. Item 2 is the position: a geohash's bits packed in 3 to 6 bytes, so its length is its accuracy (5 bytes are exactly an 8-character geohash). Item 3, with no data, says the photo is Subject only: a viewer opens framed on its subject. A receiver skips an item it doesn't know, and a position of a size it doesn't know, so a later release can add items and earlier ones still show the photo. An unknown item marked must-understand makes the photo "needs a newer MeshTrax". A photo with no tag or position has no extras, not a byte more.
- **The repair chunk** is the XOR of the data bodies, with one byte for the XOR of their lengths. Any one lost data chunk can be rebuilt from it. It's optional: a photo completes from its data chunks alone, and an incomplete one counts the repair packet only if it came.
- **Why 157:** a photo packet is 2 bytes of header and path length, the path, 3 of channel hash and MAC, and the ciphertext. That's whole 16-byte blocks of data type (2), length (1) and blob, so 157 makes 160 bytes of ciphertext and a 165-byte packet. The radio copies a heard packet to the app (`PUSH_CODE_LOG_RX_DATA`) only up to 173 bytes, so the sender can still hear its packets repeated with up to 8 bytes of path. In a region a flood also carries 4 bytes of transport codes, which leaves 4 bytes of path: 2 hops at 2-byte codes. The first repeater's copy, the one that matters for [Hearing it passed on](#hearing-it-passed-on), fits at any code width (172 bytes at 3-byte codes).
- **No CRC of its own:** the LoRa PHY checks every packet and MeshCore checks a 2-byte MAC. A merge of two senders' photos would need the same sender prefix, image id and channel within 20 minutes.

## Receiving

1. **Packets in.** Channel data arrives as `RESP_CODE_CHANNEL_DATA_RECV` (27), which the connector hands out (`channelDatagrams`). `PhotoMesh` gives packets of `0x0172` to the `ImageReassembler` (`photo_reassembler.dart`), the raw log's copies too. It keys a photo by sender prefix, image id and channel, and keeps its packets for 20 minutes from the first (`photoReceiveWindow`), since a sender waits for each packet to be heard. traxpix makes the photo from them (`ImagePackets`). A packet sent again counts as the one it repeats, its body being the same, and one that comes after the photo is whole is dropped as a late copy. MeshTrax 1.12.0 kept a photo's packets for 60 seconds. Each copy says how many repeaters it came through: a frame in its path length (`PathHelper.pathLenHops`; 0xFF means it came direct, which a photo does only zero hop), a raw copy in its path. The reassembler keeps the fewest (`fewestHops`).
2. **Whole, or not.** With all data chunks, or all but one plus the repair chunk, the photo is complete. Otherwise, 20 minutes after its first packet, the chat says "Photo incomplete: x of y packets". An item that runs past the end makes it "unreadable"; a format version or must-understand item this release doesn't know, "needs a newer MeshTrax". Until then, the user can ask the sender for the packets lost on the way ([Asking for lost packets](#asking-for-lost-packets)).
3. **Filed.** The chat gets a line "📷 Photo #id" (with the tag if any), marked by its packet hash (`photo:…`), with the fewest hops as its hop count: **Direct** when a packet came from the sender's radio itself, as for a message heard direct. And `PhotoStore` keeps a record (bytes, packets, tag, position) and the coded bytes. A position shows under the photo in the reader's coordinate format, with **Map** and **Navigate** as on a location card. A blocked sender's photos are dropped, not kept.
4. **Rebuilt** when the user taps the photo, or as it arrives if "Rebuild received photos automatically" is on and the phone has the memory:
   1. the hyperprior's synthesis and the four context stages turn the bitstream back into latents (`y_hat`, 256 × 16 × 16);
   2. the decoder runs in three parts: AEIC's synthesis transform (`gs`), SD-Turbo's UNet with AEIC's LoRA merged in (`unet`), and AdcSR's pruned VAE decoder (`vae`); the picture is `vae(unet(gs₀) + gs₁)`;
   3. the classifier checks the picture.

   A passed picture is kept as a PNG in the cache folder (at most 100 MB, oldest first out). A flagged one shows only "Image hidden", and its pixels are never stored.
5. **Full screen.** One tap on the bubble opens the viewer, which rebuilds the photo there if it hasn't been. A Subject only photo (extras item 3) keeps where its subject is in its record (`subjectBox`: the part that isn't black, from `litBox`, worked out by the sender from its preview and by a receiver as it rebuilds), and the bubble and the viewer open framed on it. It has pinch and double-tap zoom, Save, a ⋮ menu (About this photo, and Report and Block for a received photo), and **Enhance 4×**.
6. **Enhance 4×.** It runs in the same queue as the rebuilds, after a memory check, and with every other model released first (`ImageCodecSession.enhance`). The result is checked like a rebuilt picture. It isn't kept: closing the viewer drops it.
7. **Save.** Save writes what's on screen to the phone's photo library: iOS through `PHPhotoLibrary` (add only), Android to Pictures/MeshTrax through MediaStore, a Mac through a Save dialog. The copy has "AI reconstructed" drawn in its bottom-left corner, at 2.4 % of its width, and the MeshTrax footprint in its bottom-right: white at 70 % with a light shadow, 7 % of the width tall. On screen the footprint is drawn over the rebuilt picture the same way, and zooms with it in the viewer.

## Asking for lost packets

A receiver can ask a photo's sender for the packets that didn't reach it, with one tap; nothing asks by itself.

**The receiver.**

- `PhotoMesh.receiving` lists the photos coming in (`ImageReassembler.receiving`), and `PhotoReceivingStrip` shows those of the open channel above the message box: "📷 Photo #3a from Bob: 4 of 10 packets so far".
- A missing packet counts as lost when a later one came, since the sender is done with each packet before the next goes. When nothing came for 3 minutes (`askSilence`), every missing packet counts. A single missing packet doesn't count while the repair packet may still come and rebuild it.
- With packets lost, the line says how many and offers **Ask for the rest** until 15 minutes after the photo's first packet (`askWithin`), which leaves the answer time to arrive within the 20 minutes the receiver keeps the photo.
- A tap (`PhotoMesh.askForRest`) doesn't ask at once. It waits 5 to 30 seconds, at random (`askWaitLeast`, `askWaitMost`), and the line says "Asking…". Then it sends one request of kind 1 ([Channel requests](channel-requests.md)) to the sender alone: the photo's image id, its data packets, and the lost ones. The button then rests for 2 minutes (`askRest`), and the line says "Asked for 2 packets".
- **Many receivers, about one ask.** Every receiver of a photo hears the others' asks for it (`ChannelRequests.overhear`). When its wait ends, it leaves out the packets someone else asked for within the last 2 minutes: the sender's answer to that ask brings them, and the sender wouldn't send them again within 2 minutes anyway. If that leaves nothing, nothing goes, the line says "Someone asked; waiting", and the button comes back after 2 minutes, as after an ask. So when ten phones lost the same packets, the first whose wait ends asks, and the other nine hear it and wait.

**The sender** keeps each photo of its own for 20 minutes (`_SentPhoto`). A request names its sender prefix, a photo it keeps on the same channel and with the same data packets, or it's ignored. Then:

- It gathers for 10 seconds (`askGather`), so asks from several receivers go out as one.
- Each packet goes again at most once per 2 minutes (`askRest`), and the photo goes again as asked at most 3 times (`askRounds`).
- The packets go through the chat's queue (`sendChannelPackets` with `once`): each goes once, done with when the radio has it, in its turn after any photo still going, with the photo's gap, and zero hop if the photo went zero hop. Copies repeaters pass on count on the photo's row as its own do.
- **The retry byte** of every copy counts the copies of that packet that went before it, the photo's own sends and the ones asked for alike (`_SentPhoto.copy`). The chat makes each copy just before it goes, so no two copies are one packet on the air, which repeaters would pass on only once.

The log says what was asked and sent, under the Photos and Requests tags: "beef asked for packets 2, 3 of #3a", "sending packets 2, 3 of #3a again, as asked".

## The model

The `ft8` v1 files, LiteRT `.tflite`, pinned by SHA-256 in `image_codec_files.dart`:

| File | Bytes | What it is |
|---|---:|---|
| `aeic_side_ft8.tflite` | 66,868,776 | Send side: analysis transform and hyperprior, float32 |
| `aeic_hyper_ft8.tflite` | 7,917,292 | Receive side: the hyperprior's synthesis, float32 |
| `aeic_stage0_ft8.tflite` … `stage3` | 36,952,400 each | Receive side: the four context stages, float32 |
| `aeic_cdf_ft8.bin` | 813,648 | The rANS probability tables |
| `aeic_decoder_gs_ft8_pt2e.tflite` | 67,994,256 | Decoder part 1: AEIC's synthesis transform, int8 weights |
| `aeic_decoder_unet_ft8_pt2e.tflite` | 794,455,600 | Decoder part 2: SD-Turbo's UNet with the merged LoRA, int8 weights |
| `aeic_decoder_vae_ft8_f32.tflite` | 52,140,504 | Decoder part 3: AdcSR's VAE decoder, float32, run in half precision |
| `image-safety-classifier-s.tflite` | 22,794,792 | The safety classifier |
| `realesr-general-x4v3-dn05.tflite` | 4,922,696 | The 4× enlarger: Real-ESRGAN's compact model with its denoising version averaged in half and half, float32, run in half precision |

1,165,717,164 bytes in all, with `NOTICE.txt` (how each file was made) and six licence texts beside them.

- **Where they live:** `https://maps.meshtrax.io/models/ft8/v1-litert/<sha256>/<name>`, in the `models/` folder of MeshTrax's map bucket. The folder name is the file's SHA-256, so a URL never changes what it serves. Nothing there is overwritten: a new version goes to a new folder (`v2-litert`) with new pins.
- **The download:** the user turns on Photos (App settings → Messaging) and taps Download. The files come through the map downloader as downloads of kind `photo-model`, so they follow "Download on Wi-Fi only" and show in Offline maps. Each one is checked against its size and SHA-256. They go in `Documents/ft8`, which is kept out of iCloud and Android backups.
- **Licences:** the decoder is built on SD-Turbo, so the Stability AI Community License applies. The app shows "Powered by Stability AI" with the NOTICE and the licences (`photo_licences_screen.dart`). LiteRT's own licence and its third-party notices ship in `assets/licenses/` and appear in the app's licence list.

## The runtime

LiteRT 2.3.0's C API, called through FFI, on the CPU with XNNPACK. The binaries are Google's, unchanged, from `https://maps.meshtrax.io/runtimes/litert-2.3.0/<sha256>/<name>`:

- **iPhone:** `CLiteRT.xcframework.zip`, a SwiftPM binary target pinned by its checksum (`packages/traxpix_litert/ios/traxpix_litert/Package.swift`).
- **Mac:** `CLiteRT_mac.xcframework.zip`, the same way.
- **Android:** `litert-2.3.0.aar`, fetched by Gradle from an Ivy repository on the same host (`packages/traxpix_litert/android/build.gradle`). The build checks its SHA-256 and takes only `libLiteRt.so` for arm64 from it.

How the models run:

- **One worker isolate per job** (`ImageCodecSession.spawn`), which loads a model only when an operation needs it. It releases the entropy network's send and receive halves before compiling the decoder, the decoder before either half, and everything before the enlarger. The app opens a session for each rebuild or enlargement and closes it after, so nothing stays loaded between photos.
- **Threads:** one per CPU core.
- **Half precision:** the VAE and the enlarger are float32 models run with XNNPACK's `FORCE_FP16` flag, which keeps flat areas such as sky smooth. On a CPU that can't, they run in full precision.
  - Half precision overflows on some dark pictures, such as a large bright subject on black (Subject only), and the VAE's whole output comes out NaN.
  - The VAE then runs again in full precision, with the decoder's other models released first.
- **Weight cache:** XNNPACK packs each model's weights once and keeps them in `Documents/ft8/xnnpack/` (about 1.1 GB, written during the first rebuild), mapped from there afterwards. The half-precision models never use it: in LiteRT 2.3.0 the cache aborts the app on a half-precision model (`MMapWeightCacheProvider::LookUpOrInsert`).

## Photos must code alike on every phone

The entropy network's arithmetic decides the bitstream. A receiver whose send-side or context-stage outputs differ by one bit in the wrong place decodes a different, plausible picture, with no error to show for it. So every device must compute those models bit for bit alike. LiteRT 2.3.0's float32 CPU path does: 190 test photos coded and decoded identically on a Mac, the iPhone simulator, an iPhone and an Android.

The decoder doesn't have to match, and doesn't: two phones' rebuilds of one photo differ slightly, with the same quality against the original.

Before LiteRT or any entropy-network file changes, run `packages/traxpix_litert/test/litert_reference_test.dart` on a Mac (below) and the same 190 photos on an iPhone and an Android. Every one must code to the same bitstream and decode the Mac's bitstream to the same latents. A version that doesn't is a new photo format: it needs its own rate code or data type, never a silent swap.

## Memory and speed

- **iPhone limit:** iOS stops an app that goes over its memory limit, without warning. A rebuild needs about 1.4 GB more than the app is using (`kImageCodecRebuildBytes`, measured on a 4 GB iPhone with the weight cache). The 4× needs about 1 GB (`kImageCodecEnhanceBytes`).
  - Both are checked first (`os_proc_available_memory`). If short, the app frees the map's memory and checks again, then gives up with a message rather than be stopped.
  - On Android the 4× checks the system's available memory (`MemAvailable`).
- **Without the weight cache:** a rebuild doesn't fit on a 4 GB iPhone at all, nor does the 4× beside a loaded decoder.
- **Which phones:** iPhones with 4 GB of memory or more (`checkPhotoMemory`; a 4 GB iPhone reports a little under 4 GB), 64-bit Arm Android, and Macs on macOS 12 or later. There are no photos on Windows, Linux or the web.
- **Automatic 4×:** "Enlarge photos automatically" is offered only on phones that report at least 7 GB, that is phones sold with 8 GB or more. Others enlarge on a tap.
- **Timings:**

  | | 4 GB iPhone (A12) | 12 GB Android |
  |---|---|---|
  | Rebuild | about 15 s (22 s the first time, writing the cache) | about 2.5 s |
  | 4× | about 4 s | about 1 s |

  Rebuilds one after another for minutes slow down by about a fifth as the phone warms up.
- **Firmware:** the radio needs companion firmware 1.15 (version code 11) or later, for channel datagrams.

## The gap between packets

`photoGapFor` in `photo_rules.dart`, from the packet's airtime as the connector estimates it:

- **Zero hop:** the packet's airtime plus 0.5 s (`photoPacketGap`). The radio sends the highest priority waiting, back to back, and nothing can be called back once handed over, so packets handed over one at a time let an SOS or a message go between them.
- **Flood:** 8 airtimes plus 0.5 s (`photoPacketGapFlood`). A repeater passes a flood on after a random wait of up to 5 × `tx_delay_factor` (0.5 by default) = 2.5 airtimes, so the next packet waits until the last one has, at worst, cleared two hops: its own airtime, then two hops of wait and airtime. A photo of one packet waits as long after it, so a repeater's copy can be heard before it would go once more.
- **On a MeshCore frequency:** at least 4 airtimes on any route, so a photo takes at most about a quarter of the air around the sender.
- **Every gap is capped** so that all packets go out within three quarters of the receiver's 20-minute window; at MeshCore's presets it never comes to that. The count includes the repair packet only when it is sent. A packet sent again (see [Hearing it passed on](#hearing-it-passed-on)) goes only while the photo still fits that window.

At USA/Canada settings (SF7, 62.5 kHz) a packet takes about 0.53 s. A typical 4-packet photo then takes about 7 s to send zero hop and about 20 s as a flood when every packet is passed on: up to 30 s longer for each packet that waits for observers or goes again, as a text waits for its repeat.

## Rules on MeshCore frequencies

They apply on the frequencies of the presets in Radio settings, except the Off-Grid ones (`photoRulesApply`). Off-grid frequencies, TRAX included, and custom frequencies have none of them.

- **Every channel** may take a photo, Public included.
- **Before each photo** the sender confirms it: its packets, its airtime, and as how many text messages that counts (a 69-byte text packet, `photoTextMessageAirBytes`). It also says whether repeaters pass it on. A photo is usually as much as 8 text messages.
- **On Public and hashtag channels**, the first time, a longer explanation comes first: most people there won't see the photo, only MeshTrax shows photos, every repeater sends all of it again, and what's better. "Don't show this again" skips it from then on; the confirmation stays.
- **Time limits:** through repeaters, the next photo waits after the radio's last one by the size of that last one, packets with the repair packet (`photoGapRepeaters`). It is checked as the sender taps Photo, before picking one (`PhotoSendScreen.open`, `photoSendBlocked`): while it waits, a dialog says how long, and offers zero hop, which opens the photo screen with Zero hop on and locked.
  - After 1 packet: no wait. It is no more on the air than a long message, and it isn't counted.
  - After 2 packets: 5 minutes; 3: 10 minutes; 4 to 6: 20 minutes.
  - Zero hop never waits and isn't counted: it reaches only the radio's neighbours.
  - The time and the packets are kept per radio key (`notePhotoSent`), from when a photo's first packet goes. A time MeshTrax 1.12.0 kept, with no packets, waits 20 minutes.
  - **Given back:** when the wait for its copies ends (see [Hearing it passed on](#hearing-it-passed-on)), a photo through repeaters of which no copy at all was heard gives back its time (`notePhotoNotCarried`). That excludes a car repeater's copy and one sent again.
    - Only if a repeater was heard in the last minute (`photoUncarriedRepeaterWindow`, `MessageRetryService.repeaterHeardWithin`). A repeater heard then means this radio hears repeaters, so their silence means none carried it; without one, the silence could be this radio's, and the time stays.
    - Where observers are asked about the photo, the decision waits for their last answer, and an observer that heard any packet keeps the time.
  - **Ignore the photo time limits** in App settings, Messaging, Photos (off by default, for testing) lifts them on that phone.

## Subject only and Auto crop

Under the photo on the crop step, **Subject only** and **Auto crop** each start with "Tap what matters". Each tap is outlined by MediaPipe's Interactive Segmenter (MagicTouch v1, `magic_touch.tflite`, 6.2 MB, Apache-2.0 as its model card states: `assets/licenses/MagicTouch-NOTICE.txt`). It comes with the app beside the face models and runs through the app's own LiteRT code (`ImageCodecSession.segment`). Several taps are joined (the highest of their outlines).

- **The model's input** (`tapModelInput`): the whole photo stretched to 512 × 512, its colours from 0 to 1, and a fourth channel that marks the tap with a dot about two pixels across (1 at the pixel tapped, less around it). Its output is 512 × 512, the chance each pixel belongs to what was tapped. On eight photos this agrees with MediaPipe's own segmenter: an outline overlap of 0.986 to 0.998 where the subject is clear (a dog, a toy, vehicles), less on a sail or a shelf of things. On a Mac a tap takes 38 ms.
- **The square** (`subjectSquare`): around the middle 96% of the outline, so stray specks don't widen it, with 8% of margin each side and at least a quarter of the photo's short side; kept on the photo where it fits, and past a tall or wide photo where the subject is wider than the photo is tall (or taller than it's wide), where black fills in. Only Auto crop moves the square there, at once or on the first thing tapped after it; then it moves and zooms freely, out into black too.
- **The black** (`blackOutside`): everything outside the outline, cut to the square (`cropMask`), fading inward over about 8 px. On the codec's own figures, measured block by block: black costs 2 to 4 bytes a photo, since the coder skips values it predicts with certainty, so leaving it out of the format would save nothing. The outline costs about a third of a photo (100 to 140 bytes), the subject the rest with a fixed ~80 to 100 bytes of hyperprior; the 8 px fade saves 1 to 7%. On 58 photos with a clear subject, cropped to it and blacked around, the median went from 474 bytes (3.67 data packets) to 314 (2.50).
- **Smaller subjects** take fewer packets but come through with less detail. A subject filling 70% of the square still rebuilds well; at 35% it's about a 256-pixel photo of it, and the rebuild invents it.
- **Not done:** coding a rectangle instead of a square would save 0 to 11%, but every model is built for 512 × 512.
- **The model card's limits:** it names photo editing as an intended use. It puts out of scope any surveillance or identity recognition, and outlining a person who hasn't agreed to it. MeshTrax outlines only what the sender taps in their own photo, and Blur faces stays on by default.

## Faces

- **The models:** BlazeFace short range (128 px input, 896 anchors) and full range (192 px, 2304 anchors), from MediaPipe's Face Detector, Apache-2.0 (`assets/licenses/BlazeFace-NOTICE.txt`). About 1.3 MB together, they come with the app (`assets/models/`) and are copied to the cache folder for LiteRT, which reads models from files (`PhotoStore.sendingBundle`). Only the sender runs them.
- **Finding faces:** the short-range model on the whole photo, kept at 0.75 or more; the full-range model on the whole photo and on four overlapping 320 px quarters, at 0.5. Overlapping boxes merge as MediaPipe's weighted suppression merges them, and a box whose six points can't be a face (the mouth not well below the eyes, or the nose above them) is dropped.
- **Covers:** an oval fitted to the six points (tilted with the eyes, ear to ear, brow to chin) together with an oval inside the box; inside it, a Gaussian blur of the face's own pixels pulled 85 % towards grey, with a soft edge. A face under 32 px gets a flat tone instead. The fallback paints the same ovals dark grey (45).
- **Chosen by:** tests in Python on 255 crops of trip photos, where the settings left 68 of 68 photos with faces sent and shown. The Dart port feeds the models what Pillow's bilinear resize fed them, bit for bit, and blurs as scipy does: on every crop it finds the same faces (`packages/traxpix_litert/test/face_reference_test.dart`, on a Mac with the model files), and with set boxes its covers match Python's exactly (`packages/traxpix/test/face_cover_test.dart`).

## Safety

- **The classifier:** `image-safety-classifier-s`. It sees the whole picture, area-scaled to 224 × 224, never cropped. A picture is flagged when its NSFW or NSFL score is above its SFW score, the classifier author's own rule. A sender's check is stricter: SFW has to lead both by 0.3 (`ImageSafetyRule.standard`). Phones score the same rebuild a little differently (by up to 0.115 between an iPhone XS and a Mac, on 68 photos), and the margin keeps a receiver from refusing a photo its sender passed.
- **What it checks:** the sender's original before it is coded, the preview, every rebuilt picture and every enhanced one. The preview takes the sender's margin; on a phone without the memory for a preview, the original does. Flagged pixels never leave `traxpix_litert`: the results carry no picture.
- **Report** hides a photo for good and sends a report from inside the app (`PhotoReports`, `report_inbox.dart`) to the report inbox, `https://reports.meshtrax.io/v1/report`. The inbox passes each report on by email to the developer and keeps nothing. A report carries the sender's name as shown, when it arrived, its size, whether the check hid it, the user's reason and the app's version, and the photo's code only if the user ticks "Include the photo"; nothing about the reporter. Without internet it waits on the phone and is sent at the next launch, or from App settings, Messaging, Photos. App stores ask that reporting work from inside the app for AI-generated content. **Block** drops that sender's photos from then on.

## Where things are kept

| What | Where | Backed up |
|---|---|---|
| Records and coded bytes | `Documents/photos/<messageId>.json`, `.aeic` | Yes |
| Rebuilt pictures | `<cache>/photos/<messageId>.png`, 100 MB at most | No |
| The model | `Documents/ft8/` | No |
| The weight cache | `Documents/ft8/xnnpack/` | No |
| Settings | `photos_enabled`, `photo_rebuild_automatically`, `photo_enlarge_automatically`, `photo_open_channel_explained`, the last photo per radio | In the app's preferences |

Deleting the model (App settings → Messaging → Photos) deletes the weight cache with it.

## Testing

- `packages/traxpix`: `dart test`. It covers the wire format, chunking and the repair packet, reassembly, the extras (tag and position), finding and covering faces, the gaps, the transport and its sending again, and the entropy coder. The coder is checked against reference vectors, and the ft8 end-to-end recordings come from three public Kodak images.
- `packages/traxpix_litert`: `flutter test`. It covers the file pins, the classifier's input and thresholds, and the tap model's input. CI runs both. `packages/traxpix`'s `subject_only_test.dart` covers the square, the mask cut to it, the black and its fade, and the box a viewer frames.
- `litert_reference_test.dart` needs the real files, so it runs on a Mac only, with five environment variables:
  - `TRAXPIX_LITERT_LIB`: `libCLiteRT_mac.dylib`;
  - `TRAXPIX_LITERT_DIR`: the model files;
  - `TRAXPIX_LITERT_PHOTOS`: the 190 photos as 512 × 512 `.rgb`;
  - `TRAXPIX_LITERT_REBUILD`: 12 photos to rebuild;
  - `TRAXPIX_LITERT_OUT`: where its output goes.

  It codes and decodes the 190 photos, writes `ref.txt` (each photo's bitstream and latent hash, the reference a phone's results are compared with), times the 12 rebuilds, and enlarges 3 pictures.
- `face_reference_test.dart`, also on a Mac only, compares faces with the Python tests that chose the settings: with `TRAXPIX_LITERT_LIB` and `TRAXPIX_LITERT_DIR` as above, `TRAXPIX_FACES_DIR` (the two BlazeFace models) and `TRAXPIX_FACES_REF` (the crops, `all-faces3.tsv` and Python's covers in `blurred3/` and `dark/`).
- The app's tests are `test/services/photo_*`, `test/screens/photo_*` and `test/widgets/photo_*`. `photo_send_repeats_test.dart` sends photos through the chat to a radio whose repeater passes on the packets it is told to, as the raw log shows them, and checks that each packet is done with before the next goes under a text's rules, what goes again, what the chat row says while the packets go and ends with, that a Nearby only channel's photo goes zero hop, and how far a received photo's row says it came; `photo_reassembler_test.dart` checks received packets into photos, late copies and the window; `test/connector/raw_channel_data_test.dart` checks the raw-log copies and their paths.
- **Over the air:** two radios on 920.000 MHz on a private channel, zero hop, so nothing reaches the real mesh. On a MeshCore frequency, a couple of packets at most.
