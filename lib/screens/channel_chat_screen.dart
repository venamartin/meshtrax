import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../connector/meshcore_connector.dart';
import '../utils/platform_info.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/gif_helper.dart';
import '../helpers/reaction_helper.dart';
import '../helpers/report_helper.dart';
import '../helpers/snack_bar_builder.dart';
import '../helpers/link_handler.dart';
import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../models/channel_message.dart';
import '../models/contact.dart';
import '../services/app_settings_service.dart';
import '../services/chat_text_scale_service.dart';
import '../services/ui_view_state_service.dart';
import '../utils/chat_colors.dart';
import '../utils/emoji_utils.dart';
import '../widgets/byte_count_input.dart';
import '../widgets/chat_zoom_wrapper.dart';
import '../widgets/contact_tile.dart';
import '../widgets/reaction_picker_sheet.dart';
import '../widgets/gif_message.dart';
import '../widgets/gif_picker.dart';
import '../widgets/message_status_icon.dart';
import '../widgets/radio_stats_entry.dart';
import '../widgets/reaction_details_sheet.dart';
import 'channel_message_path_screen.dart';
import 'channel_share_screen.dart';
import 'chat_screen.dart';
import 'map_screen.dart';

class ChannelChatScreen extends StatefulWidget {
  final Channel channel;
  final int? unreadCount;

  /// When set (mention-notification tap), the list opens anchored on this
  /// message instead of the bottom or the oldest-unread position.
  final String? scrollToMessageId;

  const ChannelChatScreen({
    super.key,
    required this.channel,
    this.unreadCount,
    this.scrollToMessageId,
  });

  @override
  State<ChannelChatScreen> createState() => _ChannelChatScreenState();
}

class _ChannelChatScreenState extends State<ChannelChatScreen> {
  final MentionTextEditingController _textController = MentionTextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  String? _mentionSearchText;
  bool _showMentions = false;
  List<Contact> _filteredMentionContacts = [];

  // Memoized mention contact map — rebuilt when message list changes
  Map<String, Contact>? _cachedMentionMap;
  int _cachedMentionMessageCount = -1;

  ChannelMessage? _replyingToMessage;
  bool _isLoadingOlder = false;

  MeshCoreConnector? _connector;

  // DM-from-channel advert watch: armed by the no-match dialog, disarmed on
  // hit, timeout, or screen dispose. Names only — a channel message carries
  // no sender key, so a fresh advert is detected by candidates appearing
  // where there were none (clock-immune: no timestamp comparison).
  String? _awaitedAdvertName;
  Timer? _awaitedAdvertTimer;
  MeshCoreConnector? _advertWatchConnector;

  ChannelMessage? _firstUnreadMessage;
  int _initialScrollIndex = 0;
  bool _isAtBottom = true;
  DateTime? _lastChannelSendAt;
  int _previousMessageCount = 0;

  /// The watched database query is the screen's only message source
  /// (Phase 3d) — ordering and paging belong to SQL.
  List<ChannelMessage> _messages = const [];
  StreamSubscription<List<ChannelMessage>>? _messagesSub;
  int _watchLimit = 200;
  bool _didInitialAnchor = false;

  void _subscribeMessages(MeshCoreConnector connector) {
    _messagesSub?.cancel();
    _messagesSub = connector
        .watchChannelMessages(widget.channel, limit: _watchLimit)
        .listen((messages) {
      if (!mounted) return;
      setState(() {
        _messages = messages;
        if (!_didInitialAnchor) {
          _didInitialAnchor = true;
          _previousMessageCount = messages.length;
          final settings = context.read<AppSettingsService>().settings;
          final unread = widget.unreadCount ??
              connector.getUnreadCountForChannelIndex(widget.channel.index);
          final mentionTarget = widget.scrollToMessageId;
          final mentionIdx = mentionTarget == null
              ? -1
              : messages.reversed
                    .toList()
                    .indexWhere((m) => m.messageId == mentionTarget);
          if (mentionIdx != -1) {
            _initialScrollIndex = mentionIdx;
            _isAtBottom = false;
          } else if (settings.jumpToOldestUnread && unread > 0) {
            _firstUnreadMessage =
                _findOldestUnreadChannelAnchor(messages, unread);
            if (_firstUnreadMessage != null) {
              final msgIdx =
                  messages.reversed.toList().indexOf(_firstUnreadMessage!);
              if (msgIdx != -1) {
                _initialScrollIndex = msgIdx;
                _isAtBottom = false;
              }
            }
          }
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _textFieldFocusNode.addListener(_onTextFieldFocusChange);
    _itemPositionsListener.itemPositions.addListener(_scrollListener);
    _textController.addListener(_mentionsListener);

    final connector = context.read<MeshCoreConnector>();
    _subscribeMessages(connector);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      connector.setActiveChannel(widget.channel.index);
      _connector = connector;
    });
  }

  ChannelMessage? _findOldestUnreadChannelAnchor(
    List<ChannelMessage> messages,
    int unreadCount,
  ) {
    if (unreadCount <= 0 || messages.isEmpty) return null;
    var n = 0;
    ChannelMessage? oldest;
    for (final m in messages.reversed) {
      if (m.isOutgoing) continue;
      n++;
      oldest = m;
      if (n >= unreadCount) break;
    }
    return oldest;
  }

  void _scrollListener() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    int minIndex = positions.first.index;
    int maxIndex = positions.first.index;

    for (final p in positions) {
      if (p.index < minIndex) minIndex = p.index;
      if (p.index > maxIndex) maxIndex = p.index;
    }

    // With reverse:true, index 0 is the newest message at the visual bottom.
    // If item 0 is in the visible positions, the user is at the bottom.
    final isAtBottom = positions.any((p) => p.index == 0);
    if (_isAtBottom != isAtBottom) {
      setState(() => _isAtBottom = isAtBottom);
    }

    final itemCount = _messages.length;
    if (maxIndex >= itemCount - 5 && !_isLoadingOlder) {
      _loadOlderMessages();
    }
  }

  void _onTextFieldFocusChange() {
    if (_textFieldFocusNode.hasFocus && mounted && _isAtBottom && _itemScrollController.isAttached) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && _itemScrollController.isAttached) {
          _itemScrollController.scrollTo(
            index: 0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _mentionsListener() {
    if (!mounted) return;
    final text = _textController.text;
    final selection = _textController.selection;

    if (!selection.isValid || selection.baseOffset != selection.extentOffset) {
      if (_showMentions) setState(() => _showMentions = false);
      return;
    }

    final cursorPosition = selection.baseOffset;
    if (cursorPosition == 0) {
      if (_showMentions) setState(() => _showMentions = false);
      return;
    }

    // Look back from cursor to find the start of the current word
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtSignIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtSignIndex != -1) {
      final textAfterAt = textBeforeCursor.substring(lastAtSignIndex + 1);
      final charBeforeAt = lastAtSignIndex > 0 ? textBeforeCursor[lastAtSignIndex - 1] : ' ';
      
      if (!textAfterAt.contains(' ') && (charBeforeAt == ' ' || charBeforeAt == '\n')) {
        final search = textAfterAt.toLowerCase();
        final connector = Provider.of<MeshCoreConnector>(context, listen: false);

        final messages = _messages;
        final Set<String> recentSenderKeys = {};
        
        for (var m in messages) {
          if (!m.isOutgoing && m.senderKeyHex != null && m.senderKeyHex!.isNotEmpty) {
            recentSenderKeys.add(m.senderKeyHex!);
          }
        }

        // Rebuild the mention map only when the message list has changed
        if (_cachedMentionMap == null || _cachedMentionMessageCount != messages.length) {
          final Map<String, Contact> mentionMap = {};
          for (var c in connector.allContactsUnfiltered) {
            mentionMap[c.publicKeyHex] = c;
          }

          // Scan messages for anyone not in the global contact list.
          // This ensures people who have spoken but haven't been 'discovered' yet show up.
          for (var m in messages) {
            if (!m.isOutgoing) {
              if (m.senderKeyHex != null && mentionMap.containsKey(m.senderKeyHex!)) {
                continue;
              }
              // Also check by name to prevent duplicates where the same person
              // is seen as both a contact and a raw sender.
              final alreadyHasName = mentionMap.values.any((c) => c.name == m.senderName);
              if (alreadyHasName) continue;

              final key = m.senderKeyHex ?? 'name_${m.senderName}';
              mentionMap[key] = Contact(
                publicKey: m.senderKeyHex != null 
                    ? hexToPubKey(m.senderKeyHex!) 
                    : Uint8List(pubKeySize),
                name: m.senderName,
                type: advTypeChat,
                pathLength: -1,
                path: Uint8List(0),
                lastSeen: DateTime.now(),
                isActive: true,
              );
            }
          }
          _cachedMentionMap = mentionMap;
          _cachedMentionMessageCount = messages.length;
        }

        final filtered = _cachedMentionMap!.values.where((c) {
          // Filter out repeaters as they are non-human nodes
          if (c.type == advTypeRepeater) return false;
          
          return c.name.toLowerCase().contains(search) || 
                 c.publicKeyHex.toLowerCase().startsWith(search);
        }).toList();

        filtered.sort((a, b) {
          final aStart = a.name.toLowerCase().startsWith(search);
          final bStart = b.name.toLowerCase().startsWith(search);
          if (aStart && !bStart) return -1;
          if (!aStart && bStart) return 1;

          // Emoji-led names can't be reached by typing (and UTF-16 order
          // sorts them after 'z') — surface them first. They drop out of
          // the filter the moment a letter is typed anyway.
          final aEmoji = _startsWithEmoji(a.name);
          final bEmoji = _startsWithEmoji(b.name);
          if (aEmoji && !bEmoji) return -1;
          if (!aEmoji && bEmoji) return 1;

          final aIsRecent = recentSenderKeys.contains(a.publicKeyHex);
          final bIsRecent = recentSenderKeys.contains(b.publicKeyHex);
          if (aIsRecent && !bIsRecent) return -1;
          if (!aIsRecent && bIsRecent) return 1;

          return a.name.compareTo(b.name);
        });

        if (_showMentions != filtered.isNotEmpty || _mentionSearchText != search) {
          setState(() {
            _mentionSearchText = search;
            _showMentions = filtered.isNotEmpty;
            // No cap: the overlay is a lazy, scrollable list. take(15) cut
            // everyone past the first screen — and names sort by UTF-16, so
            // emoji-only names landed after 'z' and could NEVER appear.
            _filteredMentionContacts = filtered;
          });
        }
        return;
      }
    }

    if (_showMentions) {
      setState(() => _showMentions = false);
    }
  }

  void _insertMention(Contact contact) {
    final text = _textController.text;
    final selection = _textController.selection;
    final cursorPosition = selection.baseOffset;
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtSignIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtSignIndex != -1) {
      final newText = text.replaceRange(
        lastAtSignIndex,
        cursorPosition,
        '@[${contact.name}] ',
      );
      
      _textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: lastAtSignIndex + contact.name.length + 4,
        ),
      );

      setState(() => _showMentions = false);
      _textFieldFocusNode.requestFocus();
    }
  }

