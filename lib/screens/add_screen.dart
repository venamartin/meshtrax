import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/add_input.dart';
import '../helpers/channel_join_helper.dart';
import '../helpers/contact_import_helper.dart';
import '../helpers/meshcore_qr.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../models/contact.dart';
import '../services/region_service.dart';
import 'chat_screen.dart';
import 'qr_import_scanner_screen.dart';

/// Adds a contact or a channel from one box that reads every format, shows
/// what it found before adding it, and creates a private channel or joins
/// Public (owner, 2026-11-26: "the add is way too complicated").
class AddScreen extends StatefulWidget {
  /// Opens the QR scanner at once: the scan buttons on the New chat rows.
  final bool scanFirst;

  const AddScreen({super.key, this.scanFirst = false});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  final _box = TextEditingController();
  final _name = TextEditingController();
  final _keepCapitalsKey = GlobalKey();
  AddFound? _found;
  bool _keepCapitals = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _box.addListener(_read);
    _name.addListener(() => setState(() {}));
    if (widget.scanFirst) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
    }
  }

  @override
  void dispose() {
    _box.dispose();
    _name.dispose();
    super.dispose();
  }

  static String? _idOf(AddFound? found) => switch (found) {
        ContactFound(:final data) => 'contact ${data.pubKeyHex}',
        ChannelFound(:final pskHex, :final typedHashtag, :final name) =>
          'channel $pskHex $typedHashtag $name',
        null => null,
      };

  void _read() {
    final found = AddInput.read(_box.text);
    if (_idOf(found) == _idOf(_found)) {
      setState(() {});
      return;
    }
    setState(() {
      _found = found;
      _keepCapitals = false;
      _name.text = switch (found) {
        ContactFound(:final data) => data.name,
        ChannelFound(:final name) => name ?? '',
        null => '',
      };
    });
    if (found is ChannelFound &&
        found.isHashtag &&
        found.typedHashtag != found.name) {
      // With the keyboard up the page shows little more than the box:
      // bring the switch that just appeared into view.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final shown = _keepCapitalsKey.currentContext;
        if (shown == null) return;
        Scrollable.ensureVisible(
          shown,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      });
    }
  }

  Future<void> _paste() async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clip?.text?.trim() ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.add_clipboardEmpty),
      );
      return;
    }
    _box.text = text;
  }

  Future<void> _scan() async {
    final data = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrImportScannerScreen()),
    );
    if (data != null && mounted) _box.text = data;
  }

  Future<void> _addContact(ContactQrData data) async {
    setState(() => _busy = true);
    final added = await ContactImportHelper.importContact(
      context,
      ContactQrData(
        name: data.name.isEmpty ? _name.text.trim() : data.name,
        pubKeyHex: data.pubKeyHex,
        type: data.type,
        latitude: data.latitude,
        longitude: data.longitude,
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (added != null) _leaveFor(added);
  }

  /// Back to the list, where the contact is now; a room goes on to its
  /// password prompt.
  void _leaveFor(Contact contact) {
    final navigator = Navigator.of(context);
    navigator.pop();
    if (contact.type == advTypeRoom) ChatScreen.open(navigator.context, contact);
  }

  void _openChat(Contact contact) {
    final navigator = Navigator.of(context);
    navigator.pop();
    ChatScreen.open(navigator.context, contact);
  }

  Future<void> _joinChannel(String name, String pskHex, String? region) async {
    setState(() => _busy = true);
    await ChannelJoinHelper.joinChannel(
      context,
      name: name,
      pskHex: pskHex,
      region: region,
      confirm: false,
      replace: true,
    );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _createPrivateChannel() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _ChannelNameDialog(),
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || !mounted) return;
    final random = Random.secure();
    final psk = Uint8List.fromList(
      List.generate(16, (_) => random.nextInt(256)),
    );
    await _joinChannel(trimmed, Channel.formatPskHex(psk), null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final connector = context.watch<MeshCoreConnector>();
    final hasPublic = connector.channels.any((c) => c.isPublicChannel);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.add_title), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _box,
            minLines: 2,
            maxLines: 5,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              labelText: l10n.add_box,
              hintText: l10n.add_boxHint,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
              suffixIcon: _box.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: l10n.common_clear,
                      onPressed: _box.clear,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _paste,
                  icon: const Icon(Icons.content_paste),
                  label: Text(l10n.add_paste),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _scan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Text(l10n.channels_scanQrCode),
                ),
              ),
            ],
          ),
          if (_box.text.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _foundCard(context, connector),
          ],
          const SizedBox(height: 24),
          Text(
            l10n.newChat_newChannel,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.lock)),
            title: Text(l10n.channels_createPrivateChannel),
            subtitle: Text(l10n.channels_createPrivateChannelDesc),
            onTap: _busy ? null : _createPrivateChannel,
          ),
          if (!hasPublic)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(child: Icon(Icons.public)),
              title: Text(l10n.channels_joinPublicChannel),
              subtitle: Text(l10n.channels_joinPublicChannelDesc),
              onTap: _busy
                  ? null
                  : () => _joinChannel('Public', Channel.publicChannelPsk, null),
            ),
        ],
      ),
    );
  }

  Widget _foundCard(BuildContext context, MeshCoreConnector connector) {
    final found = _found;
    return switch (found) {
      ContactFound(:final data) => _contactCard(context, connector, data),
      ChannelFound() => _channelCard(context, connector, found),
      null => _card(
          context,
          icon: Icons.help_outline,
          title: context.l10n.add_unreadableTitle,
          subtitle: context.l10n.add_unreadable,
        ),
    };
  }

  Widget _contactCard(
    BuildContext context,
    MeshCoreConnector connector,
    ContactQrData data,
  ) {
    final l10n = context.l10n;
    final key = data.pubKeyHex.toLowerCase();
    final saved = connector.contacts
        .where((c) => c.publicKeyHex.toLowerCase() == key)
        .firstOrNull;
    final (icon, kind) = switch (data.type) {
      advTypeRepeater => (Icons.cell_tower, l10n.structured_repeater),
      advTypeRoom => (Icons.meeting_room, l10n.structured_room),
      advTypeSensor => (Icons.sensors, l10n.structured_sensor),
      _ => (Icons.person, l10n.structured_contact),
    };
    final name = saved?.name ?? data.name;
    return _card(
      context,
      icon: icon,
      title: name.isEmpty ? kind : name,
      subtitle: name.isEmpty
          ? '${key.substring(0, 8)}…'
          : '$kind · ${key.substring(0, 8)}…',
      field: saved == null && data.name.isEmpty
          ? TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.add_contactName,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            )
          : null,
      note: saved == null ? null : l10n.contacts_alreadyInContacts(saved.name),
      action: saved != null
          ? FilledButton.tonal(
              onPressed: () => _openChat(saved),
              child: Text(l10n.structured_open),
            )
          : FilledButton(
              onPressed: _busy ? null : () => _addContact(data),
              child: Text(l10n.structured_addContact),
            ),
    );
  }

  Widget _channelCard(
    BuildContext context,
    MeshCoreConnector connector,
    ChannelFound found,
  ) {
    final l10n = context.l10n;
    final channel = _keepCapitals ? found.withCapitals : found;
    final joined = connector.channels
        .where((c) => c.idKey.toLowerCase() == channel.pskHex)
        .firstOrNull;
    final (icon, kind) = channel.isPublic
        ? (Icons.public, l10n.channels_publicChannel)
        : channel.isHashtag
            ? (Icons.tag, l10n.channels_hashtagChannel)
            : (Icons.lock, l10n.channels_privateChannel);
    final keyOnly = found.keyOnly;
    final name = keyOnly ? _name.text.trim() : channel.name!;
    final region =
        context.read<RegionService?>()?.regionsInQr == true ? found.region : null;
    return _card(
      context,
      icon: icon,
      title: keyOnly ? kind : name,
      subtitle: keyOnly ? '${channel.pskHex.substring(0, 8)}…' : kind,
      field: keyOnly && joined == null
          ? TextField(
              controller: _name,
              maxLength: AddInput.maxChannelName,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.channels_channelName,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            )
          : null,
      extra: found.isHashtag && found.typedHashtag != found.name
          ? SwitchListTile(
              key: _keepCapitalsKey,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.channels_keepCapitals),
              value: _keepCapitals,
              onChanged: (keep) => setState(() => _keepCapitals = keep),
            )
          : null,
      note: joined != null
          ? l10n.link_alreadyJoined(joined.displayName)
          : region == null
              ? null
              : l10n.channelRegion_qrLine(region),
      action: joined != null
          ? FilledButton.tonal(
              onPressed: () => _joinChannel(joined.name, channel.pskHex, null),
              child: Text(l10n.structured_open),
            )
          : FilledButton(
              onPressed: _busy || name.isEmpty
                  ? null
                  : () => _joinChannel(name, channel.pskHex, found.region),
              child: Text(l10n.channels_addChannel),
            ),
    );
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? field,
    Widget? extra,
    String? note,
    Widget? action,
  }) {
    final theme = Theme.of(context);
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(child: Icon(icon)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (field != null) ...[const SizedBox(height: 12), field],
            ?extra,
            if (note != null) ...[
              const SizedBox(height: 8),
              Text(note, style: theme.textTheme.bodyMedium),
            ],
            if (action != null) ...[
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: action),
            ],
          ],
        ),
      ),
    );
  }
}

/// The name for a new private channel; null when cancelled.
class _ChannelNameDialog extends StatefulWidget {
  const _ChannelNameDialog();

  @override
  State<_ChannelNameDialog> createState() => _ChannelNameDialogState();
}

class _ChannelNameDialogState extends State<_ChannelNameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.channels_createPrivateChannel),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: AddInput.maxChannelName,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: l10n.channels_channelName,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (text) => Navigator.pop(context, text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.common_create),
        ),
      ],
    );
  }
}
