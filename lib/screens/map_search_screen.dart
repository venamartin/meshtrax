import 'dart:async';

import 'package:flutter/material.dart';
import 'package:traxcoords/traxcoords.dart';
import 'package:traxpoi/traxpoi.dart';

import '../helpers/geo_format.dart';
import '../helpers/poi_kinds.dart';
import '../helpers/position_text.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';

/// What the search page returns: a place to show, or a position to go to.
class MapSearchPick {
  final String name;
  final GeoPoint point;

  /// The point of interest, for its sheet; null for addresses, search-only
  /// names and typed positions.
  final int? placeId;
  final PoiRegion? region;

  const MapSearchPick(this.name, this.point, {this.placeId, this.region});
}

/// Searches the downloaded Points of interest and Addresses, and reads
/// typed positions in seven formats. Pops with a [MapSearchPick].
class MapSearchScreen extends StatefulWidget {
  final List<PoiRegion> regions;
  final GeoPoint? near;
  final UnitSystem units;

  /// Text to search for straight away.
  final String? initialQuery;

  const MapSearchScreen({
    super.key,
    required this.regions,
    required this.near,
    required this.units,
    this.initialQuery,
  });

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  final _query = TextEditingController();
  List<CoordReading> _positions = const [];
  List<(SearchResult, PoiRegion)> _results = const [];
  Timer? _debounce;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuery;
    if (q != null) {
      _query.text = q;
      _onChanged(q);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    setState(() => _positions = parseCoordinates(text));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () => _search(text));
  }

  Future<void> _search(String text) async {
    final generation = ++_generation;
    final found = <(SearchResult, PoiRegion)>[];
    if (text.trim().isNotEmpty) {
      for (final region in widget.regions) {
        for (final r in await searchRegions(
          [region],
          text,
          near: widget.near,
        )) {
          found.add((r, region));
        }
      }
    }
    final seen = <String>{};
    found
      ..sort((a, b) => b.$1.score.compareTo(a.$1.score))
      ..retainWhere((e) => seen.add(e.$1.key));
    if (mounted && generation == _generation) {
      setState(() => _results = found.take(30).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final empty =
        _query.text.trim().isNotEmpty && _positions.isEmpty && _results.isEmpty;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.search_hint,
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
        ),
        actions: [
          if (_query.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: l10n.common_clear,
              onPressed: () {
                _query.clear();
                _onChanged('');
              },
            ),
        ],
      ),
      body: ListView(
        children: [
          if (widget.regions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.search_noPlaces,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          for (final p in _positions)
            ListTile(
              leading: const Icon(Icons.my_location),
              title: Text(
                formatCoordinates(p.position, CoordFormat.decimalDegrees)!,
              ),
              subtitle: Text(coordFormatName(l10n, p.format)),
              onTap: () => Navigator.pop(
                context,
                MapSearchPick(
                  _query.text.trim(),
                  GeoPoint(p.position.lat, p.position.lon),
                ),
              ),
            ),
          for (final (r, region) in _results)
            ListTile(
              leading: Icon(poiKindIcon(r.kind)),
              title: Text(r.name),
              subtitle: Text(
                [
                  poiKindLabel(l10n, r.kind),
                  if (r.km != null)
                    GeoFormat.distanceText(r.km! * 1000, widget.units),
                ].join(' · '),
              ),
              onTap: () => Navigator.pop(
                context,
                MapSearchPick(
                  r.name,
                  r.point,
                  placeId: r.type == ResultType.place ? r.id : null,
                  region: region,
                ),
              ),
            ),
          if (empty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.search_noResults),
            ),
        ],
      ),
    );
  }
}
