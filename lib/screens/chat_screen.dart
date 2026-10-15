import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:meshtrax/screens/path_trace_map.dart';
import 'package:provider/provider.dart';

import '../utils/platform_info.dart';
import 'package:latlong2/latlong.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/reaction_helper.dart';
import '../widgets/message_status_icon.dart';
import '../helpers/gif_helper.dart';
import '../helpers/path_helper.dart';
import '../helpers/link_handler.dart';
import '../models/channel_message.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../models/path_selection.dart';
import '../services/app_settings_service.dart';
import '../services/message_retry_service.dart';
import '../services/chat_text_scale_service.dart';
import '../services/server_login_service.dart';
import '../services/storage_service.dart';
import '../services/ui_view_state_service.dart';
import '../widgets/chat_zoom_wrapper.dart';
import '../widgets/connection_status_banner.dart';
import '../widgets/routing_dialog.dart';
import '../widgets/byte_count_input.dart';
import 'channel_message_path_screen.dart';
import 'map_screen.dart';
import 'repeater_hub_screen.dart';
import '../utils/chat_colors.dart';
import '../utils/emoji_utils.dart';
import '../widgets/reaction_picker_sheet.dart';
import '../widgets/gif_message.dart';
import '../widgets/gif_picker.dart';
import '../widgets/mention_composer.dart';
import '../widgets/room_login_dialog.dart';
import '../widgets/radio_stats_entry.dart';
import '../widgets/swipe_reply_bubble.dart';
import '../l10n/l10n.dart';
import '../helpers/report_helper.dart';
import '../helpers/snack_bar_builder.dart';
import '../widgets/reaction_details_sheet.dart';
import 'telemetry_screen.dart';

class ChatScreen extends StatefulWidget {
  final Contact contact;
  final int? unreadCount;

  const ChatScreen({super.key, required this.contact, this.unreadCount});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = MentionTextEditingController();
  final _textFieldFocusNode = FocusNode();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  // Reply/mention state — rooms only; a 1-on-1 DM has no one to address.
  Message? _replyingToMessage;
  bool _showMentions = false;
  String? _mentionSearchText;
  List<Contact> _filteredMentionContacts = [];
  // Memoized resolved-author list — rebuilt when the message list changes.
  Map<String, Contact>? _cachedRoomAuthorMap;
  int _cachedAuthorMapMessageCount = -1;

  /// Reply row id → index of the quoted post in the displayed (reversed)
  /// list, -1 when it isn't loaded. Rebuilt when the message list changes.
  final Map<String, int> _replyTargetCache = {};
  List<Message>? _replyTargetCacheSource;
  int _replyTargetCacheLength = -1;

  bool get _isRoom => widget.contact.type == advTypeRoom;

  /// Last persisted ACL permissions byte for this room — a restart hint
  /// until a live login event replaces it.
  int? _storedRoomPerms;
  bool _clockBannerDismissed = false;

  bool _isLoadingOlder = false;
  MeshCoreConnector? _connector;
  Message? _firstUnreadMessage;

  /// Unread count captured synchronously at screen open. The first database
  /// emission can land after setActiveContact has already marked the chat
  /// read, so asking the connector then would always see zero — the race
  /// that kept the NEW MESSAGES divider from arming on entry paths that
  /// don't pass an unread count (room login flow, open-chat-with-author).
  int _unreadAtOpen = 0;
  int _initialScrollIndex = 0;
  bool _isAtBottom = true;
  DateTime? _lastTextSendAt;
  int _previousMessageCount = 0;

  /// The watched database query is the screen's only message source
  /// (Phase 3d) — ordering and paging belong to SQL.
  List<Message> _messages = const [];
  StreamSubscription<List<Message>>? _messagesSub;
  int _watchLimit = 200;
  bool _didInitialAnchor = false;