  /// Inserts "@[name] " at the cursor (or the end) and focuses the composer.
  /// Used by the message actions sheet and the mention swipe.
  void _insertMentionOf(String senderName) {
    final text = _textController.text;
    final sel = _textController.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final needsSpace =
        start > 0 && text[start - 1] != ' ' && text[start - 1] != '\n';
    final mention = '${needsSpace ? ' ' : ''}@[$senderName] ';
    _textController.value = TextEditingValue(
      text: text.replaceRange(start, end, mention),
      selection: TextSelection.collapsed(offset: start + mention.length),
    );
    _textFieldFocusNode.requestFocus();
  }

  // --- DM from a channel message --------------------------------------------
  // A channel message carries only a self-reported display name, so opening
  // a DM means matching that name against saved + discovered contacts and
  // letting the user verify the key. Every branch keeps the user in charge:
  // no advert is ever sent, and no contact imported, without a tap.

  /// Saved and discovered chat contacts whose name matches [senderName]
  /// (trimmed, case-insensitive — other apps let names be typed by hand).
  /// Deduped by key with the saved entry winning; newest heard first.
  List<({Contact contact, bool saved})> _dmCandidatesFor(
    MeshCoreConnector connector,
    String senderName,
  ) {
    final wanted = senderName.trim().toLowerCase();
    bool matches(Contact c) =>
        c.type == advTypeChat &&
        c.publicKeyHex != connector.selfPublicKeyHex &&
        c.name.trim().toLowerCase() == wanted;

    final byKey = <String, ({Contact contact, bool saved})>{};
    for (final c in connector.contacts) {
      if (matches(c)) byKey[c.publicKeyHex] = (contact: c, saved: true);
    }
    for (final c in connector.discoveredContacts) {
      if (matches(c)) {
        byKey.putIfAbsent(c.publicKeyHex, () => (contact: c, saved: false));
      }
    }
    return byKey.values.toList()
      ..sort((a, b) => b.contact.lastSeen.compareTo(a.contact.lastSeen));
  }

  void _startDmTo(String senderName) {
    final connector = context.read<MeshCoreConnector>();
    final candidates = _dmCandidatesFor(connector, senderName);
    if (candidates.isEmpty) {
      _showDmNoMatch(connector, senderName);
      return;
    }
    // Unambiguous and already in conversation: jump straight in. The
    // identity decision was made when that conversation started; picker
    // and warning would be pure friction.
    if (candidates.length == 1) {
      final only = candidates.single;
      if (only.saved && connector.latestContactArrivalUs(only.contact) > 0) {
        _openDmWith(connector, only.contact, saved: true);
        return;
      }
    }
    _showDmCandidatePicker(connector, senderName, candidates);
  }

  /// Always shown, even for a single match: seeing the key and last-seen
  /// time IS the identity check — names are not unique and can be imitated.
  void _showDmCandidatePicker(
    MeshCoreConnector connector,
    String senderName,
    List<({Contact contact, bool saved})> candidates,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.dmChannel_pickerTitle(senderName),
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.dmChannel_pickerHint,
                    style: Theme.of(sheetContext).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: candidates.length,
                itemBuilder: (context, index) {
                  final candidate = candidates[index];
                  return ContactTile(
                    contact: candidate.contact,
                    lastSeen: candidate.contact.lastSeen,
                    unreadCount: 0,
                    isFavorite: candidate.contact.isFavorite,
                    isDiscovered: !candidate.saved,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _openDmWith(
                        connector,
                        candidate.contact,
                        saved: candidate.saved,
                      );
                    },
                    onLongPress: () {},
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One-time informed-consent dialog; "don't show again" persists.
  Future<bool> _confirmDmIdentity() async {
    final settingsService = context.read<AppSettingsService>();
    if (settingsService.settings.dmIdentityWarningDismissed) return true;
    var dontShowAgain = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(dialogContext.l10n.dmChannel_warningTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dialogContext.l10n.dmChannel_warningBody),
              CheckboxListTile(
                title: Text(dialogContext.l10n.dmChannel_dontShowAgain),
                value: dontShowAgain,
                onChanged: (value) =>
                    setDialogState(() => dontShowAgain = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(dialogContext.l10n.common_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(dialogContext.l10n.common_continue),
            ),
          ],
        ),
      ),
    );
    if (ok == true && dontShowAgain) {
      await settingsService.dismissDmIdentityWarning();
    }
    return ok == true;
  }

