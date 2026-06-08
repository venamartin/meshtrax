import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../services/ui_view_state_service.dart';
import '../services/map_tile_cache_service.dart';
import '../screens/repeater_hub_screen.dart';
import 'repeater_login_dialog.dart';
import 'signal_ui.dart';

Contact? _getRepeaterPrefixMatchNearLocation(
  List<Contact> contacts,
  int pubkeyFirstByte, {
  LatLng? searchPoint,
  bool preferFavorites = false,
}) {
  final candidates = contacts
      .where(
        (c) =>
            c.publicKey.isNotEmpty &&
            c.publicKey.first == pubkeyFirstByte &&
            c.type == advTypeRepeater,
      )
      .toList();

  if (candidates.isEmpty) return null;

  candidates.sort((a, b) {
    if (preferFavorites) {
      final favA = a.isFavorite ? 1 : 0;
      final favB = b.isFavorite ? 1 : 0;
      final favCompare = favB.compareTo(favA);
      if (favCompare != 0) return favCompare;
    }

    final seenCompare = b.lastSeen.compareTo(a.lastSeen);
    if (seenCompare != 0) return seenCompare;

    return a.publicKeyHex.compareTo(b.publicKeyHex);
  });

  if (searchPoint == null) {
    return candidates.first;
  }

  final distance = Distance();
  Contact best = candidates.first;
  var bestDistance = double.infinity;

  for (final c in candidates) {
    if (c.hasLocation && c.latitude != null && c.longitude != null) {
      final d = distance(searchPoint, LatLng(c.latitude!, c.longitude!));
      if (d < bestDistance) {
        bestDistance = d;
        best = c;
      }
    }
  }

  return best;
}

class SNRUi {
  final IconData icon;
  final Color color;
  final String text;
  const SNRUi(this.icon, this.color, this.text);
}

List<double> getSNRfromSF(int spreadingFactor) {
  switch (spreadingFactor) {
    case 7:
      return [4.0, -2.0, -4.0, -6.0];
    case 8:
      return [4.0, -4.0, -6.0, -8.0];
    case 9:
      return [4.0, -6.0, -8.0, -10.0];
    case 10:
      return [4.0, -8.0, -10.0, -13.0];
    case 11:
      return [4.0, -10.0, -12.5, -15.0];
    case 12:
      return [4.0, -12.5, -15.0, -18.0];
    default:
      return []; // Or throw Exception('Invalid SF: $spreadingFactor');
  }
}

SNRUi snrUiFromSNR(double? snr, int? spreadingFactor) {
  if (snr == null ||
      spreadingFactor == null ||
      spreadingFactor < 7 ||
      spreadingFactor > 12) {
    return const SNRUi(Icons.signal_cellular_off, Colors.grey, '—');
  }

  final snrLevels = getSNRfromSF(spreadingFactor);

  String text = '${snr.toStringAsFixed(1)} dB';
  final tier = snr >= snrLevels[0]
      ? 0
      : snr >= snrLevels[1]
      ? 1
      : snr >= snrLevels[2]
      ? 2
      : snr >= snrLevels[3]
      ? 3
      : 4;
  final signalUi = signalUiForStrengthTier(tier);

  return SNRUi(signalUi.icon, signalUi.color, text);
}

class SNRIndicator extends StatefulWidget {
  final MeshCoreConnector connector;

  const SNRIndicator({super.key, required this.connector});

  @override
  State<SNRIndicator> createState() => _SNRIndicatorState();
}

class _SNRIndicatorState extends State<SNRIndicator> {
  bool _wasDiscovering = false;
  DateTime? _lastScanTime;
  int _updatedCountDuringScan = 0;
  Map<String, DateTime> _preScanLastUpdated = {};

  @override
  void initState() {
    super.initState();
    widget.connector.addListener(_onConnectorChanged);
    _wasDiscovering = widget.connector.isDiscovering;
  }

  @override
  void dispose() {
    widget.connector.removeListener(_onConnectorChanged);
    super.dispose();
  }

  String _getRepeaterId(DirectRepeater r) {
    return r.publicKey != null ? pubKeyToHex(r.publicKey!) : r.pubkeyFirstByte.toString();
  }

