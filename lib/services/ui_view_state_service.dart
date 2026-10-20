import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:traxmap/traxmap.dart' show LatLng, MapCamera;

import '../storage/prefs_manager.dart';
import '../utils/contact_search.dart';

const String contactsAllGroupsValue = '__all__';

enum ChannelSortOption { manual, name, latestMessages, unread }

class UiViewStateService extends ChangeNotifier {
  static const _keyContactsSelectedGroupName = 'ui_contacts_selected_group';
  static const _keyContactsSortOption = 'ui_contacts_sort_option';
  static const _keyContactsShowUnreadOnly = 'ui_contacts_show_unread_only';
  static const _keyContactsTypeFilter = 'ui_contacts_type_filter';
  static const _keyChannelsSortOption = 'ui_channels_sort_option';
  static const _keyChannelsSortIndexLegacy = 'ui_channels_sort_index';
  static const _keyRenderGifs = 'ui_render_gifs';
  static const _keySendGifsAsLinks = 'ui_send_gifs_as_links';
  static const _keyMapCamera = 'ui_map_camera';
  static const _keyDismissedPins = 'ui_dismissed_pins';
  static const _maxDismissedPerChat = 50;

  String _contactsSelectedGroupName = contactsAllGroupsValue;
  String _contactsSearchText = '';
  bool _contactsSearchExpanded = false;
  ContactSortOption _contactsSortOption = ContactSortOption.lastSeen;
  bool _contactsShowUnreadOnly = false;
  ContactTypeFilter _contactsTypeFilter = ContactTypeFilter.all;

  String _channelsSearchText = '';
  ChannelSortOption _channelsSortOption = ChannelSortOption.manual;
  bool _renderGifs = true;
  bool _sendGifsAsLinks = true;
  MapCamera? _mapCamera;

  /// Pinned-bar dismissals per chat: chat id → message ids the viewer closed.
  Map<String, List<String>> _dismissedPins = {};

  Set<String> dismissedPins(String chatId) =>
      (_dismissedPins[chatId] ?? const <String>[]).toSet();

  String get contactsSelectedGroupName => _contactsSelectedGroupName;
  String get contactsSearchText => _contactsSearchText;
  bool get contactsSearchExpanded => _contactsSearchExpanded;
  ContactSortOption get contactsSortOption => _contactsSortOption;
  bool get contactsShowUnreadOnly => _contactsShowUnreadOnly;
  ContactTypeFilter get contactsTypeFilter => _contactsTypeFilter;
  String get channelsSearchText => _channelsSearchText;
  ChannelSortOption get channelsSortOption => _channelsSortOption;
  bool get renderGifs => _renderGifs;
  bool get sendGifsAsLinks => _sendGifsAsLinks;

  /// Where the main map was last left (MapLibre zoom), for opening it with
  /// nothing else to show.
  MapCamera? get mapCamera => _mapCamera;

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

  void setMapCamera(MapCamera value) {
    _mapCamera = value;
    unawaited(
      PrefsManager.instance.setStringList(_keyMapCamera, [
        '${value.center.latitude}',
        '${value.center.longitude}',
        '${value.zoom}',
      ]),
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
