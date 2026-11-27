# Channel requests

> **What this is:** The one packet MeshTrax nodes use to ask each other for something on a channel: data type `0x0173`, its layout, how a node decides a request is for it, and the room left for later. Each kind of request says what it asks and how it is answered; the first kind asks for the lost packets of a photo ([Photos: asking for lost packets](photos.md#asking-for-lost-packets)).
>
> **Who it's for:** developers and the AI-assisted sessions working on MeshTrax, and anyone writing another kind of request.
>
> **Status:** built, not released. Firmware facts are from MeshCore 75b04ef.
>
> New to the terms? See the [glossary](../glossary.md).

## The packet

A request is one MeshCore `PAYLOAD_TYPE_GRP_DATA` with data type `0x0173`, one of the block 0170–017F that MeshTrax asked for in MeshCore's `docs/number_allocations.md` (meshcore-dev/MeshCore#3925). It's generic: nothing in it is about photos but its kind. `0x0174` is kept free for a reply of the same shape, should a kind ever need one.

```
  off  size  field
  0    1     kind: what is asked; 0 reserved, 1 the packets of a photo
  1    1     version (high 4 bits, 0) and flags (low 4 bits, 0 so far)
  2    2     build: the asker's MeshTrax build, the number after the + in
             its version (252 in 1.12.1+252), big-endian; 0 unknown
  4    1     id: the asker's own number for this request, so an answer can
             name it
  5    2     asker: the first 2 bytes of the asker's public key
  7    2     asked: the first 2 bytes of the public key of the node asked;
             0000 is anyone who can answer
  9    ..    the kind's own bytes
```

The code is `lib/models/channel_request.dart` (the layout) and `lib/services/channel_requests.dart` (sending, and handing each request to the part of the app that registered for its kind).

- **The build** is read once from the platform. An arm64 Android APK's version code is the build plus 2000 (Flutter's `--split-per-abi`), so on Android the build is the code modulo 1000, as the settings screen shows it.
- **The sender prefix** names the asker, since the firmware gives no sender with channel data. Two nodes whose keys start with the same 2 bytes can't be told apart, as with photos.

## Who takes a request

A node takes a request only when:

- it is the node asked, or anyone is;
- it isn't its own request heard back;
- its version is one the node reads (0);
- some part of the app registered for its kind.

Anything else it ignores, quietly. Flags it doesn't know, it ignores too. A kind reads the bytes it knows and ignores any after them.

## Sending one

`ChannelRequests.send` hands the request to the chat's queue (`MeshCoreConnector.sendChannelPackets`) with `once` and `ahead`:

- it goes once, and is done with when the radio has it: no wait for a repeater, nothing sent again, observers not asked;
- it goes at once, between the packets of any photo still going, as a text does.

It goes as a flood, as a message does, or zero hop on a Nearby only channel. When the radio refuses it, the caller hears why (`ChannelPacketsFailed`).

## The bytes it costs

The firmware seals `[data type (2)][length (1)][data]` in whole 16-byte AES blocks (`BaseChatMesh::sendGroupData`, `Mesh::createGroupDatagram`). On air, a group datagram is header (1), path length (1), the path, channel hash (1), MAC (2) and the ciphertext.

| Request | Data | Sealed | On air, before path |
|---|---|---|---|
| Photo packets (kind 1) | 9 + 4 = 13 | 16, one block | 21 |

A kind's body can grow up to 4 bytes before its request takes a second block; kind 1 has none to spare, so its next byte costs 16 more on air.

## Room for later

- **Kinds:** 2 to 255 are free.
- **Flags:** the low 4 bits of byte 1, which an older node ignores.
- **Version:** the high 4 bits of byte 1. An older node drops a version it doesn't read, so a new version is for a change it must not misread.
- **Bodies:** a kind's body can grow, as older nodes ignore the bytes past the ones they know.
- **Replies:** data type `0x0174`, not built.

## Kinds

| Kind | Asks | Body | Answered |
|---|---|---|---|
| 1 | The packets of a photo the asker is missing | image id (1), data packets (1), the packets missing (2, big-endian: packet i at bit i, the repair packet at bit "data packets") | By the photo's sender only, with the packets again: [Photos: asking for lost packets](photos.md#asking-for-lost-packets) |