  void _onConnectorChanged() {
    final isDiscovering = widget.connector.isDiscovering;
    if (!_wasDiscovering && isDiscovering) {
      // Scan started
      _lastScanTime = null;
      _updatedCountDuringScan = 0;
      _preScanLastUpdated = {
        for (var r in widget.connector.directRepeaters)
          _getRepeaterId(r): r.lastUpdated
      };
    } else if (_wasDiscovering && !isDiscovering) {
      // Scan ended
      int updatedCount = 0;
      for (var r in widget.connector.directRepeaters) {
        final id = _getRepeaterId(r);
        final prevTime = _preScanLastUpdated[id];
        if (prevTime == null || r.lastUpdated.isAfter(prevTime)) {
          updatedCount++;
        }
      }
      _updatedCountDuringScan = updatedCount;
      _lastScanTime = DateTime.now();
    }
    _wasDiscovering = isDiscovering;
  }

  bool _isValidSelfLocation(double lat, double lon) {
    const double epsilon = 1e-6;
    return (lat.abs() > epsilon || lon.abs() > epsilon) &&
        lat >= -90.0 &&
        lat <= 90.0 &&
        lon >= -180.0 &&
        lon <= 180.0;
  }

  @override
  Widget build(BuildContext context) {
    final directRepeaters = widget.connector.directRepeaters;
    final directBestRepeaters = List.of(directRepeaters)
      ..sort(DirectRepeater.compare);
    final directRepeater = directBestRepeaters.isEmpty
        ? null
        : directBestRepeaters.first;

    final snrUi = snrUiFromSNR(
      directBestRepeaters.isNotEmpty ? directRepeater!.snr : null,
      widget.connector.currentSf,
    );

    final selfLat = widget.connector.selfLatitude;
    final selfLon = widget.connector.selfLongitude;
    final hasValidLocation = selfLat != null && selfLon != null && _isValidSelfLocation(selfLat, selfLon);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),

