import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Route;
import 'package:traxmap/traxmap.dart' show LatLng, MapCamera;
import 'package:traxroute/traxroute.dart' show RouteResult;
import 'package:traxwater/traxwater.dart' show WaterTrip;

import '../models/map_focus.dart';
import '../storage/prefs_manager.dart';
import '../utils/contact_search.dart';

const String contactsAllGroupsValue = '__all__';

enum ChannelSortOption { manual, name, latestMessages, unread }

/// The main map's route: where to, a start picked on the map (null: your
/// position) and the route found (null: still to find), on land
/// ([RouteResult]) or on the water ([WaterTrip]).
typedef MapRoute<R> = ({
  String name,
  LatLng to,
  LatLng? from,
  R? result,
  LatLng? foundFrom,
  DateTime? foundAt,
});

class UiViewStateService extends ChangeNotifier {
  static const _keyContactsSelectedGroupName = 'ui_contacts_selected_group';
  static const _keyContactsSortOption = 'ui_contacts_sort_option';
  static const _keyContactsShowUnreadOnly = 'ui_contacts_show_unread_only';
  static const _keyContactsTypeFilter = 'ui_contacts_type_filter';
  static const _keyRepeatersSortOption = 'ui_repeaters_sort_option';
  static const _keyRepeatersTypeFilter = 'ui_repeaters_type_filter';
  static const _keyRepeatersHeardWithin = 'ui_repeaters_heard_within';
  static const _keyChannelsSortOption = 'ui_channels_sort_option';
  static const _keyChannelsSortIndexLegacy = 'ui_channels_sort_index';
  static const _keyRenderGifs = 'ui_render_gifs';
  static const _keySendGifsAsLinks = 'ui_send_gifs_as_links';
  static const _keyMapCamera = 'ui_map_camera';
  static const _keyDismissedPins = 'ui_dismissed_pins';
  static const _maxDismissedPerChat = 50;
  static const _keyDrafts = 'ui_drafts';
  static const _draftSaveDelay = Duration(seconds: 1);

  String _contactsSelectedGroupName = contactsAllGroupsValue;
  String _contactsSearchText = '';
  bool _contactsSearchExpanded = false;
  ContactSortOption _contactsSortOption = ContactSortOption.lastSeen;
  bool _contactsShowUnreadOnly = false;
  ContactTypeFilter _contactsTypeFilter = ContactTypeFilter.all;
  ContactSortOption _repeatersSortOption = ContactSortOption.lastSeen;
  ContactTypeFilter _repeatersTypeFilter = ContactTypeFilter.all;
  HeardWithin _repeatersHeardWithin = HeardWithin.anyTime;

  String _channelsSearchText = '';
  ChannelSortOption _channelsSortOption = ChannelSortOption.manual;
  bool _renderGifs = true;
  bool _sendGifsAsLinks = true;
  MapCamera? _mapCamera;
  bool _mapShownThisRun = false;

  /// Pinned-bar dismissals per chat: chat id → message ids the viewer closed.
  Map<String, List<String>> _dismissedPins = {};

  Set<String> dismissedPins(String chatId) =>
      (_dismissedPins[chatId] ?? const <String>[]).toSet();

  /// Unsent composer text per chat, by the same chat ids as the pins.
  /// Replaced, never changed in place, so a select sees a new draft.
  Map<String, String> _drafts = const {};
  Timer? _draftSave;

  Map<String, String> get drafts => _drafts;

  String draft(String chatId) => _drafts[chatId] ?? '';

  String get contactsSelectedGroupName => _contactsSelectedGroupName;
  String get contactsSearchText => _contactsSearchText;
  bool get contactsSearchExpanded => _contactsSearchExpanded;
  ContactSortOption get contactsSortOption => _contactsSortOption;
  bool get contactsShowUnreadOnly => _contactsShowUnreadOnly;
  ContactTypeFilter get contactsTypeFilter => _contactsTypeFilter;
  ContactSortOption get repeatersSortOption => _repeatersSortOption;
  ContactTypeFilter get repeatersTypeFilter => _repeatersTypeFilter;
  HeardWithin get repeatersHeardWithin => _repeatersHeardWithin;
  String get channelsSearchText => _channelsSearchText;
  ChannelSortOption get channelsSortOption => _channelsSortOption;
  bool get renderGifs => _renderGifs;
  bool get sendGifsAsLinks => _sendGifsAsLinks;

  /// Where the main map was last left (MapLibre zoom). Back on the map in
  /// the same run it opens there; the first map of a run opens there only
  /// with nothing else to show.
  MapCamera? get mapCamera => _mapCamera;

  /// Whether the main map has been shown since the app started.
  bool get mapShownThisRun => _mapShownThisRun;

  /// Set once the main map has gone to your GPS position since the app
  /// started, or you touched it or it was asked to show something before it
  /// could: it goes there by itself once a run. Not saved.
  bool mapWentToGps = false;

  /// The Map tab's route, kept as it changes: the quick switch puts another
  /// screen in the map's place, and the route is there when the map is back.
  /// A route started on a map over a chat is kept here too. Not saved, so it
  /// goes with the app.
  MapRoute<RouteResult>? mapRoute;