  Future<void> _openDmWith(
    MeshCoreConnector connector,
    Contact contact, {
    required bool saved,
  }) async {
    // An existing conversation is an already-accepted identity — only
    // warn when this DM would be a new link from channel name to contact.
    final hasConversation =
        saved && connector.latestContactArrivalUs(contact) > 0;
    if (!hasConversation && !await _confirmDmIdentity()) return;
    if (!mounted) return;
    if (!saved) {
      final success = await connector.importDiscoveredContact(contact);
      if (!mounted) return;
      if (!success) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_contactImportFailed),
        );
        return;
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(contact: contact, unreadCount: 0),
      ),
    );
  }

  void _showDmNoMatch(MeshCoreConnector connector, String senderName) {
    // The two actions are both halves of one key exchange — they need OUR
    // advert to reply, we need THEIRS to send — so taking one must not
    // close the door on the other. Sending stays in the dialog (the button
    // flips to a done-state); asking closes it only because it hands off
    // to the composer.
    var advertSent = false;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(dialogContext.l10n.dmChannel_noMatchTitle(senderName)),
          content: Text(dialogContext.l10n.dmChannel_noMatchBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(dialogContext.l10n.common_close),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _insertAskInChannel(senderName);
                _armAdvertWatch(connector, senderName);
              },
              child: Text(dialogContext.l10n.dmChannel_askInChannel),
            ),
            FilledButton(
              onPressed: advertSent
                  ? null
                  : () {
                      setDialogState(() => advertSent = true);
                      unawaited(connector.sendSelfAdvert(flood: true));
                      _armAdvertWatch(connector, senderName);
                    },
              child: Text(
                advertSent
                    ? dialogContext.l10n.settings_advertisementSent
                    : dialogContext.l10n.dmChannel_sendMyAdvert,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Prefills the composer with a plain-language advert request — the user
  /// sends it themselves. Readable by any app; the @[mention] pings
  /// MeshTrax users.
  void _insertAskInChannel(String senderName) {
    _insertMentionOf(senderName);
    final ask = context.l10n.dmChannel_askText;
    final text = _textController.text;
    final sel = _textController.selection;
    final start = sel.isValid ? sel.start : text.length;
    _textController.value = TextEditingValue(
      text: text.replaceRange(start, start, ask),
      selection: TextSelection.collapsed(offset: start + ask.length),
    );
  }

  void _armAdvertWatch(MeshCoreConnector connector, String senderName) {
    // Taking both dialog actions arms twice for the same name — the watch
    // is already running, keep it (and don't repeat the snackbar).
    if (_awaitedAdvertName == senderName && _awaitedAdvertTimer != null) {
      return;
    }
    _disarmAdvertWatch();
    _awaitedAdvertName = senderName;
    _advertWatchConnector = connector;
    _awaitedAdvertTimer =
        Timer(const Duration(minutes: 15), _disarmAdvertWatch);
    connector.addListener(_checkAwaitedAdvert);
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.dmChannel_watching),
    );
  }

  void _disarmAdvertWatch() {
    _awaitedAdvertTimer?.cancel();
    _awaitedAdvertTimer = null;
    _advertWatchConnector?.removeListener(_checkAwaitedAdvert);
    _advertWatchConnector = null;
    _awaitedAdvertName = null;
  }

  /// Armed only when the name had zero candidates, so any candidate
  /// appearing means their advert arrived.
  void _checkAwaitedAdvert() {
    final name = _awaitedAdvertName;
    final connector = _advertWatchConnector;
    if (name == null || connector == null || !mounted) return;
    final candidates = _dmCandidatesFor(connector, name);
    if (candidates.isEmpty) return;
    _disarmAdvertWatch();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.dmChannel_advertHeard(name)),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: context.l10n.dmChannel_openDm,
          onPressed: () =>
              _showDmCandidatePicker(connector, name, candidates),
        ),
      ),
    );
  }

  Widget _buildMentionsOverlay() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: _filteredMentionContacts.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final contact = _filteredMentionContacts[index];
            return ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
                child: _buildContactMentionAvatar(contact, colorScheme.primary),
              ),
              title: Text(
                contact.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () => _insertMention(contact),
            );
          },
        ),
      ),
    );
  }

  bool _startsWithEmoji(String name) {
    if (name.isEmpty) return false;
    return firstEmoji(name.characters.first) != null;
  }

  Widget _buildContactMentionAvatar(Contact contact, Color iconColor) {
    final emoji = firstEmoji(contact.name);
    if (emoji != null) {
      return Text(emoji, style: const TextStyle(fontSize: 16));
    }
    return Icon(_getTypeIcon(contact.type), color: iconColor, size: 16);
  }

  IconData _getTypeIcon(int type) {
    switch (type) {
      case advTypeChat:
        return Icons.chat_bubble;
      case advTypeRepeater:
        return Icons.cell_tower;
      case advTypeRoom:
        return Icons.group;
      case advTypeSensor:
        return Icons.sensors;
      default:
        return Icons.device_unknown;
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingOlder) return;
    // Paging is a bigger LIMIT on the watched query — SQL does the rest.
    if (_messages.length < _watchLimit) return;
    setState(() => _isLoadingOlder = true);

    _watchLimit += 200;
    _subscribeMessages(context.read<MeshCoreConnector>());

    if (mounted) {
      setState(() => _isLoadingOlder = false);
    }
  }

  @override
  void dispose() {
    _disarmAdvertWatch();
    _messagesSub?.cancel();
    _itemPositionsListener.itemPositions.removeListener(_scrollListener);
    _connector?.setActiveChannel(null);
    _textFieldFocusNode.removeListener(_onTextFieldFocusChange);
    _textController.removeListener(_mentionsListener);
    _textFieldFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _setReplyingTo(ChannelMessage message) {
    setState(() {
      _replyingToMessage = message;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  Future<void> _scrollToMessage(String messageId) async {
    if (!_itemScrollController.isAttached) return;

    final reversedMessages = _messages.reversed.toList();
    final index = reversedMessages.indexWhere((m) => m.messageId == messageId);
    
    if (index != -1) {
      await _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    } else {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chat_originalMessageNotFound),
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatColors.isLight(context) ? ChatColors.background : null,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              widget.channel.isPublicChannel
                  ? Icons.public
                  : (widget.channel.name.startsWith('#') ? Icons.tag : Icons.lock),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.channel.displayName,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            tooltip: context.l10n.channels_shareChannel,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChannelShareScreen(channel: widget.channel),
                ),
              );
            },
          ),
          const RadioStatsIconButton(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clearChat') {
                context.read<MeshCoreConnector>().clearMessagesForChannel(
                  widget.channel.index,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clearChat',
                child: Row(
                  children: [
                    const Icon(Icons.cleaning_services, size: 20, color: Colors.orange),
                    const SizedBox(width: 12),
                    Text(
                      context.l10n.contact_clearChat,
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Consumer<MeshCoreConnector>(
                builder: (context, connector, child) {
                  final settingsService = context.watch<AppSettingsService>();
                  final messages = _messages
                      .where((m) =>
                          m.isOutgoing ||
                          !settingsService.isSenderBlocked(m.senderName))
                      .toList();

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.channel.isPublicChannel
                                ? Icons.public
                                : Icons.tag,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.l10n.chat_noMessages,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.chat_sendMessageToStart,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Reverse messages so newest appear at bottom with reverse: true
                  final reversedMessages = messages.reversed.toList();
                  final itemCount =
                      reversedMessages.length + (_isLoadingOlder ? 1 : 0);

                  // Auto-scroll to bottom if user is already at bottom
                  final currentMessageCount = messages.length;
                  final newestIsOutgoing = messages.isNotEmpty && messages.last.isOutgoing;
                  if (currentMessageCount > _previousMessageCount) {
                    // Auto-scroll if: the user is already at the bottom, OR they
                    // just sent the newest message.
                    if ((_isAtBottom || newestIsOutgoing) && _itemScrollController.isAttached) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted || !_itemScrollController.isAttached) return;
                        _itemScrollController.jumpTo(
                          index: 0,
                          alignment: 0.0,
                        );
                      });
                    }
                  }
                  // Defer count update to avoid mutating state during build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _previousMessageCount = currentMessageCount;
                  });

                  return Stack(
                    children: [
                      ExcludeSemantics(
                        child: ChatZoomWrapper(
                          child: ScrollablePositionedList.builder(
                            reverse: true, // List grows from bottom up
                            itemScrollController: _itemScrollController,
                            itemPositionsListener: _itemPositionsListener,
                            initialScrollIndex: _initialScrollIndex,
                            initialAlignment: _initialScrollIndex > 0 ? 0.05 : 0.0,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                            itemCount: itemCount,
                            itemBuilder: (context, index) {
                              // Loading indicator now appears at end (bottom) of reversed list
                              if (_isLoadingOlder && index == itemCount - 1) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final messageIndex = index;
                              final message = reversedMessages[messageIndex];
                              
                              final bubble = Builder(
                                builder: (context) {
                                  final textScale = context
                                      .select<ChatTextScaleService, double>(
                                        (service) => service.scale,
                                      );
                                  return _buildMessageBubble(
                                    message,
                                    textScale,
                                  );
                                },
                              );
                              bool showDayMarker = false;
                              if (messageIndex == reversedMessages.length - 1) {
                                showDayMarker = true;
                              } else {
                                final olderMessage = reversedMessages[messageIndex + 1];
                                final currentDate = DateTime(message.timestamp.year, message.timestamp.month, message.timestamp.day);
                                final olderDate = DateTime(olderMessage.timestamp.year, olderMessage.timestamp.month, olderMessage.timestamp.day);
                                if (currentDate != olderDate) {
                                  showDayMarker = true;
                                }
                              }

                              Widget currentWidget = bubble;

                              if (_firstUnreadMessage != null && message.messageId == _firstUnreadMessage!.messageId) {
                                currentWidget = Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Row(
                                        children: [
                                          Expanded(child: Divider(color: Colors.red[400], thickness: 1)),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(context.l10n.chat_newMessages, style: TextStyle(color: Colors.red[400], fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                          Expanded(child: Divider(color: Colors.red[400], thickness: 1)),
                                        ],
                                      ),
                                    ),
                                    currentWidget,
                                  ],
                                );
                              }

                              if (showDayMarker) {
                                currentWidget = Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Row(
                                        children: [
                                          Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              DateFormat('E, d MMMM').format(message.timestamp), 
                                              style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600)
                                            ),
                                          ),
                                          Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
                                        ],
                                      ),
                                    ),
                                    currentWidget,
                                  ],
                                );
                              }

                              return currentWidget;
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: AnimatedScale(
                          scale: _isAtBottom ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            onPressed: () {
                              if (_itemScrollController.isAttached) {
                                _itemScrollController.scrollTo(
                                  index: 0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }
                            },
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (_showMentions) _buildMentionsOverlay(),
            _buildMessageComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChannelMessage message, double textScale) {
    // A stored MeshCore One reaction is one whose target message we don't
    // hold. It stays an ordinary bubble — same sender header, avatar and
    // timestamp as any message — but shows "{emoji}@[{target}]" instead of
    // the raw hash line, with a reaction icon marking what it is. If the
    // target arrives later the connector lands the reaction on it and
    // deletes this row.
    return _buildRegularMessageBubble(
      message,
      textScale,
      orphanReaction: ReactionHelper.parseMeshCoreOneReaction(message.text),
    );
  }

  Widget _buildRegularMessageBubble(
    ChannelMessage message,
    double textScale, {
    ReactionInfo? orphanReaction,
  }) {
    final settingsService = context.read<AppSettingsService>();
    final uiState = context.read<UiViewStateService>();
    final connector = context.read<MeshCoreConnector>();
    final enableTracing = settingsService.settings.enableMessageTracing;
    final senderNameColors = settingsService.settings.senderNameColors;
    final isOutgoing = message.isOutgoing;
    final gifId = GifHelper.parseGif(message.text);
    final poi = _parsePoiMessage(message.text);
    final gifPattern = RegExp(r'g:[A-Za-z0-9_-]{12,}');
    // An unresolved reaction shows what it reacted with and to — never the
    // Crockford hash line, which means nothing to a reader.
    final cleanDisplayText = orphanReaction != null
        ? orphanReaction.emoji +
            (orphanReaction.targetSender != null
                ? '@[${orphanReaction.targetSender}]'
                : '')
        : message.text.replaceAll(gifPattern, '').trim();
    final displayPathString = message.pathBytes.isNotEmpty
        ? message.displayPathString
        : (message.pathVariants.isNotEmpty
              ? message.displayPathVariants.first
              : "");

    final isJumboEmoji = gifId == null && poi == null && _isOnlyEmojis(message.text);
    final warmLight = ChatColors.isLight(context);
    final displayBubbleColor = isJumboEmoji
        ? Colors.transparent
        : warmLight
            ? (isOutgoing ? ChatColors.outgoingBubble : ChatColors.incomingBubble)
            : (isOutgoing
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest);
    final bodyFontSize = isJumboEmoji ? 48.0 : 14.0;

    const maxSwipeOffset = 64.0;
    const replySwipeThreshold = 64.0;
    final messageBody = Column(
      crossAxisAlignment: isOutgoing
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isOutgoing
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isOutgoing) ...[
              _buildAvatar(message.senderName),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: GestureDetector(
                onTap: PlatformInfo.isDesktop
                    ? null
                    : () => _showMessagePathInfo(message),
                onLongPress: () => _showMessageActions(message),
                onSecondaryTapUp: PlatformInfo.isDesktop
                    ? (_) => _showMessageActions(message)
                    : null,
                child: Container(
                  padding: gifId != null
                      ? const EdgeInsets.all(4)
                      : isJumboEmoji
                          ? EdgeInsets.zero
                          : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  decoration: BoxDecoration(
                    color: displayBubbleColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isOutgoing) ...[
                        Padding(
                          padding: gifId != null || isJumboEmoji
                              ? const EdgeInsets.only(
                                  left: 8,
                                  top: 4,
                                  bottom: 4,
                                )
                              : EdgeInsets.zero,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  message.senderName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: senderNameColors
                                        ? _getColorForName(message.senderName)
                                        : Theme.of(context)
                                            .colorScheme
                                            .primary,
                                  ),
                                ),
                              ),
                              // Some copy of this message was heard with
                              // zero hops: our radio heard THEIR radio, no
                              // repeater in between — worth celebrating.
                              // Latched, so the pill survives echo merges
                              // that adopt the longest path for display.
                              if (message.heardDirect) ...[
                                const SizedBox(width: 6),
                                _buildDirectPill(),
                              ],
                            ],
                          ),
                        ),
                        if (gifId == null) const SizedBox(height: 4),
                      ],
                      if (message.replyToSenderName != null) ...[
                        _buildReplyPreview(message, textScale),
                        const SizedBox(height: 8),
                      ],
                      if (poi != null)
                        _buildPoiMessage(
                          context,
                          poi,
                          isOutgoing,
                          textScale,
                          trailing: (!enableTracing && isOutgoing)
                              ? Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: MessageStatusIcon(
                                      isAcked:
                                          (message.status ==
                                              ChannelMessageStatus.sent ||
                                          message.status ==
                                              ChannelMessageStatus.delivered) &&
                                          displayPathString.isNotEmpty,
                                      isDelivered: message.status ==
                                          ChannelMessageStatus.delivered,
                                      isFailed:
                                          message.status ==
                                          ChannelMessageStatus.failed,
                                      isChannelMessage: true,
                                  ),
                                )
                              : null,
                        )
                      else ...[
                        if (cleanDisplayText.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: LinkHandler.buildLinkifyText(
                                  context: context,
                                  text: cleanDisplayText,
                                  style: TextStyle(
                                    fontSize: bodyFontSize * textScale,
                                  ),
                                ),
                              ),
                            if (orphanReaction != null) ...[
                              const SizedBox(width: 5),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                // Anchored to the icon, not the bubble: the
                                // bubble's own long-press opens the message
                                // actions sheet.
                                child: Tooltip(
                                  message: context.l10n
                                      .chat_reactionTargetMissing(
                                          message.senderName),
                                  triggerMode: TooltipTriggerMode.longPress,
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.add_reaction_outlined,
                                    size: 15 * textScale,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline,
                                  ),
                                ),
                              ),
                            ],
                            if (!enableTracing && isOutgoing) ...[
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: MessageStatusIcon(
                                  isAcked: (message.status ==
                                              ChannelMessageStatus.sent ||
                                          message.status ==
                                              ChannelMessageStatus.delivered) &&
                                      displayPathString.isNotEmpty,
                                  isDelivered: message.status ==
                                      ChannelMessageStatus.delivered,
                                  isFailed: message.status ==
                                      ChannelMessageStatus.failed,
                                  isChannelMessage: true,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (gifId != null) ...[
                          const SizedBox(height: 8),
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: uiState.renderGifs ? GifMessage(
                                  url:
                                      'https://media.giphy.com/media/$gifId/giphy.gif',
                                  backgroundColor: Colors.transparent,
                                  fallbackTextColor: isOutgoing
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withValues(alpha: 0.7)
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                ) : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isOutgoing
                                        ? Theme.of(context).colorScheme.primaryContainer
                                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.gif_box, 
                                        color: isOutgoing
                                            ? Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "GIF",
                                        style: TextStyle(
                                          color: isOutgoing
                                              ? Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!enableTracing && isOutgoing)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: isOutgoing
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                          : Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(10),
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: MessageStatusIcon(
                                      isAcked: (message.status ==
                                                  ChannelMessageStatus.sent ||
                                              message.status ==
                                                  ChannelMessageStatus.delivered) &&
                                          displayPathString.isNotEmpty,
                                      isDelivered: message.status ==
                                          ChannelMessageStatus.delivered,
                                      isFailed: message.status ==
                                          ChannelMessageStatus.failed,
                                      isChannelMessage: true,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                      if (enableTracing) ...[
                        if (displayPathString.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Padding(
                            padding: gifId != null
                                ? const EdgeInsets.symmetric(horizontal: 8)
                                : EdgeInsets.zero,
                            child: Text(
                              'via $displayPathString',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Padding(
                          padding: gifId != null
                              ? const EdgeInsets.only(
                                  left: 8,
                                  right: 8,
                                  bottom: 4,
                                )
                              : EdgeInsets.zero,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(message.timestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (message.repeatCount > 0) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.repeat,
                                  size: 12,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${message.repeatCount}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                              if (isOutgoing) ...[
                                const SizedBox(width: 4),
                                if (message.sendRetryCount > 0 &&
                                    connector.isChannelMessageRetrying(message.messageId) &&
                                    message.status !=
                                        ChannelMessageStatus.delivered) ...[
                                  Text(
                                    'Retrying (${message.sendRetryCount}/${settingsService.settings.maxChannelMessageRetries})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Icon(
                                  message.status == ChannelMessageStatus.delivered
                                      ? Icons.done_all
                                      : (message.status == ChannelMessageStatus.sent || 
                                         message.status == ChannelMessageStatus.failed)
                                          ? Icons.check
                                          : message.status == ChannelMessageStatus.pending
                                              ? Icons.schedule
                                              : Icons.error_outline,
                                  size: 14,
                                  color: message.status == ChannelMessageStatus.failed
                                      ? Colors.amber[700]
                                      : Colors.grey[600],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (message.reactions.isNotEmpty)
          // Chips ride up over the bubble's bottom edge, as in most
          // messaging apps, instead of floating below it.
          Transform.translate(
            offset: const Offset(0, -kReactionOverlap),
            child: Padding(
              padding: EdgeInsets.only(left: isOutgoing ? 0 : 48),
              child: _buildReactionsDisplay(message),
            ),
          ),
      ],
    );

    if (!isOutgoing && !PlatformInfo.isDesktop) {
      return _SwipeReplyBubble(
        maxSwipeOffset: maxSwipeOffset,
        replySwipeThreshold: replySwipeThreshold,
        onReplyTriggered: () => _setReplyingTo(message),
        onMentionTriggered: () => _insertMentionOf(message.senderName),
        hintBuilder: ({required mention}) => _buildSwipeHint(mention: mention),
        child: messageBody,
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: messageBody,
      );
    }
  }

  /// Hint behind a swiped bubble: reply rides the left swipe (label at the
  /// trailing edge, icon outermost), mention rides the right swipe (mirrored).
  Widget _buildSwipeHint({required bool mention}) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = Icon(
      mention ? Icons.alternate_email : Icons.reply,
      color: colorScheme.primary,
    );
    final label = Text(
      mention ? context.l10n.chat_mention : context.l10n.chat_reply,
      style: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );

    return Container(
      alignment: mention ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.primary.withValues(alpha: 0.08),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: mention
            ? [icon, const SizedBox(width: 6), label]
            : [label, const SizedBox(width: 6), icon],
      ),
    );
  }

  Widget _buildReplyPreview(ChannelMessage message, double textScale) {
    final connector = context.read<MeshCoreConnector>();
    final uiState = context.watch<UiViewStateService>();
    final isOwnNode = message.replyToSenderName == connector.selfName;
    final replyText = message.replyToText ?? '';
    final colorScheme = Theme.of(context).colorScheme;
    final previewTextColor = colorScheme.onSurface.withValues(alpha: 0.7);

    final gifId = GifHelper.parseGif(replyText);
    final poi = _parsePoiMessage(replyText);

    Widget contentPreview;
    if (gifId != null) {
      contentPreview = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: uiState.renderGifs ? GifMessage(
          url: 'https://media.giphy.com/media/$gifId/giphy.gif',
          backgroundColor: colorScheme.surfaceContainerHighest,
          fallbackTextColor: previewTextColor,
          maxSize: 80,
        ) : Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.gif_box, size: 14, color: previewTextColor),
              const SizedBox(width: 4),
              Text(
                "GIF",
                style: TextStyle(fontSize: 12 * textScale, color: previewTextColor),
              ),
            ],
          ),
        ),
      );
    } else if (poi != null) {
      contentPreview = Row(
        children: [
          Icon(Icons.location_on_outlined, size: 14, color: previewTextColor),
          const SizedBox(width: 4),
          Text(
            context.l10n.chat_location,
            style: TextStyle(fontSize: 12 * textScale, color: previewTextColor),
          ),
        ],
      );
    } else {
      // When the original message wasn't found locally, replyToText is the
      // truncated wire snippet with no trailing marker. Append it so the quote
      // doesn't end abruptly. Resolved messages (replyToMessageId != null) show
      // the full text and rely on ellipsis overflow instead.
      final isSnippet = message.replyToMessageId == null;
      final previewText = isSnippet && replyText.isNotEmpty
          ? '$replyText..'
          : replyText;
      contentPreview = Text(
        previewText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12 * textScale,
          color: previewTextColor,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return GestureDetector(
      onTap: message.replyToMessageId != null
          ? () => _scrollToMessage(message.replyToMessageId!)
          : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ChatColors.isLight(context)
              ? ChatColors.quoteBackground
              : colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: ChatColors.isLight(context)
                  ? ChatColors.quoteBorder
                  : colorScheme.secondary,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.chat_replyTo(message.replyToSenderName ?? ''),
              style: TextStyle(
                fontSize: 11 * textScale,
                fontWeight: FontWeight.bold,
                // Quoted sender wears their identity color too; own node
                // keeps the theme accent, like the composer reply banner.
                color: isOwnNode
                    ? Theme.of(context).colorScheme.secondary
                    : (context
                            .read<AppSettingsService>()
                            .settings
                            .senderNameColors
                        ? _getColorForName(message.replyToSenderName ?? '')
                        : Theme.of(context).colorScheme.onSecondaryContainer),
              ),
            ),
            const SizedBox(height: 2),
            contentPreview,
          ],
        ),
      ),
    );
  }

  Widget _buildReactionsDisplay(ChannelMessage message) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: message.reactions.entries.map((entry) {
        final emoji = entry.key;
        final count = entry.value;

        return GestureDetector(
          onTap: () => showReactionDetails(
            context,
            reactions: message.reactions,
            senders: message.reactionSenders,
            initialEmoji: emoji,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                if (count > 1) ...[
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  _PoiInfo? _parsePoiMessage(String text) {
    final trimmed = text.trim();
    final match = RegExp(
      r'm:([\-0-9.]+),([\-0-9.]+)\|([^|]*)\|',
    ).firstMatch(trimmed);
    if (match == null) return null;
    final lat = double.tryParse(match.group(1) ?? '');
    final lon = double.tryParse(match.group(2) ?? '');
    if (lat == null || lon == null) return null;
    final label = match.group(3) ?? '';
    return _PoiInfo(lat: lat, lon: lon, label: label);
  }

  Widget _buildPoiMessage(
    BuildContext context,
    _PoiInfo poi,
    bool isOutgoing,
    double textScale, {
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = isOutgoing
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;
    final metaColor = textColor.withValues(alpha: 0.7);
    final channelColor = widget.channel.isPublicChannel
        ? Colors.orange
        : Colors.blue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.location_on_outlined, color: channelColor),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MapScreen(
                  highlightPosition: LatLng(poi.lat, poi.lon),
                  highlightLabel: poi.label,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.chat_poiShared,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14 * textScale,
                ),
              ),
              if (poi.label.isNotEmpty)
                Text(
                  poi.label,
                  style: TextStyle(color: metaColor, fontSize: 12 * textScale),
                ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 4), trailing],
      ],
    );
  }

  void _showGifPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => GifPicker(
        onGifSelected: (gifId) {
          _textController.text = GifHelper.encodeGif(gifId);
        },
      ),
    );
  }

  Widget _buildAvatar(String senderName) {
    final initial = _getFirstCharacterOrEmoji(senderName);
    final color = _getColorForName(senderName);

    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withValues(alpha: 0.2),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _getFirstCharacterOrEmoji(String name) {
    if (name.isEmpty) return '?';

    final emoji = firstEmoji(name);
    if (emoji != null) return emoji;

    final runes = name.runes.toList();
    if (runes.isEmpty) return '?';
    return String.fromCharCode(runes[0]).toUpperCase();
  }

  Color _getColorForName(String name) {
    // Hue from the name hash — stable across sessions and devices. Shared
    // by the avatar, the sender name, and reply quotes so one person is one
    // color everywhere. Hand-curated, perceptually spaced hues: the
    // Material-swatch version put three near-identical purples and two
    // muddy neutrals in rotation, which read as constant collisions, and
    // its 300-shades were pastel where WhatsApp is vivid. Dark mode gets
    // the saturated tone; light mode re-derives the same hue at reading
    // depth. Two senders in a big channel can still share a hue; accepted.
    const palette = [
      Color(0xFFFF6B6B), // red
      Color(0xFFFF9F45), // orange
      Color(0xFFFFD166), // yellow
      Color(0xFFB5E361), // lime
      Color(0xFF5FD068), // green
      Color(0xFF2ED9C3), // teal
      Color(0xFF4DC9F0), // sky
      Color(0xFF5B9BFF), // blue
      Color(0xFF9D8CFF), // indigo
      Color(0xFFC77DFF), // purple
      Color(0xFFF368E0), // magenta
      // No pink: field-vetoed (2026-08-25) — reads as bubblegum on dark.
    ];
    final base = palette[name.hashCode.abs() % palette.length];
    if (!ChatColors.isLight(context)) return base;
    final hsl = HSLColor.fromColor(base);
    return hsl
        .withLightness((hsl.lightness - 0.28).clamp(0.30, 0.42))
        .toColor();
  }

  /// Tiny "Direct" pill for zero-hop messages — the packet's path is empty,
  /// so the RF we demodulated came straight from the sender's transmitter.
  /// Echo copies heard later merge into repeatCount/pathVariants and never
  /// overwrite the kept copy, so this stays honest alongside the ↻ counter.
  Widget _buildDirectPill() {
    final green = ChatColors.isLight(context)
        ? Colors.green.shade700
        : Colors.green.shade300;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: green.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Text(
        context.l10n.chat_direct,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: green,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildReplyBanner(double textScale) {
    final message = _replyingToMessage!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.reply,
            size: 18,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.chat_replyingTo(message.senderName),
                  style: TextStyle(
                    fontSize: 12 * textScale,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                _buildReplyBannerPreviewText(message, textScale),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _cancelReply,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Shows a human-readable preview of the reply target text in the composer
  /// banner, handling GIF tokens and POI messages instead of raw strings.
  Widget _buildReplyBannerPreviewText(ChannelMessage message, double textScale) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onPrimaryContainer.withValues(alpha: 0.8);

    final gifId = GifHelper.parseGif(message.text);
    if (gifId != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.gif_box, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text('GIF', style: TextStyle(fontSize: 11 * textScale, color: textColor, fontStyle: FontStyle.italic)),
        ],
      );
    }

    final poi = _parsePoiMessage(message.text);
    if (poi != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_outlined, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(context.l10n.chat_location, style: TextStyle(fontSize: 11 * textScale, color: textColor)),
        ],
      );
    }

    return Text(
      message.text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 11 * textScale, color: textColor),
    );
  }

  Widget _buildMessageComposer() {
    final connector = context.watch<MeshCoreConnector>();
    // Reserve room for the reply prefix ("@[Name]\n><snippet>..\n") while a
    // reply is active, so the byte counter and typing limit account for it.
    final baseMaxBytes = maxChannelMessageBytes(connector.selfName);
    final reply = _replyingToMessage;
    final replyOverhead = reply == null
        ? 0
        : utf8
              .encode(
                '@[${reply.senderName}]\n>'
                '${ChannelMessage.buildReplySnippet(reply.text, 10)}..\n',
              )
              .length;
    final maxBytes = (baseMaxBytes - replyOverhead).clamp(0, baseMaxBytes);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyingToMessage != null)
          Builder(
            builder: (context) {
              final textScale = context.select<ChatTextScaleService, double>(
                (service) => service.scale,
              );
              return _buildReplyBanner(textScale);
            },
          ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.gif_box),
                onPressed: () => _showGifPicker(context),
                tooltip: context.l10n.chat_sendGif,
              ),

              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textController,
                  builder: (context, value, child) {
                    final renderGifs = context.read<UiViewStateService>().renderGifs;
                    final gifId = GifHelper.parseGif(value.text);
                    if (gifId != null) {
                      return Focus(
                        autofocus: true,
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              (event.logicalKey == LogicalKeyboardKey.enter ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.numpadEnter)) {
                            _sendMessage();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: renderGifs ? GifMessage(
                                  url:
                                      'https://media.giphy.com/media/$gifId/giphy.gif',
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  fallbackTextColor: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                  maxSize: 160,
                                ) : Container(
                                  height: 60,
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.gif_box, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                                      const SizedBox(width: 8),
                                      Text(
                                        "GIF",
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _textController.clear();
                                _textFieldFocusNode.requestFocus();
                              },
                            ),
                          ],
                        ),
                      );
                    }
                    return Focus(
                      onKeyEvent: (node, event) {
                        if (PlatformInfo.isDesktop && event is KeyDownEvent) {
                          if (event.logicalKey == LogicalKeyboardKey.enter ||
                              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                            if (HardwareKeyboard.instance.isControlPressed ||
                                HardwareKeyboard.instance.isShiftPressed) {
                              final text = _textController.text;
                              final selection = _textController.selection;
                              final start = selection.start;
                              final end = selection.end;
                              if (start >= 0 && end >= 0) {
                                _textController.text = text.replaceRange(start, end, '\n');
                                _textController.selection = TextSelection.collapsed(offset: start + 1);
                              } else {
                                _textController.text += '\n';
                              }
                              return KeyEventResult.handled;
                            } else {
                              _sendMessage();
                              return KeyEventResult.handled;
                            }
                          }
                        }
                        return KeyEventResult.ignored;
                      },
                      child: ByteCountedTextField(
                        maxBytes: maxBytes,
                        controller: _textController,
                        focusNode: _textFieldFocusNode,
                        textInputAction: TextInputAction.newline,
                        onSubmitted: (_) => _sendMessage(),
                        encoder:
                            connector.isChannelSmazEnabled(widget.channel.index)
                            ? (text) => connector.prepareChannelOutboundText(
                                widget.channel.index,
                                text,
                              )
                            : null,
                        decoration: InputDecoration(
                          hintText: context.l10n.chat_typeMessage,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                tooltip: context.l10n.chat_sendMessage,
                onPressed: _sendMessage,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }



  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    if (_lastChannelSendAt != null &&
        now.difference(_lastChannelSendAt!) < const Duration(seconds: 1)) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chat_sendCooldown),
      );
      return;
    }
    _lastChannelSendAt = now;

    final connector = context.read<MeshCoreConnector>();
    final maxBytes = maxChannelMessageBytes(connector.selfName);
    final replyTarget = _replyingToMessage;

    bool fits(String candidate) {
      final outbound = connector.prepareChannelOutboundText(
        widget.channel.index,
        candidate,
      );
      return utf8.encode(outbound).length <= maxBytes;
    }

    String messageText;
    if (replyTarget != null) {
      // Build a compatible "@[Name]\n><snippet>..\n<text>" reply, shrinking the
      // snippet to fit the byte budget; fall back to a plain mention if needed.
      final built = ChannelMessage.buildReplyWireText(
        targetName: replyTarget.senderName,
        quoteText: replyTarget.text,
        body: text,
        selfName: connector.selfName ?? '',
        fits: fits,
      );
      if (built == null) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.chat_messageTooLong(maxBytes)),
        );
        return;
      }
      messageText = built;
    } else {
      messageText = text;
      if (!fits(messageText)) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.chat_messageTooLong(maxBytes)),
        );
        return;
      }
    }

    _textController.clear();
    _cancelReply();
    _textFieldFocusNode.requestFocus();
    connector.sendChannelMessage(
      widget.channel,
      messageText,
      replyTarget: replyTarget,
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showMessagePathInfo(ChannelMessage message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChannelMessagePathScreen(message: message, channelMessage: true),
      ),
    );
  }

  void _showMessageActions(ChannelMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: Text(context.l10n.chat_reply),
              onTap: () {
                Navigator.pop(sheetContext);
                _setReplyingTo(message);
              },
            ),
            if (PlatformInfo.isDesktop)
              ListTile(
                leading: const Icon(Icons.route),
                title: Text(context.l10n.chat_path),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showMessagePathInfo(message);
                },
              ),
            // Can't react to (or mention) your own messages
            if (!message.isOutgoing) ...[
              ListTile(
                leading: const Icon(Icons.add_reaction_outlined),
                title: Text(context.l10n.chat_addReaction),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showEmojiPicker(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.alternate_email),
                title: Text(context.l10n.chat_mention),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _insertMentionOf(message.senderName);
                },
              ),
              // No DM for unparsed senders: 'Unknown' is the parse fallback,
              // not a name anyone chose.
              if (message.senderName != 'Unknown')
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(context.l10n.dmChannel_menuLabel),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _startDmTo(message.senderName);
                  },
                ),
            ],
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(context.l10n.common_copy),
              onTap: () {
                Navigator.pop(sheetContext);
                // Keep brackets in clipboard for clarity (especially with emoji names)
                String textToCopy = message.text;
                _copyMessageText(textToCopy);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(context.l10n.common_delete),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _deleteMessage(message);
              },
            ),
            if (!message.isOutgoing) ...[
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ReportHelper.reportMessage(
                    context,
                    sender: message.senderName,
                    text: message.text,
                    timestamp: message.timestamp,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: Text('Block ${message.senderName}'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await context
                      .read<AppSettingsService>()
                      .blockSender(message.senderName);
                  if (mounted) {
                    showDismissibleSnackBar(
                      context,
                      content: Text('Blocked ${message.senderName}'),
                    );
                  }
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(context.l10n.common_cancel),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
          ),
        ),
      ),
    );
  }

  void _showEmojiPicker(ChannelMessage message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReactionPickerSheet(
        onEmojiSelected: (emoji) {
          _sendReaction(message, emoji);
        },
      ),
    );
  }

  void _sendReaction(ChannelMessage message, String emoji) {
    final connector = context.read<MeshCoreConnector>();
    // MeshCore One dialect: readable on every client, SHA-hashed target,
    // any emoji — no fixed table.
    connector.sendChannelMessage(
      widget.channel,
      MeshCoreConnector.channelReactionText(message, emoji),
    );
  }

  void _copyMessageText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.chat_messageCopied),
    );
  }

  Future<void> _deleteMessage(ChannelMessage message) async {
    await context.read<MeshCoreConnector>().deleteChannelMessage(message);
    if (!mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.chat_messageDeleted),
    );
  }

  bool _isOnlyEmojis(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    final noSpaces = trimmed.replaceAll(RegExp(r'\s+'), '');
    if (noSpaces.characters.length > 3) return false;

    // The analyzer's regex validator does not understand the \p{Emoji} binary
    // property, but Dart's engine does with unicode: true. An actually invalid
    // pattern would throw on construction; emoji_only_regex_test.dart proves
    // this one does not.
    // ignore: valid_regexps
    final RegExp emojiRegex = RegExp(r'^[\p{Emoji}\u200D\uFE0F\uFE0E\u20E3\s]+$', unicode: true);
    final RegExp hasLetter = RegExp(r'[\p{L}a-zA-Z0-9]', unicode: true);

    return emojiRegex.hasMatch(trimmed) && !hasLetter.hasMatch(trimmed);
  }
}

