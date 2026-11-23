import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meshtrax/services/photo_reports.dart';
import 'package:meshtrax/services/report_inbox.dart';

void main() {
  final received = DateTime.utc(2026, 11, 22, 18, 30);
  PhotoReport report({String? code, String reason = '', String? sender}) =>
      PhotoReport(
        id: 'r1',
        madeAt: received,
        sender: sender ?? 'Trail Boss',
        photoTime: received,
        bytes: 412,
        flaggedByCheck: false,
        code: code,
        reason: reason,
      );

  test('a photo report says what was reported, and nothing about the '
      'reporter', () {
    final body = report(reason: 'Not a trail photo').inboxBody(
      app: 'MeshTrax 1.11.0+223',
      platform: 'ios',
      sentAt: DateTime.utc(2026, 11, 22, 19),
    );
    expect(body, {
      'v': 1,
      'id': 'r1',
      'kind': 'photo',
      'app': 'MeshTrax 1.11.0+223',
      'platform': 'ios',
      'sentAt': '2026-11-22T19:00:00.000Z',
      'sender': 'Trail Boss',
      'receivedAt': '2026-11-22T18:30:00.000Z',
      'reason': 'Not a trail photo',
      'photo': {'bytes': 412, 'flaggedByCheck': false},
    });
  });

  test('the photo\'s code goes only when included; long texts are cut', () {
    final body = report(
      code: 'AAEC',
      reason: 'x' * 600,
      sender: 'n' * 80,
    ).inboxBody(app: 'a', platform: 'android', sentAt: received);
    expect((body['photo'] as Map)['code'], 'AAEC');
    expect((body['reason'] as String).length, 500);
    expect((body['sender'] as String).length, 64);
  });

  test('a report keeps its reason and whether it was sent', () {
    final r = report(reason: 'Spam')..sent = true;
    final back = PhotoReport.fromJson(
      jsonDecode(jsonEncode(r)) as Map<String, Object?>,
    );
    expect(back.reason, 'Spam');
    expect(back.sent, isTrue);
  });

  test('posting: JSON to the inbox, true only once it has it', () async {
    late http.Request seen;
    final ok = await postReport(
      {'v': 1},
      client: MockClient((request) async {
        seen = request;
        return http.Response('{"ok":true}', 202);
      }),
    );
    expect(ok, isTrue);
    expect(seen.method, 'POST');
    expect(seen.url.toString(), kReportInboxUrl);
    expect(seen.headers['content-type'], startsWith('application/json'));
    expect(jsonDecode(seen.body), {'v': 1});

    expect(
      await postReport({
        'v': 1,
      }, client: MockClient((_) async => http.Response('busy', 503))),
      isFalse,
    );
    expect(
      await postReport(
        {'v': 1},
        client: MockClient((_) async => throw http.ClientException('offline')),
      ),
      isFalse,
    );
  });

  test('report ids are random and long enough not to repeat', () {
    final ids = {for (var i = 0; i < 100; i++) newReportId()};
    expect(ids, hasLength(100));
    expect(ids.first, matches(RegExp(r'^[0-9a-f]{32}$')));
  });
}
