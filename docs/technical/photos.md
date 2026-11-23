# Photos: how they work

> **What this is:** How MeshTrax sends a photo over MeshCore and rebuilds it on the other phone: the packet format, the photo model and its runtime, the memory and safety checks, the rules on MeshCore frequencies, and how to check a change. The user's side is in [Photos](../photos.md).
>
> **Who it's for:** developers and the AI-assisted sessions working on MeshTrax. The feature arrived as one pull request without its earlier history, so this file is the record of how it works and why.
>
> **Status:** built. Sent over the air between an iPhone and an Android, both ways. Firmware facts are from MeshCore 75b04ef.
>
> New to the terms? See the [glossary](../glossary.md).

## In one paragraph

The sender's phone codes a 512 × 512 photo with the AEIC-SE image codec at its `ft8` level: about 400 bytes. traxpix cuts that into 2 to 6 channel-data packets of up to 157 bytes and adds one XOR repair packet. They go one at a time as MeshCore channel data, type `0xFF1C`, as a flood like a channel message, or zero hop. The receiving phone puts the packets back together, decodes the bitstream into the model's latents, and a decoder built on SD-Turbo draws a picture from them. A safety classifier checks every picture before it is shown. Full screen, the user can enlarge it 4× with a small Real-ESRGAN model. Everything runs on the phone, on the CPU, with Google's LiteRT 2.3.0.

## Where the code is

| Part | Where | What it does |
|---|---|---|
| Packet format | `packages/traxpix` (pure Dart) | `photo_chunks.dart`: wire format, chunking, the repair packet, reassembly, the transport and the gaps between packets. `photo_tag.dart`: the sender's tag. `image_codec_entropy.dart`, `rans_coder.dart`, `rans_coders.dart`, `entropy_tables.dart`: the entropy coding between latents and bitstream. |
| Model runtime | `packages/traxpix_litert` (Flutter plugin) | `litert_api.dart`: LiteRT's C API through FFI. `litert_codec_backend.dart`: runs the models. `image_codec_session.dart`: one worker isolate per job. `image_codec_bundle.dart`, `image_codec_files.dart`: the files and their hosted SHA-256 pins. `image_codec_memory.dart`: memory checks. `image_safety.dart`: the classifier and its thresholds. Platform folders: the LiteRT binaries. |
| Radio side | `lib/services/photo_mesh.dart` | Sends photos, listens for photo packets, files photos in their channel's chat, decides whether the phone can do photos at all. |
| Photos kept | `lib/services/photo_store.dart` | The records, the coded bytes, the rebuilt pictures, and the one-at-a-time queue for rebuilds and enlargements. |
| Model download | `lib/services/photo_model_downloads.dart` | Downloads the model through the map downloader. |
| Rules | `lib/services/photo_rules.dart` | Where the MeshCore-frequency rules apply, the time limits, the gap between packets, what the sender is asked. |
| Saving | `lib/services/photo_save.dart` | Draws the "AI reconstructed" mark into a copy and saves it. |
| Reports | `lib/services/photo_reports.dart`, `lib/services/report_inbox.dart` | Photo reports, kept on the phone until the report inbox has them. |
| Screens | `lib/screens/photo_send_screen.dart`, `lib/widgets/photo_message_card.dart` (chat bubble and full-screen viewer), `photo_settings_section.dart`, `photo_ai_mark.dart`, `photo_report_dialog.dart`, `lib/screens/photo_licences_screen.dart` | The user's side. |
| Native | `ios/Runner/AppDelegate.swift`, `android/.../MainActivity.kt`, `macos/Runner/MainFlutterWindow.swift` | `meshtrax/storage`: the phone's memory (iOS), free space, saving to the photo library. |

## Sending

