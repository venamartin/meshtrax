import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../models/app_settings.dart';
import '../connector/meshcore_connector.dart';
import '../services/app_settings_service.dart';
import '../services/repeater_command_service.dart';
import '../widgets/path_management_dialog.dart';
import '../helpers/cayenne_lpp.dart';
import '../utils/battery_utils.dart';
import '../helpers/snack_bar_builder.dart';

class TelemetryScreen extends StatefulWidget {
  final Contact contact;

  const TelemetryScreen({super.key, required this.contact});

  @override
  State<TelemetryScreen> createState() => _TelemetryScreenState();
}

class _TelemetryScreenState extends State<TelemetryScreen> {
  bool _isLoading = false;
  bool _isLoaded = false;
  bool _hasData = false;
  RepeaterCommandService? _commandService;
  List<Map<String, dynamic>>? _parsedTelemetry;

  int _resolveContactIndex = -1;

  Contact _resolveContact(MeshCoreConnector connector) {
    if (_resolveContactIndex >= 0 &&
        _resolveContactIndex < connector.contacts.length &&
        connector.contacts[_resolveContactIndex].publicKeyHex ==
            widget.contact.publicKeyHex) {
      return connector.contacts[_resolveContactIndex];
    }
    _resolveContactIndex = connector.contacts.indexWhere(
      (c) => c.publicKeyHex == widget.contact.publicKeyHex,
    );
    if (_resolveContactIndex == -1) {
      return widget.contact;
    }
    return connector.contacts[_resolveContactIndex];
  }

  @override
  void initState() {
    super.initState();
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    _commandService = RepeaterCommandService(connector);
    _loadTelemetry();
    _hasData = false;
  }

