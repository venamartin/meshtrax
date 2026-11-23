# traxpix

Photos over the mesh. traxpix splits a coded photo into MeshCore channel-data
packets, adds a repair packet that rebuilds any one lost packet, and puts the
packets back together on the other side. It also holds the entropy coder for
the photo model's bitstream. The package is pure Dart and has no screens; the
model itself runs in `traxpix_litert`.

## What MeshTrax does with it

- **Sending.** The sender crops a photo square. The AEIC-SE `ft8` model codes
  it to about 400 bytes, which is 3 to 7 packets with the repair packet. Each
  packet is channel data of type `0xFF1C` on the chosen channel.
- **Routes.** A photo goes as a flood, the way the radio sends the channel's
  messages, or zero hop (`sendImage(zeroHop: true)`): only radios in direct
  range hear it.
- **Pacing.** The app hands the radio one packet at a time and waits after
  each (`photoPacketGap`), so an SOS or a message sent meanwhile goes first.
  A flood waits longer (`photoPacketGapFlood`), so that one packet doesn't run
  into the one before it while repeaters pass that one on.
- **Receiving.** `ImageReassembler` collects a photo's packets for 60
  seconds. With one packet lost, the repair packet rebuilds it; with more
  lost, the app shows the photo as incomplete.
- **Tags.** The sender can type a short tag (`photoPayloadWithTag`, 24
  characters). It travels as exact text ahead of the bitstream, so the rebuilt
  picture can never change it.

The wire format is described at the top of `lib/src/photo_chunks.dart`, and
the whole feature in `docs/technical/photos.md`.

## Where the code comes from

The chunk framing, the range coder and the entropy loop are adapted from
meshcore-open (zjs81, MIT) at commit 3944c4f; see the repository's LICENSE.

## Tests

`dart test`. The end-to-end tests replay recordings of the model's entropy
network, made from three public Kodak test images with the AEIC authors' own
coder. The range coder's tests use reference vectors recorded the same way.
