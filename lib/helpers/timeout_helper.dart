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

  /// tx_delay_factor (companion and simple_repeater NodePrefs defaults): a
  /// repeater forwarding a flood waits a random share of this many airtimes.
  static const double repeaterTxDelayFactor = 0.5;

  /// getRetransmitDelay draws from 0 to 5 × (airtime × tx_delay_factor).
  static const int retransmitDelaySpan = 5;

  /// No echo watch is shorter than this: a close repeater's copy arrives
  /// well inside it, and a shorter watch parks live messages on busy air.
  static const int minEchoWaitMs = 10000;

  /// How long to wait for the first repeater's copy of my own flood before
  /// concluding none heard it: my own CAD stall, the repeater's CAD stall,
  /// its random forwarding delay at its largest, and two airtimes (mine and
  /// its). Never longer than the attempt's own ACK timeout. ~10 s at 0.6 s
  /// airtime, ~19 s at 2.4 s.
  static int echoWaitMs(int airtimeMs, int attemptTimeoutMs) {
    final wait = 2 * cadCeilingMs +
        airtimeMs * (2 + retransmitDelaySpan * repeaterTxDelayFactor);
    final floor = math.min(minEchoWaitMs, attemptTimeoutMs);
    return wait.round().clamp(floor, math.max(floor, attemptTimeoutMs));
  }

  /// direct_tx_delay_factor (simple_repeater NodePrefs default): a repeater
  /// passing on a routed packet waits a random share of this many airtimes
  /// (getDirectRetransmitDelay, 0 to 5 x airtime x factor).
  static const double repeaterDirectTxDelayFactor = 0.3;

  /// TXT_ACK_DELAY (BaseChatMesh.cpp): a companion waits this long before
  /// it sends the ACK for a message it opened.
  static const int ackDelayMs = 200;

  /// BaseChatMesh::sendAckTo sends its extra MULTIPART ACK first and the
  /// plain ACK this much later.
  static const int extraAckGapMs = 300;

  /// How long the app leaves an ACK it saw in the RX log to the radio. The
  /// radio pushes the RX log line just before it handles the packet
  /// (Dispatcher.cpp), so its SEND_CONFIRMED for an ACK it counts follows
  /// within a frame or two.
  static const int heardAckGraceMs = 1000;

  /// How long the app holds the ACK for a DM it opened from a copy that
  /// still had [hopsLeft] hops to go: until the last of those repeaters has
  /// passed the DM on (each waits at most its direct retransmit delay, then
  /// sends for one airtime), so the ACK doesn't talk over them; then the
  /// companion's own ACK delay. ~1 s for one hop left at 0.3 s airtime.
  static int passingCopyAckDelayMs(int airtimeMs, int hopsLeft) =>
      (hopsLeft *
                  airtimeMs *
                  (1 + retransmitDelaySpan * repeaterDirectTxDelayFactor))
              .round() +
          ackDelayMs;

  /// How long an app-held stand-in for the radio's ACK waits once its time
  /// has come, before it is sent: on a fresh timer, whose deadline is still
  /// ahead, a busy app handles the radio frames already waiting for it, the
  /// radio's own copy of the message among them, which drops the stand-in.
  /// An expired timer can run before those frames (simulator, 2026-11-22:
  /// the radio's copy waited over a second behind a DM's intake and reply).
  static const int standInRecheckMs = 100;

  /// How long after a flood to this radio was first heard the app waits
  /// before it sends the sender a corrected way back
  /// (MeshCoreConnector._repairWayBack). The radio's own answer has to
  /// reach them first, or it would replace the correction: it leaves within
  /// 500 ms (TXT_ACK_DELAY for a flooded path return, 500 ms for the routed
  /// path that answers a path reply, Mesh.cpp) and, as a flood, crosses
  /// [hops] + 1 legs, each a repeater's longest wait and one airtime. Then a
  /// second for busy air.
  static int wayBackRepairDelayMs(int airtimeMs, int hops) =>
      500 +
      ((hops + 1) *
              airtimeMs *
              (1 + retransmitDelaySpan * repeaterTxDelayFactor))
          .ceil() +
      1000;

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
