import 'dart:async';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
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
    final room = repeater.type == advTypeRoom;

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
      quickCommands: repeaterCliQuickCommands(l10n, room: room),
      helpNote: l10n.repeater_cliHelpIntro,
      helpSections: (context) =>
          repeaterCliHelpSections(context.l10n, room: room),
    );
  }
}

/// The quick commands over a repeater's console, or a room server's.
List<CliQuickCommand> repeaterCliQuickCommands(
  AppLocalizations l10n, {
  required bool room,
}) => [
  if (!room) ...[
    CliQuickCommand(l10n.repeater_cliQuickRepeatOn, 'set repeat on'),
    CliQuickCommand(l10n.repeater_cliQuickRepeatOff, 'set repeat off'),
  ],
  CliQuickCommand(l10n.repeater_cliQuickAdvertise, 'advert'),
  CliQuickCommand(l10n.repeater_cliQuickGetName, 'get name'),
  CliQuickCommand(l10n.repeater_cliQuickGetRadio, 'get radio'),
  CliQuickCommand(l10n.repeater_cliQuickGetTx, 'get tx'),
  // A room answers these with "Unknown command" and "not supported".
  if (!room) ...[
    CliQuickCommand(l10n.repeater_cliQuickDiscovery, 'discover.neighbors'),
    CliQuickCommand(l10n.repeater_cliQuickNeighbors, 'neighbors'),
  ],
  CliQuickCommand(l10n.repeater_cliQuickVersion, 'ver'),
  CliQuickCommand(l10n.repeater_cliQuickClock, 'clock'),
  CliQuickCommand(l10n.repeater_cliQuickClockSync, 'clock sync'),
];

