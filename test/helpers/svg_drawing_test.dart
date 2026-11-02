import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/svg_drawing.dart';
import 'package:meshtrax/helpers/svg_paste.dart';

void main() {
  SvgDrawing? read(String text) => SvgDrawing.tryParse(text);

  group('reading a drawing', () {
    test('path data draws, as lines', () {
      final d = read('M10 10h80v80H10z')!;
      expect(d.pathData, 'M10 10h80v80H10z');
      expect(d.caption, '');
      final lines = d.polylines()!;
      expect(lines, hasLength(1));
      expect(lines.single.first, (x: 10.0, y: 10.0));
      expect(lines.single.last, (x: 10.0, y: 10.0));
      expect(lines.single, hasLength(5));
    });

    test('arcs and curves become lines', () {
      final circle = read('M90 50a40 40 0 1 1 0-.1z')!.polylines()!;
      expect(circle.single.length, greaterThan(20));
      for (final p in circle.single) {
        final r = sqrt((p.x - 50) * (p.x - 50) + (p.y - 50) * (p.y - 50));
        expect(r, closeTo(40, 0.6));
      }
      expect(read('M0 0q50 100 100 0c10 10 20 20 30 0')!.polylines(), isNotNull);
    });

    test('a tap is a dot', () {
      final lines = read('M5 5h0')!.polylines()!;
      expect(lines.single, [(x: 5.0, y: 5.0), (x: 5.0, y: 5.0)]);
    });

    test('a caption line goes under the picture', () {
      final d = read('M10 10 90 90\nCamp is here')!;
      expect(d.pathData, 'M10 10 90 90');
      expect(d.caption, 'Camp is here');
    });

    test('captions that look a little like path data stay captions', () {
      for (final caption in ['Mesh', 'Ace 10', 'Lake at 5', 'Meet 2 me', 'Zone 3']) {
        final d = read('M10 10 90 90\n$caption')!;
        expect(d.caption, caption, reason: caption);
        expect(d.pathData, 'M10 10 90 90', reason: caption);
      }
    });

    test('wrapped path data reads as one drawing', () {
      final d = read('M10 10 90 90\n10 90z')!;
      expect(d.pathData, 'M10 10 90 90 10 90z');
      expect(d.caption, '');
      final more = read('M10 10h80\nv80H10z\nOur camp')!;
      expect(more.pathData, 'M10 10h80 v80H10z');
      expect(more.caption, 'Our camp');
    });

    test('anything that is not path data stays ordinary text', () {
      for (final text in [
        '',
        '<svg><path d="M0 0 9 9"/></svg>',
        '<circle cx="5" cy="5" r="4"/>',
        'hello',
        'M',
        'M10 10',
        'M10 10 m5 5',
        'L10 10',
        'M1e400 0 1 1',
        'M0 0 2000000 0',
        'M10 10 90 90 &amp;',
        'M10 10 90 90 x',
        'M0 0 ${'1 1 ' * 100}',
      ]) {
        expect(read(text), isNull, reason: text);
      }
    });

    test('an arc storm stays under the segment cap or is refused', () {
      final storm = 'M0 0${' a1000 1000 0 1 1 1 0' * 12}';
      expect(utf8.encode(storm).length, lessThan(SvgLimits.pathBytes));
      final d = read(storm);
      if (d != null) {
        final count = d.polylines()!.fold<int>(0, (n, l) => n + l.length);
        expect(count, lessThanOrEqualTo(SvgLimits.segments + 1));
      }
    });

    test('token soup never throws', () {
      final random = Random(5);
      const pieces = [
        'M', 'm', 'L', 'l', 'H', 'h', 'V', 'v', 'C', 'c', 'S', 's', 'Q', 'q',
        'T', 't', 'A', 'a', 'Z', 'z', '0', '1', '-', '.', ',', ' ', 'e', '9',
        '1e9', '1e400', '\n', 'x', '<', '"', '😀', 'NaN',
      ];
      for (var round = 0; round < 20000; round++) {
        final text = [
          for (var i = random.nextInt(40); i > 0; i--)
            pieces[random.nextInt(pieces.length)],
        ].join();
        final d = read(text);
        if (d == null) continue;
        final lines = d.polylines()!;
        for (final line in lines) {
          for (final p in line) {
            expect(p.x.isFinite && p.y.isFinite, isTrue, reason: text);
          }
        }
      }
    });
  });

  group('writing a drawing', () {
    String encode(List<SvgSubpath> list) => SvgWriter.encode(list);
    SvgPoint p(double x, double y) => (x: x, y: y);

    test('shapes come out at the sizes in the spec', () {
      expect(
        encode([SvgSubpath(p(10, 10), [SvgSegment.line(p(90, 90))])]).length,
        12,
      );
      expect(
        encode([
          SvgSubpath(p(10, 10), [
            SvgSegment.line(p(90, 10)),
            SvgSegment.line(p(90, 90)),
            SvgSegment.line(p(10, 90)),
          ], close: true),
        ]),
        'M10 10h80v80H10z',
      );
      expect(
        encode([
          SvgSubpath(p(10, 50), [SvgSegment.line(p(80, 50))]),
          SvgSubpath(p(72, 44), [
            SvgSegment.line(p(80, 50)),
            SvgSegment.line(p(72, 56)),
          ]),
        ]),
        'M10 50h70m-8-6 8 6-8 6',
      );
      expect(
        encode([
          SvgSubpath(p(90, 50), [SvgSegment.arc(p(90, 49.9), 40, 40)],
              close: true),
        ]),
        'M90 50a40 40 0 1 1 0-.1z',
      );
      expect(
        encode([SvgSubpath(p(5, 5), [SvgSegment.line(p(5, 5))])]),
        'M5 5h0',
      );
    });

    test('after a circle the position is back on whole numbers', () {
      final d = encode([
        SvgSubpath(p(90, 50), [SvgSegment.arc(p(90, 49.9), 40, 40)],
            close: true),
        SvgSubpath(p(10, 10), [SvgSegment.line(p(20, 30))]),
      ]);
      expect(d, 'M90 50a40 40 0 1 1 0-.1zM10 10l10 20');
      expect(read(d), isNotNull);
    });

    test('a circle on its own stays on the grid', () {
      // Its center and radius are both 49.5 there, and each rounds up.
      final fit = SvgWriter.fit([SvgEllipse(p(200, 150), 60, 60)], budget: 148);
      expect(fit.wire, 'SVG:M99 50a50 50 0 1 1 0-.1z');
    });

    List<SvgItem> randomItems(Random random) {
      SvgPoint any() => (x: random.nextDouble() * 400, y: random.nextDouble() * 300);
      return [
        for (var i = random.nextInt(5) + 1; i > 0; i--)
          switch (random.nextInt(10)) {
            < 6 => () {
                var x = random.nextDouble() * 400, y = random.nextDouble() * 300;
                return SvgStroke([
                  for (var j = random.nextInt(200) + 1; j > 0; j--)
                    (x: x += (random.nextDouble() - 0.5) * 12,
                     y: y += (random.nextDouble() - 0.5) * 12),
                ]);
              }(),
            6 => SvgLineItem(any(), any()),
            7 => SvgRect(any(), any()),
            8 => SvgEllipse(any(), random.nextDouble() * 80, random.nextDouble() * 80),
            _ => SvgArrow(any(), any()),
          },
      ];
    }

    test('a fit never goes over its budget, and reads back', () {
      final random = Random(11);
      var fitted = 0;
      for (var round = 0; round < 300; round++) {
        final items = randomItems(random);
        for (final budget in [127, 148, 150, 158]) {
          final caption = random.nextBool() ? 'Camp here' : '';
          final fit = SvgWriter.fit(items, budget: budget, caption: caption);
          final back = SvgDrawing.tryParse(fit.wire.substring(4));
          expect(back, isNotNull, reason: fit.wire);
          expect(back!.caption, caption);
          if (fit.fits) {
            fitted++;
            expect(fit.bytes, lessThanOrEqualTo(budget), reason: fit.wire);
            expect(utf8.encode(fit.wire).length, fit.bytes);
          }
        }
      }
      expect(fitted, greaterThan(1100));
    });

    test('encoding then reading gives the same points', () {
      final stroke = SvgStroke([
        for (var i = 0; i <= 20; i++) (x: i * 5.0, y: (i % 3) * 10.0),
      ]);
      final fit = SvgWriter.fit([stroke], budget: 160);
      expect(fit.tolerance, 0);
      final back = SvgDrawing.tryParse(fit.pathData)!.polylines()!.single;
      final sent = [
        for (final p in stroke.points)
          (x: ((p.x - fit.origin.x) * fit.scale).roundToDouble(),
           y: ((p.y - fit.origin.y) * fit.scale).roundToDouble()),
      ];
      expect(back, sent);
    });

    test('too much drawing says so', () {
      final random = Random(3);
      final scribbles = [
        for (var s = 0; s < 60; s++)
          SvgStroke([
            for (var i = 0; i < 3; i++)
              (x: random.nextDouble() * 400, y: random.nextDouble() * 300),
          ]),
      ];
      expect(SvgWriter.fit(scribbles, budget: 148).fits, isFalse);
    });

    test('a caption takes room from the drawing', () {
      final random = Random(9);
      var x = 0.0, y = 0.0;
      final stroke = SvgStroke([
        for (var i = 0; i < 300; i++)
          (x: x += random.nextDouble() * 4, y: y += (random.nextDouble() - 0.5) * 9),
      ]);
      final plain = SvgWriter.fit([stroke], budget: 148);
      final captioned = SvgWriter.fit(
        [stroke],
        budget: 148,
        caption: 'A long caption about the trail',
      );
      expect(captioned.points, lessThan(plain.points));
      expect(captioned.bytes, lessThanOrEqualTo(148));
    });
  });

  group('pasting your own SVG', () {
    (double, double) span(List<List<SvgPoint>> strokes) {
      var minX = double.infinity, maxX = double.negativeInfinity;
      for (final s in strokes) {
        for (final p in s) {
          minX = min(minX, p.x);
          maxX = max(maxX, p.x);
        }
      }
      return (minX, maxX);
    }

    test('a filled icon leaves its invisible square behind', () {
      final strokes = SvgPaste.strokes(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
        '<path d="M0 0h24v24H0z" fill="none"/>'
        '<path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2z"/></svg>',
      );
      final (lo, hi) = span(strokes);
      expect(lo, closeTo(2, 0.01));
      expect(hi, closeTo(22, 0.01));
    });

    test('a stroked icon, a transformed file, comments and titles read', () {
      expect(
        SvgPaste.strokes(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
          'stroke="currentColor"><circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/></svg>',
        ),
        hasLength(2),
      );
      final moved = SvgPaste.strokes(
        '<?xml version="1.0"?><svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">'
        '<g transform="translate(100 0) scale(2)"><path style="fill:none;stroke:#000" '
        'd="M0 0 10 10"/></g></svg>',
      );
      expect(span(moved), (100.0, 120.0));
      expect(
        SvgPaste.strokes(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><!--! Font Awesome -->'
          '<path d="M256 0a256 256 0 1 1 0 512A256 256 0 1 1 256 0z"/></svg>',
        ),
        isNotEmpty,
      );
      expect(
        SvgPaste.strokes(
          '<svg role="img" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
          '<title>Thing</title><path d="M0 0h24v24H0z"/></svg>',
        ),
        isNotEmpty,
      );
    });

    test('path data and a file without a size both read', () {
      expect(span(SvgPaste.strokes('M10 10h80v80H10z')), (10.0, 90.0));
      expect(
        span(SvgPaste.strokes(
          '<svg xmlns="http://www.w3.org/2000/svg"><path d="M10 10h80v80H10z"/></svg>',
        )),
        (10.0, 90.0),
      );
    });

    test('what it can not use says why', () {
      SvgPasteProblem problem(String text) {
        try {
          SvgPaste.strokes(text);
        } on SvgPasteError catch (e) {
          return e.problem;
        }
        fail('read: $text');
      }

      expect(problem(''), SvgPasteProblem.empty);
      expect(problem('<svg>${' ' * 30000}</svg>'), SvgPasteProblem.tooBig);
      expect(problem('<svg><unclosed'), SvgPasteProblem.unreadable);
      expect(
        problem('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 9 9">'
            '<path d="M0 0 1 1" fill="none"/></svg>'),
        SvgPasteProblem.nothing,
      );
    });
  });
}
