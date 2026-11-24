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

  /// Adds [names]. The firmware repeats a new region straight away.
  Future<bool> add(List<String> names) => _change([
    for (final name in names) 'region put ${RegionHelper.normalize(name)}',
  ]);

  /// Removes [name]. The firmware refuses a region with others under it,
  /// and nesting changes nothing on the air, so those move to the top
  /// first. Moving turns repeating on, so one that was off is turned off
  /// again.
  Future<bool> remove(String name) => _change([
    for (final child in regions.regions)
      if (child.parent == name) ...[
        'region put ${child.name}',
        if (!child.repeats) 'region denyf ${child.name}',
      ],
    'region remove $name',
  ]);

  /// The repeater's own region; null for none. `region default` saves
  /// itself, and turns repeating on for that region.
  Future<bool> setOwnRegion(String? name) => _change(
    ['region default ${name ?? '<null>'}'],
    save: false,
  );

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