/// What a repeater, or a room server, takes over the mesh in firmware 1.18:
/// MeshCore's CommonCLI and CommonRadioPrefs, and each role's own commands
/// in its MyMesh. Commands the firmware takes only over USB are left out.
List<CliHelpSection> repeaterCliHelpSections(
  AppLocalizations l10n, {
  required bool room,
}) {
  CliHelpEntry command(String text, String description) =>
      CliHelpEntry(command: text, description: description);
  // A setting's set command, with the get that reads it back.
  CliHelpEntry setting(String name, String value, String description) =>
      CliHelpEntry(
        command: 'set $name $value',
        description: description,
        getCommand: 'get $name',
      );

  return [
    CliHelpSection(l10n.repeater_general, [
      command('advert', l10n.repeater_cliHelpAdvert),
      command('advert.zerohop', l10n.repeater_cliHelpAdvertZeroHop),
      command('clock', l10n.repeater_cliHelpClock),
      command('clock sync', l10n.repeater_cliHelpClockSync),
      command('time {epoch-seconds}', l10n.repeater_cliHelpTime),
      command('ver', l10n.repeater_cliHelpVersion),
      command('board', l10n.repeater_cliHelpBoard),
      command('get role', l10n.repeater_cliHelpGetRole),
      command('get public.key', l10n.repeater_cliHelpGetPublicKey),
      command('reboot', l10n.repeater_cliHelpReboot),
      command('clkreboot', l10n.repeater_cliHelpClkReboot),
      command('poweroff', l10n.repeater_cliHelpPowerOff),
      command('start ota', l10n.repeater_cliHelpStartOta),
      command('clear stats', l10n.repeater_cliHelpClearStats),
      command('password {new-password}', l10n.repeater_cliHelpPassword),
    ]),
    if (room)
      CliHelpSection(l10n.repeater_cliSectionRoom, [
        command('room.post {message}', l10n.repeater_cliHelpRoomPost),
      ]),
    CliHelpSection(l10n.repeater_cliSectionRadio, [
      setting(
        'radio',
        '{freq},{bw},{sf},{cr}',
        l10n.repeater_cliHelpSetRadio,
      ),
      command(
        'tempradio {freq},{bw},{sf},{cr},{minutes}',
        l10n.repeater_cliHelpTempRadio,
      ),
      command('get freq', l10n.repeater_cliHelpGetFreq),
      setting('tx', '{tx-power-dbm}', l10n.repeater_cliHelpSetTxPower),
      setting('af', '{air-time-factor}', l10n.repeater_cliHelpSetAf),
      setting('dutycycle', '{1-100}', l10n.repeater_cliHelpSetDutyCycle),
      setting('cad', '{on|off}', l10n.repeater_cliHelpSetCad),
      setting('radio.rxgain', '{on|off}', l10n.repeater_cliHelpSetRxGain),
      setting('int.thresh', '{db}', l10n.repeater_cliHelpSetIntThresh),
      setting(
        'agc.reset.interval',
        '{seconds}',
        l10n.repeater_cliHelpSetAgcResetInterval,
      ),
      setting('rxdelay', '{base}', l10n.repeater_cliHelpSetRxDelay),
      setting('txdelay', '{factor}', l10n.repeater_cliHelpSetTxDelay),
      setting(
        'direct.txdelay',
        '{factor}',
        l10n.repeater_cliHelpSetDirectTxDelay,
      ),
      setting('extra.sf', '{sf},{sf},{sf}', l10n.repeater_cliHelpSetExtraSf),
    ]),
    CliHelpSection(l10n.repeater_settingsCategory, [
      setting('name', '{name}', l10n.repeater_cliHelpSetName),
      setting('lat', '{latitude}', l10n.repeater_cliHelpSetLat),
      setting('lon', '{longitude}', l10n.repeater_cliHelpSetLon),
      setting('owner.info', '{text}', l10n.repeater_cliHelpSetOwnerInfo),
      setting(
        'advert.interval',
        '{minutes}',
        l10n.repeater_cliHelpSetAdvertInterval,
      ),
      setting(
        'flood.advert.interval',
        '{hours}',
        l10n.repeater_cliHelpSetFloodAdvertInterval,
      ),
      if (!room) ...[
        setting('repeat', '{on|off}', l10n.repeater_cliHelpSetRepeat),
        setting('flood.max', '{max-hops}', l10n.repeater_cliHelpSetFloodMax),
        setting(
          'flood.max.unscoped',
          '{max-hops}',
          l10n.repeater_cliHelpSetFloodMaxUnscoped,
        ),
        setting(
          'flood.max.advert',
          '{max-hops}',
          l10n.repeater_cliHelpSetFloodMaxAdvert,
        ),
        setting(
          'loop.detect',
          '{off|minimal|moderate|strict}',
          l10n.repeater_cliHelpSetLoopDetect,
        ),
      ],
      setting('path.hash.mode', '{0|1|2}', l10n.repeater_cliHelpSetPathHashMode),
      setting('multi.acks', '{0|1}', l10n.repeater_cliHelpSetMultiAcks),
      setting(
        'guest.password',
        '{guest-password}',
        l10n.repeater_cliHelpSetGuestPassword,
      ),
      if (room)
        setting(
          'allow.read.only',
          '{on|off}',
          l10n.repeater_cliHelpSetAllowReadOnly,
        ),
      command(
        'setperm {pubkey-hex} {permissions}',
        l10n.repeater_cliHelpSetPerm,
      ),
      command('set prv.key {private-key-hex}', l10n.repeater_cliHelpSetPrvKey),
    ]),
    CliHelpSection(l10n.repeater_cliSectionPower, [
      command('power', l10n.repeater_cliHelpPower),
      command('powersaving', l10n.repeater_cliHelpPowerSaving),
      command('powersaving {on|off}', l10n.repeater_cliHelpPowerSavingSet),
      setting(
        'adc.multiplier',
        '{factor}',
        l10n.repeater_cliHelpSetAdcMultiplier,
      ),
      command('get pwrmgt.support', l10n.repeater_cliHelpGetPwrmgtSupport),
      command('get pwrmgt.source', l10n.repeater_cliHelpGetPwrmgtSource),
      command(
        'get pwrmgt.bootreason',
        l10n.repeater_cliHelpGetPwrmgtBootReason,
      ),
      command('get pwrmgt.bootmv', l10n.repeater_cliHelpGetPwrmgtBootMv),
      command('get bootloader.ver', l10n.repeater_cliHelpGetBootloaderVer),
    ]),
    if (!room)
      CliHelpSection(l10n.repeater_neighborsRepeaterOnly, [
        command('neighbors', l10n.repeater_cliHelpNeighbors),
        command('discover.neighbors', l10n.repeater_cliHelpDiscoverNeighbors),
        command(
          'neighbor.remove {pubkey-prefix}',
          l10n.repeater_cliHelpNeighborRemove,
        ),
      ]),
    CliHelpSection(l10n.repeater_cliSectionRegions, [
      command('region', l10n.repeater_cliHelpRegions),
      command('region def {name} {name|parent} ...', l10n.repeater_cliHelpRegionDef),
      command('region load', l10n.repeater_cliHelpRegionLoad),
      command('region get {* | name-prefix}', l10n.repeater_cliHelpRegionGet),
      command(
        'region put {name} {* | parent-name-prefix}',
        l10n.repeater_cliHelpRegionPut,
      ),
      command('region remove {name}', l10n.repeater_cliHelpRegionRemove),
      command(
        'region allowf {* | name-prefix}',
        l10n.repeater_cliHelpRegionAllowf,
      ),
      command(
        'region denyf {* | name-prefix}',
        l10n.repeater_cliHelpRegionDenyf,
      ),
      command('region list {allowed|denied}', l10n.repeater_cliHelpRegionList),
      command('region home', l10n.repeater_cliHelpRegionHome),
      command(
        'region home {* | name-prefix}',
        l10n.repeater_cliHelpRegionHomeSet,
      ),
      command('region default', l10n.repeater_cliHelpRegionDefault),
      command(
        'region default {name | <null>}',
        l10n.repeater_cliHelpRegionDefaultSet,
      ),
      command('region save', l10n.repeater_cliHelpRegionSave),
    ], note: l10n.repeater_regionNote),
    CliHelpSection(l10n.repeater_gpsManagement, [
      command('gps', l10n.repeater_cliHelpGps),
      command('gps {on|off}', l10n.repeater_cliHelpGpsOnOff),
      command('gps sync', l10n.repeater_cliHelpGpsSync),
      command('gps setloc', l10n.repeater_cliHelpGpsSetLoc),
      command('gps advert', l10n.repeater_cliHelpGpsAdvert),
      command('gps advert {none|share|prefs}', l10n.repeater_cliHelpGpsAdvertSet),
      command('gps diag', l10n.repeater_cliHelpGpsDiag),
    ], note: l10n.repeater_gpsNote),
    CliHelpSection(l10n.repeater_cliSectionSensors, [
      command('sensor list', l10n.repeater_cliHelpSensorList),
      command('sensor get {key}', l10n.repeater_cliHelpSensorGet),
      command('sensor set {key} {value}', l10n.repeater_cliHelpSensorSet),
    ]),
    CliHelpSection(l10n.repeater_bridge, [
      command('get bridge.type', l10n.repeater_cliHelpGetBridgeType),
      setting(
        'bridge.enabled',
        '{on|off}',
        l10n.repeater_cliHelpSetBridgeEnabled,
      ),
      setting('bridge.delay', '{0-10000}', l10n.repeater_cliHelpSetBridgeDelay),
      setting('bridge.source', '{rx|tx}', l10n.repeater_cliHelpSetBridgeSource),
      setting('bridge.baud', '{speed}', l10n.repeater_cliHelpSetBridgeBaud),
      setting('bridge.channel', '{1-14}', l10n.repeater_cliHelpSetBridgeChannel),
      setting(
        'bridge.secret',
        '{shared-secret}',
        l10n.repeater_cliHelpSetBridgeSecret,
      ),
    ]),
    CliHelpSection(l10n.repeater_logging, [
      command('log start', l10n.repeater_cliHelpLogStart),
      command('log stop', l10n.repeater_cliHelpLogStop),
      command('log erase', l10n.repeater_cliHelpLogErase),
    ]),
  ];
}
