import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/structured_message.dart';

// The repeater status card (docs/message-format.md, "Repeater status"): a
// generic report of how repeaters stand, one field each. The owner,
// 2026-11-19: a generic card, stages without "?", one card per page.
RepeaterStatusMessage _parse(String text) =>
    StructuredMessage.parse(text)! as RepeaterStatusMessage;

void main() {
  test('one field per repeater: name, volts, stage, age, keys and note', () {
    final m = _parse('Repeater: A277 3.52V crit 2m | '
        'A377 3.48V vlow 40m missed=1 step to crit unconfirmed | AD77 waiting');
    expect(m.repeaters.map((r) => r.name), ['A277', 'A377', 'AD77']);

    final a = m.repeaters[0];
    expect(a.volts, '3.52');
    expect(a.stage, RepeaterStage.crit);
    expect(a.age, const Duration(minutes: 2));
    expect(a.note, isNull);

    final b = m.repeaters[1];
    expect(b.stage, RepeaterStage.vlow);
    expect(b.age, const Duration(minutes: 40));
    expect(b.keys, {'missed': '1'});
    expect(b.note, 'step to crit unconfirmed');

    expect(m.repeaters[2].waiting, isTrue);
    expect(m.repeaters[2].state, RepeaterState.waiting);
  });

  test('volts, stage and age come before the note; keys may be anywhere', () {
    final m = _parse('Repeater: A277 failed to apply crit retrying | '
        'A377 still bumped tx=22 repeat=on for=A277 retrying');
    final failed = m.repeaters[0];
    expect(failed.stage, isNull, reason: '"crit" sits in the note');
    expect(failed.note, 'failed to apply crit retrying');
    expect(failed.state, RepeaterState.other);

    final bumped = m.repeaters[1];
    expect(bumped.keys, {'tx': '22', 'repeat': 'on', 'for': 'A277'});
    expect(bumped.note, 'still bumped retrying');
  });

  test('the fixed words: unreachable, no reading', () {
    final m = _parse('Repeater: A377 unreachable missed=2 stage=crit '
        'after a step to crit | A477 no reading reading=0.00V sensor fault');
    final gone = m.repeaters[0];
    expect(gone.unreachable, isTrue);
    expect(gone.keys, {'missed': '2', 'stage': 'crit'});
    expect(gone.note, 'after a step to crit');
    expect(gone.state, RepeaterState.unreachable);

    final faulty = m.repeaters[1];
    expect(faulty.noReading, isTrue);
    expect(faulty.volts, isNull, reason: 'a rejected reading is no level');
    expect(faulty.keys, {'reading': '0.00V'});
    expect(faulty.note, 'sensor fault');
  });

  test('page, dry run, other keys and plain text fields', () {
    final m = _parse('Repeater: R0977 3.45V crit 10m | +2 more: ask again | '
        'source=solar | dryrun=yes | page=1/4');
    expect(m.repeaters.single.name, 'R0977');
    expect(m.page, 1);
    expect(m.pages, 4);
    expect(m.dryRun, isTrue);
    expect(m.extraText, ['+2 more: ask again']);
    expect(m.extensions, {'source': 'solar'});
  });

  test('ages in minutes, hours and days; volts up to two digits', () {
    final m = _parse('repeater: A277 12.6V OK 3h\nA377 3.9V low 2d');
    expect(m.repeaters[0].volts, '12.6');
    expect(m.repeaters[0].stage, RepeaterStage.ok);
    expect(m.repeaters[0].age, const Duration(hours: 3));
    expect(m.repeaters[1].age, const Duration(days: 2));
  });

  test('ordinary text stays text', () {
    expect(StructuredMessage.parse('Repeater: +2 more'), isNull,
        reason: 'no field about a repeater');
    expect(StructuredMessage.parse('Repeater:'), isNull);
    expect(StructuredMessage.parse('Repeaters are up on the ridge'), isNull);
  });

  test('a mention before it is fine', () {
    expect(
      _parse('@[GWQ] Repeater: A277 3.52V crit').repeaters.single.name,
      'A277',
    );
  });

  test('summary for previews: names for one or two, else counts worst first',
      () {
    expect(
      _parse('Repeater: A277 3.48V crit | A377 unreachable missed=2').summary,
      'Repeater status: A277 critical, A377 unreachable',
    );
    expect(
      _parse('Repeater: A277 3.52V crit 2m | A377 3.41V crit 40m | '
              'AD77 waiting | A477 waiting | AA77 waiting')
          .summary,
      'Repeater status: 2 critical, 3 waiting',
    );
    expect(
      _parse('Repeater: A1 3.9V ok | A2 unreachable | A3 3.4V crit').counts,
      [
        (RepeaterState.unreachable, 1),
        (RepeaterState.crit, 1),
        (RepeaterState.ok, 1),
      ],
    );
  });

  test('the wire text is the fields as read', () {
    expect(
      _parse('Repeater: A277 3.52V crit 2m|AD77 waiting').toWire(),
      'Repeater: A277 3.52V crit 2m | AD77 waiting',
    );
  });
}
