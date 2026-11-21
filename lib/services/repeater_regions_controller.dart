import 'package:flutter/foundation.dart';

import '../helpers/region_helper.dart';
import '../models/repeater_regions.dart';

enum RepeaterRegionsStatus { loading, ready, tooOld, noAnswer }

/// Why the last change didn't go through.
enum RepeaterRegionsProblem { noAnswer, hasChildren, refused }

/// Reads and changes a logged-in repeater's regions through its `region`
/// commands. [send] runs one CLI command and returns the reply, throwing
/// when the repeater doesn't answer.
class RepeaterRegionsController extends ChangeNotifier {
  RepeaterRegionsController(this._send);

  final Future<String> Function(String command) _send;

  RepeaterRegionsStatus status = RepeaterRegionsStatus.loading;
  RepeaterRegions regions = const RepeaterRegions(
    noRegionRepeats: true,
    regions: [],
  );

  /// The region the repeater's adverts use, and its replies when it can't
  /// tell the asker's (`region default`).
  String? ownRegion;

  /// A change is on its way to the repeater.
  bool busy = false;

  /// Set when the last change failed; [refusal] holds the repeater's words.
  RepeaterRegionsProblem? problem;
  String? refusal;

  Future<void> load() async {
    // A reload after a change keeps the list on screen.
    if (status != RepeaterRegionsStatus.ready) {
      status = RepeaterRegionsStatus.loading;
      notifyListeners();
    }
    try {
      final allowed = await _send('region list allowed');
      if (RepeaterRegions.isError(allowed)) {
        status = RepeaterRegionsStatus.tooOld;
        notifyListeners();
        return;
      }
      final tree = await _send('region');
      final denied = tree.length >= RepeaterRegions.cutLength
          ? await _send('region list denied')
          : null;
      regions = RepeaterRegions.parse(
        tree: tree,
        allowed: allowed,
        denied: denied,
      );
      ownRegion = RepeaterRegions.parseDefault(await _send('region default'));
      status = RepeaterRegionsStatus.ready;
    } catch (_) {
      status = RepeaterRegionsStatus.noAnswer;
    }
    notifyListeners();
  }

  /// Repeat messages in [name], or with no region when [name] is null.
  Future<bool> setRepeats(String? name, bool on) => _change(
    ['region ${on ? 'allowf' : 'denyf'} ${name ?? '*'}'],
    reload: false,
    onDone: () {
      regions = RepeaterRegions(
        noRegionRepeats: name == null ? on : regions.noRegionRepeats,
        regions: [
          for (final r in regions.regions)
            r.name == name ? r.withRepeats(on) : r,
        ],
        mayBeIncomplete: regions.mayBeIncomplete,
      );
    },
  );

  /// Adds [names] under [parent] (null: the top). The firmware repeats a
  /// new region straight away.
  Future<bool> add(List<String> names, String? parent) => _change([
    for (final name in names)
      'region put ${RegionHelper.normalize(name)}'
          '${parent == null ? '' : ' $parent'}',
  ]);

  /// Moves [name] under [parent] (null: the top). Moving turns repeating
  /// on in the firmware, so a region that wasn't repeated is turned off
  /// again.
  Future<bool> move(String name, String? parent) {
    final wasOff = regions.regions.any((r) => r.name == name && !r.repeats);
    return _change([
      'region put $name ${parent ?? '*'}',
      if (wasOff) 'region denyf $name',
    ]);
  }

  Future<bool> remove(String name) => _change(['region remove $name']);

  /// The repeater's own region; null for none. `region default` saves
  /// itself, and turns repeating on for that region.
  Future<bool> setOwnRegion(String? name) => _change(
    ['region default ${name ?? '<null>'}'],
    save: false,
  );

  /// Regions under [name], at any depth.
  Set<String> descendantsOf(String name) {
    final out = <String>{};
    var grew = true;
    while (grew) {
      grew = false;
      for (final r in regions.regions) {
        if ((r.parent == name || out.contains(r.parent)) && out.add(r.name)) {
          grew = true;
        }
      }
    }
    return out;
  }

  bool hasChildren(String name) =>
      regions.regions.any((r) => r.parent == name);

  /// Runs [commands] in order, stopping at the first refusal, then
  /// `region save` when any of them went through, so a restart keeps them.
  Future<bool> _change(
    List<String> commands, {
    bool reload = true,
    bool save = true,
    VoidCallback? onDone,
  }) async {
    if (busy) return false;
    busy = true;
    problem = null;
    refusal = null;
    notifyListeners();
    try {
      var done = 0;
      for (final command in commands) {
        final reply = await _send(command);
        if (RepeaterRegions.isError(reply)) {
          problem = reply.contains('not empty')
              ? RepeaterRegionsProblem.hasChildren
              : RepeaterRegionsProblem.refused;
          refusal = reply.trim();
          break;
        }
        done++;
      }
      if (save && done > 0) {
        final saved = await _send('region save');
        if (problem == null && RepeaterRegions.isError(saved)) {
          problem = RepeaterRegionsProblem.refused;
          refusal = saved.trim();
        }
      }
      if (problem != null) return false;
      onDone?.call();
      return true;
    } catch (_) {

      problem = RepeaterRegionsProblem.noAnswer;
      return false;
    } finally {
      busy = false;
      if (reload && problem != RepeaterRegionsProblem.noAnswer) {
        await load();
      } else {
        notifyListeners();
      }
    }
  }
}