class _SwipeReplyBubble extends StatefulWidget {
  final double maxSwipeOffset;
  final double replySwipeThreshold;
  final VoidCallback onReplyTriggered;
  /// Optional swipe-right action; null keeps the bubble left-swipe only.
  final VoidCallback? onMentionTriggered;
  final Widget Function({required bool mention}) hintBuilder;
  final Widget child;

  const _SwipeReplyBubble({
    required this.maxSwipeOffset,
    required this.replySwipeThreshold,
    required this.onReplyTriggered,
    this.onMentionTriggered,
    required this.hintBuilder,
    required this.child,
  });

  @override
  State<_SwipeReplyBubble> createState() => _SwipeReplyBubbleState();
}

class _SwipeReplyBubbleState extends State<_SwipeReplyBubble> {
  Offset? _swipeStartPosition;
  double _swipeOffset = 0;
  int? _swipePointerId;
  bool _swipeLockedToHorizontal = false;
  // A vertical-dominant start is a scroll: ignore this touch entirely.
  bool _swipeRejected = false;
  // Finger is past the trigger threshold RIGHT NOW (release would commit).
  bool _swipeArmed = false;
  // Which way this gesture is going: -1 left (reply), +1 right (mention).
  int _swipeDirection = 0;

  bool get _mentionEnabled => widget.onMentionTriggered != null;

