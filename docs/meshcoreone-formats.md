# Feature request: read MeshCore One replies and reactions

MeshCore One (iOS) sends replies and reactions as plain, human-readable text.
Supporting them on **receive** would make reactions and reply quoting interop
across clients — and unlike index-based encodings, these degrade gracefully:
a client that doesn't parse them still shows something a human can read.

MeshTrax already receives and sends both dialects; this is a request for
meshcore-open to read them too.

## Reply format

```
@[{target name}]
>{first ~10 chars of the quoted message}..
{reply body}
```

Example on the wire:

```
@[GWQ∆🍓]
>Heading to..
Nice!
```

A client that parses it can render a proper quote bubble. A client that
doesn't still shows a readable reply.

## Reaction format

```
{emoji}@[{target sender}]     <- channel form; DMs omit "@[...]"
{hash}
```

Example: `👍@[GWQ∆🍓]` + newline + `kryv4zmp`

**Hash:** first 5 bytes of `SHA-256(UTF-8 text + uint32-LE sender timestamp)`,
encoded as 8 chars of Crockford Base32 (lowercase, no i/l/o/u).

**What text is hashed** (verified against MeshCore One on the air):

- the message text after the `Name: ` sender prefix
- a leading `@[name] ` mention followed by a **space** is stripped
  (it's addressing, not content)
- reply markup (`@[name]` followed by a **newline**) is kept — a reaction
  to a reply hashes the full raw reply text above
- the timestamp is the wire timestamp of whichever copy the reactor heard
  (retries re-stamp, so matching against every heard stamp is more robust)

Spec: https://github.com/Avi0n/MeshCoreOne/blob/main/docs/Reactions.md

## Why this format

On any client that supports neither meshcore-open nor MeshCore One, a
reaction arrives as `👍@[GWQ∆🍓]` — readable, obvious. An index-based
encoding arrives as line noise. For a mesh where clients update slowly and
unevenly, the format that fails readable is the better wire format.