  /// Whether the Map tab has shown [mapRoute]. A route started on a map
  /// over a chat is shown whole there the first time.
  bool mapRouteSeen = true;

  /// The Map tab's trip on the water, kept as [mapRoute] is: charts show it
  /// in the route's place.
  MapRoute<WaterTrip>? mapWaterRoute;

  /// Whether the Map tab has shown [mapWaterRoute].
  bool mapWaterRouteSeen = true;

  /// The maps open now, the Map tab or ones over other screens, by route:
  /// how to show each something. What you tap on a map shows on it, never
  /// on a second map over it.
  final Map<Route<Object?>, ValueChanged<MapFocus>> openMaps = {};

  /// The Chats tab while it is open: the map shown from it takes its place.
  Route<Object?>? chatsTab;

  Future<void> initialize() async {
    final prefs = PrefsManager.instance;

    final selectedGroupName = prefs.getString(_keyContactsSelectedGroupName);
    if (selectedGroupName != null && selectedGroupName.isNotEmpty) {
      _contactsSelectedGroupName = selectedGroupName;
    }

    final sortStr = prefs.getString(_keyContactsSortOption);
    if (sortStr != null) {
      _contactsSortOption = ContactSortOption.values.firstWhere(
        (e) => e.name == sortStr,
        orElse: () => ContactSortOption.lastSeen,
      );
    }

    _contactsShowUnreadOnly =
        prefs.getBool(_keyContactsShowUnreadOnly) ?? false;

    final typeStr = prefs.getString(_keyContactsTypeFilter);
    if (typeStr != null) {
      _contactsTypeFilter = ContactTypeFilter.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => ContactTypeFilter.all,
      );
    }

    final repeatersSortStr = prefs.getString(_keyRepeatersSortOption);
    if (repeatersSortStr != null) {
      _repeatersSortOption = ContactSortOption.values.firstWhere(
        (e) => e.name == repeatersSortStr,
        orElse: () => ContactSortOption.lastSeen,
      );
    }

    final repeatersTypeStr = prefs.getString(_keyRepeatersTypeFilter);
    if (repeatersTypeStr != null) {
      _repeatersTypeFilter = ContactTypeFilter.values.firstWhere(
        (e) => e.name == repeatersTypeStr,
        orElse: () => ContactTypeFilter.all,
      );
    }

    final heardStr = prefs.getString(_keyRepeatersHeardWithin);
    _repeatersHeardWithin = HeardWithin.values.firstWhere(
      (e) => e.name == heardStr,
      orElse: () => HeardWithin.anyTime,
    );

    _renderGifs = prefs.getBool(_keyRenderGifs) ?? true;
    _sendGifsAsLinks = prefs.getBool(_keySendGifsAsLinks) ?? true;

    final camera = prefs.getStringList(_keyMapCamera)?.map(double.tryParse);
    if (camera != null && camera.length == 3 && !camera.contains(null)) {
      final [lat, lon, zoom] = camera.cast<double>().toList();
      _mapCamera = MapCamera(center: LatLng(lat, lon), zoom: zoom);
    }

    final pinsJson = prefs.getString(_keyDismissedPins);
    if (pinsJson != null) {
      try {
        final decoded = jsonDecode(pinsJson) as Map<String, dynamic>;
        _dismissedPins = {
          for (final e in decoded.entries)
            e.key: (e.value as List).cast<String>(),
        };
      } catch (_) {
        _dismissedPins = {};
      }
    }

