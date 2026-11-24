import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'report_inbox.dart';

/// A photo the user reported, kept on the phone until the report inbox has
/// it. The photo goes with it only if the user chose that, and then only as
/// its few-hundred-byte code, never the rebuilt picture.
class PhotoReport {
  final String id;
  final DateTime madeAt;
  final String sender;
  final DateTime photoTime;
  final int bytes;
  final bool flaggedByCheck;

  /// Base64 of the photo's code, only when the user chose to include it.
  final String? code;

  /// What the user wrote about it; may be empty.
  final String reason;

  /// Whether the report inbox has it.
  bool sent;

  PhotoReport({
    required this.id,
    required this.madeAt,
    required this.sender,
    required this.photoTime,
    required this.bytes,
    required this.flaggedByCheck,
    this.code,
    this.reason = '',
    this.sent = false,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'madeAt': madeAt.toIso8601String(),
    'sender': sender,
    'photoTime': photoTime.toIso8601String(),
    'bytes': bytes,
    'flaggedByCheck': flaggedByCheck,
    'code': code,
    'reason': reason,
    'sent': sent,
  };

  factory PhotoReport.fromJson(Map<String, Object?> j) => PhotoReport(
    id: j['id'] as String,
    madeAt: DateTime.parse(j['madeAt'] as String),
    sender: j['sender'] as String,
    photoTime: DateTime.parse(j['photoTime'] as String),
    bytes: j['bytes'] as int,
    flaggedByCheck: j['flaggedByCheck'] as bool,
    code: j['code'] as String?,
    reason: j['reason'] as String? ?? '',
    sent: j['sent'] as bool? ?? false,
  );

  /// The report as the inbox takes it (version 1).
  Map<String, Object?> inboxBody({
    required String app,
    required String platform,
    required DateTime sentAt,
  }) => {
    'v': 1,
    'id': id,
    'kind': 'photo',
    'app': app,
    'platform': platform,
    'sentAt': sentAt.toUtc().toIso8601String(),
    'sender': sender.length > 64 ? sender.substring(0, 64) : sender,
    'receivedAt': photoTime.toUtc().toIso8601String(),
    'reason': reason.length > 500 ? reason.substring(0, 500) : reason,
    'photo': {'bytes': bytes, 'flaggedByCheck': flaggedByCheck, 'code': ?code},
  };
}

/// The reports kept on this phone.
class PhotoReports extends ChangeNotifier {
  static final PhotoReports instance = PhotoReports._();
  PhotoReports._();

  final List<PhotoReport> all = [];
  Future<void>? _loading;

  Future<String> get _dir async {
    final d =
        '${(await getApplicationDocumentsDirectory()).path}/photos/reports';
    Directory(d).createSync(recursive: true);
    return d;
  }

  Future<void> load() => _loading ??= () async {
    final d = await _dir;
    for (final f in Directory(d).listSync().whereType<File>()) {
      try {
        all.add(
          PhotoReport.fromJson(
            jsonDecode(f.readAsStringSync()) as Map<String, Object?>,
          ),
        );
      } catch (_) {}
    }
    all.sort((a, b) => b.madeAt.compareTo(a.madeAt));
    notifyListeners();
  }();

  Future<void> _save(PhotoReport r) async =>
      File('${await _dir}/${r.id}.json').writeAsStringSync(jsonEncode(r));

  Future<void> add(PhotoReport r) async {
    await load();
    await _save(r);
    all.insert(0, r);
    notifyListeners();
  }

  /// Sends the report to the inbox. False with no internet, when it waits
  /// for [sendWaiting].
  Future<bool> send(PhotoReport r) async {
    final source = await reportSource();
    final ok = await postReport(
      r.inboxBody(
        app: source.app,
        platform: source.platform,
        sentAt: DateTime.now(),
      ),
    );
    if (ok) {
      r.sent = true;
      await _save(r);
      notifyListeners();
    }
    return ok;
  }

  /// Sends every report still waiting: at launch, and from App settings.
  Future<void> sendWaiting() async {
    await load();
    for (final r in [...all.where((r) => !r.sent)]) {
      await send(r);
    }
  }
}
