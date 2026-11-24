import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:trax_sim/ble.dart';
import 'package:trax_sim/companion.dart';
import 'package:trax_sim/movers.dart';
import 'package:trax_sim/sim_person.dart';
import 'package:traxshare/traxshare.dart';

const usage = '''
Pretend trip members for bench tests. Through a companion radio on a serial
port or Bluetooth, each sends its location to the trip channel as MeshTrax
does in TRAX mode, with the trail behind it, while walking a trail or
driving a road.

  dart bin/trax_sim.dart (--port PATH | --ble NAME) --channel LINK_OR_NAME
      [people] [options]

People (with none given, one walker named after the radio; the first uses
the radio's own key, the others made-up ones):
  --walk NAME            walks a winding trail, resting now and then
  --drive NAME           drives a road at 45-60 mph, stopping at junctions
  --gpx FILE[=NAME]      follows a GPX track at --pace

Options:
  --port PATH            the radio's serial port, e.g. /dev/ttyACM0
  --ble NAME             or the radio over Bluetooth, paired already: its
                         name, e.g. "Trail Radio" for MeshCore-Trail Radio
  --channel X            the trip channel: its share link
                         (meshcore://channel/add?...), added to a free slot
                         unless the radio has it already, or the name of a
                         channel the radio has
  --start LAT,LON[,ALT]  where walkers and drivers start (default: the
                         radio's own position, 300 m up)
  --group N              people in the group, for the interval (default:
                         the people here and everyone heard on the trip
                         channel, as MeshTrax counts them)
  --radio MHZ,KHZ,SF,CR  set the radio first, e.g. 918,62.5,7,5 for TRAX
                         on a US mesh; this also turns Off-Grid Repeat off,
                         and both go back when it stops
  --pace M/S             for --gpx (default 1.4)
  --seed N               the same ways every run
  --dry-run              no radio: work out --minutes of reports and print
                         them (needs --start or --gpx)
  --minutes N            for --dry-run (default 30)

Reports go out as MeshTrax sends them: every 30 s per person in the group,
+/-20 %, the first 10-30 s after the start; the trail in the first report,
then in every 5th, no sooner than 10 minutes after the last. Places in the
output are distances from the start, never coordinates.

It reads the messages waiting on the radio, and they are gone from it
after: give it a radio of its own, not one an app uses. When it stops, it
takes off the trip channel if it added it.
''';

typedef PersonSpec = ({String kind, String? name, String? file});

class Options {
  String? port;
  String? ble;
  String? channel;
  ({double lat, double lon, double alt})? start;
  int? group;
  ({int freqKhz, int bwHz, int sf, int cr})? radio;
  double pace = 1.4;
  int? seed;
  bool dryRun = false;
  int minutes = 30;
  bool help = false;
  final people = <PersonSpec>[];

  static Options parse(List<String> args) {
    final o = Options();
    for (var i = 0; i < args.length; i++) {
      var arg = args[i];
      String? value;
      final eq = arg.indexOf('=');
      if (arg.startsWith('--') && eq > 0) {
        value = arg.substring(eq + 1);
        arg = arg.substring(0, eq);
      }
      String next() {
        if (value != null) return value;
        if (++i >= args.length) throw FormatException('$arg needs a value');
        return args[i];
      }

      List<double> numbers(String s, int least, int most) {
        final parts = s.split(',').map((p) => double.tryParse(p.trim()));
        if (parts.length < least ||
            parts.length > most ||
            parts.any((p) => p == null)) {
          throw FormatException('$arg: "$s"');
        }
        return [for (final p in parts) p!];
      }

      switch (arg) {
        case '-h' || '--help':
          o.help = true;
        case '--port':
          o.port = next();
        case '--ble':
          o.ble = next();
        case '--channel':
          o.channel = next();
        case '--start':
          final n = numbers(next(), 2, 3);
          o.start = (lat: n[0], lon: n[1], alt: n.length > 2 ? n[2] : 300);
        case '--group':
          o.group = int.tryParse(next()) ?? (throw FormatException(arg));
        case '--radio':
          final n = numbers(next(), 4, 4);
          o.radio = (
            freqKhz: (n[0] * 1000).round(),
            bwHz: (n[1] * 1000).round(),
            sf: n[2].round(),
            cr: n[3].round(),
          );
        case '--pace':
          o.pace = double.tryParse(next()) ?? (throw FormatException(arg));
        case '--seed':
          o.seed = int.tryParse(next()) ?? (throw FormatException(arg));
        case '--dry-run':
          o.dryRun = true;
        case '--minutes':
          o.minutes = int.tryParse(next()) ?? (throw FormatException(arg));
        case '--walk' || '--drive':
          o.people.add((kind: arg.substring(2), name: next(), file: null));
        case '--gpx':
          final v = next();
          final cut = v.indexOf('=');
          o.people.add((
            kind: 'gpx',
            name: cut < 0 ? null : v.substring(cut + 1),
            file: cut < 0 ? v : v.substring(0, cut),
          ));
        default:
          throw FormatException('unknown option $arg');
      }
    }
    return o;
  }
}

