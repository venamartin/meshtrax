# Proposal: an extra direct ACK after a flooded DM (opt-in, behind `multi_acks`)

Status: draft for the MeshCore maintainers. Written against `companion-v1.18.0`.

## Summary

When a direct message arrives as a **flood**, the receiver answers with a flooded
PATH packet that carries the ACK inside it. That is the only ACK it sends, even when
it already holds a stored route (`out_path`) back to the sender. If the return flood
is lost, the sender retries, and every retry earns another flood that can be lost
the same way.

Proposal: when `multi_acks` is on and the receiver holds an `out_path` to the sender,
also send one ordinary ACK **direct** along that route, about one second after the
flooded PATH return. Nothing else changes: no protocol change, no new command, no new
packet type.

## Current behaviour

`BaseChatMesh::onPeerDataRecv` (`TXT_TYPE_PLAIN`, and the same shape for
`TXT_TYPE_SIGNED_PLAIN`):

```cpp
if (packet->isRouteFlood()) {
  // let this sender know path TO here, so they can use sendDirect(), and ALSO encode the ACK
  mesh::Packet* path = createPathReturn(from.id, secret, packet->path, packet->path_len,
                                          PAYLOAD_TYPE_ACK, (uint8_t *) &ack_hash, 6);
  if (path) sendFloodScoped(from, path, TXT_ACK_DELAY);
} else {
  sendAckTo(from, ack_hash, 6);
}
```

- A **direct** DM is ACKed by `sendAckTo`: direct on `out_path`, plus a second copy
  when `getExtraAckTransmitCount() > 0` (`multi_acks`).
- A **flooded** DM is ACKed only inside the flooded PATH return. `out_path` and
  `multi_acks` are ignored, even when a stored route exists.

## Proposed change

```cpp
if (packet->isRouteFlood()) {
  mesh::Packet* path = createPathReturn(from.id, secret, packet->path, packet->path_len,
                                          PAYLOAD_TYPE_ACK, (uint8_t *) &ack_hash, 6);
  if (path) sendFloodScoped(from, path, TXT_ACK_DELAY);

  // NEW: the return flood can be lost; if we already know a route back and
  // the user asked for extra ACKs, send one more along that route.
  if (from.out_path_len != OUT_PATH_UNKNOWN && getExtraAckTransmitCount() > 0) {
    mesh::Packet* ack = createAck((uint8_t *) &ack_hash, 6);
    if (ack) sendDirect(ack, from.out_path, from.out_path_len,
                        TXT_ACK_DELAY + DIRECT_ACK_AFTER_FLOOD_DELAY);  // e.g. 1000 ms
  }
} else {
  sendAckTo(from, ack_hash, 6);
}
```

The same three lines go into the `TXT_TYPE_SIGNED_PLAIN` branch, with its 4-byte ACK.

### Why this is safe

- **Duplicate ACKs are already expected.** `MyMesh::processAck` matches the first
  4 bytes against the expected-ACK table and clears the entry; a second copy of the
  same ACK matches nothing and is ignored. The source comment already says "the same
  ACK can be received multiple times".
- **There is precedent.** `BaseChatMesh::onAckRecv` already reacts to "they flooded
  although we hold a direct path" by sending a direct packet back
  (`handleReturnPathRetry`). This is the same idea on the receiving side.
- **Opt-in, bounded cost.** Only radios with `multi_acks` set do it, and only when a
  route is stored: at most one extra direct packet per flooded DM, travelling
  `out_path_len` hops.
- **The delay avoids self-collision.** The return flood's first retransmissions are
  still in the air right after `TXT_ACK_DELAY`; the direct ACK waits about a second
  more.

## Field evidence (and its limits)

Drive test, 2026-10-17, two companions on a 2-byte-hash mesh: one at home, one in a
moving car.

- Of 44 DMs from the car that reached the home radio, **18 were never ACKed back to
  the car**. All 18 arrived as floods, so each was answered only by a flooded PATH
  return, and none of those returns reached the car. Every retry is a new packet and
  earned a fresh return flood; none got through either.
- Delivered ACKs took 1–15 s, and no ACK arrived after the sender had given up, so
  these were lost, not late.

Honest limit: on that drive the home radio's stored routes to the moving car were
poor (its direct sends to the car delivered 4 of 73), so a direct ACK would have
rescued only a few of the 18. The case this change helps most is the common one: a
**stationary** pair with a stored route that works, where the return flood is the
weak leg (busy mesh, collisions with the sender's own flood still propagating, region
scoping that drops one direction).

## Alternatives considered

1. **Report the attempt number to the app** (`CONTACT_MSG_RECV_V3` reserved byte) so
   the app can craft its own ACK with `CMD_SEND_RAW_PACKET`. It benefits one app only,
   needs raw header and path-hash code in the app, and the ACK leaves seconds late
   after a BLE round trip. Rejected in favour of this change.
2. **Brute-force the ACK from the app** (attempt & 3 leaves four candidate hashes).
   That sends three junk packets per DM across every hop. Rejected.
3. **Always send the direct ACK, without `multi_acks`.** That adds airtime for every
   user. The opt-in keeps today's behaviour as the default.