  void _handleSwipeStart(Offset position) {
    _swipeStartPosition = position;
    if (_swipeOffset != 0) {
      setState(() => _swipeOffset = 0);
    }
  }

  void _handleSwipePointerDown(PointerDownEvent event) {
    _swipePointerId = event.pointer;
    _swipeLockedToHorizontal = false;
    _swipeRejected = false;
    _swipeArmed = false;
    _swipeDirection = 0;
    _handleSwipeStart(event.position);
  }

  void _handleSwipePointerMove(PointerMoveEvent event) {
    if (_swipePointerId != event.pointer ||
        _swipeStartPosition == null ||
        _swipeRejected) {
      return;
    }

    final dx = event.position.dx - _swipeStartPosition!.dx;
    final dy = event.position.dy - _swipeStartPosition!.dy;

    const axisLockThreshold = 12.0;
    if (!_swipeLockedToHorizontal) {
      // Native feel: the swipe only claims the touch when horizontal
      // movement clearly dominates. A vertical-dominant start is the list
      // scrolling — reject the touch for good so a mid-scroll thumb arc
      // can never turn into a reply.
      if (dy.abs() >= axisLockThreshold && dy.abs() >= dx.abs()) {
        _swipeRejected = true;
        return;
      }
      if (dx.abs() < axisLockThreshold || dx.abs() < dy.abs() * 1.5) {
        return;
      }
      if (dx < 0) {
        _swipeDirection = -1;
      } else if (_mentionEnabled) {
        _swipeDirection = 1;
      } else {
        _swipeRejected = true;
        return;
      }
      _swipeLockedToHorizontal = true;
    }

    _handleSwipeUpdate(event.position);
  }

