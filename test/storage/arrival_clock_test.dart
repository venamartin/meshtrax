import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/storage/arrival_clock.dart';

void main() {
  setUp(ArrivalClock.resetForTesting);

  test('stamps strictly increase', () {
    final stamps = [for (var i = 0; i < 1000; i++) ArrivalClock.next()];
    for (var i = 1; i < stamps.length; i++) {
      expect(stamps[i], greaterThan(stamps[i - 1]));
    }
  });

  // Messages can arrive faster than the clock's resolution. Equal stamps would
  // leave their order down to whatever the database felt like returning.
  test('stamps issued in the same microsecond still differ', () {
    final a = ArrivalClock.next();
    final b = ArrivalClock.next();
    expect(b, greaterThan(a));
  });

  test('seeding from a sender timestamp matches the v6 migration', () {
    final ts = DateTime.fromMillisecondsSinceEpoch(1753000000000);
    expect(ArrivalClock.fromSenderTimestamp(ts), 1753000000000 * 1000);
  });

  // Ordering must survive the phone's own clock moving — an NTP correction or
  // a timezone database update should never insert new messages above old.
  test('a stamp is never lower than the one before it', () {
    final first = ArrivalClock.next();
    final second = ArrivalClock.next();
    expect(second, greaterThan(first));
    expect(ArrivalClock.next(), greaterThan(second));
  });

  // The in-memory floor dies with the process. The database seeds the clock
  // on open with MAX(received_at_us), so a phone clock that stepped backwards
  // BETWEEN sessions still cannot stamp new messages below stored rows —
  // where they would insert mid-conversation and, under the read watermark,
  // never count as unread.
  test('seeding raises the floor above persisted stamps', () {
    final future = DateTime.now().microsecondsSinceEpoch + 3600000000; // +1h
    ArrivalClock.seed(future);
    expect(ArrivalClock.next(), greaterThan(future));
  });

  test('seeding never lowers the floor', () {
    final a = ArrivalClock.next();
    ArrivalClock.seed(0);
    expect(ArrivalClock.next(), greaterThan(a));
  });
}
