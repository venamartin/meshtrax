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
  final _boxFocus = FocusNode();
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
    _boxFocus.dispose();
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
    if (found is ChannelFound && found.hasCapitals) {
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

  /// Shows how a hashtag channel is added: # in the box, ready for its name.
  void _startHashtag() {
    _box.value = const TextEditingValue(
      text: '#',
      selection: TextSelection.collapsed(offset: 1),
    );
    _boxFocus.requestFocus();
  }

  /// A channel's name and secret key, or a contact's name, public key and
  /// type, typed in two boxes.
  Future<void> _enterNameAndKey() async {
    final entered = await showDialog<_NameAndKey>(
      context: context,
      builder: (_) => const _NameKeyDialog(),
    );
    if (entered == null || !mounted) return;
    final type = entered.contactType;
    if (type == null) {
      await _joinChannel(entered.name, entered.keyHex, null);
    } else {
      await _addContact(ContactQrData(
        name: entered.name,
        pubKeyHex: entered.keyHex,
        type: type,
      ));
    }
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
        // Clear of the phone's navigation bar, drawn over the app.
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          TextField(
            controller: _box,
            focusNode: _boxFocus,
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
          // Paste as wide as its word, the rest for Scan a QR Code: in two
          // halves it wrapped on a 360 dp phone (the S20).
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _paste,
                icon: const Icon(Icons.content_paste),
                label: Text(l10n.add_paste),
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
          // A lone # is the hashtag row's start: the name comes next.
          if (_box.text.trim().isNotEmpty && _box.text.trim() != '#') ...[
            const SizedBox(height: 16),
            _foundCard(context, connector),
          ],
          const SizedBox(height: 24),
          Text(
            l10n.add_or,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.tag)),
            title: Text(l10n.add_hashtagRow),
            subtitle: Text(l10n.add_hashtagRowHelp),
            onTap: _busy ? null : _startHashtag,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.lock)),
            title: Text(l10n.channels_createPrivateChannel),
            subtitle: Text(l10n.channels_createPrivateChannelDesc),
            onTap: _busy ? null : _createPrivateChannel,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.key)),
            title: Text(l10n.add_keyRow),
            subtitle: Text(l10n.add_keyRowHelp),
            onTap: _busy ? null : _enterNameAndKey,
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
      extra: found.hasCapitals
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

/// What the Name + Key dialog adds: [contactType] null for a channel.
typedef _NameAndKey = ({String name, String keyHex, int? contactType});

/// A name and a key typed by hand (owner, 2026-11-26: "How would you
/// manually enter a channel by name a PK (same as a person)"): 32
/// characters is a channel's secret key, 64 a contact's public key, whose
/// type is picked here.
class _NameKeyDialog extends StatefulWidget {
  const _NameKeyDialog();

  @override
  State<_NameKeyDialog> createState() => _NameKeyDialogState();
}

class _NameKeyDialogState extends State<_NameKeyDialog> {
  final _name = TextEditingController();
  final _key = TextEditingController();
  int _type = advTypeChat;

  @override
  void dispose() {
    _name.dispose();
    _key.dispose();
    super.dispose();
  }

  /// The key without the spaces and colons people copy with it.
  String get _hex => _key.text.replaceAll(RegExp(r'[\s:]'), '').toLowerCase();

  bool get _isHex => RegExp(r'^[0-9a-f]+$').hasMatch(_hex);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hex = _hex;
    final channel = _isHex && hex.length == 32;
    final contact = _isHex && hex.length == 64;
    final name = _name.text.trim();
    final public = channel && hex == Channel.publicChannelPsk;
    final (IconData? icon, String? kind) = channel
        ? (public ? Icons.public : Icons.lock,
            public ? l10n.channels_publicChannel : l10n.channels_privateChannel)
        : contact
            ? (Icons.person, l10n.structured_contact)
            : (null, null);
    final canAdd = channel ? name.isNotEmpty : contact;
    return AlertDialog(
      title: Text(l10n.add_keyRow),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              maxLength: AddInput.maxChannelName,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.add_name,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _key,
              autocorrect: false,
              enableSuggestions: false,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.add_key,
                border: const OutlineInputBorder(),
                errorText: hex.isNotEmpty && kind == null
                    ? l10n.add_keyInvalid
                    : null,
                errorMaxLines: 2,
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (kind != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(kind, style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
            if (contact) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final (type, label) in [
                    (advTypeChat, l10n.add_typePerson),
                    (advTypeRepeater, l10n.structured_repeater),
                    (advTypeRoom, l10n.structured_room),
                    (advTypeSensor, l10n.structured_sensor),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: _type == type,
                      onSelected: (_) => setState(() => _type = type),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: canAdd
              ? () => Navigator.pop<_NameAndKey>(context, (
                    name: name,
                    keyHex: hex,
                    contactType: contact ? _type : null,
                  ))
              : null,
          child: Text(l10n.common_add),
        ),
      ],
    );
  }
}