  void _handleSwipeUpdate(Offset position) {
    if (_swipeStartPosition == null) return;

    // Progress along the locked direction; movement the other way resets to 0.
    final dx =
        (position.dx - _swipeStartPosition!.dx) * _swipeDirection;
    final travel = dx < 6 ? 0.0 : dx;

    // Armed = releasing now would commit. Crossing the line gives the
    // little haptic tick native apps use; sliding back disarms silently.
    final armed = travel >= widget.replySwipeThreshold;
    if (armed && !_swipeArmed) {
      HapticFeedback.lightImpact();
    }
    _swipeArmed = armed;

    final clamped = travel.clamp(0.0, widget.maxSwipeOffset);
    final adjusted =
        _applySwipeResistance(clamped, widget.maxSwipeOffset) *
        _swipeDirection;
    if (adjusted != _swipeOffset) {
      setState(() => _swipeOffset = adjusted);
    }
  }

  void _handleSwipePointerUp(Offset position) {
    // Commit on where the finger IS at release, never on how far it once
    // got: overshooting and pulling back means "never mind".
    if (_swipeLockedToHorizontal && _swipeStartPosition != null) {
      final dx =
          (position.dx - _swipeStartPosition!.dx) * _swipeDirection;
      if (dx >= widget.replySwipeThreshold) {
        if (_swipeDirection < 0) {
          widget.onReplyTriggered();
        } else {
          widget.onMentionTriggered?.call();
        }
        HapticFeedback.selectionClick();
      }
    }
    _resetSwipe();
  }

