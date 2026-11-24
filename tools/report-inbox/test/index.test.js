import assert from 'node:assert/strict';
import { test } from 'node:test';

import worker from '../src/index.js';

const INBOX = 'https://reports.meshtrax.io/v1/report';

const report = (extra = {}) => ({
  v: 1,
  id: '0123456789abcdef0123456789abcdef',
  kind: 'photo',
  app: 'MeshTrax 1.11.0+223',
  platform: 'ios',
  sentAt: '2026-11-22T19:00:00.000Z',
  sender: 'Trail Boss',
  receivedAt: '2026-11-22T18:30:00.000Z',
  reason: 'Not a trail photo',
  photo: { bytes: 412, flaggedByCheck: false },
  ...extra,
});

function inboxEnv({ allow = true, fail = false } = {}) {
  const sent = [];
  return {
    sent,
    FROM: 'reports@meshtrax.io',
    TO: 'developer@example.com',
    LIMITER: { limit: async () => ({ success: allow }) },
    REPORTS: {
      send: async (message) => {
        if (fail) throw new Error('E_RECIPIENT_NOT_ALLOWED');
        sent.push(message);
        return { messageId: 'm1' };
      },
    },
  };
}

const post = (body, headers = {}) =>
  new Request(INBOX, {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...headers },
    body: typeof body === 'string' ? body : JSON.stringify(body),
  });

test('a photo report is emailed on, and the app hears that it arrived', async () => {
  const env = inboxEnv();
  const response = await worker.fetch(post(report(), { 'cf-connecting-ip': '203.0.113.7' }), env);
  assert.equal(response.status, 202);
  assert.deepEqual(await response.json(), { ok: true });
  assert.equal(env.sent.length, 1);
  const [message] = env.sent;
  assert.equal(message.from, 'reports@meshtrax.io');
  assert.equal(message.to, 'developer@example.com');
  assert.equal(message.subject, 'MeshTrax photo report 0123456789abcdef0123456789abcdef');
  assert.match(message.text, /^Reported sender \(name as shown\): Trail Boss$/m);
  assert.match(message.text, /^Arrived: 2026-11-22T18:30:00\.000Z$/m);
  assert.match(message.text, /^Photo size: 412 bytes$/m);
  assert.match(message.text, /^Hidden by the safety check: no$/m);
  assert.match(message.text, /^Not a trail photo$/m);
  assert.match(message.text, /^App: MeshTrax 1\.11\.0\+223 \(ios\)$/m);
  assert.match(message.text, /didn't include the photo's code/);
  assert.doesNotMatch(message.text, /203\.0\.113\.7/);
});

test("the photo's code is passed on only when it was included", async () => {
  const env = inboxEnv();
  await worker.fetch(post(report({ photo: { bytes: 3, flaggedByCheck: true, code: 'AAEC' } })), env);
  await worker.fetch(post(report({ photo: { bytes: 3, code: '<b>not base64</b>' } })), env);
  assert.match(env.sent[0].text, /^Hidden by the safety check: yes$/m);
  assert.match(env.sent[0].text, /included the photo's code \(base64\):\nAAEC$/m);
  assert.match(env.sent[1].text, /didn't include the photo's code/);
  assert.doesNotMatch(env.sent[1].text, /not base64/);
});

test('long or odd text is cut, and kept to its own lines', async () => {
  const env = inboxEnv();
  await worker.fetch(
    post(report({ sender: `Fake\nSubject: x${'n'.repeat(80)}`, reason: `${'🙂'.repeat(600)}` })),
    env,
  );
  const text = env.sent[0].text;
  const sender = text.match(/^Reported sender \(name as shown\): (.*)$/m)[1];
  assert.equal([...sender].length, 64);
  assert.doesNotMatch(text, /^Subject:/m);
  assert.match(text, new RegExp(`^${'🙂'.repeat(500)}$`, 'mu'));
});

test('a wrong path, method, size or body sends nothing', async () => {
  const env = inboxEnv();
  const answers = [
    await worker.fetch(new Request('https://reports.meshtrax.io/'), env),
    await worker.fetch(new Request(INBOX), env),
    await worker.fetch(post(report({ reason: 'x'.repeat(9000) })), env),
    await worker.fetch(post('not json'), env),
    await worker.fetch(post(report({ v: 2 })), env),
    await worker.fetch(post('null'), env),
  ];
  assert.deepEqual(
    answers.map((r) => r.status),
    [404, 405, 413, 400, 400, 400],
  );
  assert.equal(env.sent.length, 0);
});

test('too many reports, or an email that cannot go out: the app keeps it for later', async () => {
  assert.equal((await worker.fetch(post(report()), inboxEnv({ allow: false }))).status, 429);
  assert.equal((await worker.fetch(post(report()), inboxEnv({ fail: true }))).status, 503);
});
