# traxpix

Photos over the mesh. traxpix splits a coded photo into MeshCore channel-data
packets, adds a repair packet that rebuilds any one lost packet, and makes the
photo again from a group of packets. It also holds the entropy coder for the
photo model's bitstream. It sends, receives and times nothing: that is the
app's. The package is pure Dart and has no screens; the model itself runs in
`traxpix_litert`.

## What MeshTrax does with it

- **Sending.** The sender crops a photo square. The AEIC-SE `ft8` model codes
  it to about 400 bytes, which is 3 to 7 packets with the repair packet
  (`buildImageChunks`). Each packet is channel data of type `0x0172` with a
  retry byte: a packet sent again carries how many times it went before
  (`photoPacketAgain`), so it is a new packet that repeaters pass on again,
  and a receiver takes it as the same packet (`samePhotoPacket`). MeshTrax
  1.12.0 sent `0x0170` packets without the byte; later releases don't read
  them.
- **The app sends them.** It hands a photo's packets to its chat, which sends
  them one at a time under a channel text's rules, as a flood or zero hop.
- **Receiving.** The app collects received packets for a while, and
  `ImagePackets` makes the photo from them. With one packet lost, the repair
  packet rebuilds it. With more lost, the user can ask the sender for them:
  traxpix writes and reads the request's body (`missingPacketBits`,
  `photoPacketsRequest`, `readPhotoPacketsRequest`), and the app sends it as
  a channel request. Otherwise the app shows the photo as incomplete.
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
