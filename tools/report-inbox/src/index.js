// The MeshTrax report inbox, a Cloudflare Worker at reports.meshtrax.io.
// The app sends it a report about something a user saw (today, a photo) and
// the inbox emails it on to the developer. It keeps nothing: not the report,
// not the sender's internet address, no logs.

const MAX_BODY_BYTES = 8192;

export default {
  async fetch(request, env) {
    if (new URL(request.url).pathname !== '/v1/report') {
      return new Response('Not found', { status: 404 });
    }
    if (request.method !== 'POST') {
      return new Response('Use POST', { status: 405, headers: { allow: 'POST' } });
    }
    // One limit for all reports, so the inbox never reads who sent one.
    const { success } = await env.LIMITER.limit({ key: 'reports' });
    if (!success) {
      return new Response('Too many reports, try later', { status: 429 });
    }
    const text = await readUpTo(request, MAX_BODY_BYTES);
    if (text === null) {
      return new Response('Too large', { status: 413 });
    }
    let report;
    try {
      report = JSON.parse(text);
    } catch {
      return new Response('Not JSON', { status: 400 });
    }
    if (report?.v !== 1) {
      return new Response('Not a version 1 report', { status: 400 });
    }
    try {
      await env.REPORTS.send({ from: env.FROM, to: env.TO, ...email(report) });
    } catch {
      // The app keeps the report and sends it again later.
      return new Response('Could not pass it on, try later', { status: 503 });
    }
    return Response.json({ ok: true }, { status: 202 });
  },
};

function email(report) {
  const kind = /^[a-z]{1,16}$/.test(report.kind) ? report.kind : 'content';
  const id = line(report.id, 64).replace(/[^0-9a-fA-F]/g, '') || 'without an id';
  const photo =
    kind === 'photo' && typeof report.photo === 'object' && report.photo !== null
      ? report.photo
      : null;
  const lines = [
    `A MeshTrax user sent a ${kind} report from inside the app.`,
    '',
    `Reported sender (name as shown): ${line(report.sender, 64) || '(none)'}`,
    `Arrived: ${line(report.receivedAt, 40) || '(unknown)'}`,
    `Reported: ${line(report.sentAt, 40) || '(unknown)'}`,
  ];
  if (photo) {
    const bytes =
      Number.isInteger(photo.bytes) && photo.bytes >= 0 ? `${photo.bytes} bytes` : '(unknown)';
    lines.push(
      `Photo size: ${bytes}`,
      `Hidden by the safety check: ${photo.flaggedByCheck === true ? 'yes' : 'no'}`,
    );
  }
  lines.push(
    '',
    'Reason given:',
    paragraph(report.reason, 500) || '(none)',
    '',
    `App: ${line(report.app, 64) || '(unknown)'} (${line(report.platform, 16) || 'unknown'})`,
    `Report id: ${id}`,
  );
  if (photo) {
    const code = typeof photo.code === 'string' ? photo.code.replace(/\s+/g, '') : '';
    lines.push(
      '',
      /^[A-Za-z0-9+/]{1,4096}={0,2}$/.test(code)
        ? `The reporter included the photo's code (base64):\n${code}`
        : "The reporter didn't include the photo's code.",
    );
  }
  return { subject: `MeshTrax ${kind} report ${id}`, text: `${lines.join('\n')}\n` };
}

// One line of text: control characters become spaces.
function line(value, max) {
  return cut(String(value ?? '').replace(/[\u0000-\u001f\u007f]+/g, ' ').trim(), max);
}

// Free text, keeping its line breaks.
function paragraph(value, max) {
  return cut(
    String(value ?? '')
      .replace(/\r\n?/g, '\n')
      .replace(/[\u0000-\u0009\u000b-\u001f\u007f]/g, '')
      .trim(),
    max,
  );
}

// At most max characters, never splitting one (emoji included).
function cut(text, max) {
  return [...text].slice(0, max).join('');
}

async function readUpTo(request, max) {
  if (!request.body) return '';
  const reader = request.body.getReader();
  const chunks = [];
  let size = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    size += value.byteLength;
    if (size > max) {
      await reader.cancel();
      return null;
    }
    chunks.push(value);
  }
  const bytes = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return new TextDecoder().decode(bytes);
}
