import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../services/repeater_command_service.dart';
import '../widgets/cli_console.dart';
import '../widgets/routing_dialog.dart';

class RepeaterCliScreen extends StatefulWidget {
  final Contact repeater;
  final String password;

  const RepeaterCliScreen({
    super.key,
    required this.repeater,
    required this.password,
  });

  @override
  State<RepeaterCliScreen> createState() => _RepeaterCliScreenState();
}

class _RepeaterCliScreenState extends State<RepeaterCliScreen> {
  StreamSubscription<Uint8List>? _frameSubscription;
  RepeaterCommandService? _commandService;

  @override
  void initState() {
    super.initState();
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    _commandService = RepeaterCommandService(connector);
    _setupMessageListener();
  }

  @override
  void dispose() {
    _frameSubscription?.cancel();
    _commandService?.dispose();
    super.dispose();
  }

  void _setupMessageListener() {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);

    // Listen for incoming text messages from the repeater
    _frameSubscription = connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;

      // Check if it's a text message response
      if (frame[0] == respCodeContactMsgRecv ||
          frame[0] == respCodeContactMsgRecvV3) {
        _handleTextMessageResponse(frame);
      }
    });
  }

  int _resolveRepeaterIndex = -1;

  Contact _resolveRepeater(MeshCoreConnector connector) {
    if (_resolveRepeaterIndex >= 0 &&
        _resolveRepeaterIndex < connector.contacts.length &&
        connector.contacts[_resolveRepeaterIndex].publicKeyHex ==
            widget.repeater.publicKeyHex) {
      return connector.contacts[_resolveRepeaterIndex];
    }
    _resolveRepeaterIndex = connector.contacts.indexWhere(
      (c) => c.publicKeyHex == widget.repeater.publicKeyHex,
    );
    if (_resolveRepeaterIndex == -1) {
      return widget.repeater;
    }
    return connector.contacts[_resolveRepeaterIndex];
  }

  void _handleTextMessageResponse(Uint8List frame) {
    final parsed = parseContactMessageText(frame);
    if (parsed == null) return;
    if (!_matchesRepeaterPrefix(parsed.senderPrefix)) return;

    // Notify command service of response (for retry handling)
    _commandService?.handleResponse(widget.repeater, parsed.text);
  }

  bool _matchesRepeaterPrefix(Uint8List prefix) {
    final target = widget.repeater.publicKey;
    if (target.length < 6 || prefix.length < 6) return false;
    for (int i = 0; i < 6; i++) {
      if (prefix[i] != target[i]) return false;
    }
    return true;
  }

  Future<String> _send(String command) {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    // One attempt, deliberately. A repeater can defer its reply for
    // an unbounded time while the channel is busy, so this will
    // occasionally report a failure for a command that ran — but in
    // a CLI the operator is driving and decides when to send again.
    // Retrying behind their back would re-execute their command.
    return _commandService!.sendCommand(
      _resolveRepeater(connector),
      command,
      retries: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();
    final repeater = _resolveRepeater(connector);

    return CliConsole(
      title: l10n.repeater_cliTitle,
      subtitle: repeater.name,
      onSend: _send,
      actions: [
        IconButton(
          icon: RoutingIcon(contact: repeater),
          tooltip: l10n.routing_title,
          onPressed: () => RoutingDialog.show(context, contact: repeater),
        ),
      ],
      debugFrameFor: (command) =>
          buildSendCliCommandFrame(widget.repeater.publicKey, command),
      quickCommands: [
        CliQuickCommand(l10n.repeater_cliQuickAdvertise, 'advert'),
        CliQuickCommand(l10n.repeater_cliQuickGetName, 'get name'),
        CliQuickCommand(l10n.repeater_cliQuickGetRadio, 'get radio'),
        CliQuickCommand(l10n.repeater_cliQuickGetTx, 'get tx'),
        CliQuickCommand(l10n.repeater_cliQuickDiscovery, 'discover.neighbors'),
        CliQuickCommand(l10n.repeater_cliQuickNeighbors, 'neighbors'),
        CliQuickCommand(l10n.repeater_cliQuickVersion, 'ver'),
        CliQuickCommand(l10n.repeater_cliQuickClock, 'clock'),
        CliQuickCommand(l10n.repeater_cliQuickClockSync, 'clock sync'),
      ],
      helpNote: l10n.repeater_commandsListNote,
      helpSections: _helpSections,
    );
  }

  List<CliHelpSection> _helpSections(BuildContext context) {
    final l10n = context.l10n;
    final generalCommands = [
      CliHelpEntry(command: 'advert', description: l10n.repeater_cliHelpAdvert),
      CliHelpEntry(command: 'reboot', description: l10n.repeater_cliHelpReboot),
      CliHelpEntry(command: 'clock', description: l10n.repeater_cliHelpClock),
      CliHelpEntry(
        command: 'password {new-password}',
        description: l10n.repeater_cliHelpPassword,
      ),
      CliHelpEntry(command: 'ver', description: l10n.repeater_cliHelpVersion),
      CliHelpEntry(
        command: 'clear stats',
        description: l10n.repeater_cliHelpClearStats,
      ),
    ];

    final settingsCommands = [
      CliHelpEntry(
        command: 'set af {air-time-factor}',
        description: l10n.repeater_cliHelpSetAf,
      ),
      CliHelpEntry(
        command: 'set tx {tx-power-dbm}',
        description: l10n.repeater_cliHelpSetTx,
      ),
      CliHelpEntry(
        command: 'set repeat {on|off}',
        description: l10n.repeater_cliHelpSetRepeat,
      ),
      CliHelpEntry(
        command: 'set allow.read.only {on|off}',
        description: l10n.repeater_cliHelpSetAllowReadOnly,
      ),
      CliHelpEntry(
        command: 'set flood.max {max-hops}',
        description: l10n.repeater_cliHelpSetFloodMax,
      ),
      CliHelpEntry(
        command: 'set int.thresh {db}',
        description: l10n.repeater_cliHelpSetIntThresh,
      ),
      CliHelpEntry(
        command: 'set agc.reset.interval {seconds}',
        description: l10n.repeater_cliHelpSetAgcResetInterval,
      ),
      CliHelpEntry(
        command: 'set multi.acks {0|1}',
        description: l10n.repeater_cliHelpSetMultiAcks,
      ),
      CliHelpEntry(
        command: 'set advert.interval {minutes}',
        description: l10n.repeater_cliHelpSetAdvertInterval,
      ),
      CliHelpEntry(
        command: 'set flood.advert.interval {hours}',
        description: l10n.repeater_cliHelpSetFloodAdvertInterval,
      ),
      CliHelpEntry(
        command: 'set guest.password {guess-password}',
        description: l10n.repeater_cliHelpSetGuestPassword,
      ),
      CliHelpEntry(
        command: 'set name {name}',
        description: l10n.repeater_cliHelpSetName,
      ),
      CliHelpEntry(
        command: 'set lat {latitude}',
        description: l10n.repeater_cliHelpSetLat,
      ),
      CliHelpEntry(
        command: 'set lon {longitude}',
        description: l10n.repeater_cliHelpSetLon,
      ),
      CliHelpEntry(
        command: 'set radio {freq},{bw},{sf},{cr}',
        description: l10n.repeater_cliHelpSetRadio,
      ),
      CliHelpEntry(
        command: 'set rxdelay {base}',
        description: l10n.repeater_cliHelpSetRxDelay,
      ),
      CliHelpEntry(
        command: 'set txdelay {factor}',
        description: l10n.repeater_cliHelpSetTxDelay,
      ),
      CliHelpEntry(
        command: 'set direct.txdelay {factor}',
        description: l10n.repeater_cliHelpSetDirectTxDelay,
      ),
      CliHelpEntry(
        command: 'set bridge.enabled {on|off}',
        description: l10n.repeater_cliHelpSetBridgeEnabled,
      ),
      CliHelpEntry(
        command: 'set bridge.delay {0-10000}',
        description: l10n.repeater_cliHelpSetBridgeDelay,
      ),
      CliHelpEntry(
        command: 'set bridge.source {rx|tx}',
        description: l10n.repeater_cliHelpSetBridgeSource,
      ),
      CliHelpEntry(
        command: 'set bridge.baud {speed}',
        description: l10n.repeater_cliHelpSetBridgeBaud,
      ),
      CliHelpEntry(
        command: 'set bridge.secret {shared-secret}',
        description: l10n.repeater_cliHelpSetBridgeSecret,
      ),
      CliHelpEntry(
        command: 'set adc.multiplier {factor}',
        description: l10n.repeater_cliHelpSetAdcMultiplier,
      ),
      CliHelpEntry(
        command: 'tempradio {freq},{bw},{sf},{cr},{minutes}',
        description: l10n.repeater_cliHelpTempRadio,
      ),
      CliHelpEntry(
        command: 'setperm {pubkey-hex} {permissions}',
        description: l10n.repeater_cliHelpSetPerm,
      ),
    ];

    final bridgeCommands = [
      CliHelpEntry(
        command: 'get bridge.type',
        description: l10n.repeater_cliHelpGetBridgeType,
      ),
    ];

    final loggingCommands = [
      CliHelpEntry(
        command: 'log start',
        description: l10n.repeater_cliHelpLogStart,
      ),
      CliHelpEntry(
        command: 'log stop',
        description: l10n.repeater_cliHelpLogStop,
      ),
      CliHelpEntry(
        command: 'log erase',
        description: l10n.repeater_cliHelpLogErase,
      ),
    ];

    final neighborCommands = [
      CliHelpEntry(
        command: 'neighbors',
        description: l10n.repeater_cliHelpNeighbors,
      ),
      CliHelpEntry(
        command: 'neighbor.remove {pubkey-prefix}',
        description: l10n.repeater_cliHelpNeighborRemove,
      ),
    ];

    final regionCommands = [
      CliHelpEntry(command: 'region', description: l10n.repeater_cliHelpRegion),
      CliHelpEntry(
        command: 'region load',
        description: l10n.repeater_cliHelpRegionLoad,
      ),
      CliHelpEntry(
        command: 'region get {* | name-prefix}',
        description: l10n.repeater_cliHelpRegionGet,
      ),
      CliHelpEntry(
        command: 'region put {name} {* | parent-name-prefix}',
        description: l10n.repeater_cliHelpRegionPut,
      ),
      CliHelpEntry(
        command: 'region remove {name}',
        description: l10n.repeater_cliHelpRegionRemove,
      ),
      CliHelpEntry(
        command: 'region allowf {* | name-prefix}',
        description: l10n.repeater_cliHelpRegionAllowf,
      ),
      CliHelpEntry(
        command: 'region denyf {* | name-prefix}',
        description: l10n.repeater_cliHelpRegionDenyf,
      ),
      CliHelpEntry(
        command: 'region home',
        description: l10n.repeater_cliHelpRegionHome,
      ),
      CliHelpEntry(
        command: 'region home {* | name-prefix}',
        description: l10n.repeater_cliHelpRegionHomeSet,
      ),
      CliHelpEntry(
        command: 'region save',
        description: l10n.repeater_cliHelpRegionSave,
      ),
    ];

    final gpsCommands = [
      CliHelpEntry(command: 'gps', description: l10n.repeater_cliHelpGps),
      CliHelpEntry(
        command: 'gps {on|off}',
        description: l10n.repeater_cliHelpGpsOnOff,
      ),
      CliHelpEntry(
        command: 'gps sync',
        description: l10n.repeater_cliHelpGpsSync,
      ),
      CliHelpEntry(
        command: 'gps setloc',
        description: l10n.repeater_cliHelpGpsSetLoc,
      ),
      CliHelpEntry(
        command: 'gps advert',
        description: l10n.repeater_cliHelpGpsAdvert,
      ),
      CliHelpEntry(
        command: 'gps advert {none|share|prefs}',
        description: l10n.repeater_cliHelpGpsAdvertSet,
      ),
    ];

    return [
      CliHelpSection(l10n.repeater_general, generalCommands),
      CliHelpSection(l10n.repeater_settingsCategory, settingsCommands),
      CliHelpSection(l10n.repeater_bridge, bridgeCommands),
      CliHelpSection(l10n.repeater_logging, loggingCommands),
      CliHelpSection(l10n.repeater_neighborsRepeaterOnly, neighborCommands),
      CliHelpSection(
        l10n.repeater_regionManagementRepeaterOnly,
        regionCommands,
        note: l10n.repeater_regionNote,
      ),
      CliHelpSection(
        l10n.repeater_gpsManagement,
        gpsCommands,
        note: l10n.repeater_gpsNote,
      ),
    ];
  }
}
