import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../services/companion_cli_service.dart';
import '../services/repeater_command_service.dart';
import '../widgets/cli_console.dart';
import '../widgets/routing_dialog.dart';

/// Text command line for a firmware 1.18+ companion: the connected radio,
/// or with [contact], another companion that lets us use its command line.
class CompanionCliScreen extends StatefulWidget {
  final Contact? contact;

  const CompanionCliScreen({super.key, this.contact});

  @override
  State<CompanionCliScreen> createState() => _CompanionCliScreenState();
}

class _CompanionCliScreenState extends State<CompanionCliScreen> {
  RepeaterCommandService? _remote;
  StreamSubscription<Uint8List>? _replySubscription;

  @override
  void initState() {
    super.initState();
    final contact = widget.contact;
    if (contact == null) return;
    final connector = context.read<MeshCoreConnector>();
    final remote = _remote = RepeaterCommandService(connector);
    // The reply is a CLI_DATA DM from that companion. A companion also
    // chats, and the service hands an untokened message to the pending
    // command, so plain messages must not reach it.
    _replySubscription = connector.receivedFrames.listen((frame) {
      final parsed = parseContactMessageText(frame);
      if (parsed == null || parsed.txtType != txtTypeCliData) return;
      for (var i = 0; i < 6; i++) {
        if (parsed.senderPrefix[i] != contact.publicKey[i]) return;
      }
      remote.handleResponse(contact, parsed.text);
    });
  }

  @override
  void dispose() {
    _replySubscription?.cancel();
    _remote?.dispose();
    super.dispose();
  }

  Contact? _resolveContact(MeshCoreConnector connector) {
    final contact = widget.contact;
    if (contact == null) return null;
    return connector.contacts.firstWhere(
      (c) => c.publicKeyHex == contact.publicKeyHex,
      orElse: () => contact,
    );
  }

  Future<String> _send(String command) async {
    final l10n = context.l10n;
    final connector = context.read<MeshCoreConnector>();
    final contact = _resolveContact(connector);
    final isPowerOff = command == 'poweroff' || command == 'shutdown';
    if (isPowerOff && !await _confirmPowerOff()) {
      return l10n.companionCli_cancelled;
    }

    if (contact != null) {
      try {
        // One attempt, as for a repeater: a retry would run it twice.
        return await _remote!.sendCommand(
          contact,
          command,
          retries: 1,
          txtType: txtTypeCliCommand,
        );
      } catch (_) {
        return command == 'reboot' || isPowerOff
            ? l10n.companionCli_remoteSentNoAnswer
            : l10n.companionCli_remoteNoReply;
      }
    }

    // CMD_REBOOT flushes pending contact writes first; the CLI reboot
    // doesn't. Neither answers.
    if (command == 'reboot') {
      await connector.rebootDevice();
      return l10n.companionCli_rebooting;
    }
    if (isPowerOff) {
      await connector.companionCli.sendWithoutReply(command);
      return l10n.companionCli_poweringOff;
    }
    try {
      final reply = await connector.companionCli.run(command);
      final kind = CliReply(reply).kind;
      // A CLI write changes what DEVICE_INFO / SELF_INFO report, and the
      // radio sends no push for it.
      if (command.startsWith('set ') &&
          (kind == CliReplyKind.ok || kind == CliReplyKind.value)) {
        unawaited(connector.refreshDeviceInfo());
      }
      return reply;
    } on TimeoutException {
      return l10n.companionCli_noReply;
    }
  }

