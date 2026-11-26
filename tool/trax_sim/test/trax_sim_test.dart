import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:trax_sim/companion.dart';
import 'package:trax_sim/movers.dart';
import 'package:trax_sim/sim_person.dart';
import 'package:traxshare/traxshare.dart';

import '../bin/trax_sim.dart' show Options;

/// A frame as the radio writes it: '>', the length, the frame.
List<int> fromRadio(List<int> frame) => [
  0x3E,
  frame.length & 0xFF,
  frame.length >> 8,
  ...frame,
];

double metres(double lat1, double lon1, double lat2, double lon2) {
  final dy = (lat2 - lat1) * metresPerDegree;
  final dx = (lon2 - lon1) * metresPerDegree * cos(lat1 * pi / 180);
  return sqrt(dx * dx + dy * dy);
}

void main() {
  group('serial frames', () {
    test('to the radio', () {
      expect(frameForRadio([22, 3]), [0x3C, 2, 0, 22, 3]);
    });

    test('from the radio, across reads, after a boot log', () {
      final bytes = [
        ...'boot ok\r\n'.codeUnits,
        ...fromRadio([0, 1]),
        ...fromRadio([0x83]),
      ];
      final splitter = FrameSplitter();
      expect(splitter.add(bytes.sublist(0, 12)), isEmpty);
      expect(splitter.add(bytes.sublist(12)), [
        [0, 1],
        [0x83],
      ]);
    });

    test('a stray ">" is skipped', () {
      expect(
        FrameSplitter().add([
          0x3E,
          0x20,
          0x3E,
          ...fromRadio([5]),
        ]),
        [
          [5],
        ],
      );
    });
  });

  test('self info', () {
    final f = Uint8List(62);
    final d = ByteData.sublistView(f)
      ..setInt32(36, 36457000, Endian.little)
      ..setInt32(40, -116866000, Endian.little)
      ..setUint32(48, 918000, Endian.little)
      ..setUint32(52, 62500, Endian.little);
    f[0] = respSelfInfo;
    for (var i = 0; i < 32; i++) {
      f[4 + i] = i;
    }
    d.setUint8(56, 7);
    d.setUint8(57, 5);
    f.setRange(58, 62, 'Trip'.codeUnits);
    final self = SelfInfo.parse(f)!;
    expect(self.publicKey.sublist(0, 4), [0, 1, 2, 3]);
    expect(self.lat, closeTo(36.457, 1e-9));
    expect(self.lon, closeTo(-116.866, 1e-9));
    expect(
      (self.freqKhz, self.bwHz, self.sf, self.cr, self.name),
      (918000, 62500, 7, 5, 'Trip'),
    );
    expect(SelfInfo.parse(Uint8List(40)), isNull);
  });

  group('companion', () {
    late StreamController<List<int>> input;
    late List<Uint8List> written;
    late Companion radio;

    setUp(() {
      input = StreamController();
      written = [];
      radio = Companion(written.add, input.stream);
    });

    List<List<int>> commands() => [for (final w in written) w.sublist(3)];

    test('one command at a time, pushes aside', () async {
      final pushes = <Uint8List>[];
      radio.pushes.listen(pushes.add);
      final info = radio.deviceInfo();
      final next = radio.nextMessage();
      await pumpEventQueue();
      expect(commands(), [
        [cmdDeviceQuery, 3],
      ]);
      input.add(fromRadio([pushMsgWaiting]));
      input.add(fromRadio([respDeviceInfo, 11, 0, 8, 0, 0, 0, 0]));
      expect(await info, (verCode: 11, channels: 8, repeat: false));
      await pumpEventQueue();
      expect(commands().last, [cmdSyncNextMessage]);
      input.add(fromRadio([respNoMoreMessages]));
      expect(await next, isNull);
      expect(pushes, [
        [pushMsgWaiting],
      ]);
    });

    test('Off-Grid Repeat, from the device info', () async {
      final info = radio.deviceInfo();
      await pumpEventQueue();
      final frame = [respDeviceInfo, 11, 0, 40, ...List.filled(76, 0), 1, 0];
      input.add(fromRadio(frame));
      expect(await info, (verCode: 11, channels: 40, repeat: true));
    });

    test('no answer: it times out, and the next command goes out', () async {
      await expectLater(
        radio.ask([cmdAppStart], timeout: const Duration(milliseconds: 20)),
        throwsA(isA<TimeoutException>()),
      );
      final next = radio.nextMessage();
      await pumpEventQueue();
      expect(commands(), [
        [cmdAppStart],
        [cmdSyncNextMessage],
      ]);
      input.add(fromRadio([respNoMoreMessages]));
      expect(await next, isNull);
    });

    test('channels: a set slot and an empty one', () async {
      final secret = List.generate(16, (i) => 0xA0 + i);
      final set = radio.channel(1);
      await pumpEventQueue();
      input.add(
        fromRadio([
          respChannelInfo,
          1,
          ...'Trip'.codeUnits,
          ...List.filled(28, 0),
          ...secret,
        ]),
      );
      final c = await set;
      expect(c?.name, 'Trip');
      expect(c?.secret, secret);
      final empty = radio.channel(2);
      await pumpEventQueue();
      input.add(fromRadio([respChannelInfo, 2, ...List.filled(48, 0)]));
      expect(await empty, isNull);
    });

    test('setting a channel and the radio', () async {
      final secret = Uint8List.fromList(List.generate(16, (i) => i));
      final channel = radio.setChannel(2, 'Trip', secret);
      await pumpEventQueue();
      input.add(fromRadio([respOk]));
      expect(await channel, isTrue);
      expect(commands().last, [
        cmdSetChannel,
        2,
        ...'Trip'.codeUnits,
        ...List.filled(28, 0),
        ...secret,
      ]);
      final settings = radio.setRadio(
        freqKhz: 918000,
        bwHz: 62500,
        sf: 7,
        cr: 5,
      );
      await pumpEventQueue();
      input.add(fromRadio([1, 1]));
      expect(await settings, isFalse);
      expect(commands().last, [
        11,
        0xF0,
        0x01,
        0x0E,
        0,
        0x24,
        0xF4,
        0,
        0,
        7,
        5,
      ]);
      final back = radio.setRadio(
        freqKhz: 918000,
        bwHz: 62500,
        sf: 7,
        cr: 5,
        repeat: true,
      );
      await pumpEventQueue();
      input.add(fromRadio([respOk]));
      expect(await back, isTrue);
      expect(commands().last.sublist(9), [7, 5, 1], reason: 'repeat on');
    });

    test('a channel datagram out', () async {
      final sent = radio.sendChannelData(
        3,
        traxshareDataType,
        Uint8List.fromList([9, 8]),
      );
      await pumpEventQueue();
      expect(commands().single, [
        cmdSendChannelData,
        3,
        0xFF,
        0x71,
        0x01,
        9,
        8,
      ]);
      input.add(fromRadio([respOk]));
      expect(await sent, isTrue);
    });
  });

  test('over a link of whole frames, as Bluetooth is', () async {
    final frames = StreamController<Uint8List>();
    final sent = <Uint8List>[];
    final radio = Companion.frames(sent.add, frames.stream);
    final pushes = <Uint8List>[];
    radio.pushes.listen(pushes.add);
    final next = radio.nextMessage();
    await pumpEventQueue();
    expect(sent, [
      [cmdSyncNextMessage],
    ]);
    frames.add(Uint8List.fromList([pushMsgWaiting]));
    frames.add(Uint8List.fromList([respNoMoreMessages]));
    expect(await next, isNull);
    expect(pushes, [
      [pushMsgWaiting],
    ]);
  });

  test('a channel datagram in', () {
    final d = parseChannelData(
      Uint8List.fromList([27, 0xF8, 0, 0, 2, 0xFF, 0x71, 0x01, 3, 7, 8, 9]),
    );
    expect(d?.channel, 2);
    expect(d?.dataType, traxshareDataType);
    expect(d?.data, [7, 8, 9]);
    final cut = Uint8List.fromList([27, 0, 0, 0, 2, 0xFF, 0x71, 0x01, 5, 1]);
    expect(parseChannelData(cut), isNull);
  });

  test('airtime, as MeshTrax works it out', () {
    expect(
      airtimeMs(bytes: 37, bwHz: 62500, sf: 7, cr: 5),
      referenceReportAirtimeMs,
    );
    expect(airtimeMs(bytes: 37, bwHz: 250000, sf: 11, cr: 5), 519);
  });

  group('movers', () {
    test('a walker walks at about 1.4 m/s, resting now and then', () {
      final w = Walker(36.457, -116.866, 300, Random(1));
      var moving = 0;
      var walked = 0.0;
      for (var s = 0; s < 3600; s++) {
        final (lat, lon) = (w.lat, w.lon);
        w.step();
        if (w.speed > 0) {
          moving++;
          walked += metres(lat, lon, w.lat, w.lon);
        }
      }
      expect(walked / moving, closeTo(1.4, 0.11));
      expect(moving, inExclusiveRange(1800, 3600));
    });

    test('a driver cruises at 45 to 60 mph and stops at junctions', () {
      final d = Driver(36.457, -116.866, 300, Random(2));
      var top = 0.0;
      var stops = 0;
      var moving = false;
      for (var s = 0; s < 3600; s++) {
        d.step();
        top = max(top, d.speed);
        if (d.speed == 0 && moving) stops++;
        moving = d.speed > 0;
      }
      expect(top, inInclusiveRange(20, 27));
      expect(stops, greaterThanOrEqualTo(3));
    });

    test('a track follower keeps to its points, then stays at the end', () {
      final t = TrackFollower([
        (lat: 36.457, lon: -116.866, ele: 300.0),
        (lat: 36.458, lon: -116.866, ele: 310.0),
        (lat: 36.458, lon: -116.865, ele: null),
      ], 2);
      for (var s = 0; s < 50; s++) {
        t.step();
      }
      expect((t.heading, t.speed), (0, 2));
      expect(metres(36.457, -116.866, t.lat, t.lon), closeTo(100, 0.01));
      for (var s = 0; s < 60; s++) {
        t.step();
      }
      expect((t.lat, t.lon, t.altitude), (36.458, -116.865, 310.0));
      expect((t.heading, t.speed, t.stillSeconds), (90, 0, 9));
    });

    test('GPX track and route points', () {
      const gpx = '''<?xml version="1.0"?>
<gpx><trk><trkseg>
<trkpt lat="36.4570" lon="-116.8660"><ele>300.5</ele></trkpt>
<trkpt lon='-116.8650' lat='36.4580'/>
</trkseg></trk><rte><rtept lat="36.459" lon="-116.864"></rtept></rte></gpx>''';
      expect(gpxPoints(gpx), [
        (lat: 36.457, lon: -116.866, ele: 300.5),
        (lat: 36.458, lon: -116.865, ele: null),
        (lat: 36.459, lon: -116.864, ele: null),
      ]);
    });
  });

  group('a pretend member', () {
    final start = DateTime.utc(2026, 11, 21, 9);
    const interval = Duration(minutes: 1);

    /// What each report of the latest [run] carried.
    final carried = <SimCarry>[];

    /// Its reports over [seconds], each with the second it went; [asks]
    /// come at their second.
    List<(int, TraxReport)> run(
      Mover mover,
      int seconds, {
      Map<int, TraxAsk> asks = const {},
    }) {
      final p = SimPerson(
        name: 'Ana',
        prefix: Uint8List.fromList([0xA1, 0xA2, 0xA3, 0xA4]),
        mover: mover,
        start: start,
        random: Random(3),
      );
      carried.clear();
      final out = <(int, TraxReport)>[];
      for (var s = 1; s <= seconds; s++) {
        final now = start.add(Duration(seconds: s));
        p.step(s);
        if (asks[s] case final ask?) p.ask(ask, now);
        if (p.due(now, interval) case final r?) {
          out.add((s, r));
          carried.add(p.carried);
        }
      }
      return out;
    }

    test('reports on the app\'s schedule, names and trails', () {
      final reports = run(Walker(36.457, -116.866, 300, Random(4)), 3600);
      expect(reports.first.$1, inInclusiveRange(10, 30));
      for (var i = 1; i < reports.length; i++) {
        expect(reports[i].$1 - reports[i - 1].$1, inInclusiveRange(48, 73));
      }
      for (final (_, r) in reports) {
        expect(r.lat * 1e4, closeTo((r.lat * 1e4).roundToDouble(), 1e-6));
        expect(r.encode().length, lessThanOrEqualTo(TraxReport.maxSize));
      }

      final named = [
        for (final (s, r) in reports)
          if (r.name != null) s,
      ];
      expect(named.first, reports.first.$1);
      for (var i = 1; i < named.length; i++) {
        expect(named[i] - named[i - 1], inInclusiveRange(1800, 1873));
      }

      final trails = [
        for (final (i, (s, r)) in reports.indexed)
          if (carried[i] == SimCarry.trail) (i, s, r),
      ];
      expect(trails.first.$1, lessThan(2));
      for (var i = 1; i < trails.length; i++) {
        expect(trails[i].$1 - trails[i - 1].$1, greaterThanOrEqualTo(5));
        expect(trails[i].$2 - trails[i - 1].$2, greaterThanOrEqualTo(600));
      }
      expect(trails.length, greaterThanOrEqualTo(5));
      final last = TraxReport.decode(trails.last.$3.encode())!;
      final points = last.track!.pieces.fold(0, (n, p) => n + p.points.length);
      expect(points, greaterThan(10));
    });

    test('a drive: one older piece halfway between trails, alone and '
        'without the name', () {
      final reports = run(Driver(36.457, -116.866, 300, Random(5)), 2 * 3600);
      var trailAt = 0;
      var olderSince = false;
      final older = <int>[];
      for (final (i, (s, r)) in reports.indexed) {
        if (carried[i] == SimCarry.trail) {
          trailAt = s;
          olderSince = false;
        } else if (carried[i] == SimCarry.older) {
          expect(r.track!.pieces, hasLength(1));
          expect(r.name, isNull);
          expect(s - trailAt, inInclusiveRange(300, 373), reason: 'halfway');
          expect(olderSince, isFalse, reason: 'one between trails');
          olderSince = true;
          older.add(r.track!.pieces.single.minute);
        }
      }
      expect(older.length, greaterThanOrEqualTo(8));
      expect(older.toSet().length, greaterThanOrEqualTo(3));
    });

    test('an ask brings the trail, then each piece the asker lacks', () {
      const at = 3600;
      final all = run(Driver(36.457, -116.866, 300, Random(5)), at);
      final pieces = <int>{
        for (final (_, r) in all) ...?r.track?.pieces.map((p) => p.minute),
      };
      expect(pieces.length, greaterThanOrEqualTo(3));
      final have = (pieces.toList()..sort()).sublist(0, 1);
      final reports = run(
        Driver(36.457, -116.866, 300, Random(5)),
        at + 600,
        asks: {
          at: TraxAsk(
            seq: 0,
            senderPrefix: Uint8List.fromList([1, 2, 3, 4]),
            session: 9,
            sentAt: start.add(const Duration(seconds: at)),
            target: Uint8List.fromList([0xA1, 0xA2, 0xA3, 0xA4]),
            have: have,
          ),
        },
      );
      final after = [
        for (final (i, (s, r)) in reports.indexed)
          if (s > at) (s, r, carried[i]),
      ];
      expect(after.first.$3, SimCarry.trail);
      expect(after.first.$1 - at, lessThanOrEqualTo(3));
      final asked = [
        for (final (s, r, c) in after)
          if (c == SimCarry.asked) (s, r.track!.pieces.single),
      ];
      expect(asked, isNotEmpty);
      for (var i = 1; i < asked.length; i++) {
        expect(asked[i].$1 - asked[i - 1].$1, greaterThanOrEqualTo(6));
        expect(asked[i].$2.minute, lessThan(asked[i - 1].$2.minute));
      }
      expect(asked.map((a) => a.$2.minute), isNot(contains(have.single)));
    });

    test('stopped for 2 minutes: not moving, and for how long', () {
      // 22 m north at 1.4 m/s: there at 16 s.
      final reports = run(
        TrackFollower([
          (lat: 36.457, lon: -116.866, ele: 300.0),
          (lat: 36.4572, lon: -116.866, ele: 300.0),
        ], 1.4),
        600,
      );
      for (final (s, sent) in reports) {
        final r = TraxReport.decode(sent.encode())!;
        if (s >= 136) {
          expect(r.stillFor, Duration(minutes: (s - 16) ~/ 60));
          expect((r.heading, r.speed), (null, null));
        } else {
          expect(r.stillFor, isNull);
          expect(r.heading, 0);
          expect(r.speed, greaterThan(1));
        }
      }
      expect(reports.where((e) => e.$1 >= 136), isNotEmpty);
    });
  });

  test('options', () {
    final o = Options.parse([
      '--walk',
      'Ana',
      '--drive=Ben',
      '--gpx=hike.gpx=Cy',
      '--gpx',
      'road.gpx',
      '--start',
      '36.457,-116.866',
      '--radio',
      '918,62.5,7,5',
      '--group=4',
    ]);
    expect(o.people, [
      (kind: 'walk', name: 'Ana', file: null),
      (kind: 'drive', name: 'Ben', file: null),
      (kind: 'gpx', name: 'Cy', file: 'hike.gpx'),
      (kind: 'gpx', name: null, file: 'road.gpx'),
    ]);
    expect(o.start, (lat: 36.457, lon: -116.866, alt: 300.0));
    expect(o.radio, (freqKhz: 918000, bwHz: 62500, sf: 7, cr: 5));
    expect(o.group, 4);
    expect(Options.parse(['--ble', 'Trail Radio']).ble, 'Trail Radio');
    expect(() => Options.parse(['--start', '36.4']), throwsFormatException);
    expect(() => Options.parse(['--fly']), throwsFormatException);
  });
}