      child: InkWell(
        onTap: () => _showFullPathDialog(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.connector.isDiscovering
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(snrUi.icon, size: 18, color: snrUi.color),
                  const SizedBox(width: 4),
                  Icon(
                    hasValidLocation ? Icons.location_on : Icons.location_off,
                    size: 14,
                    color: hasValidLocation ? Colors.green : Colors.red,
                  ),
                ],
              ),
              Text(
                widget.connector.isDiscovering ? 'Wait' : snrUi.text,
                style: TextStyle(fontSize: 12, color: snrUi.color),
              ),
              if (directRepeater != null)
                Text(
                  '${directRepeaters.length}: ${directRepeater.pubkeyFirstByte.toRadixString(16).padLeft(2, '0')}: ${_formatLastUpdated(directRepeater.lastUpdated)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLastUpdated(DateTime lastSeen) {
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    if (diff.isNegative) {
      return "0s";
    }
    if (diff.inMinutes < 1) {
      return "${diff.inSeconds}s";
    }
    if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m";
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return "${hours}h";
    }
    final days = diff.inDays;
    return "${days}d";
  }

  void _showRepeaterMap(BuildContext context, Contact contact, String? name) {
    final lat = contact.latitude!;
    final lon = contact.longitude!;
    final label = name ?? 'Repeater';
    final tileCache = context.read<MapTileCacheService>();
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(label),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
            SizedBox(
              height: 400,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lon),
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: kMapTileUrlTemplate,
                    tileProvider: tileCache.tileProvider,
                    userAgentPackageName:
                        MapTileCacheService.userAgentPackageName,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lon),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 34,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullPathDialog(BuildContext context) {
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.snrIndicator_nearByRepeaters),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<void>(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (context, _) {
              return ListenableBuilder(
                listenable: widget.connector,
                builder: (context, _) {
              final liveRepeaters = List.of(widget.connector.directRepeaters)
                ..sort(DirectRepeater.compare);

              if (liveRepeaters.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    widget.connector.isDiscovering
                        ? 'Searching for repeaters...'
                        : 'No repeaters found. Tap the radar icon to discover.',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final timeSinceScanEnd = _lastScanTime != null ? DateTime.now().difference(_lastScanTime!) : null;
              final showSummary = !widget.connector.isDiscovering && timeSinceScanEnd != null && timeSinceScanEnd.inSeconds < 10;

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: Scrollbar(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: liveRepeaters.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final repeater = liveRepeaters[index];
                    final snrUi = snrUiFromSNR(
                      repeater.snr,
                      widget.connector.currentSf,
                    );
                    final allContacts = widget.connector.allContacts;

                    Contact? contact;

                    final selfLat = widget.connector.selfLatitude;
                    final selfLon = widget.connector.selfLongitude;

                    LatLng? selfPoint;
                    if (selfLat != null &&
                        selfLon != null &&
                        _isValidSelfLocation(selfLat, selfLon)) {
                      selfPoint = LatLng(selfLat, selfLon);
                    }

                    // First try repeater/room type match
                    if (repeater.publicKey != null) {
                      final hex = pubKeyToHex(repeater.publicKey!);
                      final idx = allContacts.indexWhere((c) => c.publicKeyHex == hex);
                      if (idx >= 0) contact = allContacts[idx];
                    }

                    if (contact == null) {
                      contact = _getRepeaterPrefixMatchNearLocation(
                        allContacts,
                        repeater.pubkeyFirstByte,
                        searchPoint: selfPoint,
                        preferFavorites: true,
                      );
                    }

                    // If not found, try any contact with matching prefix for display name only
                    if (contact == null) {
                      final candidates = allContacts
                          .where(
                            (c) =>
                                c.publicKey.isNotEmpty &&
                                c.publicKey.first == repeater.pubkeyFirstByte,
                          )
                          .toList();

                      if (candidates.isNotEmpty) {
                        candidates.sort((a, b) {
                          final seenCompare = b.lastSeen.compareTo(a.lastSeen);
                          if (seenCompare != 0) return seenCompare;
                          return a.publicKeyHex.compareTo(b.publicKeyHex);
                        });
                        contact = candidates.first;
                      }
                    }

                    final name = contact?.name ?? repeater.name;
                    final displayName = (name != null && name.isNotEmpty)
                        ? name
                        : repeater.pubkeyFirstByte
                              .toRadixString(16)
                              .padLeft(2, '0')
                              .toUpperCase();

                    final hasLocation = contact?.hasLocation ?? false;
                    final fullPubKey = contact?.publicKey ?? repeater.publicKey;
                    final pubKeyHex = fullPubKey != null ? pubKeyToHex(fullPubKey) : null;
                    final durationSinceUpdate = DateTime.now().difference(repeater.lastUpdated);
                    final isRecent = durationSinceUpdate.inSeconds < 12;
                    final tileColor = isRecent ? Colors.green.withOpacity(0.15) : null;

                    return ListTile(
                      tileColor: tileColor,
                      leading: Icon(snrUi.icon, color: snrUi.color),
                      title: Text(displayName),
                      subtitle: Text(
                        'SNR: ${repeater.snr.toStringAsFixed(1)} dB\n'
                        '${pubKeyHex != null ? '<${pubKeyHex.substring(0, 6)}...${pubKeyHex.substring(pubKeyHex.length - 4)}>\n' : 'Full identity required to log in\n'}'
                        '${l10n.snrIndicator_lastSeen}: ${_formatLastUpdated(repeater.lastUpdated)}',
                      ),
                      trailing: hasLocation
                          ? const Icon(Icons.location_on)
                          : null,
                      onTap: fullPubKey != null
                          ? () async {
                              Contact? loginContact = contact;
                              if (loginContact != null) {
                                await widget.connector.setPathOverride(loginContact, pathLen: 0);
                                final idx = widget.connector.contacts.indexWhere((c) => c.publicKeyHex == loginContact!.publicKeyHex);
                                if (idx >= 0) loginContact = widget.connector.contacts[idx];
                              } else {
                                loginContact = Contact(
                                  publicKey: fullPubKey,
                                  name: displayName,
                                  type: advTypeRepeater,
                                  pathLength: -1,
                                  path: Uint8List(0),
                                  lastSeen: DateTime.now(),
                                  pathOverride: 0,
                                );
                              }
                              if (!context.mounted) return;

                              showDialog(
                                context: context,
                                builder: (ctx) => RepeaterLoginDialog(
                                  repeater: loginContact!,
                                  onLogin: (password, isAdmin) {
                                    Navigator.pop(context); // Close the SNR indicator dialog
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RepeaterHubScreen(
                                          repeater: loginContact!,
                                          password: password,
                                          isAdmin: isAdmin,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }
                          : null,
                    );
                  },
                        ),
                      ),
                    ),
                  if (showSummary)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                      child: Text(
                        'Scan complete: $_updatedCountDuringScan repeater${_updatedCountDuringScan == 1 ? '' : 's'} updated',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
            },
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: widget.connector,
            builder: (context, _) {
              return ElevatedButton.icon(
                onPressed: widget.connector.isDiscovering
                    ? null
                    : () => widget.connector.sendRepeaterDiscovery(),
                icon: widget.connector.isDiscovering
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.radar),
                label: Text(
                  widget.connector.isDiscovering ? 'Scanning...' : 'Discover',
                ),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }
}
