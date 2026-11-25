import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/services/message_retry_service.dart';

void main() {
  test('a repeater heard within a window, by the service\'s clock', () {
    var now = DateTime(2026, 11, 25, 12);
    final svc = MessageRetryService(clock: () => now);
    const minute = Duration(minutes: 1);
    expect(svc.repeaterHeardWithin(minute), isFalse, reason: 'none yet');

    svc.noteRepeaterHeard();
    now = now.add(const Duration(seconds: 50));
    expect(svc.repeaterHeardWithin(minute), isTrue);

    now = now.add(const Duration(seconds: 20));
    expect(svc.repeaterHeardWithin(minute), isFalse);
    expect(svc.repeaterHeardRecently, isTrue, reason: 'within 10 minutes');

    // A clock set back can't tell.
    now = now.subtract(const Duration(hours: 1));
    expect(svc.repeaterHeardWithin(minute), isFalse);
    expect(svc.repeaterHeardRecently, isFalse);
  });
}