1. **Pick and crop.** The photo is cropped square and scaled to 512 × 512 RGB.
2. **Check.** The classifier checks the original. A flagged photo is never coded or sent.
3. **Code.** The send side of the entropy network (`aeic_side_ft8.tflite`) turns the picture into latents, and the rANS coder writes them as a bitstream of 208 to 796 bytes, about 400 on average.
4. **Preview.** The phone rebuilds the bitstream exactly as a receiver will and checks that too, so the sender sees what the others will get. If the memory isn't there, it says so and the photo can still be sent.
5. **Tag.** The sender may type a tag, up to 24 characters and 64 UTF-8 bytes. It goes ahead of the bitstream as a length byte and the text (`photoPayloadWithTag`), and the metadata byte says it's there. The receiver shows it as text, so the AI can never change it.
6. **Packets.** The payload is cut into blobs of up to 157 bytes (`buildImageChunks`), then the XOR repair blob is added.
7. **Route.** Each blob goes to the radio as `CMD_SEND_CHANNEL_DATA` (62), with path length `0xFF` for a flood or `0` for zero hop. A flood goes through the radio's own scoped flood (`sendGroupData` → `sendFloodScoped`), the same call as a channel text, so it takes the radio's region. Where the connector puts a channel's sends in a region, or sends a Nearby only channel zero hop, channel data is included, so a photo follows its channel as text does.
8. **Pacing.** One packet at a time, each handed over only after the gap (see [The gap between packets](#the-gap-between-packets)), so an SOS or a message sent meanwhile goes first.
9. **Chat.** The photo is filed in the chat as the sender's own, with the preview as its picture.

## The packet format

Each packet is one MeshCore `PAYLOAD_TYPE_GRP_DATA` with data type `0xFF1C`, from the FF00–FFFF range that MeshCore's `docs/number_allocations.md` leaves free for apps in development, until MeshTrax has its own allocation there. A blob is at most 157 bytes:

```
  off  size  field
  0    2     sender prefix: the first 2 bytes of the sender's public key,
             in every chunk, since the firmware gives no sender identity
             with channel data
  2    1     image id, per photo
  3    1     idx << 4 | total: chunk index 0..15, data chunks 1..15;
             idx == total is the repair chunk
  4    ...   body
```

- **Chunk 0's body** starts with the metadata byte, `tag(1) | reserved(3) | resolution(2) | rate(2)`. Rate code 2 is `ft8`, the only quality; codes 0, 1 and 3 are refused, never guessed at. Resolution code 0 is 512. The tag bit says the payload starts with a tag. Chunk 0 then carries 151 bytes of payload, the others 152.
- **The repair chunk** is the XOR of the data bodies, with one byte for the XOR of their lengths. Any one lost data chunk can be rebuilt from it.
- **Why 157:** a photo packet is 2 bytes of header and path length, the path, 3 of channel hash and MAC, and the ciphertext. That's whole 16-byte blocks of data type (2), length (1) and blob, so 157 makes 160 bytes of ciphertext and a 165-byte packet. The radio copies a heard packet to the app (`PUSH_CODE_LOG_RX_DATA`) only up to 173 bytes, so the sender can still hear its packets repeated with up to 8 bytes of path.
- **No CRC of its own:** the LoRa PHY checks every packet and MeshCore checks a 2-byte MAC. A merge of two senders' photos would need the same sender prefix, image id and channel within a minute.

## Receiving

1. **Packets in.** Channel data arrives as `RESP_CODE_CHANNEL_DATA_RECV` (27). `PhotoMesh` hands frames of type `0xFF1C` to the `ImageReassembler`. It keys a photo by sender prefix, image id and channel, and holds it for 60 seconds (`kImageReassemblyTtl`).
2. **Whole, or not.** With all data chunks, or all but one plus the repair chunk, the photo is complete. Otherwise, a minute after its first chunk, the chat says "Photo incomplete: x of y packets". A damaged tag length makes it "unreadable". Nothing is asked for again.
3. **Filed.** The chat gets a line "📷 Photo #id" (with the tag if any), marked by its packet hash (`photo:…`), and `PhotoStore` keeps a record (bytes, packets, tag) and the coded bytes. A blocked sender's photos are dropped, not kept.
4. **Rebuilt** when the user taps the photo, or as it arrives if "Rebuild received photos automatically" is on and the phone has the memory:
   1. the hyperprior's synthesis and the four context stages turn the bitstream back into latents (`y_hat`, 256 × 16 × 16);
   2. the decoder runs in three parts: AEIC's synthesis transform (`gs`), SD-Turbo's UNet with AEIC's LoRA merged in (`unet`), and AdcSR's pruned VAE decoder (`vae`); the picture is `vae(unet(gs₀) + gs₁)`;
   3. the classifier checks the picture.

   A passed picture is kept as a PNG in the cache folder (at most 100 MB, oldest first out). A flagged one shows only "Image hidden", and its pixels are never stored.
5. **Full screen.** One tap on the bubble opens the viewer, which rebuilds the photo there if it hasn't been. It has pinch and double-tap zoom, Save, a ⋮ menu (About this photo, and Report and Block for a received photo), and **Enhance 4×**.
6. **Enhance 4×.** It runs in the same queue as the rebuilds, after a memory check, and with every other model released first (`ImageCodecSession.enhance`). The result is checked like a rebuilt picture. It isn't kept: closing the viewer drops it.
7. **Save.** Save writes what's on screen to the phone's photo library: iOS through `PHPhotoLibrary` (add only), Android to Pictures/MeshTrax through MediaStore, a Mac through a Save dialog. The copy has "AI reconstructed" drawn in its bottom-left corner, at 2.4 % of its width.

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
- **Flood:** 8 airtimes plus 0.5 s (`photoPacketGapFlood`). A repeater passes a flood on after a random wait of up to 5 × `tx_delay_factor` (0.5 by default) = 2.5 airtimes, so the next packet waits until the last one has, at worst, cleared two hops: its own airtime, then two hops of wait and airtime.
- **On a MeshCore frequency:** at least 4 airtimes on any route, so a photo takes at most about a quarter of the air around the sender.
- **Every gap is capped** so that all packets go out within three quarters of the receiver's 60-second window.

At USA/Canada settings (SF7, 62.5 kHz) a packet takes about 0.53 s. A typical 4-packet photo then takes about 7 s to send zero hop and about 15 s as a flood.

## Rules on MeshCore frequencies

They apply on the frequencies of the presets in Radio settings, except the Off-Grid ones (`photoRulesApply`). Off-grid frequencies, TRAX included, and custom frequencies have none of them.

- **Every channel** may take a photo, Public included.
- **Before each photo** the sender confirms it: its packets, its airtime, and as how many text messages that counts (a 69-byte text packet, `photoTextMessageAirBytes`). It also says whether repeaters pass it on. A photo is usually as much as 8 text messages.
- **On Public and hashtag channels**, the first time, a longer explanation comes first: most people there won't see the photo, only MeshTrax shows photos, every repeater sends all of it again, and what's better. "Don't show this again" skips it from then on; the confirmation stays.
- **Time limits:** one photo every 10 minutes from each radio, and one through repeaters every 30 minutes, kept per radio key (`notePhotoSent`). Zero hop is the way to send another sooner.

## Safety

- **The classifier:** `image-safety-classifier-s`. It sees the whole picture, area-scaled to 224 × 224, never cropped. A picture is flagged at NSFW ≥ 0.30, NSFL ≥ 0.30, or the two together ≥ 0.50 (`ImageSafetyThresholds.standard`).
- **What it checks:** the sender's original before it is coded, the preview, every rebuilt picture and every enhanced one. Flagged pixels never leave `traxpix_litert`: the results carry no picture.
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

- `packages/traxpix`: `dart test`. It covers the wire format, chunking and the repair packet, reassembly, the tag, the gaps, the transport, and the entropy coder. The coder is checked against reference vectors, and the ft8 end-to-end recordings come from three public Kodak images.
- `packages/traxpix_litert`: `flutter test`. It covers the file pins and the classifier's input and thresholds. CI runs both.
- `litert_reference_test.dart` needs the real files, so it runs on a Mac only, with five environment variables:
  - `TRAXPIX_LITERT_LIB`: `libCLiteRT_mac.dylib`;
  - `TRAXPIX_LITERT_DIR`: the model files;
  - `TRAXPIX_LITERT_PHOTOS`: the 190 photos as 512 × 512 `.rgb`;
  - `TRAXPIX_LITERT_REBUILD`: 12 photos to rebuild;
  - `TRAXPIX_LITERT_OUT`: where its output goes.

  It codes and decodes the 190 photos, writes `ref.txt` (each photo's bitstream and latent hash, the reference a phone's results are compared with), times the 12 rebuilds, and enlarges 3 pictures.
- The app's tests are `test/services/photo_*` and `test/screens/photo_*`.
- **Over the air:** two radios on 920.000 MHz on a private channel, zero hop, so nothing reaches the real mesh. On a MeshCore frequency, a couple of packets at most.