  void _resetSwipe() {
    if (_swipeOffset != 0) {
      setState(() => _swipeOffset = 0);
    }
    _swipeStartPosition = null;
    _swipePointerId = null;
    _swipeLockedToHorizontal = false;
    _swipeRejected = false;
    _swipeArmed = false;
    _swipeDirection = 0;
  }

  double _applySwipeResistance(double rawOffset, double maxOffset) {
    final abs = rawOffset.abs();
    if (abs <= 0) return 0;
    final norm = (abs / maxOffset).clamp(0.0, 1.0);
    const deadZone = 0.18;
    if (norm <= deadZone) {
      return rawOffset.sign * maxOffset * (norm * 0.08);
    }
    final t = ((norm - deadZone) / (1 - deadZone)).clamp(0.0, 1.0);
    final curved = t < 0.5
        ? 16 * math.pow(t, 5)
        : 1 - math.pow(-2 * t + 2, 5) / 2;
    const deadZoneEnd = 0.0144;
    return rawOffset.sign *
        maxOffset *
        (deadZoneEnd + curved * (1 - deadZoneEnd));
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handleSwipePointerDown,
      onPointerMove: _handleSwipePointerMove,
      onPointerUp: (event) => _handleSwipePointerUp(event.position),
      onPointerCancel: (_) => _resetSwipe(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: _swipeOffset.abs() / widget.maxSwipeOffset,
                child: widget.hintBuilder(mention: _swipeDirection > 0),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.translationValues(_swipeOffset, 0, 0),
              curve: Curves.easeOut,
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}

class _PoiInfo {
  final double lat;
  final double lon;
  final String label;

  const _PoiInfo({required this.lat, required this.lon, required this.label});
}

// ==========================================
// Custom Controller for Rich Text Mentions
// ==========================================
class MentionTextEditingController extends TextEditingController {
  final RegExp _mentionRegex = RegExp(r'@\[([^\]]+)\]');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<TextSpan> spans = [];
    int start = 0;

    for (final Match match in _mentionRegex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start), style: style));
      }
      spans.add(TextSpan(
        text: '@[${match.group(1)}]', // Keep brackets visible for the user
        style: style?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }

    return TextSpan(children: spans, style: style);
  }
}