  void _subscribeMessages(MeshCoreConnector connector) {
    _messagesSub?.cancel();
    _messagesSub = connector
        .watchConversation(widget.contact, limit: _watchLimit)
        .listen((messages) {
      if (!mounted) return;
      setState(() {
        _messages = messages;
        if (!_didInitialAnchor) {
          _didInitialAnchor = true;
          _previousMessageCount = messages.length;
          final settings = context.read<AppSettingsService>().settings;
          final unread = _unreadAtOpen;
          if (unread > 0) {
            // The NEW MESSAGES divider always marks the oldest unread; the
            // setting only decides whether the list opens scrolled to it.
            _firstUnreadMessage = _findOldestUnreadAnchor(messages, unread);
            if (settings.jumpToOldestUnread && _firstUnreadMessage != null) {
              final idx =
                  messages.reversed.toList().indexOf(_firstUnreadMessage!);
              if (idx != -1) {
                _initialScrollIndex = idx;
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

    final connector = context.read<MeshCoreConnector>();
    _unreadAtOpen = widget.unreadCount ??
        connector.getUnreadCountForContactKey(widget.contact.publicKeyHex);
    _subscribeMessages(connector);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      connector.setActiveContact(widget.contact.publicKeyHex);
      _connector = connector;
    });

    if (widget.contact.type == advTypeRoom) {
      _textController.addListener(_mentionsListener);
      _restoreRoomAdminSession(connector);
      StorageService().getRoomPermissions(widget.contact.publicKeyHex).then(
        (perms) {
          if (mounted && perms != null) {
            setState(() => _storedRoomPerms = perms);
          }
        },
      );
      _autoLoginRoom(connector);
    }
  }

  static const _roomLoginFreshFor = Duration(minutes: 10);

  /// The stock app logs in each time a room is opened; so do we, silently,
  /// with the password that last worked. A login is also how the radio
  /// learns a route to a room (a flooded login is answered with a PATH), so
  /// this is what brings a room back from "Flood (auto)" after a lost route.
  Future<void> _autoLoginRoom(MeshCoreConnector connector) async {
    final keyHex = widget.contact.publicKeyHex;
    final last = connector.lastRoomLoginEvent(keyHex);
    if (last != null &&
        last.success &&
        DateTime.now().difference(last.at) < _roomLoginFreshFor) {
      return;
    }
    final password = await StorageService().getRepeaterPassword(keyHex);
    if (password == null || !mounted) return;
    if (!connector.isConnected || connector.hasSendsInFlight) return;
    final room = _resolveContact(connector);
    final login = ServerLoginService(connector);
    final outcome = await login.login(
      room,
      password,
      maxAttempts: 2,
      tag: 'RoomAutoLogin',
    );
    if (outcome.success == true) {
      await login.rememberRoomLogin(room, password, outcome);
    }
  }

  /// Role in this room (0 guest, 1 read-only, 2 member, 3 admin), from the
  /// live login event when there is one, else the persisted hint.
  int? _roomRole(MeshCoreConnector connector) {
    if (!_isRoom) return null;
    final live =
        connector.lastMeasuredRoomLogin(widget.contact.publicKeyHex)?.role;
    return live ?? (_storedRoomPerms == null ? null : _storedRoomPerms! & 0x3);
  }

  String? _roomRoleLabel(int? role) {
    switch (role) {
      case 3:
        return context.l10n.room_roleAdmin;
      case 2:
        return context.l10n.room_roleMember;
      case 1:
      case 0:
        return context.l10n.room_roleReadOnly;
      default:
        return null;
    }
  }

  /// The room's ACL keeps admin clients across restarts, but the in-memory
  /// admin session dies with the app. If the last saved-password login was as
  /// admin, restore the session so the manage entry reappears.
  Future<void> _restoreRoomAdminSession(MeshCoreConnector connector) async {
    final keyHex = widget.contact.publicKeyHex;
    if (connector.roomAdminPassword(keyHex) != null) return;
    final storage = StorageService();
    if (!await storage.isRoomAdmin(keyHex)) return;
    final password = await storage.getRepeaterPassword(keyHex);
    if (password == null) return;
    connector.recordRoomLogin(keyHex, password, true);
  }

  Message? _findOldestUnreadAnchor(List<Message> messages, int unreadCount) {
    if (unreadCount <= 0 || messages.isEmpty) return null;
    var n = 0;
    Message? oldest;
    for (final m in messages.reversed) {
      if (m.isOutgoing || m.isCli) continue;
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

  void _setReplyingTo(Message message) {
    setState(() {
      _replyingToMessage = message;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToMessage = null;
    });
  }

  /// The `@[name]` a reply or mention of [message] goes on the wire with.
  /// An unresolved author falls back to the bare hex prefix — "Unknown [..]"
  /// contains a bracket and would break the wire syntax.
  String _replyTargetName(Message message, MeshCoreConnector connector) {
    if (message.isOutgoing) return connector.selfName ?? context.l10n.chat_me;
    final author =
        _resolveContactFrom4Bytes(connector, message.fourByteRoomContactKey);
    if (author != null) return author.name;
    return message.fourByteRoomContactKey.isNotEmpty
        ? pubKeyToHex(message.fourByteRoomContactKey).toUpperCase()
        : '00000000';
  }

  /// Index in [reversed] of the post that [reply] (shown at [index]) quotes,
  /// or -1. Rooms store wire text, so the original is resolved at display
  /// time by sender name + snippet prefix, the same match the connector makes
  /// for channel replies. Only posts already loaded on screen can be found.
  int _findReplyTargetIndex(
    List<Message> reversed,
    int index,
    ReplyInfo reply,
    MeshCoreConnector connector,
  ) {
    if (!identical(_replyTargetCacheSource, _messages) ||
        _replyTargetCacheLength != reversed.length) {
      _replyTargetCache.clear();
      _replyTargetCacheSource = _messages;
      _replyTargetCacheLength = reversed.length;
    }
    final cached = _replyTargetCache[reversed[index].messageId];
    if (cached != null) return cached;

    var found = -1;
    for (var j = index + 1; j < reversed.length; j++) {
      final m = reversed[j];
      final body = ChannelMessage.parseReply(m.text)?.actualMessage ?? m.text;
      if (!ChannelMessage.snippetMatches(body, reply.snippet)) continue;
      if (_replyTargetName(m, connector) == reply.mentionedNode ||
          (_isOwnPost(m, connector) &&
              reply.mentionedNode == connector.selfName)) {
        found = j;
        break;
      }
    }
    _replyTargetCache[reversed[index].messageId] = found;
    return found;
  }

  /// Our own post as it comes back from a history reload: an incoming row
  /// under our key prefix. Self is never in contacts, so [_replyTargetName]
  /// alone would only ever see the hex.
  bool _isOwnPost(Message message, MeshCoreConnector connector) {
    if (message.isOutgoing) return true;
    final key = message.fourByteRoomContactKey;
    if (key.length < 4 || connector.selfPublicKey == null) return false;
    return connector.selfPublicKeyHex
        .toLowerCase()
        .startsWith(pubKeyToHex(key).toLowerCase());
  }

  void _scrollToIndex(int index) {
    if (!_itemScrollController.isAttached) return;
    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.3,
    );
  }

  /// Room members who can be @-mentioned: authors seen in this conversation
  /// whose adverts we hold. Unresolvable prefixes and the room itself are
  /// excluded — there is no name to type.
  List<Contact> _roomMentionCandidates(MeshCoreConnector connector) {
    if (_cachedRoomAuthorMap == null ||
        _cachedAuthorMapMessageCount != _messages.length) {
      final map = <String, Contact>{};
      final room = _resolveContact(connector);
      for (final m in _messages) {
        if (m.isOutgoing || m.fourByteRoomContactKey.length < 4) continue;
        final hex = pubKeyToHex(m.fourByteRoomContactKey);
        if (map.containsKey(hex)) continue;
        final author =
            _resolveContactFrom4Bytes(connector, m.fourByteRoomContactKey);
        if (author == null) continue;
        if (author.publicKeyHex == room.publicKeyHex) continue;
        map[hex] = author;
      }
      _cachedRoomAuthorMap = map;
      _cachedAuthorMapMessageCount = _messages.length;
    }
    return _cachedRoomAuthorMap!.values.toList();
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

    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtSignIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtSignIndex != -1) {
      final textAfterAt = textBeforeCursor.substring(lastAtSignIndex + 1);
      final charBeforeAt =
          lastAtSignIndex > 0 ? textBeforeCursor[lastAtSignIndex - 1] : ' ';

      if (!textAfterAt.contains(' ') &&
          (charBeforeAt == ' ' || charBeforeAt == '\n')) {
        final search = textAfterAt.toLowerCase();
        final connector = context.read<MeshCoreConnector>();

        final filtered = _roomMentionCandidates(connector)
            .where((c) => c.name.toLowerCase().contains(search))
            .toList();
        filtered.sort((a, b) {
          final aStart = a.name.toLowerCase().startsWith(search);
          final bStart = b.name.toLowerCase().startsWith(search);
          if (aStart && !bStart) return -1;
          if (!aStart && bStart) return 1;
          return a.name.compareTo(b.name);
        });

        if (_showMentions != filtered.isNotEmpty ||
            _mentionSearchText != search) {
          setState(() {
            _mentionSearchText = search;
            _showMentions = filtered.isNotEmpty;
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
    _messagesSub?.cancel();
    _itemPositionsListener.itemPositions.removeListener(_scrollListener);
    _connector?.setActiveContact(null);
    _textFieldFocusNode.removeListener(_onTextFieldFocusChange);
    _textController.removeListener(_mentionsListener);
    _textFieldFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatColors.isLight(context) ? ChatColors.background : null,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Consumer<MeshCoreConnector>(
          builder: (context, connector, _) {
            final contact = _resolveContact(connector);
            final unreadCount = connector.getUnreadCountForContactKey(
              widget.contact.publicKeyHex,
            );
            final pathLabel = _currentPathLabel(contact, connector);
            final roleLabel = _roomRoleLabel(_roomRole(connector));
            // "Unread: 0" is noise while the chat is open (it marks itself
            // read) and it ellipsized the role badge off the narrow title.
            final subtitle = [
              pathLabel,
              if (unreadCount > 0) context.l10n.chat_unread(unreadCount),
              ?roleLabel,
            ].join(' • ');

            // Show path details if we have non-empty path data (from device or override)
            final effectivePath = contact.pathOverrideBytes ?? contact.path;
            final hasPathData = effectivePath.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(contact.name),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: hasPathData
                      ? () => _showFullPathDialog(
                            context,
                            effectivePath,
                            contact.pathOverrideBytes != null
                                ? contact.overrideHashSize(
                                    connector.pathHashByteWidth,
                                  )
                                : contact.pathHashSize,
                          )
                      : null,
                  child: Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                      decoration: hasPathData ? TextDecoration.underline : null,
                      decorationStyle: TextDecorationStyle.dotted,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        centerTitle: false,
        actions: [
          Consumer<MeshCoreConnector>(
            builder: (context, connector, _) {
              final contact = _resolveContact(connector);
              return IconButton(
                icon: RoutingIcon(contact: contact),
                tooltip: context.l10n.routing_title,
                onPressed: () => RoutingDialog.show(context, contact: contact),
              );
            },
          ),
          if (widget.contact.type == advTypeRoom)
            Consumer<MeshCoreConnector>(
              builder: (context, connector, _) {
                final adminPassword = connector.roomAdminPassword(
                  widget.contact.publicKeyHex,
                );
                return IconButton(
                  icon: const Icon(Icons.admin_panel_settings),
                  tooltip: 'Manage room',
                  onPressed: () {
                    final room = _resolveContact(connector);
                    if (adminPassword != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RepeaterHubScreen(
                            repeater: room,
                            password: adminPassword,
                            isAdmin: true,
                          ),
                        ),
                      );
                      return;
                    }
                    // No admin session this connection — verify with the
                    // server, then open the hub as admin or guest.
                    showDialog(
                      context: context,
                      builder: (dialogContext) => RoomLoginDialog(
                        room: room,
                        onLogin: (password, isAdmin) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RepeaterHubScreen(
                                repeater: room,
                                password: password,
                                isAdmin: isAdmin,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          const RadioStatsIconButton(),
          Consumer<MeshCoreConnector>(
            builder: (context, connector, _) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'info') {
                    _showContactInfo(context);
                  }
                  if (value == 'settings') {
                    _showContactSettings(context);
                  }
                  if (value == 'telemetry') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TelemetryScreen(contact: widget.contact),
                      ),
                    );
                  }
                  if (value == 'clearChat') {
                    connector.clearMessagesForContact(widget.contact);
                  }
                  if (value == 'reloadPosts') {
                    _reloadRoomPosts(connector);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20),
                        const SizedBox(width: 12),
                        Text(context.l10n.contact_info),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'telemetry',
                    child: Row(
                      children: [
                        const Icon(Icons.bar_chart, size: 20),
                        const SizedBox(width: 12),
                        Text(context.l10n.contact_telemetry),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        const Icon(Icons.settings, size: 20),
                        const SizedBox(width: 12),
                        Text(context.l10n.contact_settings),
                      ],
                    ),
                  ),
                  if (_isRoom)
                    PopupMenuItem(
                      value: 'reloadPosts',
                      child: Row(
                        children: [
                          const Icon(Icons.history, size: 20),
                          const SizedBox(width: 12),
                          Text(context.l10n.room_reloadPosts),
                        ],
                      ),
                    ),
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
              );
            },
          ),
        ],
      ),
      body: Consumer<MeshCoreConnector>(
        builder: (context, connector, child) {
          final settingsService = context.watch<AppSettingsService>();
          final contactBlocked =
              settingsService.isContactBlocked(widget.contact.publicKeyHex);
          // Hide CLI plumbing that older versions stored as chat messages.
          final visibleMessages = _messages.where((m) => !m.isCli);
          final messages = contactBlocked
              ? visibleMessages.where((m) => m.isOutgoing).toList()
              : visibleMessages.toList();
          return Column(
            children: [
              ?ConnectionStatusBanner.ifDisconnected(context, connector),
              if (_isRoom) ?_buildClockSkewBanner(connector),
              Expanded(
                child: Stack(
                  children: [
                    messages.isEmpty
                        ? _buildEmptyState()
                        : _buildMessageList(messages, connector),
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
              if (_showMentions)
                MentionsOverlay(
                  contacts: _filteredMentionContacts,
                  onSelect: _insertMention,
                ),
              if (_isRoom && _roomRole(connector) == 0)
                _buildReadOnlyBanner(),
              _buildInputBar(connector),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            context.l10n.chat_noMessages,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.chat_sendMessageTo(
              _resolveContact(context.read<MeshCoreConnector>()).name,
            ),
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    List<Message> messages,
    MeshCoreConnector connector,
  ) {
    // Reverse messages so newest appear at bottom with reverse: true
    final reversedMessages = messages.reversed.toList();
    final itemCount = reversedMessages.length + (_isLoadingOlder ? 1 : 0);

    // Auto-scroll to bottom if user is already at bottom
    final currentMessageCount = messages.length;
    final newestIsOutgoing = messages.isNotEmpty && messages.last.isOutgoing;
    if (currentMessageCount > _previousMessageCount) {
      // Auto-scroll if: the user is already at the bottom, OR they just sent
      // the newest message (so their own send always scrolls into view).
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
    _previousMessageCount = currentMessageCount;

    return ExcludeSemantics(
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final messageIndex = index;
          Contact contact = _resolveContact(connector);
          final message = reversedMessages[messageIndex];
          Contact? roomAuthor;
          String fourByteHex = '';
          if (contact.type == advTypeRoom) {
            roomAuthor = _resolveContactFrom4Bytes(
              connector,
              message.fourByteRoomContactKey,
            );
            fourByteHex = message.fourByteRoomContactKey.isNotEmpty
                ? pubKeyToHex(message.fourByteRoomContactKey).toUpperCase()
                : "00000000";
            contact = roomAuthor ?? contact;
          }

          return Builder(
            builder: (context) {
              final textScale = context.select<ChatTextScaleService, double>(
                (service) => service.scale,
              );
              final resolvedContact = _resolveContact(connector);
              final isRoom = resolvedContact.type == advTypeRoom;
              final senderName = isRoom
                  ? (roomAuthor?.name ?? "Unknown [$fourByteHex]")
                  : contact.name;
              final isAnnouncement = isRoom &&
                  roomAuthor != null &&
                  roomAuthor.publicKeyHex == resolvedContact.publicKeyHex;
              // Same format as the channel screen: raw hop prefixes, not
              // resolved names ("via AA,3F").
              String? viaLabel;
              if (message.pathBytes.isNotEmpty) {
                final hexPath = PathHelper.formatPathHex(
                  message.pathBytes,
                  stride: message.pathHashSize ?? resolvedContact.pathHashSize,
                );
                if (hexPath.isNotEmpty) viaLabel = hexPath;
              }
              final replyInfo =
                  isRoom ? ChannelMessage.parseReply(message.text) : null;
              final replyTargetIndex = replyInfo == null
                  ? -1
                  : _findReplyTargetIndex(
                      reversedMessages, index, replyInfo, connector);
              final replyTarget = replyTargetIndex == -1
                  ? null
                  : reversedMessages[replyTargetIndex];
              Widget bubble = _MessageBubble(
                message: message,
                senderName: senderName,
                isRoomServer: isRoom,
                replyInfo: replyInfo,
                replyTarget: replyTarget,
                replyTargetIsSelf:
                    replyTarget != null && _isOwnPost(replyTarget, connector),
                onReplyTap: replyTarget == null
                    ? null
                    : () => _scrollToIndex(replyTargetIndex),
                viaLabel: viaLabel,
                isAnnouncement: isAnnouncement,
                textScale: textScale,
                onTap: () => message.isOutgoing &&
                        message.status == MessageStatus.failed
                    ? _retryMessage(message)
                    : _openMessagePath(message),
                onLongPress: () => _showMessageActions(message, contact),
                onRetryReaction: (msg, emoji) => _sendReaction(msg, emoji),
              );
              if (isRoom && !message.isOutgoing && !PlatformInfo.isDesktop) {
                bubble = SwipeReplyBubble(
                  maxSwipeOffset: 64.0,
                  replySwipeThreshold: 64.0,
                  onReplyTriggered: () => _setReplyingTo(message),
                  // No resolved name, nothing to type into the composer.
                  onMentionTriggered: roomAuthor == null
                      ? null
                      : () => _insertMentionOf(roomAuthor!.name),
                  hintBuilder: ({required mention}) =>
                      SwipeHint(mention: mention),
                  child: bubble,
                );
              }
              bool showDayMarker = false;
              if (index == reversedMessages.length - 1) {
                showDayMarker = true;
              } else {
                final olderMessage = reversedMessages[index + 1];
                final currentDate = DateTime(message.timestamp.year, message.timestamp.month, message.timestamp.day);
                final olderDate = DateTime(olderMessage.timestamp.year, olderMessage.timestamp.month, olderMessage.timestamp.day);
                if (currentDate != olderDate) {
                  showDayMarker = true;
                }
              }

              Widget currentWidget = bubble;

              if (_firstUnreadMessage != null && 
                  message.timestamp == _firstUnreadMessage!.timestamp && 
                  message.text == _firstUnreadMessage!.text) {
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
                            child: Text(
                              "NEW MESSAGES",
                              style: TextStyle(
                                color: Colors.red[400],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
          );
        },
      ),
    ),
    );
  }

  /// Re-asks the room for its recent backlog (the server holds up to 32
  /// posts in memory). The radio's sync cursor can only be rewound by
  /// deleting and re-adding the contact; the login that follows must carry
  /// the password — stock servers ignore the rewind on a blank re-login.
  Future<void> _reloadRoomPosts(MeshCoreConnector connector) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.room_reloadPosts),
            content: Text(l10n.room_reloadPostsExplain),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.common_cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.room_reloadPosts),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    final ok = await connector.resetRoomSyncCursor(_resolveContact(connector));
    if (!mounted) return;
    if (!ok) {
      showDismissibleSnackBar(
        context,
        content: Text(l10n.room_reloadFailed),
        backgroundColor: Colors.red,
      );
      return;
    }
    // The login (with the password) is what makes the server re-push.
    await showDialog(
      context: context,
      builder: (context) => RoomLoginDialog(
        room: widget.contact,
        onLogin: (password, isAdmin) {},
      ),
    );
  }

  /// Amber strip when the room server's clock disagrees with ours by more
  /// than five minutes (its clock stamps every post). Admins get a one-tap
  /// fix; anyone can dismiss it for this visit.
  Widget? _buildClockSkewBanner(MeshCoreConnector connector) {
    if (_clockBannerDismissed) return null;
    final event =
        connector.lastMeasuredRoomLogin(widget.contact.publicKeyHex);
    final serverClock = event?.serverClock;
    if (event == null || serverClock == null) return null;
    // The measurement comes from the last login. After a fix was sent, stay
    // down until a NEWER login re-measures — re-warning from the stale
    // reading made the banner look like the fix never worked.
    final syncSentAt =
        connector.roomClockSyncSentAt(widget.contact.publicKeyHex);
    if (syncSentAt != null && event.at.isBefore(syncSentAt)) return null;
    final skew = serverClock.difference(event.at);
    if (skew.abs() < const Duration(minutes: 5)) return null;
    // The firmware only winds a clock FORWARD: a room running behind is
    // fixable from here, a room running ahead needs its own console.
    final fixable = skew.isNegative;
    final isAdmin = fixable &&
        connector.roomAdminPassword(widget.contact.publicKeyHex) != null;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: colorScheme.tertiaryContainer,
      child: Row(
        children: [
          Icon(Icons.schedule, size: 18, color: colorScheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.room_clockOff(skew.abs().inMinutes),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          if (isAdmin)
            TextButton(
              onPressed: () async {
                final timestampSeconds =
                    DateTime.now().millisecondsSinceEpoch ~/ 1000;
                try {
                  await connector.sendFrame(
                    buildSendCliCommandFrame(
                      _resolveContact(connector).publicKey,
                      'clock sync',
                      timestampSeconds: timestampSeconds,
                    ),
                  );
                } catch (_) {}
                connector.markRoomClockSyncSent(widget.contact.publicKeyHex);
                if (mounted) {
                  setState(() => _clockBannerDismissed = true);
                  showDismissibleSnackBar(
                    context,
                    content: Text(context.l10n.room_clockSyncSent),
                  );
                }
              },
              child: Text(context.l10n.room_fixClock),
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            color: colorScheme.onTertiaryContainer,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _clockBannerDismissed = true),
          ),
        ],
      ),
    );
  }

  /// Shown above the composer when the last login came back as a guest:
  /// the room relays nothing a guest posts (stock firmware never ACKs it).
  Widget _buildReadOnlyBanner() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: colorScheme.surfaceContainerHigh,
      child: Row(
        children: [
          Icon(
            Icons.visibility_outlined,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.room_readOnlyNotice,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(MeshCoreConnector connector) {
    // Reserve room for the reply prefix ("@[Name]\n><snippet>..\n") while a
    // reply is active, so the byte counter and typing limit account for it.
    final baseMaxBytes =
        _isRoom ? maxRoomMessageBytes() : maxContactMessageBytes();
    final reply = _replyingToMessage;
    final replyOverhead = reply == null
        ? 0
        : utf8
              .encode(
                '@[${_replyTargetName(reply, connector)}]\n>'
                '${ChannelMessage.buildReplySnippet(ChannelMessage.parseReply(reply.text)?.actualMessage ?? reply.text, 10)}..\n',
              )
              .length;
    final maxBytes = (baseMaxBytes - replyOverhead).clamp(0, baseMaxBytes);
    final colorScheme = Theme.of(context).colorScheme;
    // Same composer treatment as the channel screen: a soft upward shadow,
    // not the divider line (near-white in dark mode).
    final inputBar = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
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
                          _sendMessage(connector);
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
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                fallbackTextColor: colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                maxSize: 160,
                              ) : Container(
                                height: 60,
                                color: colorScheme.surfaceContainerHighest,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.gif_box, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                                    const SizedBox(width: 8),
                                    Text(
                                      "GIF",
                                      style: TextStyle(
                                        color: colorScheme.onSurface.withValues(alpha: 0.6),
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
                            _sendMessage(connector);
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
                      hintText: context.l10n.chat_typeMessage,
                      onSubmitted: (_) => _sendMessage(connector),
                      encoder:
                          connector.isContactSmazEnabled(
                            widget.contact.publicKeyHex,
                          )
                          ? (text) => connector.prepareContactOutboundText(
                              widget.contact,
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
            IconButton.filled(
              icon: const Icon(Icons.send),
              tooltip: context.l10n.chat_sendMessageTo(
                _resolveContact(connector).name,
              ),
              onPressed: () => _sendMessage(connector),
            ),
          ],
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (reply != null)
          Builder(
            builder: (context) {
              final textScale = context.select<ChatTextScaleService, double>(
                (service) => service.scale,
              );
              return _buildReplyBanner(reply, connector, textScale);
            },
          ),
        inputBar,
      ],
    );
  }

  Widget _buildReplyBanner(
    Message reply,
    MeshCoreConnector connector,
    double textScale,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final previewColor = colorScheme.onPrimaryContainer.withValues(alpha: 0.8);
    final previewSource =
        ChannelMessage.parseReply(reply.text)?.actualMessage ?? reply.text;
    final gifId = GifHelper.parseGif(previewSource);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, size: 18, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n
                      .chat_replyingTo(_replyTargetName(reply, connector)),
                  style: TextStyle(
                    fontSize: 12 * textScale,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                if (gifId != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.gif_box, size: 14, color: previewColor),
                      const SizedBox(width: 4),
                      Text(
                        'GIF',
                        style: TextStyle(
                          fontSize: 11 * textScale,
                          color: previewColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    previewSource,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11 * textScale,
                      color: previewColor,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _cancelReply,
            color: colorScheme.onPrimaryContainer,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
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



  Future<void> _sendMessage(MeshCoreConnector connector) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    if (!connector.isConnected) {
      // The connector drops sends silently while disconnected; the user has
      // to hear about it, and their text has to stay in the box.
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chat_notConnected),
      );
      return;
    }

    final now = DateTime.now();
    if (_lastTextSendAt != null &&
        now.difference(_lastTextSendAt!) < const Duration(seconds: 1)) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chat_sendCooldown),
      );
      return;
    }
    _lastTextSendAt = now;

    final contact = _resolveContact(connector);
    final maxBytes = _isRoom ? maxRoomMessageBytes() : maxContactMessageBytes();

    bool fits(String candidate) {
      final outbound = connector.prepareContactOutboundText(contact, candidate);
      return utf8.encode(outbound).length <= maxBytes;
    }

    String sendText = text;
    final replyTarget = _replyingToMessage;
    if (_isRoom && replyTarget != null) {
      // Build a compatible "@[Name]\n><snippet>..\n<text>" reply, shrinking
      // the snippet to fit the byte budget. Quoting a reply quotes its body,
      // not its own reply header.
      final built = ChannelMessage.buildReplyWireText(
        targetName: _replyTargetName(replyTarget, connector),
        quoteText: ChannelMessage.parseReply(replyTarget.text)?.actualMessage ??
            replyTarget.text,
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
      sendText = built;
    } else if (!fits(sendText)) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chat_messageTooLong(maxBytes)),
      );
      return;
    }

    _textController.clear();
    if (_replyingToMessage != null) _cancelReply();
    _textFieldFocusNode.requestFocus();
    connector.sendMessage(contact, sendText);
  }

  void _showFullPathDialog(BuildContext context, List<int> pathBytes, int hashSize) {
    if (pathBytes.isEmpty) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chat_pathDetailsNotAvailable),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final connector = context.read<MeshCoreConnector>();
    final allContacts = connector.allContacts;

    final formattedPath = PathHelper.formatPathHex(pathBytes, stride: hashSize);
    final resolvedNames = PathHelper.resolvePathNames(pathBytes, allContacts, stride: hashSize);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.chat_fullPath),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(formattedPath),
            const SizedBox(height: 8),
            SelectableText(
              resolvedNames,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PathTraceMapScreen(
                  title: context.l10n.contacts_repeaterPathTrace,
                  path: Uint8List.fromList(pathBytes),
                  flipPathAround: true,
                  targetContact: widget.contact,
                  pathHashByteWidth: hashSize,
                ),
              ),
            ),
            child: Text(context.l10n.contacts_pathTrace),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
  }

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

  /// Resolves a room post's 4-byte author prefix to a contact, or null when
  /// no advert from the author has been heard. A match on the room's own key
  /// is genuine — the room server authors its system posts.
  Contact? _resolveContactFrom4Bytes(
    MeshCoreConnector connector,
    Uint8List key4Bytes,
  ) {
    if (key4Bytes.length < 4) return null;
    // Search discovered contacts too — the post author doesn't have to be an
    // active device contact for us to know their name.
    return connector.allContactsUnfiltered
        .cast<Contact?>()
        .firstWhere(
          (c) =>
              c!.publicKey.length >= 4 &&
              listEquals(c.publicKey.sublist(0, 4), key4Bytes.sublist(0, 4)),
          orElse: () => null,
        );
  }

  String _currentPathLabel(Contact contact, MeshCoreConnector connector) {
    // Check if user has set a path override
    if (contact.pathOverride != null) {
      if (contact.pathOverride! < 0) return context.l10n.chat_floodForced;
      if (contact.pathOverride == 0) return context.l10n.chat_directForced;
      // Derive hop count from bytes when available — pathOverride int
      // may be stale if it was stored as a raw byte count by older code.
      if (contact.pathOverrideBytes != null &&
          contact.pathOverrideBytes!.isNotEmpty) {
        final hopCount = PathHelper.getHopCount(
          contact.pathOverrideBytes!,
          stride: contact.overrideHashSize(connector.pathHashByteWidth),
        );
        if (hopCount == 0) return context.l10n.chat_directForced;
        return context.l10n.chat_hopsForced(hopCount);
      }
      return context.l10n.chat_hopsForced(contact.pathOverride!);
    }

    // Use device's path — prefer trimmed byte count over raw pathLength
    // because pathLength may reflect a padded buffer full of trailing zeros.
    final effectivePath = contact.pathOverrideBytes ?? contact.path;
    if (effectivePath.isNotEmpty) {
      final hopCount = PathHelper.getHopCount(effectivePath, stride: contact.pathHashSize);
      if (hopCount == 0) return context.l10n.chat_direct;
      return context.l10n.chat_hopsCount(hopCount);
    }

    if (contact.pathLength < 0) return context.l10n.chat_floodAuto;
    if (contact.pathLength == 0) return context.l10n.chat_direct;
    return context.l10n.chat_hopsCount(contact.pathLength);
  }

  void _showContactInfo(BuildContext context) {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final contact = _resolveContact(connector);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: SelectableText(contact.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(context.l10n.chat_type, contact.typeLabel),
              _buildInfoRow(context.l10n.chat_path, contact.pathLabel),
              _buildInfoRow(
                context.l10n.contact_lastSeen,
                _formatContactLastMessage(contact.lastMessageAt),
              ),
              if (contact.hasLocation)
                _buildInfoRow(
                  context.l10n.chat_location,
                  '${contact.latitude?.toStringAsFixed(4)}, ${contact.longitude?.toStringAsFixed(4)}',
                ),
              _buildInfoRow(context.l10n.chat_publicKey, contact.publicKeyHex),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
  }

  void _showContactSettings(BuildContext context) {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    connector.ensureContactSmazSettingLoaded(widget.contact.publicKeyHex);
    final contact = widget.contact;
    bool smazEnabled = connector.isContactSmazEnabled(contact.publicKeyHex);
    bool teleBaseEnabled = contact.teleBaseEnabled;
    bool teleLocEnabled = contact.teleLocEnabled;
    bool teleEnvEnabled = contact.teleEnvEnabled;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.l10n.contact_settings),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (contact.hasLocation) ...[
                  _buildInfoRow(
                    context.l10n.chat_location,
                    '${contact.latitude?.toStringAsFixed(4)}, ${contact.longitude?.toStringAsFixed(4)}',
                  ),
                  const Divider(height: 8),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.channels_smazCompression),
                  subtitle: Text(context.l10n.chat_compressOutgoingMessages),
                  value: smazEnabled,
                  onChanged: (value) {
                    connector.setContactSmazEnabled(
                      contact.publicKeyHex,
                      value,
                    );
                    setDialogState(() => smazEnabled = value);
                  },
                ),
                const Divider(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.contact_teleBase),
                  subtitle: Text(context.l10n.contact_teleBaseSubtitle),
                  value: teleBaseEnabled,
                  onChanged: (value) {
                    setDialogState(() => teleBaseEnabled = value);
                  },
                ),
                const Divider(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.contact_teleLoc),
                  subtitle: Text(context.l10n.contact_teleLocSubtitle),
                  value: teleLocEnabled,
                  onChanged: (value) {
                    setDialogState(() => teleLocEnabled = value);
                  },
                ),
                const Divider(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.contact_teleEnv),
                  subtitle: Text(context.l10n.contact_teleEnvSubtitle),
                  value: teleEnvEnabled,
                  onChanged: (value) {
                    setDialogState(() => teleEnvEnabled = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                connector.setContactFlags(
                  contact,
                  teleBase: teleBaseEnabled,
                  teleLoc: teleLocEnabled,
                  teleEnv: teleEnvEnabled,
                );
                Navigator.pop(context);
              },
              child: Text(context.l10n.common_close),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }

  String _formatContactLastMessage(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.isNegative || diff.inMinutes < 5) {
      return context.l10n.contacts_lastSeenNow;
    }
    if (diff.inMinutes < 60) {
      return context.l10n.contacts_lastSeenMinsAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return hours == 1
          ? context.l10n.contacts_lastSeenHourAgo
          : context.l10n.contacts_lastSeenHoursAgo(hours);
    }
    final days = diff.inDays;
    return days == 1
        ? context.l10n.contacts_lastSeenDayAgo
        : context.l10n.contacts_lastSeenDaysAgo(days);
  }

  void _openChat(BuildContext context, Contact contact) {
    // Check if this is a repeater
    context.read<MeshCoreConnector>().markContactRead(contact.publicKeyHex);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen(contact: contact)),
    );
  }

  void _openMessagePath(Message message) {
    final connector = context.read<MeshCoreConnector>();
    final fourByteHex = pubKeyToHex(message.fourByteRoomContactKey).toUpperCase();
    final String senderName;
    if (message.isOutgoing) {
      senderName = connector.selfName ?? context.l10n.chat_me;
    } else if (_resolveContact(connector).type == advTypeRoom) {
      final author =
          _resolveContactFrom4Bytes(connector, message.fourByteRoomContactKey);
      senderName = author?.name ?? "Unknown [$fourByteHex]";
    } else {
      senderName = _resolveContact(connector).name;
    }
    final pathMessage = ChannelMessage(
      senderKey: null,
      senderName: senderName,
      text: message.text,
      timestamp: message.timestamp,
      isOutgoing: message.isOutgoing,
      status: ChannelMessageStatus.sent,
      repeatCount: 0,
      pathLength: message.pathLength,
      pathBytes: message.pathBytes,
      pathHashSize:
          message.pathHashSize ?? _resolveContact(connector).pathHashSize,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChannelMessagePathScreen(message: pathMessage),
      ),
    );
  }

  void _showMessageActions(Message message, Contact contact) {
    final chatContact = _resolveContact(context.read<MeshCoreConnector>());
    final isRoom = chatContact.type == advTypeRoom;
    // In a room, [contact] is the resolved post author; it falls back to the
    // room itself when the author is unknown or the room authored the post.
    final isRoomItself =
        isRoom && contact.publicKeyHex == chatContact.publicKeyHex;
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Can't react to your own messages
            if (!message.isOutgoing)
              ListTile(
                leading: const Icon(Icons.add_reaction_outlined),
                title: Text(context.l10n.chat_addReaction),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showEmojiPicker(message);
                },
              ),
            if (isRoom)
              ListTile(
                leading: const Icon(Icons.reply),
                title: Text(context.l10n.chat_reply),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _setReplyingTo(message);
                  _textFieldFocusNode.requestFocus();
                },
              ),
            if (isRoom && !message.isOutgoing && !isRoomItself)
              ListTile(
                leading: const Icon(Icons.alternate_email),
                title: Text(context.l10n.chat_mention),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _insertMentionOf(contact.name);
                },
              ),
            if (PlatformInfo.isDesktop)
              ListTile(
                leading: const Icon(Icons.route),
                title: Text(context.l10n.chat_path),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openMessagePath(message);
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(context.l10n.common_copy),
              onTap: () {
                Navigator.pop(sheetContext);
                _copyMessageText(message.text);
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
            if (message.isOutgoing && message.status == MessageStatus.failed)
              ListTile(
                leading: const Icon(Icons.refresh),
                title: Text(context.l10n.common_retry),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _retryMessage(message);
                },
              ),
            if (!message.isOutgoing &&
                isRoom &&
                !isRoomItself &&
                contact.type == advTypeChat)
              ListTile(
                leading: const Icon(Icons.chat),
                title: Text(context.l10n.contacts_openChat),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openChat(context, contact);
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
                    sender: contact.name,
                    text: message.text,
                    timestamp: message.timestamp,
                  );
                },
              ),
              // Blocking a room post whose author is the room (or unknown)
              // would block the room itself and silence every member.
              if (!isRoomItself)
                ListTile(
                  leading: const Icon(Icons.block),
                  title: Text('Block ${contact.name}'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await context
                        .read<AppSettingsService>()
                        .blockContact(contact.publicKeyHex);
                    if (mounted) {
                      showDismissibleSnackBar(
                        context,
                        content: Text('Blocked ${contact.name}'),
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
    );
  }

  void _copyMessageText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.chat_messageCopied),
    );
  }

  Future<void> _deleteMessage(Message message) async {
    await context.read<MeshCoreConnector>().deleteMessage(message);
    if (!mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.chat_messageDeleted),
    );
  }