  Future<bool> _confirmPowerOff() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.companionCli_powerOffTitle),
        content: Text(l10n.companionCli_powerOffBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.companionCli_powerOff),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();
    final contact = _resolveContact(connector);
    // Whether another companion has WiFi is unknown; its help lists it.
    final hasWifi = contact != null || connector.hasWifi == true;

    return CliConsole(
      title: l10n.companionCli_title,
      subtitle: contact?.name ?? connector.selfName ?? '',
      onSend: _send,
      actions: [
        if (contact != null)
          IconButton(
            icon: RoutingIcon(contact: contact),
            tooltip: l10n.routing_title,
            onPressed: () => RoutingDialog.show(context, contact: contact),
          ),
      ],
      debugFrameFor: contact == null
          ? buildRunCliCommandFrame
          : (command) => buildSendCliCommandFrame(
              contact.publicKey,
              command,
              txtType: txtTypeCliCommand,
            ),
      quickCommands: [
        CliQuickCommand(l10n.repeater_cliQuickVersion, 'ver'),
        CliQuickCommand(l10n.companionCli_quickBoard, 'board'),
        CliQuickCommand(l10n.repeater_cliQuickGetName, 'get name'),
        CliQuickCommand(l10n.repeater_cliQuickGetRadio, 'get radio'),
        CliQuickCommand(l10n.repeater_cliQuickGetTx, 'get tx'),
        if (contact == null && hasWifi) ...[
          CliQuickCommand(l10n.companionCli_quickWifiStatus, 'get wifi.status'),
          CliQuickCommand(l10n.companionCli_quickWifiAddress, 'get wifi.ip'),
        ],
      ],
      helpNote: l10n.repeater_commandsListNote,
      helpSections: (context) => _helpSections(context, hasWifi: hasWifi),
    );
  }

  List<CliHelpSection> _helpSections(
    BuildContext context, {
    required bool hasWifi,
  }) {
    final l10n = context.l10n;
    return [
      CliHelpSection(l10n.repeater_general, [
        CliHelpEntry(command: 'ver', description: l10n.repeater_cliHelpVersion),
        CliHelpEntry(
          command: 'board',
          description: l10n.companionCli_helpBoard,
        ),
        CliHelpEntry(
          command: 'reboot',
          description: l10n.companionCli_helpReboot,
        ),
        CliHelpEntry(
          command: 'poweroff',
          description: l10n.companionCli_helpPowerOff,
        ),
        CliHelpEntry(
          command: 'set name {name}',
          description: l10n.repeater_cliHelpSetName,
        ),
        CliHelpEntry(
          command: 'set pin {6 digits}',
          description: l10n.companionCli_helpSetPin,
        ),
        CliHelpEntry(
          command: 'set tz.offset {hours}',
          description: l10n.companionCli_helpSetTzOffset,
        ),
      ]),
      CliHelpSection(l10n.repeater_settingsCategory, [
        CliHelpEntry(
          command: 'set radio {freq},{bw},{sf},{cr}',
          description: l10n.repeater_cliHelpSetRadio,
        ),
        CliHelpEntry(
          command: 'set tx {dbm}',
          description: l10n.companionCli_helpSetTx,
        ),
        CliHelpEntry(
          command: 'set af {air-time-factor}',
          description: l10n.repeater_cliHelpSetAf,
        ),
        CliHelpEntry(
          command: 'set rxdelay {0-20}',
          description: l10n.repeater_cliHelpSetRxDelay,
        ),
        CliHelpEntry(
          command: 'set txdelay {0-2}',
          description: l10n.repeater_cliHelpSetTxDelay,
        ),
        CliHelpEntry(
          command: 'set direct.txdelay {0-2}',
          description: l10n.repeater_cliHelpSetDirectTxDelay,
        ),
        CliHelpEntry(
          command: 'set int.thresh {db}',
          description: l10n.companionCli_helpSetIntThresh,
        ),
        CliHelpEntry(
          command: 'set agc.reset.interval {seconds}',
          description: l10n.repeater_cliHelpSetAgcResetInterval,
        ),
        CliHelpEntry(
          command: 'set cad {on|off}',
          description: l10n.companionCli_helpSetCad,
        ),
        CliHelpEntry(
          command: 'set radio.rxgain {on|off}',
          description: l10n.companionCli_helpSetRxGain,
        ),
        CliHelpEntry(
          command: 'set multi.acks {0|1}',
          description: l10n.repeater_cliHelpSetMultiAcks,
        ),
        CliHelpEntry(
          command: 'set path.hash.mode {0|1|2}',
          description: l10n.companionCli_helpSetPathHashMode,
        ),
      ]),
      if (hasWifi)
        CliHelpSection(l10n.wifi_title, [
          CliHelpEntry(
            command: 'get wifi.status',
            description: l10n.companionCli_helpWifiStatus,
          ),
          CliHelpEntry(
            command: 'get wifi.ip',
            description: l10n.companionCli_helpWifiIp,
          ),
          CliHelpEntry(
            command: 'set wifi.ssid {name}',
            description: l10n.companionCli_helpWifiSsid,
          ),
          CliHelpEntry(
            command: 'set wifi.pwd {password}',
            description: l10n.companionCli_helpWifiPwd,
          ),
          CliHelpEntry(
            command: 'set wifi.enabled {0|1}',
            description: l10n.companionCli_helpWifiEnabled,
          ),
          CliHelpEntry(
            command: 'set wifi.clear',
            description: l10n.companionCli_helpWifiClear,
          ),
        ]),
    ];
  }
}
