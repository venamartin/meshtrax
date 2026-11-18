import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/services/radio_ask_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

import '../helpers/radio_ask_fakes.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  final at = DateTime(2026, 11, 18, 14, 2);

  RadioAskService service(AskRadio radio, {bool heard = true}) =>
      RadioAskService(radio, repeaterHeardRecently: () => heard, now: () => at);

  test('an answer with a position asks again a minute later; a new reading '
      'leaves no doubt', () {
    fakeAsync((async) {
      final radio = AskRadio();
      final asks = service(radio);
      var reads = 0;
      radio.reply = (i, _) => radio.telemetry([
        ...lppBattery,
        ...lppGps(36.5, -117.0, 610.0 + reads++),
        ...lppTemperature,
      ]);

      asks.ask(gwq);
      async.flushMicrotasks();
      final ask = asks.askFor(gwq)!;
      expect(ask.phase, RadioAskPhase.checkingAgain);
      expect(ask.attempt, 0);
      expect(ask.recheckAt, at.add(const Duration(minutes: 1)));
      final first = ask.first!;
      expect(first.position, (lat: 36.5, lon: -117.0, altitude: 610.0));
      expect(first.volts, closeTo(4.15, 1e-9));
      expect(first.celsius, 40.0);
      expect(radio.tags, hasLength(1));

      async.elapse(const Duration(seconds: 59));
      expect(radio.tags, hasLength(1));
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(ask.phase, RadioAskPhase.done);
      expect(ask.second!.position!.altitude, 611.0);
      expect(ask.unchanged, isFalse);
      expect(ask.noFix, isFalse);
      expect(asks.positionOf(gwq), same(ask.second));
      expect(radio.tags, hasLength(2));
    });
  });

  test('the same reading a minute apart: may be old', () {
    fakeAsync((async) {
      final radio = AskRadio();
      final asks = service(radio);
      radio.reply = (_, _) => radio.telemetry(lppGps(36.5, -117.0, 610));

      asks.ask(gwq);
      async.elapse(const Duration(minutes: 1));
      async.flushMicrotasks();
      final ask = asks.askFor(gwq)!;
      expect(ask.phase, RadioAskPhase.done);
      expect(ask.unchanged, isTrue);
    });
  });

  test('altitude exactly 0: no live fix, so no second read', () {
    fakeAsync((async) {
      final radio = AskRadio();
      final asks = service(radio);
      radio.reply = (_, _) => radio.telemetry(lppGps(36.5, -117.0, 0));

      asks.ask(gwq);
      async.elapse(const Duration(minutes: 2));
      final ask = asks.askFor(gwq)!;
      expect(ask.phase, RadioAskPhase.done);
      expect(ask.noFix, isTrue);
      expect(radio.tags, hasLength(1));
    });
  });

  test('no GPS item, or 0, 0: no position', () {
    for (final lpp in [
      lppBattery,
      [...lppBattery, ...lppGps(0, 0, 0)],
    ]) {
      fakeAsync((async) {
        final radio = AskRadio();
        final asks = service(radio);
        radio.reply = (_, _) => radio.telemetry(lpp);

        asks.ask(gwq);
        async.elapse(const Duration(minutes: 2));
        final ask = asks.askFor(gwq)!;
        expect(ask.phase, RadioAskPhase.done);
        expect(ask.latest!.position, isNull);
        expect(ask.latest!.volts, closeTo(4.15, 1e-9));
        expect(asks.positionOf(gwq), isNull);
        expect(asks.located, isEmpty);
        expect(radio.tags, hasLength(1));
      });
    }
  });

  test('an answer to an earlier try comes back by its tag', () {
    fakeAsync((async) {
      final radio = AskRadio();
      final asks = service(radio);
      radio.reply = (i, _) {
        // The radio cleared the first request, then answers it late.
        if (i == 2) radio.binary(radio.tags[0], lppGps(36.5, -117.0, 0));
      };

      asks.ask(gwq);
      async.elapse(const Duration(minutes: 2));
      final ask = asks.askFor(gwq)!;
      expect(radio.tags, hasLength(3));
      expect(ask.phase, RadioAskPhase.done);
      expect(ask.first!.position!.lat, 36.5);
    });
  });

  test('an answer to someone else is not theirs', () {
    fakeAsync((async) {
      final radio = AskRadio();
      final asks = service(radio);
      radio.reply = (_, _) {
        radio.telemetry(lppGps(1, 2, 3), key: keyOf(0x10));
        radio.binary([0x99, 0, 0, 0], lppGps(1, 2, 3));
      };

      asks.ask(gwq);
      async.elapse(const Duration(minutes: 2));
      final ask = asks.askFor(gwq)!;
      expect(ask.phase, RadioAskPhase.noAnswer);
      expect(ask.latest, isNull);
      expect(radio.tags, hasLength(RadioAskService.attempts));
    });
  });

  test('a second read that gets nothing keeps the first answer', () {
    fakeAsync((async) {
      final radio = AskRadio();
      final asks = service(radio);
      radio.reply = (i, _) {
        if (i == 0) radio.telemetry(lppGps(36.5, -117.0, 610));
      };

      asks.ask(gwq);
      async.elapse(const Duration(minutes: 3));
      final ask = asks.askFor(gwq)!;
      expect(ask.phase, RadioAskPhase.done);
      expect(ask.second, isNull);
      expect(ask.latest!.position!.altitude, 610);
      expect(radio.tags, hasLength(1 + RadioAskService.attempts));
    });
  });

  test('one ask at a time; asking again while one is under way changes '
      'nothing', () {
    fakeAsync((async) {
      final radio = AskRadio();
      final asks = service(radio);
      final other = person('Ridge', keyOf(0x10));

      asks.ask(gwq);
      asks.ask(other);
      asks.ask(gwq);
      async.flushMicrotasks();
      expect(asks.askFor(gwq)!.phase, RadioAskPhase.asking);
      expect(asks.askFor(other)!.phase, RadioAskPhase.waiting);
      expect(radio.askedOf, [gwq.publicKeyHex.substring(0, 12)]);

      async.elapse(const Duration(minutes: 2));
      expect(asks.askFor(gwq)!.phase, RadioAskPhase.noAnswer);
      expect(asks.askFor(other)!.phase, RadioAskPhase.noAnswer);
      expect(radio.askedOf, [
        for (var i = 0; i < RadioAskService.attempts; i++)
          gwq.publicKeyHex.substring(0, 12),
        for (var i = 0; i < RadioAskService.attempts; i++)
          other.publicKeyHex.substring(0, 12),
      ]);
    });
  });

  test('asking again shows the last answer until the new one comes', () {
    fakeAsync((async) {
      final radio = AskRadio();
      final asks = service(radio);
      radio.reply = (_, _) => radio.telemetry(lppGps(36.5, -117.0, 0));
      asks.ask(gwq);
      async.elapse(const Duration(minutes: 1));
      final before = asks.askFor(gwq)!.latest;

      radio.reply = (_, _) {};
      asks.ask(gwq);
      final again = asks.askFor(gwq)!;
      expect(again.latest, same(before));
      async.elapse(const Duration(minutes: 2));
      expect(again.phase, RadioAskPhase.noAnswer);
      expect(asks.positionOf(gwq), same(before));
    });
  });

  test('with no repeater heard lately, every try floods', () {
    fakeAsync((async) {
      final radio = AskRadio();
      service(radio, heard: false).ask(gwq);
      async.flushMicrotasks();
      expect(radio.floodOnly, isTrue);

      final heard = AskRadio();
      service(heard).ask(gwq);
      async.flushMicrotasks();
      expect(heard.floodOnly, isFalse);
    });
  });
}
