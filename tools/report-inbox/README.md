# Report inbox

A Cloudflare Worker at `https://reports.meshtrax.io/v1/report`. When a user reports a photo, MeshTrax sends the report here from inside the app, and the inbox emails it on to the developer, at the address published in [docs/privacy.md](../../docs/privacy.md). App stores ask that reporting of AI-generated content work without leaving the app, which an email app opening doesn't.

It keeps nothing:
- no storage: no KV, D1, R2 or Durable Objects;
- no logs: Workers Logs are off (`[observability] enabled = false`), and it writes no console output;
- no internet addresses: the rate limit counts all reports together, so the Worker never reads who sent one;
- the email holds the report's fields and nothing from the request itself.

## What the app sends

`POST`, `content-type: application/json`, at most 8 KB. Version 1, from `PhotoReport.inboxBody`:

```json
{
  "v": 1,
  "id": "0123456789abcdef0123456789abcdef",
  "kind": "photo",
  "app": "MeshTrax 1.11.0+223",
  "platform": "ios",
  "sentAt": "2026-11-22T19:00:00.000Z",
  "sender": "Trail Boss",
  "receivedAt": "2026-11-22T18:30:00.000Z",
  "reason": "Not a trail photo",
  "photo": { "bytes": 412, "flaggedByCheck": false, "code": "AAEC…" }
}
```

- `id`: 32 random hex characters. It goes in the email's subject, so a report the app sent twice (when the answer was lost) is easy to spot.
- `sender`: the reported photo's sender, as the app showed their name. Nothing about the person reporting is sent.
- `photo.code`: the photo's code in base64, only when the reporter ticked **Include the photo**. It's a few hundred bytes the photo can be rebuilt from, not the picture.

Strings are cut rather than refused: `sender` at 64 characters, `reason` at 500.

## What it answers

| Status | When | What the app does |
|---|---|---|
| 202 | The email went out | Marks the report sent |
| 400 | Not JSON, or not version 1 | Keeps it, tries again at the next launch |
| 404, 405 | Another path, or not `POST` | — |
| 413 | Over 8 KB | Keeps it |
| 429 | Over 30 reports a minute at one Cloudflare location | Keeps it, tries again later |
| 503 | The email couldn't go out | Keeps it, tries again later |

## Deploying

Once, in the Cloudflare dashboard for meshtrax.io:
1. Email → Email Routing: turn it on. It adds MX and SPF records; meshtrax.io has no other mail.
2. Email Routing → Destination addresses: add the developer address from `wrangler.toml`, and click the link in Cloudflare's verification email. The Worker can send only to that address.

Then, from this folder, with Node 20 or later, signed in with `npx wrangler@4 login` or with `CLOUDFLARE_API_TOKEN` set:

```sh
npx wrangler@4 deploy
```

`reports.meshtrax.io` is a Custom Domain, so the deploy creates its DNS record and certificate. There's no workers.dev address.

## Testing

```sh
node --test test/*.test.js
```

After a deploy, send one report and check that the email arrives (the first may land in spam):

```sh
curl -i https://reports.meshtrax.io/v1/report -H 'content-type: application/json' \
  -d '{"v":1,"id":"00000000000000000000000000000001","kind":"photo","sender":"Test","reason":"Test report","photo":{"bytes":0,"flaggedByCheck":false}}'
```

Email Routing's summary lists emails a Worker sent as dropped, even when they arrived.