Future<void> main(List<String> args) async {
  final Options o;
  try {
    o = Options.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n\n$usage');
    exitCode = 64;
    return;
  }
  if (o.help) {
    stdout.write(usage);
    return;
  }
  final random = Random(o.seed);
  try {
    if (o.dryRun) {
      _dryRun(o, random);
      return;
    }
    await _run(o, random);
    stdout.writeln('Stopped.');
  } on _Stop catch (e) {
    stderr.writeln(e.message);
    exitCode = 1;
  }
  if (o.dryRun) return;
  await stdout.flush();
  // A read of a serial port can't be called off, so stop the whole program.
  exit(exitCode);
}

class _Stop implements Exception {
  _Stop(this.message);
  final String message;
}

void _dryRun(Options o, Random random) {
  var now = DateTime.now();
  final people = _people(
    o,
    random,
    o.start,
    ownPrefix: Uint8List.fromList([0xD0, 0x5E, 0x00, 0x01]),
    radioName: 'Sim radio',
    now: now,
  );
  final interval = _interval(o, people.length + 1, referenceReportAirtimeMs);
  final origin = people.first.position;
  for (var s = 1; s <= o.minutes * 60; s++) {
    now = now.add(const Duration(seconds: 1));
    for (final p in people) {
      p.step(s);
      if (p.due(now, interval) case final r?) {
        stdout.writeln(_describe(p, r, now, origin));
      }
    }
  }
}

Future<void> _run(Options o, Random random) async {
  final channelSpec =
      o.channel ?? (throw _Stop('Which trip channel? Give --channel.'));
  BleLink? ble;
  final Companion radio;
  if (o.ble case final name?) {
    stdout.writeln('Connecting to "$name" over Bluetooth');
    try {
      ble = await BleLink.open(name);
    } on Object catch (e) {
      throw _Stop('Can\'t connect to "$name" over Bluetooth: $e');
    }
    radio = Companion.frames(ble.send, ble.frames);
  } else if (o.port case final port?) {
    final stty = await Process.run('stty', [
      '-F',
      port,
      '115200',
      'raw',
      '-echo',
      '-hupcl',
    ]);
    if (stty.exitCode != 0) {
      throw _Stop('Can\'t set up $port: ${stty.stderr}');
    }
    final out = await File(port).open(mode: FileMode.writeOnly);
    radio = Companion(out.writeFromSync, File(port).openRead());
    stdout.writeln('Radio on $port');
    // Some boards restart when their port opens.
    await Future<void>.delayed(const Duration(seconds: 2));
  } else {
    throw _Stop('Which radio? Give --port PATH or --ble NAME.');
  }
  try {
    await _simulate(o, random, radio, channelSpec);
  } finally {
    await ble?.close();
  }
}