    final draftsJson = prefs.getString(_keyDrafts);
    if (draftsJson != null) {
      try {
        _drafts = Map.unmodifiable(
          (jsonDecode(draftsJson) as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, v as String)),
        );
      } catch (_) {
        _drafts = const {};
      }
    }

    final channelSortStr = prefs.getString(_keyChannelsSortOption);
    if (channelSortStr != null) {
      _channelsSortOption = ChannelSortOption.values.firstWhere(
        (e) => e.name == channelSortStr,
        orElse: () => ChannelSortOption.manual,
      );
      return;
    }

    // Backward compatibility for old persisted index format.
    switch (prefs.getInt(_keyChannelsSortIndexLegacy) ?? 0) {
      case 0:
        _channelsSortOption = ChannelSortOption.manual;
        break;
      case 1:
        _channelsSortOption = ChannelSortOption.name;
        break;
      case 2:
        _channelsSortOption = ChannelSortOption.latestMessages;
        break;
      case 3:
        _channelsSortOption = ChannelSortOption.unread;
        break;
      default:
        _channelsSortOption = ChannelSortOption.manual;
    }
  }

  void setContactsSelectedGroupName(String value) {
    if (_contactsSelectedGroupName == value) return;
    _contactsSelectedGroupName = value;
    notifyListeners();
    unawaited(
      PrefsManager.instance.setString(_keyContactsSelectedGroupName, value),
    );
  }

  void setContactsSearchText(String value) {
    if (_contactsSearchText == value) return;
    _contactsSearchText = value;
    notifyListeners();
  }

  void setContactsSearchExpanded(bool value) {
    if (_contactsSearchExpanded == value) return;
    _contactsSearchExpanded = value;
    notifyListeners();
  }

  void setContactsSortOption(ContactSortOption value) {
    if (_contactsSortOption == value) return;
    _contactsSortOption = value;
    notifyListeners();
    unawaited(
      PrefsManager.instance.setString(_keyContactsSortOption, value.name),
    );
  }

  void setContactsShowUnreadOnly(bool value) {
    if (_contactsShowUnreadOnly == value) return;
    _contactsShowUnreadOnly = value;
    notifyListeners();
    unawaited(PrefsManager.instance.setBool(_keyContactsShowUnreadOnly, value));
  }

  void setContactsTypeFilter(ContactTypeFilter value) {
    if (_contactsTypeFilter == value) return;
    _contactsTypeFilter = value;
    notifyListeners();
    unawaited(
      PrefsManager.instance.setString(_keyContactsTypeFilter, value.name),
    );
  }

  void setRepeatersSortOption(ContactSortOption value) {
    if (_repeatersSortOption == value) return;
    _repeatersSortOption = value;
    notifyListeners();
    unawaited(
      PrefsManager.instance.setString(_keyRepeatersSortOption, value.name),
    );
  }

  void setRepeatersTypeFilter(ContactTypeFilter value) {
    if (_repeatersTypeFilter == value) return;
    _repeatersTypeFilter = value;
    notifyListeners();
    unawaited(
      PrefsManager.instance.setString(_keyRepeatersTypeFilter, value.name),
    );
  }

  void setRepeatersHeardWithin(HeardWithin value) {
    if (_repeatersHeardWithin == value) return;
    _repeatersHeardWithin = value;
    notifyListeners();
    unawaited(
      PrefsManager.instance.setString(_keyRepeatersHeardWithin, value.name),
    );
  }

  void setChannelsSearchText(String value) {
    if (_channelsSearchText == value) return;
    _channelsSearchText = value;
    notifyListeners();
  }

  void setChannelsSortOption(ChannelSortOption value) {
    if (_channelsSortOption == value) return;
    _channelsSortOption = value;
    notifyListeners();
    unawaited(
      PrefsManager.instance.setString(_keyChannelsSortOption, value.name),
    );
  }

  void setRenderGifs(bool value) {
    if (_renderGifs == value) return;
    _renderGifs = value;
    notifyListeners();
    unawaited(PrefsManager.instance.setBool(_keyRenderGifs, value));
  }

  void setSendGifsAsLinks(bool value) {
    if (_sendGifsAsLinks == value) return;
    _sendGifsAsLinks = value;
    notifyListeners();
    unawaited(PrefsManager.instance.setBool(_keySendGifsAsLinks, value));
  }

  /// Keeps where the main map is; with [save], on the device too.
  void setMapCamera(MapCamera value, {bool save = true}) {
    _mapCamera = value;
    _mapShownThisRun = true;
    if (!save) return;
    unawaited(
      PrefsManager.instance.setStringList(_keyMapCamera, [
        '${value.center.latitude}',
        '${value.center.longitude}',
        '${value.zoom}',
      ]),
    );
  }

  /// Keeps [text] as [chatId]'s draft; blank text clears it. Saved to the
  /// device shortly after the last change, so an app killed mid-sentence
  /// keeps it. Quiet while typing: bubbles watch this service, so the chats
  /// list hears only from [flushDrafts].
  void setDraft(String chatId, String text) {
    final value = text.trim().isEmpty ? '' : text;
    if (draft(chatId) == value) return;
    _drafts = Map.unmodifiable(
      value.isEmpty
          ? ({..._drafts}..remove(chatId))
          : {..._drafts, chatId: value},
    );
    _draftSave?.cancel();
    _draftSave = Timer(_draftSaveDelay, _saveDrafts);
  }

  /// A chat is closing: save now and let the chats list show its draft.
  /// It writes nothing itself: the screen wrote every change as it happened,
  /// so with two screens open on one chat, the one closing last cannot bring
  /// back a draft the other sent. The notify waits a microtask, since a
  /// route's dispose runs while the widget tree is locked.
  void flushDrafts() {
    _draftSave?.cancel();
    _saveDrafts();
    scheduleMicrotask(notifyListeners);
  }

  void _saveDrafts() {
    _draftSave = null;
    unawaited(
      PrefsManager.instance.setString(_keyDrafts, jsonEncode(_drafts)),
    );
  }

  void dismissPin(String chatId, String messageId) {
    final list = List<String>.from(_dismissedPins[chatId] ?? const []);
    if (list.contains(messageId)) return;
    list.add(messageId);
    if (list.length > _maxDismissedPerChat) list.removeAt(0);
    _dismissedPins = {..._dismissedPins, chatId: list};
    notifyListeners();
    unawaited(
      PrefsManager.instance
          .setString(_keyDismissedPins, jsonEncode(_dismissedPins)),
    );
  }
}
