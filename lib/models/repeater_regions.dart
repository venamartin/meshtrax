import '../helpers/region_helper.dart';

/// One region on a repeater, as its `region` command lists it.
class RepeaterRegion {
  final String name;

  /// 0 at the top; the firmware indents a child one space more.
  final int depth;

  /// Null at the top, or when the list was cut and the parent is unknown.
  final String? parent;

  /// The repeater passes on messages in this region (`F` in the listing).
  final bool repeats;

  const RepeaterRegion({
    required this.name,
    required this.depth,
    required this.parent,
    required this.repeats,
  });

  RepeaterRegion withRepeats(bool on) =>
      RepeaterRegion(name: name, depth: depth, parent: parent, repeats: on);
}

/// What a repeater says about its regions, read from its replies to
/// `region`, `region list allowed|denied` and `region default`
/// (MeshCore src/helpers/CommonCLI.cpp handleRegionCmd, RegionMap.cpp).
class RepeaterRegions {
  /// A CLI reply is cut at 160 bytes (159 characters); one this long may
  /// be missing its end.
  static const int cutLength = 150;

  /// Messages with no region (the firmware's `*`) are passed on.
  final bool noRegionRepeats;
  final List<RepeaterRegion> regions;

  /// The listing was cut and the name lists were too, so some regions may
  /// be missing.
  final bool mayBeIncomplete;

  const RepeaterRegions({
    required this.noRegionRepeats,
    required this.regions,
    this.mayBeIncomplete = false,
  });

  /// Builds the picture from the replies. [allowed] is required (it also
  /// tells a repeater too old for this screen: `Err - ??`); [denied] is
  /// read only when [tree] was cut.
  factory RepeaterRegions.parse({
    required String tree,
    required String allowed,
    String? denied,
  }) {
    final treeCut = tree.length >= cutLength;
    final lines = tree.split('\n').where((l) => l.trim().isNotEmpty).toList();
    // A cut listing can end mid-line.
    if (treeCut && lines.isNotEmpty) lines.removeLast();

    var noRegionRepeats = false;
    final regions = <RepeaterRegion>[];
    final parents = <String>[];
    for (final line in lines) {
      final depth = line.length - line.trimLeft().length;
      final parts = line.trim().split(' ');
      final name = RegionHelper.normalize(parts.first.replaceAll('^', ''));
      final repeats = parts.length > 1 && parts[1] == 'F';
      if (name == '*') {
        noRegionRepeats = repeats;
        continue;
      }
      // The '*' line is depth 0 and its children depth 1.
      if (depth < 1) continue;
      final level = depth - 1 > parents.length ? parents.length : depth - 1;
      parents.length = level;
      regions.add(RepeaterRegion(
        name: name,
        depth: level,
        parent: level == 0 ? null : parents.last,
        repeats: repeats,
      ));
      parents.add(name);
    }

    final allowedNames = parseNameList(allowed);
    if (!treeCut) {
      return RepeaterRegions(
        noRegionRepeats: noRegionRepeats,
        regions: regions,
      );
    }

    // The tree was cut: the name lists fill in what it lost.
    final deniedNames = denied == null ? <String>[] : parseNameList(denied);
    final known = {for (final r in regions) r.name};
    for (final name in [...allowedNames, ...deniedNames]) {
      if (name == '*' || !known.add(name)) continue;
      regions.add(RepeaterRegion(
        name: name,
        depth: 0,
        parent: null,
        repeats: allowedNames.contains(name),
      ));
    }
    return RepeaterRegions(
      noRegionRepeats: allowedNames.contains('*'),
      regions: regions,
      mayBeIncomplete: allowed.length >= cutLength ||
          (denied?.length ?? 0) >= cutLength,
    );
  }

  /// `region list allowed|denied`: names separated by commas, or `-none-`.
  static List<String> parseNameList(String reply) {
    final text = reply.trim();
    if (text.isEmpty || text == '-none-') return const [];
    return text
        .split(',')
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .map((n) => n == '*' ? n : RegionHelper.normalize(n))
        .toList();
  }

  /// `region default`: ` default scope is sf`, or `<null>` for none.
  static String? parseDefault(String reply) {
    final at = reply.lastIndexOf(' is ');
    if (at < 0) return null;
    final name = reply.substring(at + 4).trim();
    if (name.isEmpty || name == '<null>') return null;
    return RegionHelper.normalize(name);
  }

  /// A refusal: `Err - …` (also an unknown `region` sub-command, `Err - ??`),
  /// or older firmware's `Unknown command` and `??`.
  static bool isError(String reply) {
    final text = reply.trimLeft();
    return text.startsWith('Err') ||
        text.startsWith('??') ||
        text.startsWith('Unknown command');
  }
}