/// Sets the radio up, sends the reports until Ctrl-C, then undoes what it
/// changed on the radio.
Future<void> _simulate(
  Options o,
  Random random,
  Companion radio,
  String channelSpec,
) async {
  ({int verCode, int channels, bool repeat})? info;
  for (var attempt = 0; info == null && attempt < 5; attempt++) {
    try {
      info = await radio.deviceInfo();
    } on TimeoutException {
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }
  if (info == null) throw _Stop('No answer from a companion radio.');
  if (info.verCode < channelDataVerCode) {
    throw _Stop(
      'This radio\'s firmware can\'t send channel datagrams: it needs '
      'companion firmware 1.15 or later (version code $channelDataVerCode); '
      'it has version code ${info.verCode}.',
    );
  }
  final repeat = info.repeat;
  var self = await radio.appStart();
  final before = self;
  if (o.radio case final r?) {
    if (!await radio.setRadio(
      freqKhz: r.freqKhz,
      bwHz: r.bwHz,
      sf: r.sf,
      cr: r.cr,
    )) {
      throw _Stop('The radio refused those settings.');
    }
    self = await radio.appStart();
  }
  stdout.writeln('Radio "${self.name}": ${_settings(self)}');
  try {
    final (index, channelName, added) = await _tripChannel(
      radio,
      info.channels,
      channelSpec,
    );
    try {
      await _report(o, random, radio, self, index, channelName);
    } finally {
      if (added) {
        await _undo(
          'Taking "$channelName" off the radio',
          () => radio.setChannel(index, '', Uint8List(16)),
        );
      }
    }
  } finally {
    if (o.radio != null) {
      await _undo(
        'Putting the radio back on ${_settings(before)}'
        '${repeat ? ', Off-Grid Repeat on' : ''}',
        () => radio.setRadio(
          freqKhz: before.freqKhz,
          bwHz: before.bwHz,
          sf: before.sf,
          cr: before.cr,
          repeat: repeat,
        ),
      );
    }
  }
}

String _settings(SelfInfo s) =>
    '${(s.freqKhz / 1000).toStringAsFixed(3)} MHz, ${s.bwHz / 1000} kHz, '
    'SF${s.sf}, CR${s.cr}';

Future<void> _undo(String what, Future<bool> Function() change) async {
  try {
    stdout.writeln('$what: ${await change() ? 'done' : 'REFUSED'}');
  } on Object catch (e) {
    stdout.writeln('$what: FAILED ($e)');
  }
}

/// Sends each person's reports on the trip channel until Ctrl-C.
Future<void> _report(
  Options o,
  Random random,
  Companion radio,
  SelfInfo self,
  int index,
  String channelName,
) async {
  final start =
      o.start ??
      (self.lat != 0 || self.lon != 0
          ? (lat: self.lat, lon: self.lon, alt: 300.0)
          : null);
  final people = _people(
    o,
    random,
    start,
    ownPrefix: Uint8List.fromList(self.publicKey.sublist(0, 4)),
    radioName: self.name,
    now: DateTime.now(),
  );
  final airtime = airtimeMs(
    bytes: 37,
    bwHz: self.bwHz,
    sf: self.sf,
    cr: self.cr,
  );
  final ours = {for (final p in people) _hex(p.prefix)};
  // Like MeshTrax, the group is everyone heard on the trip channel.
  final others = <String>{};
  var interval = _interval(o, people.length, airtime);
  final origin = people.first.position;
  stdout.writeln(
    '${people.map((p) => p.name).join(', ')} on "$channelName" '
    '(slot $index), every ${interval.inSeconds} s +/-20 %. Ctrl-C stops.',
  );

  var otherMessages = 0;
  var draining = false;
  Future<void> drain() async {
    if (draining) return;
    draining = true;
    try {
      while (true) {
        final m = await radio.nextMessage();
        if (m == null) break;
        final d = parseChannelData(m);
        if (d == null ||
            d.channel != index ||
            d.dataType != traxshareDataType) {
          otherMessages++;
          continue;
        }
        final r = TraxReport.decode(d.data);
        final who = r == null ? null : _hex(r.senderPrefix);
        if (r == null || ours.contains(who)) continue;
        stdout.writeln(_heard(r, people.first));
        if (others.add(who!) && o.group == null) {
          interval = _interval(o, people.length + others.length, airtime);
          stdout.writeln(
            'A group of ${people.length + others.length}: '
            'every ${interval.inSeconds} s',
          );
        }
      }
    } on Object catch (e) {
      stdout.writeln('Reading a message failed: $e');
    } finally {
      draining = false;
    }
  }

  radio.pushes.listen((f) {
    if (f[0] == pushMsgWaiting) unawaited(drain());
  });
  await drain();
  if (otherMessages > 0) {
    stdout.writeln(
      'Read ${_messages(otherMessages)} that were waiting on the radio; '
      'they are gone from it now.',
    );
  }

  var seconds = 0;
  final timer = Timer.periodic(const Duration(seconds: 1), (_) {
    seconds++;
    final now = DateTime.now();
    for (final p in people) {
      p.step(seconds);
      final report = p.due(now, interval);
      if (report == null) continue;
      final line = _describe(p, report, now, origin);
      radio
          .sendChannelData(index, traxshareDataType, report.encode())
          .then(
            (ok) => stdout.writeln('$line  ${ok ? 'sent' : 'REFUSED'}'),
            onError: (Object e) => stdout.writeln('$line  FAILED: $e'),
          );
    }
  });
  final stop = Completer<void>();
  for (final signal in [ProcessSignal.sigint, ProcessSignal.sigterm]) {
    signal.watch().first.then((_) {
      if (!stop.isCompleted) stop.complete();
    });
  }
  await stop.future;
  timer.cancel();
  stdout.writeln(
    otherMessages == 0
        ? 'Stopping.'
        : 'Stopping. It read ${_messages(otherMessages)} off the radio.',
  );
}

String _messages(int n) => n == 1 ? '1 message' : '$n messages';

/// The trip channel's slot on the radio and its name, adding it from its
/// link if the radio doesn't have it, and whether it did.
Future<(int, String, bool)> _tripChannel(
  Companion radio,
  int slots,
  String spec,
) async {
  final link = _parseLink(spec);
  int? free;
  for (var i = 0; i < slots; i++) {
    final c = await radio.channel(i);
    if (c == null) {
      free ??= i;
    } else if (link != null
        ? _same(c.secret, link.secret)
        : c.name.toLowerCase() == spec.toLowerCase()) {
      return (i, c.name, false);
    }
  }
  if (link == null) throw _Stop('The radio has no channel named "$spec".');
  if (free == null) throw _Stop('The radio has no free channel slot.');
  if (!await radio.setChannel(free, link.name, link.secret)) {
    throw _Stop('The radio refused the channel.');
  }
  stdout.writeln('Added "${link.name}" to the radio, slot $free');
  return (free, link.name, true);
}

({String name, Uint8List secret})? _parseLink(String spec) {
  if (!spec.toLowerCase().startsWith('meshcore://')) return null;
  final uri = Uri.tryParse(spec.trim());
  final hex = uri?.queryParameters['secret'] ?? '';
  if (!RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(hex)) {
    throw _Stop('That link has no 16-byte secret.');
  }
  return (
    name: uri!.queryParameters['name'] ?? 'Trip',
    secret: Uint8List.fromList([
      for (var i = 0; i < 32; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ]),
  );
}

bool _same(List<int> a, List<int> b) => _hex(a) == _hex(b);

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

Duration _interval(Options o, int group, int airtime) =>
    beaconInterval(members: o.group ?? group, reportAirtimeMs: airtime);

List<SimPerson> _people(
  Options o,
  Random random,
  ({double lat, double lon, double alt})? start, {
  required Uint8List ownPrefix,
  required String radioName,
  required DateTime now,
}) {
  final specs = o.people.isEmpty
      ? <PersonSpec>[(kind: 'walk', name: null, file: null)]
      : o.people;
  return [
    for (final (i, s) in specs.indexed)
      SimPerson(
        name: s.name ?? (i == 0 ? radioName : 'Sim ${i + 1}'),
        prefix: i == 0 ? ownPrefix : _madeUpPrefix(random, ownPrefix),
        mover: _mover(o, s, start, Random(random.nextInt(1 << 31))),
        start: now,
        random: Random(random.nextInt(1 << 31)),
      ),
  ];
}

Mover _mover(
  Options o,
  PersonSpec s,
  ({double lat, double lon, double alt})? start,
  Random random,
) {
  if (s.kind == 'gpx') {
    final file = File(s.file!);
    if (!file.existsSync()) throw _Stop('No file ${s.file}');
    final points = gpxPoints(file.readAsStringSync());
    if (points.length < 2) throw _Stop('${s.file} has no track in it.');
    return TrackFollower(points, o.pace);
  }
  if (start == null) {
    throw _Stop('Where do they start? Give --start LAT,LON.');
  }
  return s.kind == 'walk'
      ? Walker(start.lat, start.lon, start.alt, random)
      : Driver(start.lat, start.lon, start.alt, random);
}

Uint8List _madeUpPrefix(Random random, Uint8List own) {
  while (true) {
    final p = Uint8List.fromList(List.generate(4, (_) => random.nextInt(256)));
    if (!_same(p, own)) return p;
  }
}

String _hhmmss(DateTime t) =>
    [t.hour, t.minute, t.second].map((v) => '$v'.padLeft(2, '0')).join(':');

String _offset(TrailPoint from, TrailPoint to, [String of = 'the start']) {
  final dy = (to.lat - from.lat) * metresPerDegree;
  final dx = (to.lon - from.lon) * metresPerDegree * cos(from.lat * pi / 180);
  final d = sqrt(dx * dx + dy * dy);
  if (d < 1) return 'at $of';
  const compass = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  final bearing = (atan2(dx, dy) * 180 / pi + 360) % 360;
  final where = compass[((bearing + 22.5) ~/ 45) % 8];
  return d < 1000
      ? '${d.round()} m $where of $of'
      : '${(d / 1000).toStringAsFixed(1)} km $where of $of';
}

String _describe(SimPerson p, TraxReport r, DateTime now, TrailPoint origin) {
  final motion = r.stillFor != null
      ? 'not moving for ${r.stillFor!.inMinutes} min'
      : r.speed != null
      ? '${r.heading!.round()}° ${r.speed!.toStringAsFixed(1)} m/s'
      : 'no heading yet';
  return [
    _hhmmss(now),
    p.name.padRight(12),
    '#${r.seq}'.padRight(4),
    _offset(origin, (lat: r.lat, lon: r.lon)).padRight(24),
    motion.padRight(20),
    if (r.trail case final t?)
      'trail ${t.points.length} point${t.points.length == 1 ? '' : 's'}',
    if (r.name != null) 'name',
    '${r.encode().length} B',
  ].join('  ');
}

String _heard(TraxReport r, SimPerson near) {
  final who = r.name ?? _hex(r.senderPrefix);
  final speed = r.speed == null ? '' : ', ${r.speed!.toStringAsFixed(1)} m/s';
  final where = _offset(near.position, (lat: r.lat, lon: r.lon), near.name);
  return '${_hhmmss(DateTime.now())}  heard $who: $where$speed';
}
