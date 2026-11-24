# traxpix_litert

The photo model's runtime for traxpix. One long-lived worker isolate owns the
LiteRT models:
- the send side of the entropy network, which codes a photo;
- the receive side (the hyperprior's synthesis and four context stages),
  which turns the bitstream back into the model's latents;
- the decoder, in three parts, which rebuilds a 512 x 512 picture from them
  (its last part, a float32 model, runs in half precision, which keeps flat
  areas such as sky smooth);
- the 4x enlarger, the compact Real-ESRGAN model, which turns a rebuilt
  picture into a 2048 x 2048 one, also in half precision;
- a small image safety classifier, which checks a photo before it is sent and
  every rebuilt or enlarged picture before it is shown.

No rebuilt pixels leave the package without that check.

## LiteRT

LiteRT 2.3.0's C API, called through FFI (`lib/src/litert_api.dart`), on the
CPU with XNNPACK:
- iPhones: Google's `CLiteRT.xcframework`, a SwiftPM binary target pinned by
  its SHA-256 (`ios/traxpix_litert/Package.swift`).
- Macs: Google's `CLiteRT_mac.xcframework`, the same way.
- Android: `libLiteRt.so` for arm64, taken out of Google's
  `com.google.ai.edge.litert:litert:2.3.0` AAR and checked against its SHA-256
  (`android/build.gradle`). The AAR's Java classes aren't used.

All three come from MeshTrax's host, `maps.meshtrax.io/runtimes/litert-2.3.0`,
byte for byte as Google published them, with LiteRT's licence and third-party
notices beside them.

The coded photo depends on the entropy network's arithmetic, so every device
must compute it bit for bit alike. Before LiteRT is updated, run
`test/litert_reference_test.dart` on the new version and the phone test on an
iPhone and an Android: every one of the 190 test photos must code and decode
exactly as before. A version that doesn't is a new photo format.

## The model

The `ft8` model files are pinned by SHA-256 in `lib/src/image_codec_files.dart`
and download on the user's choice, about 1.2 GB, with their licence texts and
a NOTICE that says how they were made. They are converted from the AEIC
authors' PyTorch models (AEIC code MIT) with litert-torch 0.10. The decoder is
built on SD-Turbo, so the Stability AI Community License applies to it: the
app shows "Powered by Stability AI" with the licences.

The safety classifier is `image-safety-classifier-s` (MIT). The enlarger is
Real-ESRGAN's `realesr-general-x4v3` with its denoising version averaged in
half and half (BSD 3-Clause).

## Memory

The model files are mapped, not read into memory. XNNPACK's packed weights go
in a cache beside the model (`xnnpack/`, about 1.1 GB, written on first use)
and are mapped from there too, so a rebuild takes far less of the app's memory
than the model's size. The decoder's last part is the exception: LiteRT 2.3.0
can't cache a half-precision model, and it is small. The app checks for room before a rebuild
(`imageCodecHasRoomToRebuild`) and frees what it can first.

An enlargement needs about 1 GiB more. It releases every other model first,
and the app checks for room again (`imageCodecHasRoomToEnhance`); on a 4 GB
iPhone it doesn't fit beside a loaded decoder.
