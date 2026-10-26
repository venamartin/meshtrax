import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../connector/meshcore_connector.dart';
import '../utils/platform_info.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/gif_helper.dart';
import '../helpers/reaction_helper.dart';
import '../helpers/report_helper.dart';
import '../helpers/snack_bar_builder.dart';
import '../helpers/markdown_helper.dart';
import '../widgets/message_text.dart';
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
import '../widgets/clear_chat_dialog.dart';
import '../widgets/message_actions.dart';
import '../widgets/connection_status_banner.dart';
import '../widgets/contact_tile.dart';
import '../widgets/reaction_picker_sheet.dart';
import '../widgets/gif_message.dart';
import '../widgets/gif_picker.dart';
import '../widgets/mention_composer.dart';
import '../widgets/message_status_icon.dart';
import '../widgets/gps_status_button.dart';
import '../widgets/swipe_reply_bubble.dart';
import '../helpers/structured_message.dart';
import '../services/short_link_resolver.dart';
import '../widgets/composer_attach_tray.dart';
import '../widgets/paste_conversion_bar.dart';
import '../widgets/pinned_messages_bar.dart';
import '../widgets/structured_message_card.dart';
import '../widgets/structured_message_dialogs.dart';
import '../widgets/reaction_details_sheet.dart';
import 'channel_message_path_screen.dart';
import 'channel_share_screen.dart';
import 'chat_screen.dart';

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
  bool _trayOpen = false;
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

  // In-channel search. Matches come from the FULL stored history (the
  // watched window only pages the visible list); jumping to a match
  // outside the window grows _watchLimit until the row is loaded.
  bool _searchActive = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  List<({ChannelMessage message, int fromNewest})> _searchMatches = const [];
  int _searchPos = -1;
  String? _pendingSearchJumpId;

  void _subscribeMessages(MeshCoreConnector connector) {
    _messagesSub?.cancel();
    _messagesSub = connector
        .watchChannelMessages(widget.channel, limit: _watchLimit)
        .listen((messages) {
      if (!mounted) return;
      // A search jump whose target was outside the watched window waits
      // here for the grown window to deliver the row.
      final pendingJump = _pendingSearchJumpId;
      if (pendingJump != null &&
          messages.any((m) => m.messageId == pendingJump)) {
        _pendingSearchJumpId = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToMessage(pendingJump);
        });
      }
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

  /// Where the half-typed message waits while the chat is closed.
  late final UiViewStateService _drafts;

  void _keepDraft() =>
      _drafts.setDraft(widget.channel.idKey, _textController.text);

  @override
  void initState() {
    super.initState();
    _textFieldFocusNode.addListener(_closeTrayOnFocus);
    ShortLinkResolver.instance.addListener(_onShortLinkResolved);
    _textFieldFocusNode.addListener(_onTextFieldFocusChange);
    _itemPositionsListener.itemPositions.addListener(_scrollListener);
    // Before the mentions listener: a restored "@" must not open the list.
    _drafts = context.read<UiViewStateService>();
    _textController.text = _drafts.draft(widget.channel.idKey);
    _textController.addListener(_keepDraft);
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
                pathHashSize: connector.pathHashByteWidth,
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

  bool _startsWithEmoji(String name) {
    if (name.isEmpty) return false;
    return firstEmoji(name.characters.first) != null;
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
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _itemPositionsListener.itemPositions.removeListener(_scrollListener);
    _connector?.setActiveChannel(null);
    _textFieldFocusNode.removeListener(_onTextFieldFocusChange);
    _textController.removeListener(_mentionsListener);
    _textController.removeListener(_keepDraft);
    _drafts.leaveDraft(widget.channel.idKey, _textController.text);
    _textFieldFocusNode.removeListener(_closeTrayOnFocus);
    ShortLinkResolver.instance.removeListener(_onShortLinkResolved);
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

  void _openSearch() {
    setState(() => _searchActive = true);
    _searchFocusNode.requestFocus();
  }

  void _closeSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _searchActive = false;
      _searchMatches = const [];
      _searchPos = -1;
      _pendingSearchJumpId = null;
    });
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    // The RAW query goes through: a space at either edge means "word
    // boundary" to the store's matcher, so trimming here would erase it.
    _searchDebounce = Timer(
      const Duration(milliseconds: 250),
      () => _runSearch(query),
    );
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    if (query.trim().isEmpty) {
      setState(() {
        _searchMatches = const [];
        _searchPos = -1;
      });
      return;
    }
    final connector = context.read<MeshCoreConnector>();
    final settingsService = context.read<AppSettingsService>();
    // SQL does the heavy lifting (text + sender names, newest first) —
    // the full history is never loaded here.
    final found = await connector.searchChannelMessages(widget.channel, query);
    if (!mounted || query != _searchController.text) return;
    final matches = <({ChannelMessage message, int fromNewest})>[
      for (final f in found)
        if (f.message.isOutgoing ||
            !settingsService.isSenderBlocked(f.message.senderName))
          f,
    ];
    setState(() {
      _searchMatches = matches;
      _searchPos = matches.isEmpty ? -1 : 0;
    });
    if (matches.isNotEmpty) _jumpToMatch(0);
  }

  /// [delta] +1 steps to an older match, -1 to a newer one. Clamps at the
  /// ends — wrapping around made the arrows feel reversed (UP at the
  /// oldest match visually jumped DOWN to the newest).
  void _searchStep(int delta) {
    final next = _searchPos + delta;
    if (next < 0 || next >= _searchMatches.length) return;
    _jumpToMatch(next);
  }

  bool get _searchHasOlder => _searchPos >= 0 && _searchPos < _searchMatches.length - 1;
  bool get _searchHasNewer => _searchPos > 0;

  void _jumpToMatch(int pos) {
    final match = _searchMatches[pos];
    setState(() => _searchPos = pos);
    if (_messages.any((m) => m.messageId == match.message.messageId)) {
      _scrollToMessage(match.message.messageId);
      return;
    }
    // Outside the watched window: grow it past the target and jump when
    // the subscription delivers the row (see _subscribeMessages).
    final needed = ((match.fromNewest + 51) ~/ 200 + 1) * 200;
    if (needed > _watchLimit) _watchLimit = needed;
    _pendingSearchJumpId = match.message.messageId;
    _subscribeMessages(context.read<MeshCoreConnector>());
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
    return PopScope(
      canPop: !_searchActive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeSearch();
      },
      child: Scaffold(
      backgroundColor: ChatColors.isLight(context) ? ChatColors.background : null,
      appBar: AppBar(
        title: _searchActive
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                onSubmitted: (_) {
                  _searchStep(1);
                  _searchFocusNode.requestFocus();
                },
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: context.l10n.chat_searchMessages,
                  border: InputBorder.none,
                ),
              )
            : Row(
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
        actions: _searchActive
            ? [
                if (_searchController.text.trim().isNotEmpty)
                  Center(
                    child: Text(
                      _searchMatches.isEmpty
                          ? context.l10n.chat_searchNoMatches
                          : '${_searchPos + 1}/${_searchMatches.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up),
                  onPressed: _searchHasOlder ? () => _searchStep(1) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: _searchHasNewer ? () => _searchStep(-1) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _closeSearch,
                ),
              ]
            : [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: context.l10n.chat_searchMessages,
            onPressed: _openSearch,
          ),
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
          const GpsStatusButton(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clearChat') {
                final connector = context.read<MeshCoreConnector>();
                ClearChatDialog.show(context).then((choice) {
                  if (choice == null) return;
                  connector.clearMessagesForChannel(
                    widget.channel.index,
                    olderThan: choice.olderThan,
                  );
                });
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
            Consumer<MeshCoreConnector>(
              builder: (context, connector, _) =>
                  ConnectionStatusBanner.ifDisconnected(context, connector) ??
                  ConnectionStatusBanner.ifSecondApp(context, connector) ??
                  const SizedBox.shrink(),
            ),
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

                  final pinnedBar = _buildPinnedBar(messages);
                  return Column(
                    children: [
                      ?pinnedBar,
                      Expanded(
                        child: Stack(
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

                              final focusedMatchId =
                                  _searchActive && _searchPos >= 0
                                      ? _searchMatches[_searchPos]
                                          .message
                                          .messageId
                                      : null;
                              if (message.messageId == focusedMatchId) {
                                currentWidget = Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: currentWidget,
                                );
                              }

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
                  ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (_showMentions)
              MentionsOverlay(
                contacts: _filteredMentionContacts,
                onSelect: _insertMention,
              ),
            _buildMessageComposer(),
          ],
        ),
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
    final enableTracing = settingsService.settings.enableMessageTracing;
    final senderNameColors = settingsService.settings.senderNameColors;
    final isOutgoing = message.isOutgoing;
    final gifId = GifHelper.parseGif(message.text);
    final structured = StructuredMessage.parse(
      message.text,
      resolveShortLink: ShortLinkResolver.instance.cached,
    );
    if (structured == null) ShortLinkResolver.instance.prefetchIn(message.text);
    // An unresolved reaction shows what it reacted with and to — never the
    // Crockford hash line, which means nothing to a reader.
    final cleanDisplayText = orphanReaction != null
        ? (orphanReaction.targetSender != null
                ? '@[${orphanReaction.targetSender}]'
                : '') +
            orphanReaction.emoji
        : GifHelper.stripGif(message.text);
    final displayPathString = message.pathBytes.isNotEmpty
        ? message.displayPathString
        : (message.pathVariants.isNotEmpty
              ? message.displayPathVariants.first
              : "");

    final isJumboEmoji =
        gifId == null && structured == null && isEmojiOnly(message.text);
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
                child: Container(
                  padding: structured != null
                      ? const EdgeInsets.fromLTRB(14, 12, 14, 10)
                      : gifId != null
                          ? const EdgeInsets.all(4)
                          : isJumboEmoji
                              ? EdgeInsets.zero
                              : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: BoxConstraints(
                    maxWidth: structured != null
                        ? StructuredMessageCard.maxBubbleWidth(context)
                        : MediaQuery.of(context).size.width * 0.65,
                  ),
                  decoration: structured != null
                      ? StructuredMessageCard.bubbleDecoration(context, structured)
                      : BoxDecoration(
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
                      if (structured != null) ...[
                        StructuredMessageCard(
                          message: structured,
                          textScale: textScale,
                          isOutgoing: isOutgoing,
                          senderName: message.senderName,
                        ),
                        if (enableTracing || isOutgoing)
                          StructuredCardFooter(
                            message: structured,
                            time: enableTracing
                                ? _formatTime(message.timestamp)
                                : null,
                            path: enableTracing ? displayPathString : null,
                            repeats: enableTracing ? message.repeatCount : 0,
                            extra: [
                              if (enableTracing &&
                                  isOutgoing &&
                                  _isRetrying(message))
                                'Retrying (${message.sendRetryCount}/${settingsService.settings.maxChannelMessageRetries})',
                            ],
                            status: !isOutgoing
                                ? null
                                : enableTracing
                                    ? _tracingStatusIcon(message)
                                    : _statusIcon(message, displayPathString),
                          ),
                      ] else ...[
                        if (cleanDisplayText.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                // Large emoji shrink only when they would
                                // not fit the bubble.
                                child: isJumboEmoji
                                    ? FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: Text(
                                          cleanDisplayText,
                                          style: TextStyle(
                                            fontSize: bodyFontSize * textScale,
                                          ),
                                        ),
                                      )
                                    : MessageText(
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
                                child: _statusIcon(message, displayPathString),
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
                                    child: _statusIcon(message, displayPathString),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                      if (enableTracing && structured == null) ...[
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
                                if (_isRetrying(message)) ...[
                                  Text(
                                    'Retrying (${message.sendRetryCount}/${settingsService.settings.maxChannelMessageRetries})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                _tracingStatusIcon(message),
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
      return SwipeReplyBubble(
        maxSwipeOffset: maxSwipeOffset,
        replySwipeThreshold: replySwipeThreshold,
        onReplyTriggered: () => _setReplyingTo(message),
        onMentionTriggered: () => _insertMentionOf(message.senderName),
        hintBuilder: ({required mention}) => SwipeHint(mention: mention),
        child: messageBody,
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        // Desktop: a right-click anywhere on the message, text included.
        child: ContextMenuRegion(
          onContextMenu: PlatformInfo.isDesktop
              ? (at) => _showMessageActions(message, at: at)
              : null,
          child: messageBody,
        ),
      );
    }
  }

  bool _isRetrying(ChannelMessage message) =>
      message.sendRetryCount > 0 &&
      context.read<MeshCoreConnector>().isChannelMessageRetrying(message.messageId) &&
      message.status != ChannelMessageStatus.delivered;

  Widget _statusIcon(ChannelMessage message, String displayPathString) =>
      MessageStatusIcon(
        isAcked: (message.status == ChannelMessageStatus.sent ||
                message.status == ChannelMessageStatus.delivered) &&
            displayPathString.isNotEmpty,
        isDelivered: message.status == ChannelMessageStatus.delivered,
        isFailed: message.status == ChannelMessageStatus.failed,
        isChannelMessage: true,
      );

  Widget _tracingStatusIcon(ChannelMessage message) => Icon(
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
      );

  Widget _buildReplyPreview(ChannelMessage message, double textScale) {
    final connector = context.read<MeshCoreConnector>();
    final uiState = context.watch<UiViewStateService>();
    final isOwnNode = message.replyToSenderName == connector.selfName;
    final replyText = message.replyToText ?? '';
    final colorScheme = Theme.of(context).colorScheme;
    final previewTextColor = colorScheme.onSurface.withValues(alpha: 0.7);

    final gifId = GifHelper.parseGif(replyText);
    final structured = StructuredMessage.parse(replyText);

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
    } else if (structured != null) {
      contentPreview = Row(
        children: [
          Icon(
            StructuredMessageCard.iconFor(structured),
            size: 14,
            color: StructuredPalette.of(context, structured).ink,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              structured.summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12 * textScale, color: previewTextColor),
            ),
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
        MarkdownHelper.toPlainText(
          previewText,
          formatting:
              context.read<AppSettingsService>().settings.showTextFormatting,
        ),
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

  void _onShortLinkResolved() {
    if (mounted) setState(() {});
  }

  void _toggleTray() {
    if (!_trayOpen) _textFieldFocusNode.unfocus();
    setState(() => _trayOpen = !_trayOpen);
  }

  void _closeTrayOnFocus() {
    if (_textFieldFocusNode.hasFocus && _trayOpen) {
      setState(() => _trayOpen = false);
    }
  }

  /// Puts [text] in the composer and closes the tray. The keyboard stays
  /// down: a dialog just closed, and asking for the keyboard while Android
  /// is still hiding it leaves a black gap where the keyboard should be.
  void _insertComposerText(String text) {
    _textController.text = text;
    _textController.selection = TextSelection.collapsed(offset: text.length);
    setState(() => _trayOpen = false);
  }

  Future<void> _runTile(Future<String?> Function() build) async {
    final wire = await build();
    if (!mounted || wire == null) return;
    _insertComposerText(wire);
  }

  Widget _buildAttachTray(MeshCoreConnector connector) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return ComposerAttachTray(
      tiles: [
        AttachTile(
          icon: Icons.gif_box,
          label: l10n.tray_gif,
          onTap: () {
            setState(() => _trayOpen = false);
            _showGifPicker(context);
          },
        ),
        AttachTile(
          icon: Icons.my_location,
          label: l10n.tray_myLocation,
          onTap: () => _runTile(
            () => StructuredMessageDialogs.myLocation(context, connector),
          ),
        ),
        AttachTile(
          icon: Icons.place,
          label: l10n.tray_pointOnMap,
          onTap: () =>
              _runTile(() => StructuredMessageDialogs.pointOnMap(context)),
        ),
        AttachTile(
          icon: Icons.warning_rounded,
          label: l10n.tray_sos,
          color: scheme.errorContainer,
          onTap: () =>
              _runTile(() => StructuredMessageDialogs.sos(context, connector)),
        ),
        AttachTile(
          icon: Icons.event,
          label: l10n.tray_event,
          onTap: () => _runTile(() => StructuredMessageDialogs.event(context)),
        ),
        AttachTile(
          icon: Icons.campaign,
          label: l10n.tray_notice,
          onTap: () => _runTile(() => StructuredMessageDialogs.notice(context)),
        ),
      ],
    );
  }

  /// SOS and the next upcoming Event, pinned above the list until dismissed.
  /// Only the newest 200 messages are read.
  Widget? _buildPinnedBar(List<ChannelMessage> messages) {
    final uiState = context.watch<UiViewStateService>();
    final chatId = widget.channel.idKey;
    final total = messages.length;
    final start = total > 200 ? total - 200 : 0;
    final candidates = <PinCandidate>[
      for (var i = start; i < total; i++)
        PinCandidate(
          id: messages[i].messageId,
          text: messages[i].text,
          timestamp: messages[i].timestamp,
          index: total - 1 - i,
        ),
    ];
    final entries = PinnedMessagesBar.compute(
      candidates: candidates,
      dismissed: uiState.dismissedPins(chatId),
      isRoom: false,
      resolveShortLink: ShortLinkResolver.instance.cached,
    );
    if (entries.isEmpty) return null;
    return PinnedMessagesBar(
      entries: entries,
      onTap: (e) {
        if (!_itemScrollController.isAttached) return;
        _itemScrollController.scrollTo(
          index: e.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
      onDismiss: (e) => uiState.dismissPin(chatId, e.id),
    );
  }

  void _showGifPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => GifPicker(
        onGifSelected: (gifId) {
          _textController.text = GifHelper.encodeGif(
            gifId,
            asLink: context.read<UiViewStateService>().sendGifsAsLinks,
          );
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

    final structured = StructuredMessage.parse(message.text);
    if (structured != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(StructuredMessageCard.iconFor(structured), size: 14, color: StructuredPalette.of(context, structured).ink),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              structured.summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11 * textScale, color: textColor),
            ),
          ),
        ],
      );
    }

    return Text(
      MarkdownHelper.toPlainText(
        message.text,
        formatting:
            context.read<AppSettingsService>().settings.showTextFormatting,
      ),
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
        PasteConversionBar(
          controller: _textController,
          onReplace: _insertComposerText,
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
              ComposerActionButton(
                controller: _textController,
                trayOpen: _trayOpen,
                onToggleTray: _toggleTray,
                onSend: _sendMessage,
                sendTooltip: context.l10n.chat_sendMessage,
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: _trayOpen
              ? _buildAttachTray(connector)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }



  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final connector = context.read<MeshCoreConnector>();
    if (!_warnIfDisconnected(connector)) return;

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

  /// The message's actions: a sheet after a long-press, a menu at [at]
  /// after a right-click on desktop.
  void _showMessageActions(ChannelMessage message, {Offset? at}) {
    final l10n = context.l10n;
    showMessageActions(context, position: at, [
      MessageAction(Icons.reply, l10n.chat_reply, () => _setReplyingTo(message)),
      if (PlatformInfo.isDesktop)
        MessageAction(
            Icons.route, l10n.chat_path, () => _showMessagePathInfo(message)),
      // Can't react to (or mention) your own messages
      if (!message.isOutgoing) ...[
        MessageAction(Icons.add_reaction_outlined, l10n.chat_addReaction,
            () => _showEmojiPicker(message)),
        MessageAction(Icons.alternate_email, l10n.chat_mention,
            () => _insertMentionOf(message.senderName)),
        // No DM for unparsed senders: 'Unknown' is the parse fallback,
        // not a name anyone chose.
        if (message.senderName != 'Unknown')
          MessageAction(Icons.chat_bubble_outline, l10n.dmChannel_menuLabel,
              () => _startDmTo(message.senderName)),
      ],
      // Keep brackets in clipboard for clarity (especially with emoji names)
      MessageAction(
          Icons.copy, l10n.common_copy, () => _copyMessageText(message.text)),
      MessageAction(Icons.delete_outline, l10n.common_delete,
          () => _deleteMessage(message)),
      if (!message.isOutgoing) ...[
        MessageAction(
          Icons.flag_outlined,
          'Report',
          () => ReportHelper.reportMessage(
            context,
            sender: message.senderName,
            text: message.text,
            timestamp: message.timestamp,
          ),
        ),
        MessageAction(Icons.block, 'Block ${message.senderName}', () async {
          await context
              .read<AppSettingsService>()
              .blockSender(message.senderName);
          if (mounted) {
            showDismissibleSnackBar(
              context,
              content: Text('Blocked ${message.senderName}'),
            );
          }
        }),
      ],
    ]);
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

  /// The connector drops sends silently while disconnected; the user has to
  /// hear about it, and their text has to stay in the box.
  bool _warnIfDisconnected(MeshCoreConnector connector) {
    if (connector.isConnected) return true;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.chat_notConnected),
    );
    return false;
  }

  void _sendReaction(ChannelMessage message, String emoji) {
    final connector = context.read<MeshCoreConnector>();
    if (!_warnIfDisconnected(connector)) return;
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
}