  void _handleTelemetryResponse(Uint8List frame) {
    final parsedTelemetry = CayenneLpp.parseByChannel(frame);
    final batteryMv = _extractTelemetryBatteryMillivolts(parsedTelemetry);
    if (batteryMv != null) {
      final connector = Provider.of<MeshCoreConnector>(context, listen: false);
      connector.updateRepeaterBatterySnapshot(
        widget.contact.publicKeyHex,
        batteryMv,
        source: 'telemetry',
      );
    }
    if (!mounted) return;
    setState(() {
      _parsedTelemetry = parsedTelemetry;
    });

    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.telemetry_receivedData),
      backgroundColor: Colors.green,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isLoaded = true;
      _hasData = true;
    });
  }

  Future<void> _loadTelemetry() async {
    final service = _commandService;
    if (service == null) return;

    setState(() {
      _isLoading = true;
      _isLoaded = false;
    });
    try {
      final connector = Provider.of<MeshCoreConnector>(context, listen: false);
      // Retries, per-attempt escalation, timeout-model training and path
      // stats all live in the service. The old code armed one timer with
      // the companion's est_timeout — an OUTBOUND-only estimate that never
      // budgeted the repeater's 300 ms reply hold or the response airtime.
      final payload = await service.sendTelemetryRequest(
        _resolveContact(connector),
      );
      if (!mounted) return;
      _handleTelemetryResponse(payload);
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoaded = false;
        });
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.telemetry_requestTimeout),
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoaded = false;
        });

        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.telemetry_errorLoading(e.toString())),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  void dispose() {
    _commandService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();
    final settings = context.watch<AppSettingsService>().settings;
    final isImperialUnits = settings.unitSystem == UnitSystem.imperial;
    final isFloodMode = widget.contact.pathOverride == -1;
    final isDirectMode = widget.contact.pathOverride == 0;
    final activeMode = isFloodMode
        ? 'flood'
        : isDirectMode
        ? 'direct'
        : 'auto';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.repeater_telemetry,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.contact.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(isFloodMode ? Icons.waves : (isDirectMode ? Icons.settings_ethernet : Icons.route)),
            tooltip: l10n.repeater_routingMode,
            onSelected: (mode) async {
              if (mode == 'flood') {
                await connector.setPathOverride(widget.contact, pathLen: -1);
              } else if (mode == 'direct') {
                await connector.setPathOverride(widget.contact, pathLen: 0, pathBytes: Uint8List(0));
              } else {
                await connector.setPathOverride(widget.contact, pathLen: null);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'auto',
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_mode,
                      size: 20,
                      color: activeMode == 'auto'
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.repeater_autoUseSavedPath,
                      style: TextStyle(
                        fontWeight: activeMode == 'auto'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'direct',
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_ethernet,
                      size: 20,
                      color: activeMode == 'direct'
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.repeater_forceDirectMode,
                      style: TextStyle(
                        fontWeight: activeMode == 'direct'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'flood',
                child: Row(
                  children: [
                    Icon(
                      Icons.waves,
                      size: 20,
                      color: activeMode == 'flood'
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.repeater_forceFloodMode,
                      style: TextStyle(
                        fontWeight: activeMode == 'flood'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.timeline),
            tooltip: l10n.repeater_pathManagement,
            onPressed: () =>
                PathManagementDialog.show(context, contact: widget.contact),
          ),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadTelemetry,
            tooltip: l10n.repeater_refresh,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadTelemetry,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!_isLoaded &&
                  !_hasData &&
                  (_parsedTelemetry == null || _parsedTelemetry!.isEmpty))
                Center(
                  child: Text(
                    l10n.telemetry_noData,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              if ((_isLoaded || _hasData) &&
                  _parsedTelemetry != null &&
                  _parsedTelemetry!.isNotEmpty)
                for (final entry in _parsedTelemetry ?? [])
                  _buildChannelInfoCard(
                    entry['values'],
                    l10n.telemetry_channelTitle(entry['channel']),
                    entry['channel'],
                    isImperialUnits,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelInfoCard(
    Map<String, dynamic> channelData,
    String title,
    int channel,
    bool isImperialUnits,
  ) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).textTheme.headlineSmall?.color,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            for (final entry in channelData.entries)
              if (entry.key == 'voltage' && channel == 1)
                _buildInfoRow(
                  l10n.telemetry_batteryLabel,
                  _batteryText(entry.value),
                )
              else if (entry.key == 'voltage')
                _buildInfoRow(
                  l10n.telemetry_voltageLabel,
                  l10n.telemetry_voltageValue(entry.value.toString()),
                )
              else if (entry.key == 'temperature' && channel == 1)
                _buildInfoRow(
                  l10n.telemetry_mcuTemperatureLabel,
                  _temperatureText(entry.value, isImperialUnits),
                )
              else if (entry.key == 'temperature')
                _buildInfoRow(
                  l10n.telemetry_temperatureLabel,
                  _temperatureText(entry.value, isImperialUnits),
                )
              else if (entry.key == 'current' && channel == 1)
                _buildInfoRow(
                  l10n.telemetry_currentLabel,
                  l10n.telemetry_currentValue(entry.value.toString()),
                )
              else
                _buildInfoRow(entry.key, entry.value.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  int? _extractTelemetryBatteryMillivolts(List<Map<String, dynamic>> entries) {
    for (final entry in entries) {
      if (entry['channel'] != 1) continue;
      final values = entry['values'];
      if (values is! Map<String, dynamic>) continue;
      final voltage = values['voltage'];
      if (voltage is num) return (voltage.toDouble() * 1000).round();
    }
    return null;
  }

  String _batteryText(double? telemetryVolts) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();
    final batteryMv =
        connector.getRepeaterBatteryMillivolts(widget.contact.publicKeyHex) ??
        (telemetryVolts == null ? null : (telemetryVolts * 1000).round());
    if (batteryMv == null) return l10n.common_notAvailable;
    final chemistry = _batteryChemistry();
    final percent = estimateBatteryPercentFromMillivolts(batteryMv, chemistry);
    final volts = (batteryMv / 1000).toStringAsFixed(2);
    return l10n.telemetry_batteryValue(percent, volts);
  }

  String _batteryChemistry() {
    final settingsService = context.read<AppSettingsService>();
    return settingsService.batteryChemistryForRepeater(
      widget.contact.publicKeyHex,
    );
  }

  String _temperatureText(double? tempC, bool isImperialUnits) {
    final l10n = context.l10n;
    if (tempC == null) return l10n.common_notAvailable;
    final tempF = (tempC * 9 / 5) + 32;
    if (isImperialUnits) {
      return '${tempF.toStringAsFixed(1)}°F';
    }
    return '${tempC.toStringAsFixed(1)}°C';
  }
}