  Future<void> _retryMessage(Message message) async {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final contact = _resolveContact(connector);
    // The failed bubble is replaced by the new send, which starts with a
    // flood — unless the user pinned a route, which outranks the heuristic.
    final override = contact.pathOverride;
    await connector.deleteMessage(message);
    await connector.sendMessage(contact, message.text, floodFirst: true);
    if (!mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(override != null && override >= 0
          ? context.l10n.chat_resendingByRoute
          : context.l10n.chat_resendingByFlood),
    );
  }

  void _showEmojiPicker(Message message) {
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

  void _sendReaction(Message message, String emoji) {
    final connector = context.read<MeshCoreConnector>();
    // MeshCore One dialect: the SHA hash names the target on every client,
    // so unlike the legacy r: format there is no sender field and no fixed
    // emoji table — any emoji goes.
    connector.sendMessage(
      _resolveContact(connector),
      MeshCoreConnector.contactReactionText(
        message,
        emoji,
        // Rooms have many voices: name the author so the reaction reads
        // "@[author]👍" on every client, decoded or not.
        targetSender: _isRoom ? _replyTargetName(message, connector) : null,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final String senderName;
  final bool isRoomServer;
  /// Parsed reply markup (rooms only): the bubble shows a quote box and the
  /// reply body instead of the raw wire text.
  final ReplyInfo? replyInfo;

  /// The quoted post when it is loaded on screen: the quote shows its full
  /// body and tapping it scrolls there. Null falls back to the wire snippet.
  final Message? replyTarget;
  final bool replyTargetIsSelf;
  final VoidCallback? onReplyTap;

  /// Hex hop prefixes for this message's path (channel-screen format),
  /// shown under the body when message tracing is on — outgoing: the route
  /// the send used; incoming: our known route, only when its length matches
  /// the hops the packet actually reported.
  final String? viaLabel;

  /// Post authored by the room server itself (room.post / system post) —
  /// gets an announcement marker next to the sender name.
  final bool isAnnouncement;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final void Function(Message message, String emoji)? onRetryReaction;
  final double textScale;

  const _MessageBubble({
    required this.message,
    required this.senderName,
    required this.isRoomServer,
    required this.textScale,
    this.replyInfo,
    this.replyTarget,
    this.replyTargetIsSelf = false,
    this.onReplyTap,
    this.viaLabel,
    this.isAnnouncement = false,
    this.onTap,
    this.onLongPress,
    this.onRetryReaction,
  });

  @override
  Widget build(BuildContext context) {
    // A stored MeshCore One reaction is one whose target message we don't
    // hold. It stays an ordinary bubble — same sender header, avatar and
    // timestamp as any message — but shows "{emoji}@[{target}]" instead of
    // the raw hash line, with a reaction icon marking what it is. If the
    // target arrives later the connector lands the reaction on it and
    // deletes this row.
    final orphanReaction = ReactionHelper.parseMeshCoreOneReaction(
      message.text,
    );
    final settingsService = context.watch<AppSettingsService>();
    final uiState = context.watch<UiViewStateService>();
    final enableTracing = settingsService.settings.enableMessageTracing;
    final isOutgoing = message.isOutgoing;
    final colorScheme = Theme.of(context).colorScheme;

    final messageText = replyInfo?.actualMessage ?? message.text;

    final gifId = GifHelper.parseGif(messageText);
    final poi = _parsePoiMessage(messageText);
    final isFailed = message.status == MessageStatus.failed;
    final warmLight = ChatColors.isLight(context);
    // Same palette as the channel chat screen: warm ChatColors in light
    // mode, primaryContainer/surfaceContainerHighest in dark.
    final bubbleColor = isFailed
        ? colorScheme.errorContainer
        : warmLight
            ? (isOutgoing ? ChatColors.outgoingBubble : ChatColors.incomingBubble)
            : (isOutgoing
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest);
    final textColor = isFailed
        ? colorScheme.onErrorContainer
        : warmLight
            ? ChatColors.bubbleText
            : colorScheme.onSurface;
    // An unresolved reaction shows what it reacted with and to — never the
    // Crockford hash line, which means nothing to a reader.
    final cleanDisplayText = orphanReaction != null
        ? (orphanReaction.targetSender != null
                ? '@[${orphanReaction.targetSender}]'
                : '') +
            orphanReaction.emoji
        : GifHelper.stripGif(messageText);

    final isJumboEmoji = gifId == null && poi == null && _isOnlyEmojis(messageText);
    final displayBubbleColor = isJumboEmoji ? Colors.transparent : bubbleColor;
    final displayTextColor = isJumboEmoji ? colorScheme.onSurface : textColor;
    final displayMetaColor = displayTextColor.withValues(alpha: 0.7);
    final bodyFontSize = isJumboEmoji ? 48.0 : 14.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isOutgoing
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: PlatformInfo.isDesktop ? null : onTap,
            onLongPress: onLongPress,
            onSecondaryTapUp: PlatformInfo.isDesktop
                ? (_) => onLongPress?.call()
                : null,
            child: Row(
              mainAxisAlignment: isOutgoing
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isOutgoing) ...[
                  _buildAvatar(senderName, colorScheme),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Container(
                    padding: gifId != null
                        ? const EdgeInsets.all(4)
                        : isJumboEmoji
                            ? EdgeInsets.zero
                            : const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.65,
                    ),
                    decoration: BoxDecoration(
                      color: displayBubbleColor,
                      borderRadius: BorderRadius.circular(16),
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
                                if (isAnnouncement) ...[
                                  Icon(
                                    Icons.campaign,
                                    size: 14 * textScale,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Flexible(
                                  child: Text(
                                    senderName,
                                    style: TextStyle(
                                      fontSize: 12 * textScale,
                                      fontWeight: FontWeight.bold,
                                      color: settingsService
                                              .settings.senderNameColors
                                          ? _getColorForName(senderName)
                                          : colorScheme.primary,
                                    ),
                                  ),
                                ),
                                // Heard with zero hops: our radio heard
                                // theirs, no repeater in between.
                                if (message.pathLength == 0) ...[
                                  const SizedBox(width: 6),
                                  _buildDirectPill(context),
                                ],
                              ],
                            ),
                          ),
                          if (gifId == null) const SizedBox(height: 4),
                        ],
                        if (replyInfo != null) ...[
                          _buildReplyQuote(
                            context,
                            replyInfo!,
                            colorScheme,
                            uiState,
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (poi != null)
                          _buildPoiMessage(
                            context,
                            poi,
                            textColor,
                            displayMetaColor,
                            textScale,
                            trailing: (!enableTracing && isOutgoing)
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: MessageStatusIcon(
                                      isAcked:
                                          message.status == MessageStatus.delivered,
                                      isFailed:
                                          message.status ==
                                          MessageStatus.failed,
                                    ),
                                  )
                                : null,
                          )
                        else if (gifId != null)
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: uiState.renderGifs ? GifMessage(
                                  url:
                                      'https://media.giphy.com/media/$gifId/giphy.gif',
                                  backgroundColor: Colors.transparent,
                                  fallbackTextColor: textColor.withValues(
                                    alpha: 0.7,
                                  ),
                                ) : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: displayBubbleColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.gif_box, color: displayTextColor.withValues(alpha: 0.7)),
                                      const SizedBox(width: 8),
                                      Text(
                                        "GIF",
                                        style: TextStyle(
                                          color: displayTextColor.withValues(alpha: 0.7),
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
                                      color: bubbleColor,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(10),
                                        topRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: MessageStatusIcon(
                                      isAcked:
                                          message.status == MessageStatus.delivered,
                                      isFailed:
                                          message.status ==
                                          MessageStatus.failed,
                                    ),
                                  ),
                                ),
                            ],
                          )
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: LinkHandler.buildLinkifyText(
                                  context: context,
                                  text: cleanDisplayText,
                                  style: TextStyle(
                                    color: isJumboEmoji ? null : displayTextColor,
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
                                        .chat_reactionTargetMissing(senderName),
                                    triggerMode: TooltipTriggerMode.longPress,
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.add_reaction_outlined,
                                      size: 15 * textScale,
                                      color: displayMetaColor,
                                    ),
                                  ),
                                ),
                              ],
                              if (!enableTracing && isOutgoing) ...[
                                const SizedBox(width: 4),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: MessageStatusIcon(
                                    isAcked:
                                        message.status == MessageStatus.delivered,
                                    isFailed:
                                        message.status == MessageStatus.failed,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        if (enableTracing && viaLabel != null) ...[
                          const SizedBox(height: 4),
                          Padding(
                            padding: gifId != null
                                ? const EdgeInsets.symmetric(horizontal: 8)
                                : EdgeInsets.zero,
                            child: Text(
                              'via $viaLabel',
                              style: TextStyle(
                                fontSize: 11,
                                color: displayMetaColor,
                              ),
                            ),
                          ),
                        ],
                        if (isOutgoing) ...[
                          Builder(
                            builder: (context) {
                              final line = _deliveryStatus(
                                context,
                                detailed: enableTracing,
                              );
                              if (line == null) return const SizedBox.shrink();
                              final style = TextStyle(
                                fontSize: 10,
                                color: displayMetaColor,
                                fontWeight: FontWeight.w500,
                              );
                              // A Pathfinder route is marked by the amber
                              // path icon, just before the route kind (or
                              // the trip time when the kind isn't shown).
                              final mark =
                                  message.routeSource == RouteSource.graph
                                      ? line.indexOf(enableTracing
                                          ? _routeKind(context)
                                          : _tripSecs)
                                      : -1;
                              return Padding(
                                padding: EdgeInsets.only(
                                  top: 4,
                                  left: gifId != null ? 8 : 0,
                                  right: gifId != null ? 8 : 0,
                                ),
                                child: mark < 0
                                    ? Text(line, style: style)
                                    : Text.rich(
                                        TextSpan(
                                          style: style,
                                          children: [
                                            TextSpan(
                                                text: line.substring(0, mark)),
                                            WidgetSpan(
                                              alignment:
                                                  PlaceholderAlignment.middle,
                                              child: Icon(
                                                RoutingIcon.icon,
                                                size: 12,
                                                color: RoutingIcon
                                                    .pathfinderColor(context),
                                              ),
                                            ),
                                            TextSpan(
                                                text:
                                                    ' ${line.substring(mark)}'),
                                          ],
                                        ),
                                      ),
                              );
                            },
                          ),
                        ],
                        if (enableTracing) ...[
                          const SizedBox(height: 4),
                          Padding(
                            padding: gifId != null
                                ? const EdgeInsets.only(
                                    left: 8,
                                    right: 8,
                                    bottom: 4,
                                  )
                                : EdgeInsets.zero,
                            child: Wrap(
                              spacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _formatTime(message.timestamp),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: displayMetaColor,
                                  ),
                                ),
                                if (!isOutgoing &&
                                    _receivedKindLabel(context) != null)
                                  Text(
                                    '· ${_receivedKindLabel(context)!}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: displayMetaColor,
                                    ),
                                  ),
                                if (isOutgoing) ...[
                                  const SizedBox(width: 4),
                                  _buildStatusIcon(displayMetaColor),
                                ],
                                if (!isOutgoing &&
                                    message.tripTimeMs != null &&
                                    message.status ==
                                        MessageStatus.delivered) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.speed,
                                    size: 10,
                                    color: isOutgoing
                                        ? displayMetaColor
                                        : Colors.green[700],
                                  ),
                                  Text(
                                    '${(message.tripTimeMs! / 1000).toStringAsFixed(1)}s',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isOutgoing
                                          ? displayMetaColor
                                          : Colors.green[700],
                                    ),
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
              ],
            ),
          ),
          if (message.reactions.isNotEmpty)
            // Chips ride up over the bubble's bottom edge, as in most
            // messaging apps, instead of floating below it.
            Transform.translate(
              offset: const Offset(0, -kReactionOverlap),
              child: Padding(
                padding: EdgeInsets.only(left: isOutgoing ? 0 : 48),
                child: _buildReactionsDisplay(context, message, colorScheme),
              ),
            ),
        ],
      ),
    );
  }

  _PoiInfo? _parsePoiMessage(String text) {
    final trimmed = text.trim();
    final match = RegExp(
      r'^m:([\-0-9.]+),([\-0-9.]+)\|([^|]*)\|.*$',
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
    Color textColor,
    Color metaColor,
    double textScale, {
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.location_on_outlined, color: textColor),
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

  Widget _buildReactionsDisplay(
    BuildContext context,
    Message message,
    ColorScheme colorScheme,
  ) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: message.reactions.entries.map((entry) {
        final emoji = entry.key;
        final count = entry.value;
        final status = message.reactionStatuses[emoji];
        final isPending =
            status == MessageStatus.pending || status == MessageStatus.sent;
        final isFailed = status == MessageStatus.failed;

        return GestureDetector(
          onTap: isFailed && onRetryReaction != null
              ? () => onRetryReaction!(message, emoji)
              : () => showReactionDetails(
                  context,
                  reactions: message.reactions,
                  senders: message.reactionSenders,
                  initialEmoji: emoji,
                ),
          child: Opacity(
            opacity: isPending ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: isFailed
                    ? colorScheme.errorContainer
                    : colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isFailed
                      ? colorScheme.error
                      : colorScheme.outline.withValues(alpha: 0.3),
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
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                  if (isPending) ...[
                    const SizedBox(width: 2),
                    SizedBox(
                      width: 8,
                      height: 8,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                  if (isFailed) ...[
                    const SizedBox(width: 2),
                    Icon(Icons.replay, size: 10, color: colorScheme.error),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Compact quote box above a reply's body — same shape as the channel
  /// screen's reply preview. With a resolved [replyTarget] it shows the
  /// original's full body (GIF thumbnail / location label for those) and
  /// taps scroll to it; otherwise only the wire snippet, not tappable.
  Widget _buildReplyQuote(
    BuildContext context,
    ReplyInfo reply,
    ColorScheme colorScheme,
    UiViewStateService uiState,
  ) {
    final warmLight = ChatColors.isLight(context);
    final connector = context.read<MeshCoreConnector>();
    final isOwnNode =
        replyTargetIsSelf || reply.mentionedNode == connector.selfName;
    final senderNameColors =
        context.read<AppSettingsService>().settings.senderNameColors;
    final headerColor = isOwnNode
        ? colorScheme.secondary
        : senderNameColors
            ? _getColorForName(reply.mentionedNode)
            : warmLight
                ? ChatColors.quoteBorder
                : colorScheme.onSecondaryContainer;
    final snippetColor = (warmLight
            ? ChatColors.bubbleText
            : colorScheme.onSecondaryContainer)
        .withValues(alpha: 0.7);

    final target = replyTarget;
    final quoteText = target == null
        ? (reply.snippet.isEmpty ? '' : '${reply.snippet}..')
        : (ChannelMessage.parseReply(target.text)?.actualMessage ??
            target.text);
    final gifId = target == null ? null : GifHelper.parseGif(quoteText);
    final poi = target == null ? null : _parsePoiMessage(quoteText);

    Widget? preview;
    if (gifId != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: uiState.renderGifs
            ? GifMessage(
                url: 'https://media.giphy.com/media/$gifId/giphy.gif',
                backgroundColor: colorScheme.surfaceContainerHighest,
                fallbackTextColor: snippetColor,
                maxSize: 80,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gif_box, size: 14, color: snippetColor),
                  const SizedBox(width: 4),
                  Text(
                    'GIF',
                    style: TextStyle(
                      fontSize: 12 * textScale,
                      color: snippetColor,
                    ),
                  ),
                ],
              ),
      );
    } else if (poi != null) {
      preview = Row(
        children: [
          Icon(Icons.location_on_outlined, size: 14, color: snippetColor),
          const SizedBox(width: 4),
          Text(
            context.l10n.chat_location,
            style: TextStyle(fontSize: 12 * textScale, color: snippetColor),
          ),
        ],
      );
    } else if (quoteText.isNotEmpty) {
      preview = Text(
        quoteText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12 * textScale,
          color: snippetColor,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return GestureDetector(
      onTap: onReplyTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: warmLight
              ? ChatColors.quoteBackground
              : colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: warmLight ? ChatColors.quoteBorder : colorScheme.secondary,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.chat_replyTo(reply.mentionedNode),
              style: TextStyle(
                fontSize: 11 * textScale,
                fontWeight: FontWeight.bold,
                color: headerColor,
              ),
            ),
            if (preview != null) ...[
              const SizedBox(height: 2),
              preview,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String senderName, ColorScheme colorScheme) {
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
    // Generate a consistent color based on the name hash
    final hash = name.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
      Colors.deepOrange,
    ];

    return colors[hash.abs() % colors.length];
  }

  /// One line that says where the send is in the attempt ladder. Delivered
  /// and failed always show; the in-flight detail only with tracing on.
  /// How a received packet reached us, from the hop count it reported:
  /// "route (N hops)". Zero hops wears the Direct pill by the sender name
  /// instead; null when the frame didn't say (older stored rows).
  String? _receivedKindLabel(BuildContext context) {
    final hops = message.pathLength;
    if (hops == null || hops <= 0) return null;
    return context.l10n.chat_kindRoute(hops);
  }

  /// Same pill as the channel screen: this copy of the message was heard
  /// with zero hops — our radio heard theirs, no repeater in between.
  Widget _buildDirectPill(BuildContext context) {
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

  String _routeKind(BuildContext context) {
    final l10n = context.l10n;
    final hops = message.pathLength;
    if (hops == null || hops < 0) return l10n.chat_kindFlood;
    if (hops == 0) return l10n.chat_kindDirect;
    return l10n.chat_kindRoute(hops);
  }

  String get _tripSecs =>
      ((message.tripTimeMs ?? 0) / 1000).toStringAsFixed(1);

  String? _deliveryStatus(BuildContext context, {required bool detailed}) {
    final l10n = context.l10n;
    final m = message;
    String kind() => _routeKind(context);
    final secs = _tripSecs;
    switch (m.status) {
      case MessageStatus.delivered:
        if (!detailed) return l10n.chat_statusDeliveredShort(secs);
        if (m.deliveredLate) return l10n.chat_statusDeliveredLate(kind(), secs);
        if (m.retryCount > 0) {
          return l10n.chat_statusDeliveredAttempt(m.retryCount + 1, kind(), secs);
        }
        return l10n.chat_statusDelivered(kind(), secs);
      case MessageStatus.failed:
        return detailed
            ? l10n.chat_statusFailed(m.retryCount + 1)
            : l10n.chat_statusFailedShort;
      case MessageStatus.pending:
      case MessageStatus.sent:
        if (!detailed) return null;
        if (context.read<MessageRetryService>().isQueued(m.messageId)) {
          return l10n.chat_statusQueued;
        }
        if (m.retryCount > 0) {
          final max = context.read<AppSettingsService>().settings.maxMessageRetries;
          return l10n.chat_statusRetrying(m.retryCount + 1, max, kind());
        }
        return l10n.chat_statusSending(kind());
    }
  }

  Widget _buildStatusIcon(Color color) {
    IconData icon;
    switch (message.status) {
      case MessageStatus.pending:
        icon = Icons.access_time;
        break;
      case MessageStatus.sent:
        icon = Icons.schedule;
        break;
      case MessageStatus.delivered:
        icon = Icons.check;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        break;
    }

    return Icon(icon, size: 12, color: color);
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

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _PoiInfo {
  final double lat;
  final double lon;
  final String label;

  const _PoiInfo({required this.lat, required this.lon, required this.label});
}
