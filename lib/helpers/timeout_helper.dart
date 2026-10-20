import 'dart:math' as math;

/// All send/reply timeout math in one place. Every constant is anchored to a
/// firmware symbol, not guessed; the formulas are shared by the connector,
/// the repeater command service, and the bench.
class TimeoutHelper {
  TimeoutHelper._();

  /// SEND_TIMEOUT_BASE_MILLIS (firmware Mesh.h).
  static const int sendBaseMs = 500;

  /// DIRECT_SEND_PERHOP_FACTOR — the firmware budgets 6 airtimes per hop.
  static const int perHopAirtimeFactor = 6;

  /// DIRECT_SEND_PERHOP_EXTRA_MILLIS — per-hop turnaround allowance.
  static const int perHopExtraMs = 250;

  /// CLI_REPLY_DELAY_MILLIS (simple_repeater/MyMesh.cpp): the repeater
  /// deliberately waits this long before transmitting any reply. A 1.18
  /// companion answering a remote CLI command waits the same 600 ms
  /// (CLI_REPLY_DELAY_MILLIS, BaseChatMesh.cpp).
  static const int replyDelayMs = 600;

  /// CLI_REPLY_DELAY_MILLIS in simple_sensor/SensorMesh.cpp: a sensor waits
  /// longer than a repeater before it answers a CLI command.
  static const int sensorReplyDelayMs = 1000;

  /// CADFailMaxDuration (Dispatcher.cpp): a busy channel can defer one
  /// transmission this long before the send is forced out.
  static const int cadCeilingMs = 4000;

  /// No attempt may be shorter than this — under the repeater's own reply
  /// delay a budget cannot succeed on any path.
  static const int minAttemptMs = 3000;

  /// Floor for the final attempt of a retry ladder on a fast path.
  static const int lastAttemptFloorMs = 8000;

  /// Hops assumed for a flood to a contact whose distance is unknown.
  static const int defaultFloodHops = 8;

  static const int minFloodMs = 10000;
  static const int maxMs = 60000;

  /// The firmware's own give-up bound for pushing one packet out over
  /// (hops + 1) radio legs: worst-case CAD stalls on every leg. Use it for
  /// retry-ladder budgets that must never expire before the radio does.
  static int sendLegMs(int airtimeMs, int hops) =>
      sendBaseMs + (airtimeMs * perHopAirtimeFactor + perHopExtraMs) * (hops + 1);

  /// A realistic command round trip on a known route: the request crosses
  /// (hops + 1) legs, the repeater waits [replyDelayMs], the reply crosses
  /// the same legs back, and one full CAD stall is allowed somewhere along
  /// the way. Typical round trips come in far under this; the firmware's
  /// [sendLegMs] bound tripled (the old one-shot policy) sat at 3-5x it.
  static int roundTripMs(int airtimeMs, int hops) =>
      2 * (hops + 1) * (airtimeMs + perHopExtraMs) + replyDelayMs + cadCeilingMs;

  /// Budget for one attempt of an [attemptCount]-attempt ladder.
  ///
  /// With several attempts, early ones scale with the path and the final one
  /// keeps the full conservative budget (max(8 s, base x 3), never above
  /// [maxMs]) so a genuinely slow path still completes. A single attempt is
  /// NOT a final rung: the caller passes a round-trip base and gets it back
  /// untripled — tripling it is what made a failed one-shot CLI command sit
  /// for ~24 s at one hop. The [maxMs] cap is what stopped a telemetry
  /// ladder to an unknown-distance contact from waiting 60+120+180 s.
  static int attemptMs(int baseMs, int attempt, int attemptCount) {
    if (attemptCount <= 1) return math.max(minAttemptMs, math.min(baseMs, maxMs));
    final ceiling =
        math.min(maxMs, math.max(lastAttemptFloorMs, baseMs * 3));
    if (attempt >= attemptCount - 1) return ceiling;
    final scaled = baseMs * (attempt + 1);
    return math.min(ceiling, math.max(minAttemptMs, scaled));
  }
}
