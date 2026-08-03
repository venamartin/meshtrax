import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/export.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_blue_plus_platform_interface/flutter_blue_plus_platform_interface.dart';

import '../models/channel.dart';
import '../models/channel_message.dart';
import '../models/companion_radio_stats.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../models/path_selection.dart';
import '../helpers/path_helper.dart';
import '../helpers/reaction_helper.dart';
import '../helpers/smaz.dart';
import '../services/app_debug_log_service.dart';
import '../services/ble_debug_log_service.dart';
import '../services/linux_ble_error_classifier.dart';
import '../services/linux_ble_pairing_service_stub.dart'
    if (dart.library.io) '../services/linux_ble_pairing_service.dart';
import '../services/message_retry_service.dart';
import '../services/path_history_service.dart';
import '../services/app_settings_service.dart';
import '../services/background_service.dart';
import '../services/timeout_prediction_service.dart';
import '../services/notification_service.dart';
import 'meshcore_connector_usb.dart';
import 'meshcore_connector_tcp.dart';
import '../storage/channel_message_store.dart';
import '../storage/channel_order_store.dart';
import '../storage/channel_settings_store.dart';
import '../storage/channel_store.dart';
import '../storage/contact_discovery_store.dart';
import '../storage/contact_settings_store.dart';
import '../storage/contact_store.dart';
import '../storage/message_store.dart';
import '../storage/prefs_manager.dart';
import '../utils/app_logger.dart';
import '../utils/battery_utils.dart';
import '../utils/platform_info.dart';
import 'meshcore_uuids.dart';
import 'meshcore_protocol.dart';

class DirectRepeater {
  static const int maxAgeMinutes = 30; // Max age for direct repeater info
  final Uint8List pubkeyPrefix; // leading bytes of the pub key (on-air hash)
  Uint8List? publicKey;
  String? name;
  double snr;
  DateTime lastUpdated;

  DirectRepeater({
    required this.pubkeyPrefix,
    this.publicKey,
    this.name,
    required this.snr,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  String get prefixHex => pubkeyPrefix
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join()
      .toUpperCase();

  /// True when [hash] (a hop hash or public key) agrees with this repeater's
  /// prefix on their common leading bytes.
  bool matchesHash(List<int> hash) {
    if (pubkeyPrefix.isEmpty || hash.isEmpty) return false;
    final n = math.min(pubkeyPrefix.length, hash.length);
    for (var i = 0; i < n; i++) {
      if (pubkeyPrefix[i] != hash[i]) return false;
    }
    return true;
  }

  /// True when this repeater is the first hop of [pathBytes].
  bool matchesFirstHopOf(List<int> pathBytes, {int stride = 1}) {
    if (pathBytes.isEmpty) return false;
    return matchesHash(pathBytes.sublist(0, math.min(stride, pathBytes.length)));
  }

  void update(double newSNR) {
    snr = newSNR;
    lastUpdated = DateTime.now();
  }

  static int compare(DirectRepeater a, DirectRepeater b) {
    final snrCmp = b.snr.compareTo(a.snr);
    if (snrCmp != 0) return snrCmp;
    return b.lastUpdated.compareTo(a.lastUpdated);
  }

  bool isStale() {
    return DateTime.now().difference(lastUpdated) >
        const Duration(minutes: maxAgeMinutes);
  }
}

enum MeshCoreConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  disconnecting,
}

enum MeshCoreTransportType { bluetooth, usb, tcp }

class RepeaterBatterySnapshot {
  final int millivolts;
  final DateTime updatedAt;
  final String source;

  const RepeaterBatterySnapshot({
    required this.millivolts,
    required this.updatedAt,
    required this.source,
  });
}

class MeshCoreRadioStateSnapshot {
  final int freqHz;
  final int bwHz;
  final int sf;
  final int cr;
  final int txPowerDbm;

  const MeshCoreRadioStateSnapshot({
    required this.freqHz,
    required this.bwHz,
    required this.sf,
    required this.cr,
    required this.txPowerDbm,
  });
}

enum PathState {
  unknown,
  searching,
  found,
  failed,
}

enum SyncStatus {
  deviceInfo,
  contacts,
  channels,
  messages,
}

/// What can be done about a radio whose clock disagrees with the phone's.
enum DeviceClockAction {
  /// Close enough to leave alone.
  ok,

  /// The radio is behind us; the firmware accepts a forward set.
  windForward,

  /// The radio is ahead of us, and CMD_SET_DEVICE_TIME rejects any time
  /// earlier than the radio's own, so this app cannot fix it.
  stuckAhead,
}

class MeshCoreConnector extends ChangeNotifier {
  // Message windowing to limit memory usage

  MeshCoreConnectionState _state = MeshCoreConnectionState.disconnected;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxCharacteristic;
  BluetoothCharacteristic? _txCharacteristic;
  String? _deviceDisplayName;
  String? _deviceId;
  BluetoothDevice? _lastDevice;
  String? _lastDeviceId;
  String? _lastDeviceDisplayName;
  bool _launchAutoConnectAttempted = false;
  static const String _lastBleDeviceIdKey = 'last_ble_device_id';
  static const String _lastBleDeviceNameKey = 'last_ble_device_name';
  bool _manualDisconnect = false;
  final MeshCoreUsbManager _usbManager = MeshCoreUsbManager();
  final LinuxBlePairingService _linuxBlePairingService =
      LinuxBlePairingService();
  StreamSubscription<Uint8List>? _usbFrameSubscription;
  final MeshCoreTcpConnector _tcpConnector = MeshCoreTcpConnector();
  MeshCoreTransportType _activeTransport = MeshCoreTransportType.bluetooth;

  final List<ScanResult> _scanResults = [];
  final List<ScanResult> _linuxSystemScanResults = [];
  final List<Contact> _contacts = [];
  final List<Contact> _discoveredContacts = [];
  final List<Channel> _channels = [];
  /// Mirror of the watched per-channel unread COUNT query — lets legacy
  /// synchronous callers (badges, notification totals) read DB-authoritative
  /// values. Single writer: the subscription in
  /// [_resubscribeChannelUnreadWatch].
  Map<String, int> _channelUnreadByIdKey = const {};
  StreamSubscription<Map<String, int>>? _channelUnreadSub;
  Map<String, ({ChannelMessage message, int arrivalUs})>
      _channelLatestByIdKey = const {};
  StreamSubscription<Map<String, ({ChannelMessage message, int arrivalUs})>>?
      _channelLatestSub;
  Map<String, int> _contactUnreadByKey = const {};
  StreamSubscription<Map<String, int>>? _contactUnreadSub;
  Map<String, ({Message message, int arrivalUs})> _contactLatestByKey =
      const {};
  StreamSubscription<Map<String, ({Message message, int arrivalUs})>>?
      _contactLatestSub;
  final List<String> _pendingChannelSentQueue = [];
  final List<_PendingCommandAck> _pendingGenericAckQueue = [];
  static const String _reactionSendQueuePrefix = '__reaction_send__';
  int _reactionSendQueueSequence = 0;
  final Map<String, Set<String>> _processedChannelReactions =
      {}; // channel idKey -> Set of "targetHash_emoji"
  final Map<String, Set<String>> _processedContactReactions =
      {}; // contactPubKeyHex -> Set of "targetHash_emoji"
  final Map<String, DateTime> _localDiscoveredTimes = {};

  DateTime? getLocalDiscoveredTime(String pubKeyHex) {
    return _localDiscoveredTimes[pubKeyHex];
  }

  // Room server admin sessions for this connection, keyed by room pubkey hex.
  // Lets the room chat offer the management hub without re-prompting for the
  // password; cleared on disconnect.
  final Map<String, String> _roomAdminPasswords = {};

  void recordRoomLogin(String pubKeyHex, String password, bool isAdmin) {
    if (isAdmin) {
      _roomAdminPasswords[pubKeyHex] = password;
    } else {
      _roomAdminPasswords.remove(pubKeyHex);
    }
    notifyListeners();
  }

  String? roomAdminPassword(String pubKeyHex) => _roomAdminPasswords[pubKeyHex];

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notifySubscription;
  Timer? _notifyListenersTimer;
  Timer? _selfInfoRetryTimer;
  Timer? _reconnectTimer;
  Timer? _batteryPollTimer;
  Timer? _gpsPollTimer;
  Timer? _radioStatsPollTimer;
  final Map<String, Timer> _channelMessageTimers = {};
  final Map<String, Timer> _channelRepeatTimers = {};
  final Map<String, int> _channelMessageRetries = {};
  int _radioStatsPollRefCount = 0;
  final ValueNotifier<CompanionRadioStats?> radioStatsNotifier =
      ValueNotifier<CompanionRadioStats?>(null);
  int _reconnectAttempts = 0;
  bool _notifyListenersDirty = false;
  static const Duration _notifyListenersDebounce = Duration(milliseconds: 50);

  final StreamController<Uint8List> _receivedFramesController =
      StreamController<Uint8List>.broadcast();
  final StreamController<int> _errorStreamController =
      StreamController<int>.broadcast();

  Uint8List? _selfPublicKey;
  String? _selfName;
  int? _currentTxPower;
  int? _maxTxPower;
  int? _currentFreqHz;
  int? _currentBwHz;
  int? _currentSf;
  int? _currentCr;
  bool? _clientRepeat;
  MeshCoreRadioStateSnapshot? _rememberedNonRepeatRadioState;
  int? _firmwareVerCode;
  String? _firmwareVersion;
  int _pathHashByteWidth = 1;
  CompanionRadioStats? _latestRadioStats;
  Stopwatch? _airtimeBumpStopwatch;
  int _prevTotalAirSecs = 0;
  int? _batteryMillivolts;
  double? _selfLatitude;
  double? _selfLongitude;
  final List<DirectRepeater> _directRepeaters = List.empty(growable: true);
  int? _pendingDiscoverTag;
  Timer? _discoverTimer;
  bool _isDiscovering = false;
  bool _isLoadingContacts = false;
  int _expectedContactsCount = 0;
  int _loadedContactsCount = 0;
  bool _isLoadingChannels = false;
  bool _hasLoadedChannels = false;
  TimeoutPredictionService? _timeoutPredictionService;
  // Intentionally global (not per-contact): tracks overall network activity.
  // Frequent RX from any source indicates a busy network with more collisions.
  DateTime _lastRxTime = DateTime.now();
  DateTime _lastRadioRxTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastContactMsgRxTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastChannelMsgRxTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _radioQuietMs = 3000;
  static const int _radioQuietMaxWaitMs = 3000;
  // Channel sends fire right after the inbound burst the user was reading, so
  // they need a longer window to find a quiet gap before transmitting into the
  // still-propagating mesh. DMs keep the shorter ceiling: their 15s pre-sent
  // safety timer leaves little slack for a long pre-send wait.
  static const int _channelRadioQuietMaxWaitMs = 8000;

  /// When companion radio stats are unavailable, keep the legacy fixed backoff.
  static const int _contactMsgBackoffFallbackMs = 5000;
  static const int _contactMsgBackoffMinMs = 500;
  static const int _contactMsgBackoffMaxMs = 15000;
  int _pollingInterval = 30;
  bool _batteryRequested = false;
  bool _awaitingSelfInfo = false;
  bool _hasReceivedDeviceInfo = false;
  bool _pendingInitialChannelSync = false;
  bool _pendingInitialContactsSync = false;
  bool _bleInitialSyncStarted = false;
  bool _pendingDeferredChannelSyncAfterContacts = false;
  bool _webInitialHandshakeRequestSent = false;
  bool _initialSyncComplete = false;
  bool _preserveContactsOnRefresh = false;
  bool _autoAddUsers = false;
  bool _autoAddRepeaters = false;
  bool _autoAddRoomServers = false;
  bool _autoAddSensors = false;
  bool _overwriteOldest = false;
  bool _manualAddContacts = false;
  int _telemetryModeBase = 0;
  int _telemetryModeLoc = 0;
  int _telemetryModeEnv = 0;
  int _advertLocPolicy = 0;
  int _multiAcks = 1; // Default to enabled (1 ACK)

  static const int _defaultMaxContacts = 32;
  static const int _defaultMaxChannels = 8;
  int _maxContacts = _defaultMaxContacts;
  int _maxChannels = _defaultMaxChannels;
  bool _isSyncingQueuedMessages = false;
  int _queuedMessagesRead = 0;
  bool _queuedMessageSyncInFlight = false;
  bool _didInitialQueueSync = false;
  bool _pendingQueueSync = false;
  bool _pendingChannelSyncAfterQueueSync = false;
  Timer? _queueSyncTimeout;
  int _queueSyncRetries = 0;
  static const int _maxQueueSyncRetries = 3;
  static const int _queueSyncTimeoutMs = 5000; // 5 second timeout
  // Serializes path operations (setContactPath/clearContactPath) to prevent
  // interleaved async calls from leaving in-memory state inconsistent with device.
  Future<void> _pathOpLock = Future.value();
  Map<String, String>? _currentCustomVars;

  // Channel syncing state (sequential pattern)
  bool _isSyncingChannels = false;
  bool _channelSyncInFlight = false;
  Timer? _channelSyncTimeout;
  int _channelSyncRetries = 0;
  int _nextChannelIndexToRequest = 0;
  int _totalChannelsToRequest = 0;
  List<Channel> _previousChannelsCache = [];
  static const int _maxChannelSyncRetries = 3;
  static const int _channelSyncTimeoutMs = 2000; // 2 second timeout per channel
  static const Duration _batteryPollInterval = Duration(seconds: 120);

  // Services
  MessageRetryService? _retryService;
  PathHistoryService? _pathHistoryService;
  AppSettingsService? _appSettingsService;
  BackgroundService? _backgroundService;
  final NotificationService _notificationService = NotificationService();
  BleDebugLogService? _bleDebugLogService;
  AppDebugLogService? _appDebugLogService;
  final ChannelMessageStore _channelMessageStore = ChannelMessageStore();
  final MessageStore _messageStore = MessageStore();
  final ChannelOrderStore _channelOrderStore = ChannelOrderStore();
  final ChannelSettingsStore _channelSettingsStore = ChannelSettingsStore();
  final ContactSettingsStore _contactSettingsStore = ContactSettingsStore();
  final ContactStore _contactStore = ContactStore();
  final ContactDiscoveryStore _discoveryContactStore = ContactDiscoveryStore();
  final ChannelStore _channelStore = ChannelStore();
  List<Channel> _cachedChannels = [];
  final Map<String, bool> _channelSmazEnabled = {}; // keyed by Channel.idKey
  bool _lastSentWasCliCommand =
      false; // Track if last sent message was a CLI command
  final Map<String, bool> _contactSmazEnabled = {};
  final Set<String> _knownContactKeys = {};
  final Map<String, RepeaterBatterySnapshot> _repeaterBatterySnapshots = {};
  final Map<String, _RepeaterAckContext> _pendingRepeaterAcks = {};
  String? _activeContactKey;
  int? _activeChannelIndex;
  List<int> _channelOrder = [];

  int _storageUsedKb = -1;
  int _storageTotalKb = -1;

  // Getters
  MeshCoreConnectionState get state => _state;
  BluetoothDevice? get device => _device;
  String? get deviceId => _deviceId;
  String get deviceIdLabel => _deviceId ?? 'Unknown';

  MeshCoreTransportType get activeTransport => _activeTransport;
  String? get activeUsbPort => _usbManager.activePortKey;
  String? get activeUsbPortDisplayLabel => _usbManager.activePortDisplayLabel;
  bool get isUsbTransportConnected =>
      _state == MeshCoreConnectionState.connected &&
      _activeTransport == MeshCoreTransportType.usb;
  bool get isAutoReconnectScheduled =>
      _shouldAutoReconnect && (_reconnectTimer?.isActive ?? false);
  /// True as soon as a non-manual disconnect occurs, even before the reconnect
  /// timer fires. Use this in build() checks to avoid the race where the timer
  /// hasn't been set yet when notifyListeners() triggers the first rebuild.
  bool get willAutoReconnect => _shouldAutoReconnect;
  String? get activeTcpEndpoint => _tcpConnector.activeEndpoint;
  bool get isTcpTransportConnected =>
      _state == MeshCoreConnectionState.connected &&
      _activeTransport == MeshCoreTransportType.tcp;

  String get deviceDisplayName {
    if (_selfName != null && _selfName!.isNotEmpty) {
      return _selfName!;
    }
    final platformName = _device?.platformName;
    if (platformName != null && platformName.isNotEmpty) {
      return platformName;
    }
    if (_deviceDisplayName != null && _deviceDisplayName!.isNotEmpty) {
      return _deviceDisplayName!;
    }
    return 'Unknown Device';
  }

  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);
  List<Contact> get contacts {
    final selfKey = _selfPublicKey;
    if (selfKey == null) {
      return List.unmodifiable(_contacts);
    }
    return List.unmodifiable(
      _contacts.where((contact) => !listEquals(contact.publicKey, selfKey)),
    );
  }

  List<Contact> get allContacts => List.unmodifiable([
    ..._contacts,
    ..._discoveredContacts.where(
      (c) => !c.isActive && c.publicKeyHex != selfPublicKeyHex,
    ),
  ]);

  List<Contact> get allContactsUnfiltered =>
      List.unmodifiable([..._contacts, ..._discoveredContacts]);

  List<Contact> get discoveredContacts {
    return List.unmodifiable(_discoveredContacts);
  }

  /// During a slot resync `_channels` is rebuilt from empty over several
  /// seconds (slow on BLE) — serving it raw made Public vanish from the UI
  /// on every phone reconnect (field-reported disappear/reappear; bench
  /// D10). Display always sees the last SETTLED table; filing and sending
  /// keep using the live one via [_liveChannelByIdKey].
  List<Channel> get channels => List.unmodifiable(
        _isSyncingChannels ? _previousChannelsCache : _channels,
      );

  /// True once this connection's slot map has been confirmed against the
  /// radio. Sends and slot-indexed filing stay blocked while false.
  bool get channelsVerified => _channelsVerified;
  bool get isConnected => _state == MeshCoreConnectionState.connected;
  bool get isLoadingContacts => _isLoadingContacts;
  bool get isLoadingChannels => _isLoadingChannels;
  Stream<Uint8List> get receivedFrames => _receivedFramesController.stream;
  Stream<int> get errorStream => _errorStreamController.stream;
  Uint8List? get selfPublicKey => _selfPublicKey;
  String get selfPublicKeyHex => pubKeyToHex(_selfPublicKey ?? Uint8List(0));
  String? get selfName => _selfName;
  double? get selfLatitude => _selfLatitude;
  double? get selfLongitude => _selfLongitude;
  List<DirectRepeater> get directRepeaters => _directRepeaters;
  bool get isDiscovering => _isDiscovering;
  int? get currentTxPower => _currentTxPower;
  int? get maxTxPower => _maxTxPower;

  int get pathHashByteWidth => _pathHashByteWidth;

  CompanionRadioStats? get latestRadioStats => _latestRadioStats;

  bool get supportsCompanionRadioStats => (_firmwareVerCode ?? 0) >= 8;

  bool get radioStatsAirActivityPulse {
    final sw = _airtimeBumpStopwatch;
    if (sw == null || !sw.isRunning) return false;
    return sw.elapsed < const Duration(seconds: 2);
  }

  int? get currentFreqHz => _currentFreqHz;
  int? get currentBwHz => _currentBwHz;
  int? get currentSf => _currentSf;
  int? get currentCr => _currentCr;
  MeshCoreRadioStateSnapshot? get rememberedNonRepeatRadioState =>
      _rememberedNonRepeatRadioState;
  bool? get autoAddUsers => _autoAddUsers;
  bool? get autoAddRepeaters => _autoAddRepeaters;
  bool? get autoAddRoomServers => _autoAddRoomServers;
  bool? get autoAddSensors => _autoAddSensors;
  bool? get autoAddOverwriteOldest => _overwriteOldest;
  int get telemetryModeBase => _telemetryModeBase;
  int get telemetryModeLoc => _telemetryModeLoc;
  int get telemetryModeEnv => _telemetryModeEnv;
  int get advertLocationPolicy => _advertLocPolicy;
  int get multiAcks => _multiAcks;
  bool? get clientRepeat => _clientRepeat;
  void rememberNonRepeatRadioState(MeshCoreRadioStateSnapshot snapshot) {
    _rememberedNonRepeatRadioState = snapshot;
  }

  int? get firmwareVerCode => _firmwareVerCode;
  String? get firmwareVersion => _firmwareVersion;
  Map<String, String>? get currentCustomVars => _currentCustomVars;
  int? get batteryMillivolts => _batteryMillivolts;
  int? get storageUsedKb => _storageUsedKb;
  int? get storageTotalKb => _storageTotalKb;
  int get maxContacts => _maxContacts;
  int get maxChannels => _maxChannels;
  Set<String> get knownContactKeys => Set.unmodifiable(_knownContactKeys);
  SyncStatus? get currentSyncStatus {
    if (_initialSyncComplete) return null;
    if (_awaitingSelfInfo) return SyncStatus.deviceInfo;
    if (_isLoadingContacts) return SyncStatus.contacts;
    if (_isLoadingChannels) return SyncStatus.channels;
    if (_isSyncingQueuedMessages) return SyncStatus.messages;
    return null;
  }

  bool get isSyncingQueuedMessages => _isSyncingQueuedMessages;
  int get queuedMessagesRead => _queuedMessagesRead;
  bool get isSyncingChannels => _isSyncingChannels;
  
  bool isChannelMessageRetrying(String messageId) {
    return _channelRepeatTimers.containsKey(messageId) || 
           _channelMessageTimers.containsKey(messageId);
  }
  int get channelSyncProgress =>
      _isSyncingChannels && _totalChannelsToRequest > 0
      ? ((_nextChannelIndexToRequest / _totalChannelsToRequest) * 100).round()
      : 0;
  int get loadedChannelsCount => _nextChannelIndexToRequest;
  int get expectedChannelsCount => _totalChannelsToRequest;
  int get loadedContactsCount => _loadedContactsCount;
  int get expectedContactsCount => _expectedContactsCount;
  int get contactsSyncProgress =>
      _isLoadingContacts && _expectedContactsCount > 0
          ? ((_loadedContactsCount / _expectedContactsCount) * 100).round()
          : 0;
  int? get batteryPercent => _batteryMillivolts == null
      ? null
      : estimateBatteryPercentFromMillivolts(
          _batteryMillivolts!,
          _batteryChemistryForDevice(),
        );
  RepeaterBatterySnapshot? getRepeaterBatterySnapshot(String contactKeyHex) =>
      _repeaterBatterySnapshots[contactKeyHex];
  int? getRepeaterBatteryMillivolts(String contactKeyHex) =>
      _repeaterBatterySnapshots[contactKeyHex]?.millivolts;

  void updateRepeaterBatterySnapshot(
    String contactKeyHex,
    int millivolts, {
    String source = 'unknown',
  }) {
    if (contactKeyHex.isEmpty || millivolts <= 0) return;
    final previous = _repeaterBatterySnapshots[contactKeyHex];
    final snapshot = RepeaterBatterySnapshot(
      millivolts: millivolts,
      updatedAt: DateTime.now(),
      source: source,
    );
    _repeaterBatterySnapshots[contactKeyHex] = snapshot;
    if (previous?.millivolts != millivolts) {
      notifyListeners();
    }
  }

  String _batteryChemistryForDevice() {
    final deviceId = _device?.remoteId.toString();
    if (deviceId == null || _appSettingsService == null) return 'nmc';
    return _appSettingsService!.batteryChemistryForDevice(deviceId);
  }

  Future<void> deleteMessage(Message message) async {
    await _messageStore.deleteMessage(
      message.senderKeyHex,
      message.messageId,
    );
    notifyListeners();
  }

  /// A contact became known this session: ensure its read watermark exists
  /// so pre-existing history never floods unread (Phase 3d — messages live
  /// in the database and reach the UI through watched queries).
  Future<void> _loadMessagesForContact(String contactKeyHex) async {
    await _messageStore.initializeReadMarkIfAbsent(contactKeyHex);
  }

  Channel? _liveChannelByIdKey(String idKey) {
    for (final c in _channels) {
      if (c.idKey == idKey) return c;
    }
    return null;
  }

  /// Live stream of a channel's messages — the UI's ONLY read path.
  /// Ordering, paging, and dedup belong to the database (Phase 3d);
  /// identity is the key, so slot churn and resyncs can't blank a screen.
  Stream<List<ChannelMessage>> watchChannelMessages(
    Channel channel, {
    int limit = 200,
  }) =>
      _channelMessageStore.watchChannelMessages(channel.idKey, limit: limit);

  /// One-shot read for non-reactive consumers (map pins, export, bench).
  Future<List<ChannelMessage>> loadChannelMessagesFor(Channel channel) =>
      _channelMessageStore.loadChannelMessages(channel.idKey);

  /// Watched unread counts per channel identity (chats-screen badges).
  Stream<Map<String, int>> watchChannelUnreadCounts() =>
      _channelMessageStore.watchUnreadCounts();

  /// Watched newest message per channel identity, with its arrival stamp
  /// (subtitles + tile ordering).
  Stream<Map<String, ({ChannelMessage message, int arrivalUs})>>
      watchChannelLatest() => _channelMessageStore.watchLatestPerChannel();

  // Messages received for a radio slot whose identity the app doesn't know
  // yet. Held until CHANNEL_INFO reveals the slot's channel, then filed by
  // identity — never stored under a bare index.
  final Map<int, List<ChannelMessage>> _pendingUntrackedChannelMessages = {};
  final Set<int> _slotsToRequery = {};
  bool _pendingQueueSyncAfterChannelSync = false;

  /// Set when a forced channel resync arrives while a pass is in flight
  /// (rapid setChannel/deleteChannel): the running pass may already be past
  /// the changed slot, so a follow-up pass runs when it completes.
  bool _pendingForceChannelResync = false;
  // Pubkey of the node whose per-node state is currently loaded; a change
  // means all channel state must be wiped before loading the new node's.
  String? _lastLoadedNodeKey;
  // False from disconnect until a channel sync completes on the current
  // connection. While false the slot->identity map may be stale (slots can
  // be rearranged externally while we're away), so slot-indexed messages
  // must buffer rather than file through it.
  bool _channelsVerified = false;
  // Sends attempted while the map was unverified. Messages file to the DB
  // at once (pending, keyed by the caller's trusted idKey) and transmit when
  // a sync pass completes; reactions wait as raw text (messageId == null).
  final List<({String idKey, String? messageId, String text})>
  _pendingUnverifiedSends = [];
  // Queued sends have no transmit timer of their own — the 30s send timeout is
  // armed only once a frame goes out. Without this a row whose map never
  // re-verifies sits on the pending clock forever, with no failure to retry.
  final Map<String, Timer> _unverifiedSendTimers = {};
  static const Duration _unverifiedSendMaxWait = Duration(seconds: 60);
  // Re-attempts a channel sync that died with the connection still up —
  // without it the session stays send-gated until the next reconnect.
  Timer? _channelSyncRetryTimer;

  Future<void> deleteChannelMessage(ChannelMessage message) async {
    final channelIndex = message.channelIndex;
    if (channelIndex == null) return;
    final channel = _findChannelByIndex(channelIndex);
    if (channel == null) return;
    await _channelMessageStore.deleteMessage(channel.idKey, message.messageId);
    notifyListeners();
  }

  int getUnreadCountForContact(Contact contact) {
    if (contact.type == advTypeRepeater) return 0;
    return getUnreadCountForContactKey(contact.publicKeyHex);
  }

  int getUnreadCountForContactKey(String contactKeyHex) {
    if (!_shouldTrackUnreadForContactKey(contactKeyHex)) return 0;
    return _contactUnreadByKey[contactKeyHex] ?? 0;
  }

  int getUnreadCountForChannel(Channel channel) {
    return _channelUnreadByIdKey[channel.idKey] ?? 0;
  }

  int getUnreadCountForChannelIndex(int channelIndex) {
    final channel = _findChannelByIndex(channelIndex);
    if (channel == null) return 0;
    return _channelUnreadByIdKey[channel.idKey] ?? 0;
  }

  int getTotalUnreadCount() {
    var total = 0;
    // Both sides come from watched COUNT queries (DB-authoritative).
    for (final contact in _contacts) {
      total += getUnreadCountForContact(contact);
    }
    for (final count in _channelUnreadByIdKey.values) {
      total += count;
    }
    return total;
  }

  bool isChannelSmazEnabled(int channelIndex) {
    final channel = _findChannelByIndex(channelIndex);
    if (channel == null) return false;
    return _channelSmazEnabled[channel.idKey] ?? false;
  }

  bool isContactSmazEnabled(String contactKeyHex) {
    return _contactSmazEnabled[contactKeyHex] ?? false;
  }

  void ensureContactSmazSettingLoaded(String contactKeyHex) {
    _ensureContactSmazSettingLoaded(contactKeyHex);
  }

  Future<void> loadCachedChannels() async {
    _cachedChannels = await _channelStore.loadChannels();
  }

  void setActiveContact(String? contactKeyHex) {
    if (contactKeyHex != null &&
        !_shouldTrackUnreadForContactKey(contactKeyHex)) {
      _activeContactKey = null;
      return;
    }
    _activeContactKey = contactKeyHex;
    if (contactKeyHex != null) {
      markContactRead(contactKeyHex);
    }
  }

  void setActiveChannel(int? channelIndex) {
    _activeChannelIndex = channelIndex;
    if (channelIndex != null) {
      markChannelRead(channelIndex);
    }
  }

  void markContactRead(String contactKeyHex) {
    if (!_shouldTrackUnreadForContactKey(contactKeyHex)) return;
    // The read watermark is the unread authority; the watched COUNT
    // updates every consumer.
    unawaited(_messageStore.markRead(contactKeyHex));
    _notificationService.clearContactNotification(
      contactKeyHex,
      getTotalUnreadCount(),
    );
    notifyListeners();
  }

  void markChannelRead(int channelIndex) {
    final channel = _findChannelByIndex(channelIndex);
    if (channel == null) return;
    channel.unreadCount = 0;
    // The read watermark is the unread authority; the watched COUNT updates
    // every consumer.
    unawaited(_channelMessageStore.markRead(channel.idKey));
    _notificationService.clearChannelNotification(
      channelIndex,
      getTotalUnreadCount(),
    );
    notifyListeners();
  }

  Future<void> setChannelSmazEnabled(int channelIndex, bool enabled) async {
    final channel = _findChannelByIndex(channelIndex);
    if (channel == null) return;
    _channelSmazEnabled[channel.idKey] = enabled;
    await _channelSettingsStore.saveSmazEnabled(channel.idKey, enabled);
    notifyListeners();
  }

  Future<void> setContactSmazEnabled(String contactKeyHex, bool enabled) async {
    _contactSmazEnabled[contactKeyHex] = enabled;
    await _contactSettingsStore.saveSmazEnabled(contactKeyHex, enabled);
    notifyListeners();
  }

  Future<void> _loadChannelOrder() async {
    _channelOrder = await _channelOrderStore.loadChannelOrder();
    _applyChannelOrder();
    notifyListeners();
  }

  void initialize({
    required MessageRetryService retryService,
    required PathHistoryService pathHistoryService,
    AppSettingsService? appSettingsService,
    BleDebugLogService? bleDebugLogService,
    AppDebugLogService? appDebugLogService,
    BackgroundService? backgroundService,
    TimeoutPredictionService? timeoutPredictionService,
  }) {
    _retryService = retryService;
    _pathHistoryService = pathHistoryService;
    _appSettingsService = appSettingsService;
    _bleDebugLogService = bleDebugLogService;
    _appDebugLogService = appDebugLogService;
    _backgroundService = backgroundService;
    _timeoutPredictionService = timeoutPredictionService;
    _usbManager.setDebugLogService(_appDebugLogService);
    _tcpConnector.setDebugLogService(_appDebugLogService);

    // Initialize notification service
    _notificationService.initialize();
    _loadChannelOrder();
    _restoreLastBleDevice();

    // Initialize retry service callbacks
    _retryService?.initialize(
      RetryServiceConfig(
        sendMessage: _sendMessageDirect,
        addMessage: _addMessage,
        updateMessage: _updateMessage,
        clearContactPath: clearContactPath,
        setContactPath: setContactPath,
        calculateTimeout: (pathLength, messageBytes, {String? contactKey}) =>
            calculateTimeout(
              pathLength: pathLength,
              messageBytes: messageBytes,
              contactKey: contactKey,
            ),
        getSelfPublicKey: () => _selfPublicKey,
        prepareContactOutboundText: prepareContactOutboundText,
        appSettingsService: appSettingsService,
        debugLogService: _appDebugLogService,
        recordPathResult: _recordPathResult,
        selectRetryPath:
            (contactKey, attemptIndex, maxRetries, recentSelections) =>
                _selectAutoPathForAttempt(
                  contactKey,
                  attemptIndex: attemptIndex,
                  maxRetries: maxRetries,
                  recentSelections: recentSelections,
                ),
        onDeliveryObserved: (contactKey, pathLength, messageBytes, tripTimeMs) {
          final secSinceRx = DateTime.now().difference(_lastRxTime).inSeconds;
          _timeoutPredictionService?.recordObservation(
            contactKey: contactKey,
            pathLength: pathLength,
            messageBytes: messageBytes,
            tripTimeMs: tripTimeMs,
            secondsSinceLastRx: secSinceRx,
          );
        },
      ),
    );
    final maxRetries = _appSettingsService?.settings.maxMessageRetries ?? 5;
    _retryService?.setMaxRetries(maxRetries);
  }

  Future<void> loadContactCache() async {
    final cached = await _contactStore.loadContacts();
    _knownContactKeys
      ..clear()
      ..addAll(cached.map((c) => c.publicKeyHex));
    _contacts
      ..clear()
      ..addAll(cached);
    for (final contact in cached) {
      _ensureContactSmazSettingLoaded(contact.publicKeyHex);
    }
  }

  Future<void> _loadDiscoveredContactCache() async {
    final cached = await _discoveryContactStore.loadContacts();
    _discoveredContacts
      ..clear()
      ..addAll(cached);
  }

  Future<void> loadChannelSettings({int? maxChannels}) async {
    _channelSmazEnabled.clear();
    final known = _channels.isNotEmpty ? _channels : _cachedChannels;
    for (final channel in known) {
      if (channel.isEmpty) continue;
      _channelSmazEnabled[channel.idKey] =
          await _channelSettingsStore.loadSmazEnabled(channel.idKey);
    }
  }

  /// After an incoming DM or channel message, wait before TX so we do not
  /// collide with mesh propagation. With companion stats, scale wait by RF
  /// conditions (up to [_contactMsgBackoffMaxMs]); otherwise use
  /// [_contactMsgBackoffFallbackMs].
  int _contactMessageBackoffTargetMs() {
    if (!supportsCompanionRadioStats || _latestRadioStats == null) {
      return _contactMsgBackoffFallbackMs;
    }
    final stats = _latestRadioStats!;
    final nf = stats.noiseFloorDbm.toDouble();
    // Quieter (more negative) → lower score; noisier → higher.
    const noiseQuietDbm = -118.0;
    const noiseNoisyDbm = -88.0;
    final noiseT = ((nf - noiseQuietDbm) / (noiseNoisyDbm - noiseQuietDbm))
        .clamp(0.0, 1.0);

    final snr = stats.lastSnrDb;
    const snrGood = 12.0;
    const snrBad = -2.0;
    final snrT = (1.0 - ((snr - snrBad) / (snrGood - snrBad))).clamp(0.0, 1.0);

    final airBusy = _recentAirtimeBusyFraction();
    final severity = (math.max(noiseT, snrT) * 0.82 + airBusy * 0.18).clamp(
      0.0,
      1.0,
    );

    return (_contactMsgBackoffMinMs +
            severity * (_contactMsgBackoffMaxMs - _contactMsgBackoffMinMs))
        .round();
  }

  /// 1.0 shortly after TX/RX airtime counters increase, decaying to 0 over ~8s.
  double _recentAirtimeBusyFraction() {
    final sw = _airtimeBumpStopwatch;
    if (sw == null || !sw.isRunning) return 0;
    final ms = sw.elapsedMilliseconds;
    const windowMs = 8000;
    if (ms >= windowMs) return 0;
    return 1.0 - (ms / windowMs);
  }

  /// Start of the post-inbound cool-down: the later of BLE message RX time and
  /// companion airtime bump ([_airtimeBumpStopwatch], same as the activity dot).
  DateTime _postTxBackoffAnchor(DateTime lastInboundRxTime) {
    if (!supportsCompanionRadioStats) return lastInboundRxTime;
    final sw = _airtimeBumpStopwatch;
    if (sw == null || !sw.isRunning) return lastInboundRxTime;
    final bumpAt = DateTime.now().subtract(sw.elapsed);
    return bumpAt.isAfter(lastInboundRxTime) ? bumpAt : lastInboundRxTime;
  }

  Future<void> _waitForRadioQuiet({
    required DateTime lastInboundRxTime,
    int maxQuietWaitMs = _radioQuietMaxWaitMs,
  }) async {
    // Wait for backoff after inbound traffic / RF airtime (avoid collision with
    // mesh propagation). Elapsed time uses the dot's airtime bump when newer.
    final backoffTargetMs = _contactMessageBackoffTargetMs();
    final anchor = _postTxBackoffAnchor(lastInboundRxTime);
    final msSinceAnchor = DateTime.now().difference(anchor).inMilliseconds;
    if (msSinceAnchor < backoffTargetMs) {
      final waitMs = backoffTargetMs - msSinceAnchor;
      debugPrint(
        'Post-inbound backoff: waiting ${waitMs}ms '
        '(target=${backoffTargetMs}ms, anchorAge=${msSinceAnchor}ms)',
      );
      await Future<void>.delayed(Duration(milliseconds: waitMs));
    }

    // Then wait for radio silence (no RF activity for 3s)
    final msSinceRx = DateTime.now()
        .difference(_lastRadioRxTime)
        .inMilliseconds;
    if (msSinceRx >= _radioQuietMs) return;

    final deadline = DateTime.now().add(
      Duration(milliseconds: maxQuietWaitMs),
    );
    while (DateTime.now().isBefore(deadline)) {
      final quiet = DateTime.now().difference(_lastRadioRxTime).inMilliseconds;
      if (quiet >= _radioQuietMs) {
        debugPrint('Radio quiet for ${quiet}ms, proceeding with send');
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    debugPrint(
      'Radio quiet wait exceeded ${maxQuietWaitMs}ms, sending anyway',
    );
  }

  Future<void> _sendMessageDirect(
    Contact contact,
    String text,
    int attempt,
    int timestampSeconds,
  ) async {
    if (!isConnected || text.isEmpty) return;
    try {
      await _waitForRadioQuiet(lastInboundRxTime: _lastContactMsgRxTime);
      final outboundText = prepareContactOutboundText(contact, text);
      await sendFrame(
        buildSendTextMsgFrame(
          contact.publicKey,
          outboundText,
          attempt: attempt,
          timestampSeconds: timestampSeconds,
        ),
      );
    } catch (e) {
      appLogger.error('Failed to send message: $e', tag: 'Connector');
    }
  }

  void _updateMessage(Message message) {
    final contactKey = pubKeyToHex(message.senderKey);
    unawaited(() async {
      final updated = await _messageStore.updateMessage(
        contactKey,
        message.messageId,
        (_) => message,
      );
      if (updated) notifyListeners();

      // A settled reaction send updates the target's reaction status row.
      final reactionInfo = ReactionHelper.parseReaction(message.text);
      if (reactionInfo != null &&
          (message.status == MessageStatus.delivered ||
              message.status == MessageStatus.failed)) {
        await _setReactionStatus(contactKey, reactionInfo, message.status);
        notifyListeners();
      }
    }());
  }


  void _recordPathResult(
    String contactPubKeyHex,
    PathSelection selection,
    bool success,
    int? tripTimeMs,
  ) {
    if (_pathHistoryService == null) return;
    final settings = _appSettingsService?.settings;
    _pathHistoryService!.recordPathResult(
      contactPubKeyHex,
      selection,
      success: success,
      tripTimeMs: tripTimeMs,
      successIncrement: settings?.routeWeightSuccessIncrement ?? 0.2,
      failureDecrement: settings?.routeWeightFailureDecrement ?? 0.2,
      maxWeight: settings?.maxRouteWeight ?? 5.0,
    );

    // Flood path attribution: when a flood delivery succeeds, credit the
    // contact's current device path so the route the ACK traveled back
    // through gets a weight boost in the path history.
    if (selection.useFlood && success) {
      final contact = _contacts.cast<Contact?>().firstWhere(
        (c) => c?.publicKeyHex == contactPubKeyHex,
        orElse: () => null,
      );
      if (contact != null &&
          contact.pathLength >= 0 &&
          contact.path.isNotEmpty) {
        _pathHistoryService!.recordFloodPathAttribution(
          contactPubKeyHex: contactPubKeyHex,
          pathBytes: contact.path,
          hopCount: contact.pathLength,
          tripTimeMs: tripTimeMs,
          successIncrement: settings?.routeWeightSuccessIncrement ?? 0.2,
          maxWeight: settings?.maxRouteWeight ?? 5.0,
        );
      }

      // Request a fresh contact from the device so the next flood
      // attribution uses the most up-to-date path.
      if (contact != null) {
        unawaited(getContactByKey(contact.publicKey));
      }
    }
  }

  PathSelection? _selectAutoPathForAttempt(
    String contactPubKeyHex, {
    required int attemptIndex,
    required int maxRetries,
    List<PathSelection> recentSelections = const [],
  }) {
    final hasKnownPaths =
        _pathHistoryService?.getRecentPaths(contactPubKeyHex).isNotEmpty ??
        false;
    if (!hasKnownPaths) {
      return null;
    }

    final selection = _pathHistoryService?.selectPathForAttempt(
      contactPubKeyHex,
      attemptIndex: attemptIndex,
      maxRetries: maxRetries,
      recentSelections: recentSelections,
    );
    if (selection != null) {
      _pathHistoryService?.recordPathAttempt(contactPubKeyHex, selection);
    }
    return selection;
  }

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_state == MeshCoreConnectionState.scanning) return;

    _scanResults.clear();
    _linuxSystemScanResults.clear();
    _setState(MeshCoreConnectionState.scanning);

    // Ensure any previous scan is fully stopped. Guard with isScanningNow to
    // avoid triggering stale native callbacks when no scan is active.
    if (FlutterBluePlus.isScanningNow) {
      try {
        await FlutterBluePlus.stopScan();
      } catch (e) {
        _appDebugLogService?.warn(
          'stopScan error in startScan (ignored): $e',
          tag: 'BLE Scan',
        );
      }
    }
    await _scanSubscription?.cancel();

    // On iOS/macOS, wait for Bluetooth to be powered on before scanning
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      // Wait for adapter state to be powered on
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        // Wait for the adapter to turn on, with timeout
        await FlutterBluePlus.adapterState
            .firstWhere((state) => state == BluetoothAdapterState.on)
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                _setState(MeshCoreConnectionState.disconnected);
                throw Exception('Bluetooth adapter not available');
              },
            );
      }

      // Add a small delay to allow BLE stack to fully initialize
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (PlatformInfo.isLinux) {
      await _loadLinuxSystemDevicesForScan();
    }

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults
        ..clear()
        ..addAll(results);
      _mergeLinuxSystemScanResults();
      notifyListeners();
    });

    try {
      await FlutterBluePlus.startScan(
        withKeywords: MeshCoreUuids.deviceNamePrefixes,
        webOptionalServices: [Guid(MeshCoreUuids.service)],
        timeout: timeout,
        androidScanMode: AndroidScanMode.lowLatency,
      );
    } catch (error) {
      _appDebugLogService?.warn('Scan/picker failure: $error', tag: 'BLE Scan');
      _setState(MeshCoreConnectionState.disconnected);
      rethrow;
    }

    await Future.delayed(timeout);
    await stopScan();
  }

  Future<void> _loadLinuxSystemDevicesForScan() async {
    try {
      final systemDevices = await FlutterBluePlus.systemDevices([
        Guid(MeshCoreUuids.service),
      ]);
      _linuxSystemScanResults
        ..clear()
        ..addAll(
          systemDevices
              .where(
                (device) => MeshCoreUuids.deviceNamePrefixes.any(
                  device.platformName.startsWith,
                ),
              )
              .map(
                (device) => ScanResult(
                  device: device,
                  advertisementData: AdvertisementData(
                    advName: device.platformName,
                    txPowerLevel: null,
                    appearance: null,
                    connectable: true,
                    manufacturerData: const <int, List<int>>{},
                    serviceData: const <Guid, List<int>>{},
                    serviceUuids: <Guid>[Guid(MeshCoreUuids.service)],
                  ),
                  rssi: 0,
                  timeStamp: DateTime.now(),
                ),
              ),
        );
      _mergeLinuxSystemScanResults();
      notifyListeners();
    } catch (error) {
      _appDebugLogService?.warn(
        'Failed loading Linux paired/system BLE devices: $error',
        tag: 'BLE Scan',
      );
    }
  }

  void _mergeLinuxSystemScanResults() {
    if (!PlatformInfo.isLinux || _linuxSystemScanResults.isEmpty) {
      return;
    }
    final existingIds = _scanResults
        .map((result) => result.device.remoteId.str)
        .toSet();
    for (final result in _linuxSystemScanResults) {
      if (existingIds.contains(result.device.remoteId.str)) {
        continue;
      }
      _scanResults.add(result);
    }
  }

  Future<void> stopScan() async {
    // Only call FlutterBluePlus.stopScan() when a scan is actually running.
    // Calling it when idle triggers a native BLE completion callback even
    // though no scan was started. After a hot restart Dart has already freed
    // those callback handles, so the callback crashes with
    // "Callback invoked after it has been deleted".
    if (FlutterBluePlus.isScanningNow) {
      try {
        await FlutterBluePlus.stopScan();
      } catch (e) {
        _appDebugLogService?.warn(
          'stopScan error (ignored): $e',
          tag: 'BLE Scan',
        );
      }
    }
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    if (_state == MeshCoreConnectionState.scanning) {
      _setState(MeshCoreConnectionState.disconnected);
    }
  }

  Future<List<String>> listUsbPorts() => _usbManager.listPorts();

  void setUsbRequestPortLabel(String label) {
    _usbManager.setRequestPortLabel(label);
  }

  void setUsbFallbackDeviceName(String label) {
    _usbManager.setFallbackDeviceName(label);
  }

  Future<void> connectUsb({
    required String portName,
    int baudRate = 115200,
  }) async {
    if (_state == MeshCoreConnectionState.connecting ||
        _state == MeshCoreConnectionState.connected) {
      _appDebugLogService?.warn(
        'connectUsb ignored: already $_state',
        tag: 'USB',
      );
      return;
    }

    _appDebugLogService?.info(
      'connectUsb: port=$portName baud=$baudRate',
      tag: 'USB',
    );

    await stopScan();
    _cancelReconnectTimer();
    _manualDisconnect = false;
    _resetConnectionHandshakeState();
    _activeTransport = MeshCoreTransportType.usb;
    _setState(MeshCoreConnectionState.connecting);

    try {
      await _usbFrameSubscription?.cancel();
      _usbFrameSubscription = null;
      _appDebugLogService?.info('connectUsb: opening serial port…', tag: 'USB');
      await _usbManager.connect(portName: portName, baudRate: baudRate);
      _appDebugLogService?.info(
        'connectUsb: serial port opened, label=${_usbManager.activePortDisplayLabel}',
        tag: 'USB',
      );
      notifyListeners();
      if (PlatformInfo.isWeb) {
        await stopScan();
      }
      // Wait before subscribing so any unsolicited boot output from the device
      // flows through _frameController with no listener and is discarded.
      // This prevents stale/partial frames from confusing the decoder.
      await Future<void>.delayed(const Duration(milliseconds: 2000));
      _usbFrameSubscription = _usbManager.frameStream.listen(
        _handleFrame,
        onError: (error, stackTrace) {
          _appDebugLogService?.error('USB transport error: $error', tag: 'USB');
          unawaited(disconnect(manual: false));
        },
        onDone: () {
          _appDebugLogService?.warn('USB frame stream ended', tag: 'USB');
          unawaited(disconnect(manual: false));
        },
      );

      _setState(MeshCoreConnectionState.connected);
      _pendingInitialChannelSync = true;
      _appDebugLogService?.info(
        'connectUsb: requesting device info…',
        tag: 'USB',
      );
      await _requestDeviceInfo();
      // Cancel the periodic APP_START retry timer. On USB (reliable transport)
      // repeated APP_START commands can interrupt the device's initialization
      // sequence, preventing it from ever completing a SELF_INFO response.
      _selfInfoRetryTimer?.cancel();
      _selfInfoRetryTimer = null;
      _startBatteryPolling();
      if (_radioStatsPollRefCount > 0) _startRadioStatsPolling();
      // Wait for SELF_INFO in up to three windows (7s + 7s + 6s = 20s total).
      // Shorter windows with spaced retries are more reliable than one 15s wait:
      // if the device is still booting when the initial APP_START is sent it may
      // miss it, and 15s without a retry means we depend on a single lucky send.
      // Retries are spaced ≥7s apart so we don't spam the device mid-boot.
      var gotSelfInfo = await _waitForSelfInfo(
        timeout: const Duration(seconds: 7),
      );
      if (!gotSelfInfo && isConnected) {
        _appDebugLogService?.warn(
          'connectUsb: no SELF_INFO after 7s, retrying…',
          tag: 'USB',
        );
        await sendFrame(buildAppStartFrame());
        gotSelfInfo = await _waitForSelfInfo(
          timeout: const Duration(seconds: 7),
        );
      }
      if (!gotSelfInfo && isConnected) {
        _appDebugLogService?.warn(
          'connectUsb: no SELF_INFO after 14s, retrying…',
          tag: 'USB',
        );
        await sendFrame(buildAppStartFrame());
        gotSelfInfo = await _waitForSelfInfo(
          timeout: const Duration(seconds: 6),
        );
      }
      if (!gotSelfInfo) {
        throw StateError('Timed out waiting for SELF_INFO during connect');
      }

      _appDebugLogService?.info('connectUsb: syncing time…', tag: 'USB');
      await syncTime();
      _appDebugLogService?.info('connectUsb: complete', tag: 'USB');
    } catch (error) {
      _appDebugLogService?.error('USB connection error: $error', tag: 'USB');
      await disconnect(manual: false);
      rethrow;
    }
  }

  Future<void> connectTcp({required String host, required int port}) async {
    if (_state == MeshCoreConnectionState.connecting ||
        _state == MeshCoreConnectionState.connected) {
      _appDebugLogService?.warn(
        'connectTcp ignored: already $_state',
        tag: 'TCP',
      );
      return;
    }

    _appDebugLogService?.info('connectTcp: endpoint=$host:$port', tag: 'TCP');

    await stopScan();
    _cancelReconnectTimer();
    _manualDisconnect = false;
    _resetConnectionHandshakeState();
    _activeTransport = MeshCoreTransportType.tcp;
    _setState(MeshCoreConnectionState.connecting);

    try {
      Future<void> handleTcpConnectAbort({required String message}) async {
        _appDebugLogService?.warn(message, tag: 'TCP');
        final shouldResetState = shouldResetStateAfterTcpConnectAbort(
          state: _state,
          activeTransport: _activeTransport,
        );
        if (shouldResetState) {
          await disconnect(manual: false);
          return;
        }
        if (_tcpConnector.isConnected) {
          await _tcpConnector.disconnect();
        }
      }

      await _tcpConnector.cancelFrameSubscription();
      await _tcpConnector.connect(host: host, port: port);
      final isTcpConnectCancelled =
          _activeTransport != MeshCoreTransportType.tcp ||
          _state != MeshCoreConnectionState.connecting ||
          !_tcpConnector.isConnected;
      if (isTcpConnectCancelled) {
        await handleTcpConnectAbort(
          message:
              'connectTcp aborted before handshake: state=$_state transport=$_activeTransport connected=${_tcpConnector.isConnected}',
        );
        return;
      }
      notifyListeners();

      await Future<void>.delayed(const Duration(milliseconds: 200));
      final isTcpConnectCancelledAfterDelay =
          _activeTransport != MeshCoreTransportType.tcp ||
          _state != MeshCoreConnectionState.connecting ||
          !_tcpConnector.isConnected;
      if (isTcpConnectCancelledAfterDelay) {
        await handleTcpConnectAbort(
          message:
              'connectTcp aborted after connect delay: state=$_state transport=$_activeTransport connected=${_tcpConnector.isConnected}',
        );
        return;
      }
      _tcpConnector.listenFrames(
        onFrame: _handleFrame,
        onError: (error, stackTrace) {
          _appDebugLogService?.error('TCP transport error: $error', tag: 'TCP');
          unawaited(disconnect(manual: false));
        },
        onDone: () {
          _appDebugLogService?.warn('TCP frame stream ended', tag: 'TCP');
          unawaited(disconnect(manual: false));
        },
      );

      _setState(MeshCoreConnectionState.connected);
      _pendingInitialChannelSync = true;
      await _requestDeviceInfo();
      _startBatteryPolling();
      if (_radioStatsPollRefCount > 0) _startRadioStatsPolling();

      var gotSelfInfo = await _waitForSelfInfo(
        timeout: const Duration(seconds: 3),
      );
      if (!gotSelfInfo) {
        await refreshDeviceInfo();
        gotSelfInfo = await _waitForSelfInfo(
          timeout: const Duration(seconds: 3),
        );
      }
      if (!gotSelfInfo) {
        throw StateError('Timed out waiting for SELF_INFO during TCP connect');
      }

      await syncTime();
    } catch (error) {
      _appDebugLogService?.error('TCP connection error: $error', tag: 'TCP');
      final tcpConnectCancelledBeforeHandshake =
          shouldIgnoreLateTcpConnectError(
            manualDisconnect: _manualDisconnect,
            state: _state,
            activeTransport: _activeTransport,
            tcpManagerConnected: _tcpConnector.isConnected,
          );
      if (tcpConnectCancelledBeforeHandshake) {
        _appDebugLogService?.info(
          'Ignoring late TCP connect error after cancellation/switch: state=$_state transport=$_activeTransport',
          tag: 'TCP',
        );
        return;
      }
      await disconnect(manual: false);
      rethrow;
    }
  }

  @visibleForTesting
  static bool shouldIgnoreLateTcpConnectError({
    required bool manualDisconnect,
    required MeshCoreConnectionState state,
    required MeshCoreTransportType activeTransport,
    required bool tcpManagerConnected,
  }) {
    return manualDisconnect &&
        (state == MeshCoreConnectionState.disconnected ||
            state == MeshCoreConnectionState.disconnecting) &&
        (activeTransport != MeshCoreTransportType.tcp || !tcpManagerConnected);
  }

  @visibleForTesting
  static bool shouldResetStateAfterTcpConnectAbort({
    required MeshCoreConnectionState state,
    required MeshCoreTransportType activeTransport,
  }) {
    return state == MeshCoreConnectionState.connecting &&
        activeTransport == MeshCoreTransportType.tcp;
  }

  Future<void> connect(
    BluetoothDevice device, {
    String? displayName,
    Future<String?> Function()? linuxPairingPinProvider,
  }) async {
    if (_state == MeshCoreConnectionState.connecting ||
        _state == MeshCoreConnectionState.connected) {
      return;
    }

    _activeTransport = MeshCoreTransportType.bluetooth;

    await stopScan();

    // Give the Bluetooth stack a moment to settle after scanning stops.
    // This reduces the chance of GATT 133 errors when connecting immediately.
    if (!PlatformInfo.isWeb) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    _setState(MeshCoreConnectionState.connecting);
    _device = device;
    _deviceId = device.remoteId.toString();
    if (displayName != null && displayName.trim().isNotEmpty) {
      _deviceDisplayName = displayName.trim();
    } else if (device.platformName.isNotEmpty) {
      _deviceDisplayName = device.platformName;
    }
    _lastDevice = device;
    _lastDeviceId = _deviceId;
    _lastDeviceDisplayName = _deviceDisplayName;
    _manualDisconnect = false;
    _cancelReconnectTimer();
    _bleInitialSyncStarted = false;
    if (PlatformInfo.isWeb) {
      _resetConnectionHandshakeState();
    }
    unawaited(_backgroundService?.start());
    notifyListeners();

    try {
      final connectLabel = _deviceDisplayName ?? _deviceId;
      _appDebugLogService?.info(
        'Starting connect to $connectLabel',
        tag: 'BLE Connect',
      );
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;
      await _notifySubscription?.cancel();
      _notifySubscription = null;
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected && isConnected) {
          _handleDisconnection();
        }
      });

      if (PlatformInfo.isLinux) {
        final remoteId = device.remoteId.str;
        _appDebugLogService?.info(
          'Linux pre-connect BlueZ disconnect for $remoteId',
          tag: 'BLE Connect',
        );
        await _linuxBlePairingService.disconnectDevice(
          remoteId,
          onLog: (message) {
            _appDebugLogService?.info(message, tag: 'BLE Pair');
          },
        );
      }

      final connectTimeout = PlatformInfo.isLinux
          ? const Duration(seconds: 6)
          : const Duration(seconds: 15);
      _appDebugLogService?.info(
        'device.connect timeout set to ${connectTimeout.inSeconds}s',
        tag: 'BLE Connect',
      );
      if (PlatformInfo.isLinux) {
        Future<void> attemptConnect() {
          return device
              .connect(
                timeout: connectTimeout,
                mtu: null,
                license: License.free,
              )
              .timeout(
                connectTimeout + const Duration(seconds: 2),
                onTimeout: () {
                  throw TimeoutException(
                    'Linux connect hard-timeout after ${connectTimeout.inSeconds + 2}s',
                  );
                },
              );
        }

        try {
          await attemptConnect();
        } catch (error) {
          _appDebugLogService?.error(
            'device.connect() failure: $error',
            tag: 'BLE Connect',
          );
          final remoteId = device.remoteId.str;
          _appDebugLogService?.warn(
            'Linux immediate retry: forcing BlueZ disconnect before second connect attempt',
            tag: 'BLE Connect',
          );
          await _linuxBlePairingService.disconnectDevice(
            remoteId,
            onLog: (message) {
              _appDebugLogService?.info(message, tag: 'BLE Pair');
            },
          );
          await Future<void>.delayed(const Duration(milliseconds: 700));
          try {
            await attemptConnect();
            _appDebugLogService?.info(
              'Linux immediate retry connect succeeded',
              tag: 'BLE Connect',
            );
          } catch (retryError, retryStackTrace) {
            Object finalConnectError = retryError;
            StackTrace finalConnectStackTrace = retryStackTrace;
            final retryErrorText = retryError.toString().toLowerCase();
            final isAbortByLocal = retryErrorText.contains(
              'le-connection-abort-by-local',
            );
            var recoveredOnThirdAttempt = false;
            if (isAbortByLocal) {
              _appDebugLogService?.warn(
                'Linux immediate retry aborted by local stack; waiting and retrying once more',
                tag: 'BLE Connect',
              );
              await Future<void>.delayed(const Duration(milliseconds: 1200));
              try {
                await attemptConnect();
                _appDebugLogService?.info(
                  'Linux third-attempt connect succeeded after local abort',
                  tag: 'BLE Connect',
                );
                recoveredOnThirdAttempt = true;
              } catch (thirdError, thirdStackTrace) {
                finalConnectError = thirdError;
                finalConnectStackTrace = thirdStackTrace;
                _appDebugLogService?.error(
                  'device.connect() third-attempt failure: $thirdError',
                  tag: 'BLE Connect',
                );
              }
            }
            if (!recoveredOnThirdAttempt) {
              final recoveredByPairing = await _recoverLinuxConnectFailure(
                device,
                attemptConnect: attemptConnect,
                onRequestPin: linuxPairingPinProvider,
              );
              if (recoveredByPairing) {
                _appDebugLogService?.info(
                  'Linux connect succeeded after pairing/trust recovery',
                  tag: 'BLE Connect',
                );
              } else {
                _appDebugLogService?.error(
                  'device.connect() retry failure: $finalConnectError',
                  tag: 'BLE Connect',
                );
                Error.throwWithStackTrace(
                  _wrapLinuxConnectStageError(finalConnectError),
                  finalConnectStackTrace,
                );
              }
            }
          }
        }
      } else {
        try {
          await device.connect(
            timeout: connectTimeout,
            autoConnect: false,
            mtu: null,
            license: License.free,
          );
        } catch (error) {
          bool shouldRetry = false;
          if (error is FlutterBluePlusException && error.code == 133) {
            shouldRetry = true;
          }
          
          if (shouldRetry) {
            _appDebugLogService?.warn(
              'device.connect() failed with 133, retrying: $error',
              tag: 'BLE Connect',
            );
            try {
              await device.disconnect();
            } catch (_) {}
            
            if (PlatformInfo.isAndroid) {
              try {
                await device.clearGattCache();
              } catch (e) {
                _appDebugLogService?.warn(
                  'clearGattCache failed: $e',
                  tag: 'BLE Connect',
                );
              }
            }

            await Future<void>.delayed(const Duration(milliseconds: 1500));
            try {
              await device.connect(
                timeout: connectTimeout,
                autoConnect: false,
                mtu: null,
                license: License.free,
              );
              _appDebugLogService?.info(
                'device.connect() retry succeeded',
                tag: 'BLE Connect',
              );
            } catch (retryError) {
              _appDebugLogService?.error(
                'device.connect() retry failure: $retryError',
                tag: 'BLE Connect',
              );
              rethrow;
            }
          } else {
            _appDebugLogService?.error(
              'device.connect() failure: $error',
              tag: 'BLE Connect',
            );
            rethrow;
          }
        }
      }

      if (PlatformInfo.isLinux) {
        await _ensureLinuxBleBond(
          device,
          onRequestPin: linuxPairingPinProvider,
        );
      }

      // Request larger MTU only where the platform path supports it.
      if (!PlatformInfo.isWeb && !PlatformInfo.isLinux) {
        try {
          final mtu = await device.requestMtu(185);
          _appDebugLogService?.info('MTU set to: $mtu', tag: 'BLE Connect');
        } catch (e) {
          _appDebugLogService?.warn(
            'MTU request failed: $e, using default',
            tag: 'BLE Connect',
          );
        }
      } else if (PlatformInfo.isLinux) {
        _appDebugLogService?.info(
          'Skipping MTU request on Linux; flutter_blue_plus only supports requestMtu on Android',
          tag: 'BLE Connect',
        );
      }

      late final List<BluetoothService> services;
      try {
        services = await device.discoverServices();
      } catch (error) {
        _appDebugLogService?.error(
          'service discovery failure: $error',
          tag: 'BLE Connect',
        );
        if (PlatformInfo.isWeb &&
            error.toString().contains('GATT Server is disconnected')) {
          // Chrome Web Bluetooth intermittently disconnects between connect()
          // and service discovery; retry once to recover that transient state.
          _appDebugLogService?.warn(
            'retrying service discovery after transient web disconnect',
            tag: 'BLE Connect',
          );
          await Future<void>.delayed(const Duration(milliseconds: 300));
          await device.connect(
            timeout: const Duration(seconds: 15),
            mtu: null,
            license: License.free,
          );
          services = await device.discoverServices();
        } else {
          rethrow;
        }
      }

      BluetoothService? uartService;
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == MeshCoreUuids.service) {
          uartService = service;
          break;
        }
      }

      if (uartService == null) {
        throw Exception("MeshCore UART service not found");
      }

      for (var characteristic in uartService.characteristics) {
        String uuid = characteristic.uuid.toString().toLowerCase();
        if (uuid == MeshCoreUuids.rxCharacteristic) {
          _rxCharacteristic = characteristic;
        } else if (uuid == MeshCoreUuids.txCharacteristic) {
          _txCharacteristic = characteristic;
        }
      }

      if (_rxCharacteristic == null || _txCharacteristic == null) {
        throw Exception("MeshCore characteristics not found");
      }

      if (PlatformInfo.isWeb) {
        _appDebugLogService?.info(
          'Starting setNotifyValue(true)',
          tag: 'BLE Connect',
        );
        _appDebugLogService?.info(
          'Web: Calling setNotifyValue(true) without awaiting',
          tag: 'BLE Connect',
        );
        unawaited(() async {
          try {
            await _txCharacteristic!.setNotifyValue(true);
          } catch (error) {
            _appDebugLogService?.warn(
              'notify failure (web, ignored): $error',
              tag: 'BLE Connect',
            );
            _appDebugLogService?.warn(
              'Web setNotifyValue error (ignoring): $error',
              tag: 'BLE Connect',
            );
          }
        }());
        _appDebugLogService?.info(
          'setNotifyValue(true) configuration completed',
          tag: 'BLE Connect',
        );
      } else {
        bool notifySet = false;
        for (int attempt = 0; attempt < 3 && !notifySet; attempt++) {
          try {
            if (attempt > 0) {
              await Future.delayed(Duration(milliseconds: 500 * attempt));
            }
            await _txCharacteristic!.setNotifyValue(true);
            notifySet = true;
          } catch (e) {
            _appDebugLogService?.warn('notify failure: $e', tag: 'BLE Connect');
            _appDebugLogService?.warn(
              'setNotifyValue attempt ${attempt + 1}/3 failed: $e',
              tag: 'BLE Connect',
            );
            if (attempt == 2) rethrow;
          }
        }
      }
      _notifySubscription = _txCharacteristic!.onValueReceived.listen(
        _handleFrame,
      );

      _setState(MeshCoreConnectionState.connected);
      unawaited(_persistLastBleDevice());
      if (_shouldGateInitialChannelSync) {
        _hasReceivedDeviceInfo = false;
        _pendingInitialChannelSync = true;
      }
      await _startBleInitialSync();
    } catch (e) {
      _appDebugLogService?.error('Connection error: $e', tag: 'BLE Connect');
      final errorText = e.toString();
      final lowerErrorText = errorText.toLowerCase();
      final isLinuxPairingFailure =
          PlatformInfo.isLinux && isLinuxBlePairingFailureText(errorText);
      final isLikelyPairingTimeout = isLikelyLinuxBlePairingTimeoutText(
        errorText,
      );
      final isConnectFailure = isLinuxBleConnectFailureText(errorText);
      final isConnectTimeoutFailure =
          isConnectFailure && lowerErrorText.contains('timed out');
      final isLinuxConnectFailure = PlatformInfo.isLinux && isConnectFailure;
      // Linux pairing failures should not enter auto-reconnect loops; user
      // needs to retry manually so they can re-enter PIN / resolve pairing.
      if (isLinuxPairingFailure) {
        _appDebugLogService?.warn(
          isLikelyPairingTimeout
              ? 'Linux pairing timed out: stopping reconnect until user retries manually'
              : 'Linux pairing failure: stopping reconnect until user retries manually',
          tag: 'BLE Connect',
        );
        await disconnect(manual: true);
      } else if (isLinuxConnectFailure) {
        _appDebugLogService?.warn(
          isConnectTimeoutFailure
              ? 'Linux connect timeout: issuing BlueZ disconnect before reconnect'
              : 'Linux connect failure: issuing BlueZ disconnect before reconnect',
          tag: 'BLE Connect',
        );
        final remoteId = _device?.remoteId.str;
        if (remoteId != null) {
          await _linuxBlePairingService.disconnectDevice(
            remoteId,
            onLog: (message) {
              _appDebugLogService?.info(message, tag: 'BLE Pair');
            },
          );
        }
        await disconnect(manual: false, skipBleDeviceDisconnect: true);
      } else {
        await disconnect(manual: false);
      }
      rethrow;
    }
  }

  Future<bool> _recoverLinuxConnectFailure(
    BluetoothDevice device, {
    required Future<void> Function() attemptConnect,
    Future<String?> Function()? onRequestPin,
  }) async {
    if (!PlatformInfo.isLinux ||
        !await _linuxBlePairingService.isBluetoothctlAvailable()) {
      return false;
    }
    final remoteId = device.remoteId.str;
    final pluginBondState = await _getLinuxPluginBondState(device);
    final trustedByBluez = await _linuxBlePairingService.isPairedAndTrusted(
      remoteId,
    );
    final needsBondRecovery =
        (pluginBondState != null &&
            pluginBondState != BmBondStateEnum.bonded) ||
        !trustedByBluez;
    if (!needsBondRecovery) {
      return false;
    }
    _appDebugLogService?.warn(
      pluginBondState == BmBondStateEnum.bonded
          ? 'Linux connect failed with an untrusted bond; attempting trust/pair recovery'
          : 'Linux connect failed before bond completed; attempting pairing fallback',
      tag: 'BLE Connect',
    );
    await _ensureLinuxBleBond(device, onRequestPin: onRequestPin);
    _appDebugLogService?.info(
      'Resetting BlueZ connection after Linux pairing/trust recovery',
      tag: 'BLE Connect',
    );
    await _linuxBlePairingService.disconnectDevice(
      remoteId,
      onLog: (message) {
        _appDebugLogService?.info(message, tag: 'BLE Pair');
      },
    );
    await Future<void>.delayed(const Duration(milliseconds: 700));
    try {
      await attemptConnect();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(_wrapLinuxConnectStageError(error), stackTrace);
    }
    return true;
  }

  Object _wrapLinuxConnectStageError(Object error) {
    final errorText = error.toString();
    if (errorText.toLowerCase().contains(linuxConnectStageFailureMarker)) {
      return error;
    }
    return StateError('Linux connect stage failure: $error');
  }

  Future<BmBondStateEnum?> _getLinuxPluginBondState(
    BluetoothDevice device,
  ) async {
    try {
      final response = await FlutterBluePlusPlatform.instance.getBondState(
        BmBondStateRequest(remoteId: device.remoteId),
      );
      return response.bondState;
    } catch (error) {
      _appDebugLogService?.warn(
        'Linux getBondState unavailable for ${device.remoteId.str}: $error',
        tag: 'BLE Connect',
      );
      return null;
    }
  }

  Future<void> _ensureLinuxBleBond(
    BluetoothDevice device, {
    Future<String?> Function()? onRequestPin,
  }) async {
    final remoteId = device.remoteId.str;
    final bluetoothctlAvailable = await _linuxBlePairingService
        .isBluetoothctlAvailable();
    final beforeBondState = await _getLinuxPluginBondState(device);
    if (!bluetoothctlAvailable) {
      if (beforeBondState == BmBondStateEnum.bonded) {
        _appDebugLogService?.warn(
          'bluetoothctl unavailable; continuing with plugin bonded state',
          tag: 'BLE Connect',
        );
      } else if (beforeBondState == null) {
        _appDebugLogService?.warn(
          'bluetoothctl unavailable and plugin bond state is unknown; skipping Linux pairing fallback',
          tag: 'BLE Connect',
        );
      } else {
        _appDebugLogService?.warn(
          'bluetoothctl unavailable and device is not bonded; skipping Linux pairing fallback',
          tag: 'BLE Connect',
        );
      }
      return;
    }

    final trustedByBluez = await _linuxBlePairingService.isPairedAndTrusted(
      remoteId,
    );
    if (trustedByBluez) {
      _appDebugLogService?.info(
        'Linux BLE device already paired/trusted, skipping pairing flow',
        tag: 'BLE Connect',
      );
      return;
    }

    if (beforeBondState == BmBondStateEnum.bonded && !trustedByBluez) {
      _appDebugLogService?.warn(
        'Linux BLE device is bonded but not trusted in BlueZ; repairing trust',
        tag: 'BLE Connect',
      );
      final trustRepaired = await _linuxBlePairingService.trustDevice(
        remoteId,
        onLog: (message) {
          _appDebugLogService?.info(message, tag: 'BLE Pair');
        },
      );
      if (trustRepaired) {
        _appDebugLogService?.info(
          'Linux BLE trust repair succeeded without re-pairing',
          tag: 'BLE Connect',
        );
        return;
      }
      _appDebugLogService?.warn(
        'Linux BLE trust repair did not stick; retrying pairing flow',
        tag: 'BLE Connect',
      );
    }

    _appDebugLogService?.info(
      beforeBondState == BmBondStateEnum.bonded
          ? 'Linux BLE device still untrusted after repair; requesting pair'
          : beforeBondState == null
          ? 'Linux BLE device bond state unknown; requesting pair'
          : 'Linux BLE device not bonded, requesting pair',
      tag: 'BLE Connect',
    );
    final paired = await _linuxBlePairingService.pairAndTrust(
      remoteId: remoteId,
      onLog: (message) {
        _appDebugLogService?.info(message, tag: 'BLE Pair');
      },
      onRequestPin: onRequestPin,
    );
    if (!paired) {
      throw StateError('Linux pairing fallback failed');
    }

    final afterBondState = await _getLinuxPluginBondState(device);
    if (afterBondState != null && afterBondState != BmBondStateEnum.bonded) {
      throw StateError('Linux BLE pairing did not complete');
    } else if (afterBondState == null) {
      _appDebugLogService?.warn(
        'Linux plugin bond state unavailable after pairing; relying on BlueZ trust verification',
        tag: 'BLE Connect',
      );
    }
    final trustedAfter = await _linuxBlePairingService.isPairedAndTrusted(
      remoteId,
    );
    if (!trustedAfter) {
      throw StateError('Linux BLE trust repair did not complete');
    }
  }

  Future<bool> _waitForSelfInfo({required Duration timeout}) async {
    if (_selfPublicKey != null) return true;
    if (!isConnected) return false;

    final completer = Completer<bool>();
    late final VoidCallback listener;
    listener = () {
      if (_selfPublicKey != null) {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      } else if (!isConnected) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      }
    };
    addListener(listener);

    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    final result = await completer.future;
    timer.cancel();
    removeListener(listener);
    return result;
  }

  Future<void> _startBleInitialSync() async {
    if (_bleInitialSyncStarted ||
        !isConnected ||
        _activeTransport != MeshCoreTransportType.bluetooth) {
      return;
    }
    _bleInitialSyncStarted = true;

    await _requestDeviceInfo();
    _startBatteryPolling();
    if (_radioStatsPollRefCount > 0) _startRadioStatsPolling();

    final gotSelfInfo = await _waitForSelfInfo(
      timeout: const Duration(seconds: 3),
    );
    if (!gotSelfInfo) {
      await refreshDeviceInfo();
      await _waitForSelfInfo(timeout: const Duration(seconds: 3));
    }

    await syncTime();
    unawaited(getChannels());
  }

  void _resetConnectionHandshakeState() {
    _selfPublicKey = null;
    _selfName = null;
    _selfLatitude = null;
    _selfLongitude = null;
    _awaitingSelfInfo = false;
    _webInitialHandshakeRequestSent = false;
    _selfInfoRetryTimer?.cancel();
    _selfInfoRetryTimer = null;
    _hasReceivedDeviceInfo = false;
    _pendingInitialChannelSync = false;
    _pendingInitialContactsSync = false;
    _bleInitialSyncStarted = false;
    _pendingDeferredChannelSyncAfterContacts = false;
    _pendingChannelSyncAfterQueueSync = false;
    _initialSyncComplete = false;
    _pathHashByteWidth = 1;
  }

  bool get _shouldAutoReconnect =>
      !_manualDisconnect &&
      _lastDeviceId != null &&
      _activeTransport == MeshCoreTransportType.bluetooth;

  /// True when a previously connected Bluetooth device is remembered and can be
  /// auto-connected on the next launch.
  bool get hasRememberedBleDevice => _lastDeviceId != null;

  void _restoreLastBleDevice() {
    try {
      final prefs = PrefsManager.instance;
      _lastDeviceId ??= prefs.getString(_lastBleDeviceIdKey);
      _lastDeviceDisplayName ??= prefs.getString(_lastBleDeviceNameKey);
    } catch (_) {
      // Prefs unavailable (e.g. in tests) — nothing to restore.
    }
  }

  Future<void> _persistLastBleDevice() async {
    final id = _lastDeviceId;
    if (id == null) return;
    try {
      final prefs = PrefsManager.instance;
      await prefs.setString(_lastBleDeviceIdKey, id);
      final name = _lastDeviceDisplayName;
      if (name != null && name.isNotEmpty) {
        await prefs.setString(_lastBleDeviceNameKey, name);
      } else {
        await prefs.remove(_lastBleDeviceNameKey);
      }
    } catch (_) {
      // Best effort — a failed persist just means no auto-connect next launch.
    }
  }

  /// Attempts a one-shot connection to the last remembered Bluetooth device on
  /// app launch. No-op if the setting is disabled, on web, when nothing is
  /// remembered, or once an attempt has already been made this process.
  /// Callers must ensure the Bluetooth adapter is on before invoking.
  Future<void> autoConnectToLastDevice() async {
    if (_launchAutoConnectAttempted) return;
    if (PlatformInfo.isWeb) return;
    if (_appSettingsService?.settings.autoConnectLastDevice != true) return;
    final id = _lastDeviceId;
    if (id == null) return;
    if (_state != MeshCoreConnectionState.disconnected) return;
    _launchAutoConnectAttempted = true;
    _appDebugLogService?.info(
      'Auto-connecting to last device $id',
      tag: 'BLE Connect',
    );
    try {
      await connect(
        BluetoothDevice.fromId(id),
        displayName: _lastDeviceDisplayName,
      );
    } catch (e) {
      _appDebugLogService?.info(
        'Auto-connect to last device failed: $e',
        tag: 'BLE Connect',
      );
    }
  }

  bool get _shouldGateInitialChannelSync =>
      _activeTransport == MeshCoreTransportType.usb ||
      _activeTransport == MeshCoreTransportType.tcp ||
      (_activeTransport == MeshCoreTransportType.bluetooth &&
          PlatformInfo.isWeb);

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
  }

  int _nextReconnectDelayMs() {
    final attempt = _reconnectAttempts < 6 ? _reconnectAttempts : 6;
    _reconnectAttempts += 1;
    final delayMs = 1000 * (1 << attempt);
    return delayMs > 30000 ? 30000 : delayMs;
  }

  void _scheduleReconnect() {
    if (!_shouldAutoReconnect) return;
    if (_reconnectTimer?.isActive == true) return;

    final delayMs = _nextReconnectDelayMs();
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () async {
      if (!_shouldAutoReconnect) return;
      if (_state == MeshCoreConnectionState.connecting ||
          _state == MeshCoreConnectionState.connected) {
        return;
      }

      final device =
          _lastDevice ??
          (_lastDeviceId == null
              ? null
              : BluetoothDevice.fromId(_lastDeviceId!));
      if (device == null) return;

      try {
        await connect(device, displayName: _lastDeviceDisplayName);
      } catch (_) {
        _scheduleReconnect();
      }
    });
  }

  Future<void> disconnect({
    bool manual = true,
    bool skipBleDeviceDisconnect = false,
  }) async {
    if (_state == MeshCoreConnectionState.disconnecting) return;

    _discoverTimer?.cancel();
    _isDiscovering = false;
    _pendingDiscoverTag = null;

    final transportAtDisconnect = _activeTransport;
    final transportLabel = switch (transportAtDisconnect) {
      MeshCoreTransportType.bluetooth => 'BLE',
      MeshCoreTransportType.usb => 'USB',
      MeshCoreTransportType.tcp => 'TCP',
    };

    _appDebugLogService?.info(
      'Starting disconnect transport=$transportLabel manual=$manual',
      tag: 'Connection',
    );

    if (manual) {
      _manualDisconnect = true;
      _cancelReconnectTimer();
      unawaited(_backgroundService?.stop());
    } else {
      _manualDisconnect = false;
    }
    _setState(MeshCoreConnectionState.disconnecting);
    _stopBatteryPolling();
    _stopRadioStatsPolling();

    await _usbFrameSubscription?.cancel();
    _usbFrameSubscription = null;
    await _usbManager.disconnect();
    await _tcpConnector.disconnect();

    await _notifySubscription?.cancel();
    _notifySubscription = null;

    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _selfInfoRetryTimer?.cancel();
    _selfInfoRetryTimer = null;
    _queueSyncTimeout?.cancel();
    _queueSyncTimeout = null;
    _queueSyncRetries = 0;
    _channelSyncTimeout?.cancel();
    _channelSyncTimeout = null;
    _channelSyncRetries = 0;

    if (!skipBleDeviceDisconnect) {
      try {
        // Skip queued BLE operations so disconnect doesn't get stuck behind them.
        await _device?.disconnect(queue: false);
      } catch (e) {
        _appDebugLogService?.warn('Disconnect error: $e', tag: 'BLE Connect');
      }
    } else {
      _appDebugLogService?.info(
        'Skipping plugin BLE disconnect and continuing cleanup',
        tag: 'BLE Connect',
      );
    }

    _device = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
    _deviceDisplayName = null;
    _deviceId = null;
    _contacts.clear();
    _discoveredContacts.clear();
    _roomAdminPasswords.clear();
    // Connection-scoped channel state. Pending buffers are KEPT: the radio's
    // queue never redelivers drained messages, flushing requires a fresh
    // CHANNEL_INFO on the next connection, and the node-switch wipe clears
    // them before any different-radio sync.
    _queriedUntrackedChannels.clear();
    _slotsToRequery.clear();
    _channelsVerified = false;
    _failStrandedUnverifiedSends();
    _selfPublicKey = null;
    _selfName = null;
    _selfLatitude = null;
    _selfLongitude = null;
    _clientRepeat = null;
    _rememberedNonRepeatRadioState = null;
    _firmwareVerCode = null;
    _firmwareVersion = null;
    _batteryMillivolts = null;
    _repeaterBatterySnapshots.clear();
    _batteryRequested = false;
    _awaitingSelfInfo = false;
    _hasReceivedDeviceInfo = false;
    _pendingInitialChannelSync = false;
    _pendingInitialContactsSync = false;
    _maxContacts = _defaultMaxContacts;
    _maxChannels = _defaultMaxChannels;
    _isSyncingQueuedMessages = false;
    _queuedMessageSyncInFlight = false;
    _didInitialQueueSync = false;
    _pendingQueueSync = false;
    _pendingChannelSyncAfterQueueSync = false;
    _isSyncingChannels = false;
    _channelSyncInFlight = false;
    _hasLoadedChannels = false;
    _pendingChannelSentQueue.clear();
    _pendingGenericAckQueue.clear();
    _reactionSendQueueSequence = 0;

    _activeTransport = MeshCoreTransportType.bluetooth;

    _setState(MeshCoreConnectionState.disconnected);
    _appDebugLogService?.info(
      'Disconnect complete transport=$transportLabel manual=$manual',
      tag: 'Connection',
    );
    if (!manual && transportAtDisconnect == MeshCoreTransportType.bluetooth) {
      _scheduleReconnect();
    }
  }

  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    if (!isConnected) {
      throw Exception("Not connected to a MeshCore device");
    }
    _bleDebugLogService?.logFrame(data, outgoing: true);

    // Register the pending ack BEFORE writing, with no await in between. On fast
    // transports (USB serial) the device's RESP_CODE_OK can arrive within ~1ms
    // and be dispatched on the event loop during the write/delay below — if the
    // queue entry isn't in place yet, _handleOk sees an empty queue and discards
    // the ack, leaving the message stuck 'pending' until it falsely times out.
    _trackPendingGenericAck(
      data,
      channelSendQueueId: channelSendQueueId,
      expectsGenericAck: expectsGenericAck,
    );

    if (_activeTransport == MeshCoreTransportType.usb) {
      await _usbManager.write(data);
      // Brief pause so the device firmware can process each frame before the
      // next arrives. Without this, rapid-fire frames over USB can cause the
      // device to miss responses (especially on reconnect).
      await Future<void>.delayed(const Duration(milliseconds: 10));
    } else if (_activeTransport == MeshCoreTransportType.tcp) {
      await _tcpConnector.write(data);
    } else {
      if (_rxCharacteristic == null) {
        throw Exception("MeshCore RX characteristic not available");
      }
      // Prefer write without response when supported; fall back to write with response.
      final properties = _rxCharacteristic!.properties;
      final canWriteWithoutResponse = properties.writeWithoutResponse;
      final canWriteWithResponse = properties.write;
      if (!canWriteWithoutResponse && !canWriteWithResponse) {
        throw Exception("MeshCore RX characteristic does not support write");
      }
      await _rxCharacteristic!.write(
        data.toList(),
        withoutResponse: canWriteWithoutResponse,
      );
    }
  }

  Future<bool> _sendAndWaitForAck(
    Uint8List data, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    if (!isConnected) return false;
    final completer = Completer<bool>();
    final subscription = receivedFrames.listen((rxFrame) {
      if (rxFrame.isEmpty) return;
      if (rxFrame[0] == respCodeOk) {
        if (!completer.isCompleted) completer.complete(true);
      } else if (rxFrame[0] == respCodeErr) {
        if (!completer.isCompleted) completer.complete(false);
      }
    });

    try {
      await sendFrame(data);
      return await completer.future.timeout(timeout);
    } catch (_) {
      return false;
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> requestBatteryStatus({bool force = false}) async {
    if (!isConnected) return;
    if (_batteryRequested && !force) return;
    _batteryRequested = true;
    await sendFrame(buildGetBattAndStorageFrame());
  }

  void _startBatteryPolling() {
    _batteryPollTimer?.cancel();
    _batteryPollTimer = Timer.periodic(_batteryPollInterval, (timer) {
      if (!isConnected) {
        timer.cancel();
        return;
      }
      unawaited(requestBatteryStatus(force: true));
    });
  }

  void _stopBatteryPolling() {
    _batteryPollTimer?.cancel();
    _batteryPollTimer = null;
  }

  void _updateGpsPolling() {
    _gpsPollTimer?.cancel();
    _gpsPollTimer = null;

    if (!isConnected) return;
    
    final customVars = _currentCustomVars ?? {};
    final bool hasGPS = customVars.containsKey("gps");
    final bool isGPSEnabled = customVars["gps"] == "1";
    
    if (hasGPS && isGPSEnabled) {
      final interval = int.tryParse(customVars["gps_interval"] ?? "") ?? 900;
      if (interval > 0) {
        _gpsPollTimer = Timer.periodic(Duration(seconds: interval), (timer) {
          if (!isConnected) {
            timer.cancel();
            return;
          }
          unawaited(sendFrame(buildAppStartFrame()));
        });
      }
    }
  }

  void setPollingInterval(int i) {
    _pollingInterval = i.clamp(1, 60);
    if (isConnected) {
      _startRadioStatsPolling();
    }
  }

  void _startRadioStatsPolling() {
    _radioStatsPollTimer?.cancel();
    _radioStatsPollTimer = Timer.periodic(Duration(seconds: _pollingInterval), (
      _,
    ) {
      if (!isConnected) {
        _stopRadioStatsPolling();
        return;
      }
      unawaited(requestRadioStats());
    });
  }

  void _stopRadioStatsPolling() {
    _radioStatsPollTimer?.cancel();
    _radioStatsPollTimer = null;
  }

  void acquireRadioStatsPolling() {
    _radioStatsPollRefCount++;
    if (_radioStatsPollRefCount == 1 && isConnected) {
      _startRadioStatsPolling();
    }
  }

  void releaseRadioStatsPolling() {
    _radioStatsPollRefCount = (_radioStatsPollRefCount - 1).clamp(0, 999);
    if (_radioStatsPollRefCount == 0) {
      _stopRadioStatsPolling();
    }
  }

  Future<void> requestRadioStats() async {
    if (!isConnected) return;
    if (!supportsCompanionRadioStats) return;
    try {
      await sendFrame(buildGetStatsFrame(statsTypeRadio));
    } catch (_) {}
  }

  Future<void> setPathHashMode(int mode) async {
    if (!isConnected) return;
    await sendFrame(buildSetPathHashModeFrame(mode.clamp(0, 2)));
  }

  Future<void> refreshDeviceInfo() async {
    if (!isConnected) return;
    if (PlatformInfo.isWeb &&
        _activeTransport == MeshCoreTransportType.bluetooth &&
        _webInitialHandshakeRequestSent &&
        _selfPublicKey == null) {
      return;
    }
    _awaitingSelfInfo = true;
    if (PlatformInfo.isWeb &&
        _activeTransport == MeshCoreTransportType.bluetooth &&
        _selfPublicKey == null) {
      _webInitialHandshakeRequestSent = true;
    }
    await sendFrame(buildDeviceQueryFrame());
    await sendFrame(buildAppStartFrame());
    await requestBatteryStatus(force: true);
    await sendFrame(buildGetCustomVarsFrame());
    await sendFrame(buildGetAutoAddFlagsFrame());

    _scheduleSelfInfoRetry();
  }

  Future<void> _requestDeviceInfo() async {
    if (!isConnected || _awaitingSelfInfo) return;
    if (PlatformInfo.isWeb &&
        _activeTransport == MeshCoreTransportType.bluetooth &&
        _webInitialHandshakeRequestSent &&
        _selfPublicKey == null) {
      return;
    }
    _awaitingSelfInfo = true;
    if (PlatformInfo.isWeb &&
        _activeTransport == MeshCoreTransportType.bluetooth &&
        _selfPublicKey == null) {
      _webInitialHandshakeRequestSent = true;
    }
    await sendFrame(buildDeviceQueryFrame());
    await sendFrame(buildAppStartFrame());
    await sendFrame(buildGetCustomVarsFrame());
    await requestBatteryStatus();
    await sendFrame(buildGetAutoAddFlagsFrame());
    _scheduleSelfInfoRetry();
  }

  void _scheduleSelfInfoRetry() {
    _selfInfoRetryTimer?.cancel();
    if (PlatformInfo.isWeb &&
        _activeTransport == MeshCoreTransportType.bluetooth) {
      var attempts = 0;
      const maxAttempts = 3;
      _selfInfoRetryTimer = Timer.periodic(const Duration(seconds: 10), (
        timer,
      ) {
        if (!isConnected || !_awaitingSelfInfo) {
          timer.cancel();
          return;
        }
        if (_isLoadingContacts || _isSyncingChannels || _channelSyncInFlight) {
          return;
        }
        attempts += 1;
        unawaited(sendFrame(buildAppStartFrame()));
        if (attempts >= maxAttempts) {
          timer.cancel();
        }
      });
      return;
    }
    _selfInfoRetryTimer = Timer.periodic(const Duration(milliseconds: 3500), (
      timer,
    ) {
      if (!isConnected) {
        timer.cancel();
        return;
      }
      if (!_awaitingSelfInfo) {
        timer.cancel();
        return;
      }
      unawaited(sendFrame(buildAppStartFrame()));
    });
  }

  Contact getFromDiscovered(Contact contact) {
    final tmp = _discoveredContacts.firstWhere(
      (c) => c.publicKeyHex == contact.publicKeyHex,
      orElse: () => contact,
    );
    return contact.copyWith(
      rawPacket: tmp.rawPacket,
      latitude: tmp.latitude,
      longitude: tmp.longitude,
    );
  }

  Future<void> getContacts({int? since, bool preserveExisting = false}) async {
    if (!isConnected) return;

    _isLoadingContacts = true;
    _preserveContactsOnRefresh = preserveExisting;
    if (!preserveExisting) {
      _contacts.clear();
      notifyListeners();
    }

    await sendFrame(buildGetContactsFrame(since: since));
  }

  Future<void> refreshContacts() async {
    await getContacts(preserveExisting: true);
  }

  Future<void> refreshContactsSinceLastmod() async {
    await getContacts(since: _latestContactLastmod(), preserveExisting: true);
  }

  Future<void> getContactByKey(Uint8List pubKey) async {
    if (!isConnected) return;
    await sendFrame(buildGetContactByKeyFrame(pubKey));
  }

  Future<void> sendMessage(
    Contact contact,
    String text,
  ) async {
    if (!isConnected || text.isEmpty) return;

    // Check if this is a reaction - apply locally with pending status and route through retry service
    final reactionInfo = ReactionHelper.parseReaction(text);
    if (reactionInfo != null) {
      // Apply to the target row; watched queries update the UI.
      final history = await _messageStore.loadMessages(contact.publicKeyHex);
      _processOutgoingContactReaction(history, reactionInfo, contact);
      await _messageStore.upsertMessages(contact.publicKeyHex, history);
      await _setReactionStatus(
        contact.publicKeyHex,
        reactionInfo,
        MessageStatus.pending,
      );
      notifyListeners();

      // Route through retry service (same as normal messages)
      // Don't use auto-rotation for reactions — just send directly
      if (_retryService != null) {
        _retryService!.sendMessageWithRetry(contact: contact, text: text);
      } else {
        final outboundText = prepareContactOutboundText(contact, text);
        await sendFrame(buildSendTextMsgFrame(contact.publicKey, outboundText));
      }
      return;
    }

    if (_retryService != null) {
      await _retryService!.sendMessageWithRetry(
        contact: contact,
        text: text,
      );
    } else {
      // Fallback to old behavior if retry service not initialized
      final resolved = resolvePathSelection(contact);
      final message = Message.outgoing(
        contact.publicKey,
        text,
        pathLength: resolved.useFlood ? -1 : resolved.hopCount,
        pathBytes: Uint8List.fromList(resolved.pathBytes),
      );
      _addMessage(contact.publicKeyHex, message);
      notifyListeners();
      final outboundText = prepareContactOutboundText(contact, text);
      await sendFrame(buildSendTextMsgFrame(contact.publicKey, outboundText));
    }
  }

  Future<void> setContactPath(
    Contact contact,
    Uint8List customPath,
    int hopCount,
  ) async {
    // Serialize path operations to prevent interleaved async calls from
    // leaving in-memory state inconsistent with the device.
    final prev = _pathOpLock;
    final completer = Completer<void>();
    _pathOpLock = completer.future;
    await prev;
    try {
      if (!isConnected) return;

      await sendFrame(
        buildUpdateContactPathFrame(
          contact.publicKey,
          customPath,
          hopCount,
          _pathHashByteWidth,
          type: contact.type,
          flags: contact.flags,
          name: contact.name,
          lat: contact.latitude,
          lon: contact.longitude,
          lastModified: contact.lastSeen,
        ),
      );
      // USB writes return instantly (no BLE flow control), so give the firmware
      // time to persist the path change before subsequent commands.
      if (_activeTransport == MeshCoreTransportType.usb) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      final idx = _contacts.indexWhere(
        (c) => c.publicKeyHex == contact.publicKeyHex,
      );
      if (idx != -1) {
        _contacts[idx] = _contacts[idx].copyWith(
          pathLength: hopCount,
          path: customPath,
        );
        notifyListeners();
      }
    } finally {
      completer.complete();
    }
  }

  Future<void> setContactFlags(
    Contact contact, {
    bool? isFavorite,
    bool? teleBase,
    bool? teleLoc,
    bool? teleEnv,
  }) async {
    if (!isConnected) return;
    final latestContact =
        await _fetchContactSnapshotFromDevice(contact.publicKey) ?? contact;
    int updatedFlags = isFavorite != null
        ? (isFavorite
              ? (latestContact.flags | contactFlagFavorite)
              : (latestContact.flags & ~contactFlagFavorite))
        : latestContact.flags;
    updatedFlags = teleBase != null
        ? (teleBase
              ? (updatedFlags | contactFlagTeleBase)
              : (updatedFlags & ~contactFlagTeleBase))
        : updatedFlags;
    updatedFlags = teleLoc != null
        ? (teleLoc
              ? (updatedFlags | contactFlagTeleLoc)
              : (updatedFlags & ~contactFlagTeleLoc))
        : updatedFlags;
    updatedFlags = teleEnv != null
        ? (teleEnv
              ? (updatedFlags | contactFlagTeleEnv)
              : (updatedFlags & ~contactFlagTeleEnv))
        : updatedFlags;

    await sendFrame(
      buildUpdateContactPathFrame(
        latestContact.publicKey,
        latestContact.path,
        latestContact.pathLength,
        latestContact.pathHashSize,
        type: latestContact.type,
        flags: updatedFlags,
        name: latestContact.name,
        lat: latestContact.latitude,
        lon: latestContact.longitude,
        lastModified: latestContact.lastSeen,
      ),
    );

    final index = _contacts.indexWhere(
      (c) => c.publicKeyHex == contact.publicKeyHex,
    );
    if (index >= 0) {
      _contacts[index] = _contacts[index].copyWith(
        type: latestContact.type,
        name: latestContact.name,
        pathLength: latestContact.pathLength,
        path: latestContact.path,
        flags: updatedFlags,
      );
      notifyListeners();
      unawaited(_persistContacts());
    }
  }

  Future<Contact?> _fetchContactSnapshotFromDevice(
    Uint8List pubKey, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (!isConnected) return null;
    final expectedKeyHex = pubKeyToHex(pubKey);
    final completer = Completer<Contact?>();

    void finish(Contact? result) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    final subscription = receivedFrames.listen((frame) {
      if (frame.isEmpty || frame[0] != respCodeContact) return;
      final parsed = Contact.fromFrame(frame);
      if (parsed == null || parsed.publicKeyHex != expectedKeyHex) return;
      finish(parsed);
    });

    final timer = Timer(timeout, () => finish(null));
    try {
      await getContactByKey(pubKey);
      return await completer.future;
    } finally {
      timer.cancel();
      await subscription.cancel();
    }
  }

  /// Set path override for a contact (persists across contact refreshes)
  /// pathLen: -1 = force flood, null = auto (use device path), >= 0 = specific path
  Future<void> setPathOverride(
    Contact contact, {
    int? pathLen,
    Uint8List? pathBytes,
  }) async {
    // Automatically calculate path length if bytes are provided but length is missing
    if (pathLen == null && pathBytes != null && pathBytes.isNotEmpty) {
      pathLen = PathHelper.getHopCount(pathBytes, stride: _pathHashByteWidth);
    }

    appLogger.info(
      'setPathOverride called for ${contact.name}: pathLen=$pathLen, bytesLen=${pathBytes?.length ?? 0}',
      tag: 'Connector',
    );

    // Find contact in list
    final index = _contacts.indexWhere(
      (c) => c.publicKeyHex == contact.publicKeyHex,
    );
    if (index == -1) {
      appLogger.warn(
        'setPathOverride: Contact not found in list: ${contact.name}',
        tag: 'Connector',
      );
      return;
    }

    appLogger.info(
      'Found contact at index $index. Current override: ${_contacts[index].pathOverride}',
      tag: 'Connector',
    );

    // Update contact with new path override
    _contacts[index] = _contacts[index].copyWith(
      pathOverride: pathLen,
      pathOverrideBytes: pathBytes,
      clearPathOverride: pathLen == null, // Clear if pathLen is null
    );

    appLogger.info(
      'Updated contact. New override: ${_contacts[index].pathOverride}, bytesLen: ${_contacts[index].pathOverrideBytes?.length}',
      tag: 'Connector',
    );

    // Save to storage
    await _contactStore.saveContacts(_contacts);
    appLogger.info('Saved contacts to storage', tag: 'Connector');

    // Update any in-flight retries so they use the new path override
    _retryService?.updatePendingContact(_contacts[index]);

    // If setting a specific path (not flood, not auto), also sync with device
    if (pathLen != null && pathLen >= 0 && pathBytes != null) {
      appLogger.info('Sending path to device...', tag: 'Connector');
      await setContactPath(contact, pathBytes, pathLen);
      appLogger.info('Path sent to device', tag: 'Connector');
    }

    debugPrint(
      'Set path override for ${contact.name}: pathLen=$pathLen, bytes=${pathBytes?.length ?? 0}',
    );
    notifyListeners();
  }

  Future<PathSelection> preparePathForContactSend(Contact contact) async {
    PathSelection? autoSelection;
    final autoRotationEnabled =
        _appSettingsService?.settings.autoRouteRotationEnabled == true;
    if (autoRotationEnabled && contact.pathOverride == null) {
      final maxRetries = _appSettingsService?.settings.maxMessageRetries ?? 5;
      autoSelection = _selectAutoPathForAttempt(
        contact.publicKeyHex,
        attemptIndex: 0,
        maxRetries: maxRetries,
      );
    }

    final resolved = resolvePathSelection(contact, selection: autoSelection);

    if (resolved.useFlood) {
      await clearContactPath(contact);
    } else {
      await setContactPath(
        contact,
        Uint8List.fromList(resolved.pathBytes),
        resolved.hopCount,
      );
    }

    return resolved;
  }

  void trackRepeaterAck({
    required Contact contact,
    required PathSelection selection,
    required String text,
    required int timestampSeconds,
    int attempt = 0,
  }) {
    final selfKey = _selfPublicKey;
    if (selfKey == null) return;
    // Use transformed text to match device's ACK hash computation
    final outboundText = prepareContactOutboundText(contact, text);
    final ackHash = MessageRetryService.computeExpectedAckHash(
      timestampSeconds,
      attempt,
      outboundText,
      selfKey,
    );
    final ackHashHex = ackHashToHex(ackHash);
    final messageBytes = utf8.encode(outboundText).length;
    _pendingRepeaterAcks[ackHashHex]?.timeout?.cancel();
    _pendingRepeaterAcks[ackHashHex] = _RepeaterAckContext(
      contactKeyHex: contact.publicKeyHex,
      selection: selection,
      pathLength: selection.useFlood ? -1 : selection.hopCount,
      messageBytes: messageBytes,
    );
  }

  void recordRepeaterPathResult(
    Contact contact,
    PathSelection selection,
    bool success,
    int? tripTimeMs,
  ) {
    _recordPathResult(contact.publicKeyHex, selection, success, tripTimeMs);
  }

  Future<bool> verifyContactPathOnDevice(
    Contact contact,
    Uint8List expectedPath, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (!isConnected) return false;

    final expectedHopCount = PathHelper.getHopCount(expectedPath, stride: _pathHashByteWidth);
    final completer = Completer<bool>();

    void finish(bool result) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    final subscription = receivedFrames.listen((frame) {
      if (frame.isEmpty || frame[0] != respCodeContact) return;
      final updated = Contact.fromFrame(frame);
      if (updated == null) return;
      if (updated.publicKeyHex != contact.publicKeyHex) return;
      final matchesLength = updated.pathLength == expectedHopCount;
      final matchesBytes = _pathsEqual(updated.path, expectedPath);
      if (matchesLength && matchesBytes) {
        finish(true);
      }
    });

    final timer = Timer(timeout, () => finish(false));
    try {
      await getContactByKey(contact.publicKey);
      return await completer.future;
    } finally {
      await subscription.cancel();
      timer.cancel();
    }
  }

  Future<void> _failQueuedSend(String idKey, String messageId) async {
    await _channelMessageStore.updateMessage(
      idKey,
      messageId,
      (m) => m.copyWith(status: ChannelMessageStatus.failed),
    );
    notifyListeners();
  }

  /// Sends queued while the map was unverified cannot survive the connection
  /// they were typed in: fail their rows so the user sees and can retry.
  void _failStrandedUnverifiedSends() {
    _channelSyncRetryTimer?.cancel();
    if (_pendingUnverifiedSends.isEmpty) return;
    final stranded = List.of(_pendingUnverifiedSends);
    _pendingUnverifiedSends.clear();
    for (final send in stranded) {
      final messageId = send.messageId;
      if (messageId == null) continue; // reactions: nothing filed to fail
      _cancelUnverifiedSendWatchdog(messageId);
      unawaited(_failQueuedSend(send.idKey, messageId));
    }
  }

  /// Fails a queued send that no sync pass ever came to transmit — a silently
  /// pending row is indistinguishable from one in flight, so it must settle.
  void _armUnverifiedSendWatchdog(String idKey, String messageId) {
    _unverifiedSendTimers[messageId]?.cancel();
    _unverifiedSendTimers[messageId] = Timer(_unverifiedSendMaxWait, () {
      _unverifiedSendTimers.remove(messageId);
      _pendingUnverifiedSends.removeWhere((s) => s.messageId == messageId);
      appLogger.warn(
        'Queued send $messageId never transmitted — failing it',
        tag: 'Connector',
      );
      unawaited(_failQueuedSend(idKey, messageId));
    });
  }

  void _cancelUnverifiedSendWatchdog(String messageId) {
    _unverifiedSendTimers.remove(messageId)?.cancel();
  }

  Future<void> sendChannelMessage(
    Channel channel,
    String text, {
    ChannelMessage? replyTarget,
  }) async {
    if (!isConnected || text.isEmpty) return;

    // The caller's Channel may be stale (screen opened before a resync).
    // Resolve the LIVE slot for this identity — sending by a stale index
    // would encrypt with whatever key now occupies that slot.
    final live = _liveChannelByIdKey(channel.idKey);
    if (live == null && _channelsVerified) {
      // Verified map, identity simply not on the radio (channel deleted
      // from another device). Nothing to encrypt with.
      appLogger.warn(
        'Refusing channel send: ${channel.displayName} not on radio',
        tag: 'Connector',
      );
      return;
    }
    if (!_channelsVerified) {
      // Same rule as the receive path: after a reconnect the slot map is
      // untrusted until re-verified — sending would encrypt with whatever
      // key now owns the slot. Never DISCARD the user's text though: file
      // it by trusted identity and transmit when a sync pass completes.
      if (ReactionHelper.parseReaction(text) != null) {
        _pendingUnverifiedSends.add(
          (idKey: channel.idKey, messageId: null, text: text),
        );
        return;
      }
      final message = ChannelMessage.outgoing(
        text,
        _selfName ?? 'Me',
        channel.index,
        pathHashSize: pathHashByteWidth,
      );
      await _ingestChannelMessage(
        channel.index,
        message,
        replyTarget: replyTarget,
        identity: channel,
      );
      _pendingUnverifiedSends.add(
        (idKey: channel.idKey, messageId: message.messageId, text: text),
      );
      _armUnverifiedSendWatchdog(channel.idKey, message.messageId);
      appLogger.warn(
        'Channel map unverified — queued send for ${channel.displayName}',
        tag: 'Connector',
      );
      notifyListeners();
      return;
    }
    channel = live!;

    // Check if this is a reaction - if so, process it immediately instead of adding as a message
    final reactionInfo = ReactionHelper.parseReaction(text);
    if (reactionInfo != null) {
      // Check if we've already processed this reaction. Keyed by reactor too:
      // two people reacting with the same emoji are two reactions, not a
      // duplicate of one.
      final reactorName = _selfName ?? 'Me';
      _processedChannelReactions.putIfAbsent(channel.idKey, () => {});
      final reactionIdentifier =
          '${reactionInfo.targetHash}_${reactionInfo.emoji}_$reactorName';

      if (_processedChannelReactions[channel.idKey]!.contains(
        reactionIdentifier,
      )) {
        // Already processed, don't process again
        return;
      }

      // Apply to the target row; watched queries update the UI.
      final history = await _channelMessageStore.loadChannelMessages(
        channel.idKey,
      );
      _processReaction(history, reactionInfo, reactorName);
      await _channelMessageStore.upsertMessages(channel.idKey, history);

      // Mark this reaction as processed
      _processedChannelReactions[channel.idKey]!.add(reactionIdentifier);

      notifyListeners();

      // Send the reaction to the device (don't add as a visible message)
      final reactionQueueId = _nextReactionSendQueueId();
      _pendingChannelSentQueue.add(reactionQueueId);
      await _waitForRadioQuiet(
      lastInboundRxTime: _lastChannelMsgRxTime,
      maxQuietWaitMs: _channelRadioQuietMaxWaitMs,
    );
      await sendFrame(
        buildSendChannelTextMsgFrame(channel.index, text),
        channelSendQueueId: reactionQueueId,
        expectsGenericAck: true,
      );
      return;
    }

    final message = ChannelMessage.outgoing(
      text,
      _selfName ?? 'Me',
      channel.index,
      pathHashSize: pathHashByteWidth,
    );
    await _ingestChannelMessage(channel.index, message,
        replyTarget: replyTarget);
    _pendingChannelSentQueue.add(message.messageId);
    _channelMessageRetries[message.messageId] = 0;
    
    _channelMessageTimers[message.messageId] = Timer(const Duration(seconds: 30), () {
      _handleChannelMessageTimeout(channel.index, message.messageId);
    });
    
    notifyListeners();

    final outboundText = prepareChannelOutboundText(channel.index, text);
    await _waitForRadioQuiet(
      lastInboundRxTime: _lastChannelMsgRxTime,
      maxQuietWaitMs: _channelRadioQuietMaxWaitMs,
    );
    // Stamp here (the same instant the builder used to) and remember it:
    // radio-quiet waits can push the wire clock seconds past the row's
    // construction clock, and MeshCore One reaction hashes are computed
    // over the wire value. Transmitted bytes are unchanged.
    final wireSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await sendFrame(
      buildSendChannelTextMsgFrame(
        channel.index,
        outboundText,
        timestampSecs: wireSecs,
      ),
      channelSendQueueId: message.messageId,
      expectsGenericAck: true,
    );
    await _recordSentWireSecs(channel.idKey, message.messageId, wireSecs);
  }

  /// Appends a transmitted wire timestamp to the row's [sentWireSecs] so
  /// incoming MeshCore One reactions can hash-match every stamp this
  /// message ever carried on the air.
  Future<void> _recordSentWireSecs(
    String idKey,
    String messageId,
    int secs,
  ) {
    return _channelMessageStore.updateMessage(
      idKey,
      messageId,
      (m) => m.sentWireSecs.contains(secs)
          ? m
          : m.copyWith(sentWireSecs: [...m.sentWireSecs, secs]),
    );
  }

  Future<void> resendChannelMessageById(int channelIndex, String messageId) async {
    // Same live-slot rule as sendChannelMessage: retrying with a slot index
    // whose key changed (mid-sync, or slot reshuffled) would encrypt the
    // text for the wrong channel. A settled live slot plus the message
    // still being in its bucket proves index and identity agree —
    // _adoptSlotIdentity replaces the bucket whenever the identity changes.
    final live = _channels.cast<Channel?>().firstWhere(
      (c) => c?.index == channelIndex,
      orElse: () => null,
    );
    if (live == null || _isSyncingChannels || !_channelsVerified) {
      markChannelMessageFailed(channelIndex, messageId);
      return;
    }
    final message = await _channelMessageStore.findByMessageId(
      live.idKey,
      messageId,
    );
    if (message == null) return;
    final retries = _channelMessageRetries[messageId] ?? 0;
    await _channelMessageStore.updateMessage(
      live.idKey,
      messageId,
      (m) => m.copyWith(
        sendRetryCount: retries,
        status: ChannelMessageStatus.pending,
      ),
    );
    notifyListeners();

    appLogger.info('Retrying channel message $messageId (attempt ${_channelMessageRetries[messageId]})', tag: 'Connector');
    
    _pendingChannelSentQueue.add(messageId);
    _channelMessageTimers[messageId] = Timer(const Duration(seconds: 30), () {
      _handleChannelMessageTimeout(channelIndex, messageId);
    });
    
    // Rebuild the full "@[Name]\n><snippet>..\n<body>" reply on resend, since
    // message.text only stores the stripped body. Falls back to the body alone.
    var wireText = message.text;
    if (message.replyToSenderName != null) {
      final maxBytes = maxChannelMessageBytes(_selfName);
      wireText =
          ChannelMessage.buildReplyWireText(
            targetName: message.replyToSenderName!,
            quoteText: message.replyToText ?? '',
            body: message.text,
            selfName: _selfName ?? '',
            fits: (candidate) =>
                utf8
                    .encode(prepareChannelOutboundText(channelIndex, candidate))
                    .length <=
                maxBytes,
          ) ??
          message.text;
    }

    final outboundText = prepareChannelOutboundText(channelIndex, wireText);
    await _waitForRadioQuiet(
      lastInboundRxTime: _lastChannelMsgRxTime,
      maxQuietWaitMs: _channelRadioQuietMaxWaitMs,
    );
    // Retries re-stamp on purpose (an identical payload would be dropped by
    // mesh dedup); record this stamp too so reactions to the retry copy
    // still hash-match our row.
    final wireSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await sendFrame(
      buildSendChannelTextMsgFrame(
        channelIndex,
        outboundText,
        timestampSecs: wireSecs,
      ),
      channelSendQueueId: messageId,
      expectsGenericAck: true,
    );
    await _recordSentWireSecs(live.idKey, messageId, wireSecs);
  }

  Future<void> removeContact(Contact contact) async {
    if (!isConnected) return;

    await _sendAndWaitForAck(buildRemoveContactFrame(contact.publicKey));
    _contacts.removeWhere((c) => c.publicKeyHex == contact.publicKeyHex);
    _discoveredContacts.removeWhere((c) => c.publicKeyHex == contact.publicKeyHex);
    _localDiscoveredTimes.remove(contact.publicKeyHex);
    _knownContactKeys.remove(contact.publicKeyHex);
    _messageStore.clearMessages(contact.publicKeyHex);
    notifyListeners();
    unawaited(_persistContacts());
  }

  /// Removes all contacts that are not favorites (or all contacts if [includesFavorites] is true).
  Future<void> purgeContacts({bool includesFavorites = false}) async {
    if (!isConnected) return;
    final toRemove = _contacts
        .where((c) => includesFavorites || !c.isFavorite)
        .toList();
    for (final contact in toRemove) {
      await _sendAndWaitForAck(buildRemoveContactFrame(contact.publicKey));
    }
    _contacts.removeWhere((c) => includesFavorites || !c.isFavorite);
    _discoveredContacts.removeWhere(
        (c) => toRemove.any((r) => r.publicKeyHex == c.publicKeyHex));
    for (final contact in toRemove) {
      _localDiscoveredTimes.remove(contact.publicKeyHex);
      _knownContactKeys.remove(contact.publicKeyHex);


      _messageStore.clearMessages(contact.publicKeyHex);
    }
    notifyListeners();
    unawaited(_persistContacts());
  }

  Future<void> updateKnownDiscovered() async {
    if (!isConnected) return;
    for (int i = 0; i < _discoveredContacts.length; i++) {
      _discoveredContacts[i] = _discoveredContacts[i].copyWith(
        isActive: _knownContactKeys.contains(
          _discoveredContacts[i].publicKeyHex,
        ),
      );
    }
    unawaited(_persistDiscoveredContacts());
    notifyListeners();
  }

  Future<void> removeDiscoveredContact(Contact contact) async {
    if (!isConnected) return;
    _discoveredContacts.removeWhere(
      (c) => c.publicKeyHex == contact.publicKeyHex,
    );
    unawaited(_persistDiscoveredContacts());
    notifyListeners();
  }

  Future<bool> importDiscoveredContact(Contact contact) async {
    if (!isConnected) return false;

    final success = await _sendAndWaitForAck(
      buildUpdateContactPathFrame(
        contact.publicKey,
        contact.path,
        contact.pathLength,
        contact.pathHashSize,
        type: contact.type,
        flags: contact.flags,
        name: contact.name,
        lat: contact.latitude,
        lon: contact.longitude,
        lastModified: contact.lastSeen,
      ),
    );

    if (!success) {
      appLogger.error('Failed to import contact ${contact.name}', tag: 'Connector');
      return false;
    }

    // Update the discovered contact to mark it as active (imported)
    final discoveredIndex = _discoveredContacts.indexWhere(
      (c) => c.publicKeyHex == contact.publicKeyHex,
    );
    if (discoveredIndex >= 0) {
      _discoveredContacts[discoveredIndex] =
          _discoveredContacts[discoveredIndex].copyWith(isActive: true);
    }

    _handleContactAdvert(
      Contact(
        publicKey: contact.publicKey,
        name: contact.name,
        type: contact.type,
        pathLength: contact.pathLength,
        path: contact.path,
        pathHashSize: contact.pathHashSize, // preserve hash size
        latitude: contact.latitude,
        longitude: contact.longitude,
        lastSeen: DateTime.now(),
        flags: contact.flags,
        pathOverride: contact.pathOverride,
        pathOverrideBytes: contact.pathOverrideBytes,
      ),
    );

    // Always persist immediately — _handleContactAdvert skips persist
    // when _isLoadingContacts is true, which would lose this contact on restart.
    await _persistContacts();
    notifyListeners();
    return true;
  }

  Future<void> clearContactPath(Contact contact) async {
    // Serialize path operations to prevent interleaved async calls.
    final prev = _pathOpLock;
    final completer = Completer<void>();
    _pathOpLock = completer.future;
    await prev;
    try {
      if (!isConnected) return;

      await sendFrame(buildResetPathFrame(contact.publicKey));
      if (_activeTransport == MeshCoreTransportType.usb) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      final existingIndex = _contacts.indexWhere(
        (c) => c.publicKeyHex == contact.publicKeyHex,
      );
      if (existingIndex >= 0) {
        final existing = _contacts[existingIndex];
        // Preserve pathOverride and pathOverrideBytes — only reset device path
        _contacts[existingIndex] = existing.copyWith(
          pathLength: -1,
          path: Uint8List(0),
        );
        notifyListeners();
        unawaited(_persistContacts());
      }
    } finally {
      completer.complete();
    }
  }

  void updateContactInMemory(
    String publicKeyHex, {
    Uint8List? pathBytes,
    int? pathLength,
  }) {
    final existingIndex = _contacts.indexWhere(
      (c) => c.publicKeyHex == publicKeyHex,
    );
    if (existingIndex >= 0) {
      final existing = _contacts[existingIndex];
      _contacts[existingIndex] = existing.copyWith(
        pathLength: pathLength,
        path: pathBytes,
      );
      notifyListeners();
      unawaited(_persistContacts());
    }
  }

  /// How far the radio's clock sat from the phone's at the last check
  /// (positive = radio ahead). Null until a connection checks it.
  Duration? get deviceClockSkew => _lastDeviceClockSkew;
  Duration? _lastDeviceClockSkew;

  /// True when the radio's clock is wrong and this app cannot fix it, because
  /// the firmware refuses to wind a clock backwards. Every message the radio
  /// transmits carries a future timestamp until it is corrected another way.
  bool get deviceClockStuckAhead => _deviceClockStuckAhead;
  bool _deviceClockStuckAhead = false;

  /// A radio clock is only worth correcting once it is off by more than this;
  /// the set/read round-trip itself costs tens of milliseconds.
  static const Duration deviceClockTolerance = Duration(seconds: 5);

  /// What to do about a radio whose clock differs from ours by [skew]
  /// (positive = radio ahead of us).
  ///
  /// The firmware only accepts a time at or after its current one
  /// (CMD_SET_DEVICE_TIME in MyMesh.cpp rejects anything earlier with
  /// ERR_CODE_ILLEGAL_ARG), so a radio running AHEAD cannot be corrected from
  /// here at all — it can only be reported.
  @visibleForTesting
  static DeviceClockAction decideDeviceClockAction(Duration skew) {
    if (skew.abs() <= deviceClockTolerance) return DeviceClockAction.ok;
    return skew.isNegative
        ? DeviceClockAction.windForward
        : DeviceClockAction.stuckAhead;
  }

  /// Sets the radio's clock from the phone, then reads it back to confirm it
  /// actually took.
  ///
  /// This used to be a single fire-and-forget SET with no reply check, so a
  /// dropped frame — or the firmware's refusal to wind a clock backwards —
  /// left the radio stamping every message it sent with the wrong time, with
  /// nothing logged and no way to find out after the fact.
  Future<void> syncTime() async {
    if (!isConnected) return;

    final before = await _readDeviceClockSkew();
    if (before == null) {
      // No reply. Set anyway (the old behaviour) rather than skip the sync.
      appLogger.warn(
        'Radio clock unreadable; setting it blind',
        tag: 'Connector',
      );
      await sendFrame(
        buildSetDeviceTimeFrame(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      );
      return;
    }

    _lastDeviceClockSkew = before;
    switch (decideDeviceClockAction(before)) {
      case DeviceClockAction.ok:
        _deviceClockStuckAhead = false;
        appLogger.info(
          'Radio clock within ${_describeSkew(before)} of this device',
          tag: 'Connector',
        );
        return;
      case DeviceClockAction.stuckAhead:
        // The firmware will reject this, but attempt it so the refusal is
        // visible in the frame log rather than assumed.
        await sendFrame(
          buildSetDeviceTimeFrame(DateTime.now().millisecondsSinceEpoch ~/ 1000),
        );
        _deviceClockStuckAhead = true;
        appLogger.error(
          'Radio clock is ${_describeSkew(before)} AHEAD of this device and '
          'the firmware refuses to wind a clock backwards, so it cannot be '
          'corrected from here. Every message this radio sends will carry a '
          'future timestamp until its clock is reset on the device itself.',
          tag: 'Connector',
        );
        return;
      case DeviceClockAction.windForward:
        await sendFrame(
          buildSetDeviceTimeFrame(DateTime.now().millisecondsSinceEpoch ~/ 1000),
        );
        final after = await _readDeviceClockSkew();
        _lastDeviceClockSkew = after ?? before;
        if (after != null &&
            decideDeviceClockAction(after) == DeviceClockAction.ok) {
          _deviceClockStuckAhead = false;
          appLogger.info(
            'Radio clock was ${_describeSkew(before)} behind; corrected',
            tag: 'Connector',
          );
        } else {
          appLogger.error(
            'Radio clock was ${_describeSkew(before)} behind and did not take '
            'the correction'
            '${after == null ? ' (no reply on re-read)' : ' (still ${_describeSkew(after)})'}',
            tag: 'Connector',
          );
        }
        return;
    }
  }

  static String _describeSkew(Duration skew) {
    final s = skew.abs();
    if (s.inMinutes < 1) return '${s.inSeconds}s';
    if (s.inHours < 1) return '${s.inMinutes}m ${s.inSeconds % 60}s';
    return '${s.inHours}h ${s.inMinutes % 60}m';
  }

  /// Asks the radio for its clock and returns how far it sits from ours
  /// (positive = radio ahead), or null when it does not answer.
  Future<Duration?> _readDeviceClockSkew({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (!isConnected) return null;
    final completer = Completer<Duration?>();
    final subscription = receivedFrames.listen((frame) {
      if (frame.length < 5 || frame[0] != respCodeCurrTime) return;
      final deviceSecs = ByteData.sublistView(
        frame,
        1,
        5,
      ).getUint32(0, Endian.little);
      if (completer.isCompleted) return;
      completer.complete(
        DateTime.fromMillisecondsSinceEpoch(deviceSecs * 1000)
            .difference(DateTime.now()),
      );
    });
    try {
      await sendFrame(buildGetDeviceTimeFrame());
      return await completer.future.timeout(timeout, onTimeout: () => null);
    } catch (e) {
      appLogger.warn('Radio clock read failed: $e', tag: 'Connector');
      return null;
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> syncQueuedMessages({bool force = false}) async {
    if (!isConnected) return;
    if (!force && _isSyncingQueuedMessages) return;
    if (_awaitingSelfInfo || _isLoadingContacts) {
      _pendingQueueSync = true;
      return;
    }
    // Queue messages are slot-indexed: drain only against a verified channel
    // map. Channels load first, queue after — never concurrently (the radio
    // can't serve two sequential-request protocols at once).
    if (!_channelsVerified || _isSyncingChannels) {
      _pendingQueueSyncAfterChannelSync = true;
      return;
    }
    await _startQueueSyncNow();
  }

  /// Bypasses the verified-map gate: used by the channel-sync completion and
  /// failure paths, where re-checking the gate would re-defer forever. On the
  /// failure path unverified filing is safe — unknown slots buffer.
  Future<void> _startQueueSyncNow() async {
    if (!isConnected) return;
    _isSyncingQueuedMessages = true;
    _queuedMessagesRead = 0;
    notifyListeners();
    await _requestNextQueuedMessage();
  }

  Future<void> _requestNextQueuedMessage() async {
    if (!isConnected) {
      _isSyncingQueuedMessages = false;
      _queuedMessageSyncInFlight = false;
      _queueSyncRetries = 0;
      return;
    }
    if (_queuedMessageSyncInFlight) return;
    _queuedMessageSyncInFlight = true;

    // Cancel any existing timeout
    _queueSyncTimeout?.cancel();

    // Set up timeout for this request
    _queueSyncTimeout = Timer(Duration(milliseconds: _queueSyncTimeoutMs), () {
      _handleQueueSyncTimeout();
    });

    debugPrint(
      '[QueueSync] Requesting next message (retry: $_queueSyncRetries/$_maxQueueSyncRetries)',
    );

    try {
      await sendFrame(buildSyncNextMessageFrame());
    } catch (e) {
      debugPrint('[QueueSync] Error sending sync request: $e');
      _queuedMessageSyncInFlight = false;
      _isSyncingQueuedMessages = false;
      notifyListeners();
      _queueSyncTimeout?.cancel();
      _queueSyncRetries = 0;
    }
  }

  void _handleQueueSyncTimeout() {
    debugPrint(
      '[QueueSync] Timeout waiting for message (retry: $_queueSyncRetries/$_maxQueueSyncRetries)',
    );

    if (_queueSyncRetries < _maxQueueSyncRetries) {
      // Retry
      _queueSyncRetries++;
      _queuedMessageSyncInFlight = false;
      _requestNextQueuedMessage();
    } else {
      // Max retries reached, give up
      debugPrint('[QueueSync] Max retries reached, stopping sync');
      _queuedMessageSyncInFlight = false;
      _isSyncingQueuedMessages = false;
      notifyListeners();
      _queueSyncRetries = 0;
    }
  }

  Future<void> sendCliCommand(String command) async {
    if (!isConnected) return;

    // CLI commands are sent as UTF-8 text with a special prefix
    final commandBytes = utf8.encode(command);
    final bytes = Uint8List.fromList([0x01, ...commandBytes, 0x00]);
    _lastSentWasCliCommand = true;
    await sendFrame(bytes);
  }

  Future<void> setNodeName(String name) async {
    if (!isConnected) return;
    await sendFrame(buildSetAdvertNameFrame(name));
  }

  Future<void> setNodeLocation({
    required double lat,
    required double lon,
  }) async {
    if (!isConnected) return;
    await sendFrame(buildSetAdvertLatLonFrame(lat, lon));
  }

  Future<void> setCustomVar(String value) async {
    if (!isConnected) return;
    await sendFrame(buildSetCustomVarFrame(value));
  }

  Future<void> sendSelfAdvert({bool flood = true}) async {
    if (!isConnected) return;
    await sendFrame(buildSendSelfAdvertFrame(flood: flood));
  }

  Future<void> sendRepeaterDiscovery() async {
    if (!isConnected) return;

    final rand = math.Random();
    final tag = rand.nextInt(0xFFFFFFFF);
    _pendingDiscoverTag = tag;
    _isDiscovering = true;
    notifyListeners();

    _discoverTimer?.cancel();
    // Repeater firmware answers with a randomized anti-collision delay
    // (sendZeroHop with getRetransmitDelay x4, simple_repeater/MyMesh.cpp) —
    // a 10s window dropped legitimate late responses on the bench.
    _discoverTimer = Timer(const Duration(seconds: 30), () {
      _isDiscovering = false;
      _pendingDiscoverTag = null;
      notifyListeners();
    });

final frame = buildRepeaterDiscoveryFrame(tag);

    try {
      await sendFrame(frame);
      appLogger.info('Sent repeater discovery query with tag 0x${tag.toRadixString(16).padLeft(8, "0")}');
    } catch (e) {
      appLogger.error('Failed to send repeater discovery frame: $e');
      _discoverTimer?.cancel();
      _isDiscovering = false;
      _pendingDiscoverTag = null;
      notifyListeners();
    }
  }

  Future<void> rebootDevice() async {
    if (!isConnected) return;
    await sendFrame(buildRebootFrame());
  }

  Future<void> setPrivacyMode(bool enabled) async {
    await sendCliCommand('set privacy ${enabled ? 'on' : 'off'}');
  }

  Future<void> setTelemetryModeBase(
    int base,
    int location,
    int env,
    int advert,
    int multiAcks,
  ) async {
    if (!isConnected) return;
    _telemetryModeBase = base.clamp(teleModeDeny, teleModeAllowAll).toInt();
    _telemetryModeLoc = location.clamp(teleModeDeny, teleModeAllowAll).toInt();
    _telemetryModeEnv = env.clamp(teleModeDeny, teleModeAllowAll).toInt();
    _advertLocPolicy = advert.clamp(0, 1).toInt();
    _multiAcks = multiAcks.clamp(0, 2).toInt();
    await sendFrame(
      buildSetOtherParamsFrame(
        (_telemetryModeLoc << 4) |
            (_telemetryModeEnv << 2) |
            _telemetryModeBase,
        _advertLocPolicy,
        _multiAcks,
      ),
    );
    notifyListeners();
  }

  /// A loaded map that is no longer VERIFIED is not loaded for our purposes:
  /// every disconnect invalidates the slot->identity map, and the reconnect
  /// path fetches without force. Skipping there left the map permanently
  /// unverified, which gates every channel send for the rest of the session.
  @visibleForTesting
  static bool shouldSkipChannelFetch({
    required bool hasLoadedChannels,
    required bool channelsVerified,
    required bool force,
  }) => hasLoadedChannels && channelsVerified && !force;

  Future<void> getChannels({int? maxChannels, bool force = false}) async {
    if (!isConnected) return;
    if (_isSyncingChannels) {
      if (force) {
        // The in-flight pass may already be past the slot that just
        // changed — dropping the request would leave the change invisible
        // until some unrelated later sync.
        _pendingForceChannelResync = true;
        debugPrint('[ChannelSync] Sync in flight — queued follow-up resync');
      } else {
        debugPrint('[ChannelSync] Already syncing channels, ignoring request');
      }
      return;
    }

    // Skip fetching if already loaded and not forced
    if (shouldSkipChannelFetch(
      hasLoadedChannels: _hasLoadedChannels,
      channelsVerified: _channelsVerified,
      force: force,
    )) {
      debugPrint(
        '[ChannelSync] Channels already loaded, skipping fetch (use force=true to reload)',
      );
      return;
    }

    _isLoadingChannels = true;
    _isSyncingChannels = true;
    _previousChannelsCache = List<Channel>.from(_channels);
    _channels.clear();
    _nextChannelIndexToRequest = 0;
    _totalChannelsToRequest = maxChannels ?? _maxChannels;
    _channelSyncRetries = 0;
    _slotsToRequery.clear();
    _queriedUntrackedChannels.clear();
    notifyListeners();

    debugPrint(
      '[ChannelSync] Starting sync for $_totalChannelsToRequest channels',
    );

    // Start sequential sync
    await _requestNextChannel();
  }

  Future<void> _requestNextChannel() async {
    if (!isConnected) {
      _cleanupChannelSync(completed: false);
      return;
    }

    if (_channelSyncInFlight) return;

    // Check if we've requested all channels
    if (_nextChannelIndexToRequest >= _totalChannelsToRequest) {
      _completeChannelSync();
      return;
    }

    _channelSyncInFlight = true;
    final channelIndex = _nextChannelIndexToRequest;

    // Cancel any existing timeout
    _channelSyncTimeout?.cancel();

    // Set up timeout for this channel request
    _channelSyncTimeout = Timer(
      Duration(milliseconds: _channelSyncTimeoutMs),
      () => _handleChannelSyncTimeout(channelIndex),
    );

    debugPrint(
      '[ChannelSync] Requesting channel $channelIndex/$_totalChannelsToRequest (retry: $_channelSyncRetries/$_maxChannelSyncRetries)',
    );

    try {
      await sendFrame(buildGetChannelFrame(channelIndex));
    } catch (e) {
      debugPrint('[ChannelSync] Error sending channel request: $e');
      _channelSyncInFlight = false;
      _cleanupChannelSync(completed: false);
    }
  }

  void _handleChannelSyncTimeout(int channelIndex) {
    debugPrint(
      '[ChannelSync] Timeout waiting for channel $channelIndex (retry: $_channelSyncRetries/$_maxChannelSyncRetries)',
    );

    if (_channelSyncRetries < _maxChannelSyncRetries) {
      // Retry the same channel
      _channelSyncRetries++;
      _channelSyncInFlight = false;
      unawaited(_requestNextChannel());
    } else {
      // Max retries reached. Do NOT resurrect the slot's identity from a
      // previous session's cache — gluing a stale channel onto a slot files
      // messages into the wrong conversation. Re-query the slot after the
      // sync pass finishes instead.
      debugPrint(
        '[ChannelSync] Max retries reached for channel $channelIndex, will re-query after sync',
      );
      _slotsToRequery.add(channelIndex);

      // Move to next channel
      _nextChannelIndexToRequest++;
      _channelSyncRetries = 0;
      _channelSyncInFlight = false;
      unawaited(_requestNextChannel());
    }
  }

  void _completeChannelSync() {
    _channelSyncTimeout?.cancel();

    debugPrint(
      '[ChannelSync] Sync complete: received ${_channels.length}/$_totalChannelsToRequest channels',
    );

    _cleanupChannelSync(completed: true);
    _channelsVerified = true;

    // Drain messages that buffered for already-confirmed slots while the
    // rest of the sync was still running — nothing else flushes them.
    for (final channel in List<Channel>.from(_channels)) {
      _flushPendingForSlot(channel);
    }
    // Buffers for slots with no live channel (their sync attempt timed out)
    // would otherwise strand until disconnect: solicit their CHANNEL_INFO
    // directly, bypassing the query-once set.
    for (final idx in _pendingUntrackedChannelMessages.keys.toList()) {
      unawaited(sendFrame(buildGetChannelFrame(idx)));
    }

    // A slot changed while this pass ran: the map is valid but already
    // stale. Rerun now — a deferred queue drain stays deferred so it always
    // drains against the freshest map.
    if (_pendingForceChannelResync) {
      _pendingForceChannelResync = false;
      unawaited(getChannels(force: true));
      return;
    }

    // Map verified — now the deferred queue drain may run.
    if (_pendingQueueSyncAfterChannelSync) {
      _pendingQueueSyncAfterChannelSync = false;
      unawaited(_startQueueSyncNow());
    }

    // Transmit sends that queued while the map was unverified. Rows are
    // already filed (pending); the resend path rebuilds reply wire text.
    _channelSyncRetryTimer?.cancel();
    if (_pendingUnverifiedSends.isNotEmpty) {
      final queued = List.of(_pendingUnverifiedSends);
      _pendingUnverifiedSends.clear();
      for (final send in queued) {
        final target = _liveChannelByIdKey(send.idKey);
        final messageId = send.messageId;
        if (messageId != null) _cancelUnverifiedSendWatchdog(messageId);
        if (target == null) {
          appLogger.warn(
            'Queued send dropped: channel identity no longer on radio',
            tag: 'Connector',
          );
          if (messageId != null) {
            unawaited(_failQueuedSend(send.idKey, messageId));
          }
          continue;
        }
        if (messageId == null) {
          unawaited(sendChannelMessage(target, send.text));
        } else {
          unawaited(resendChannelMessageById(target.index, messageId));
        }
      }
    }

    _runChannelHealthCheck();

    // Cache channels for offline use. Retain prior cached entries for slots
    // that merely TIMED OUT this pass — dropping them stranded the slot from
    // both lists, silently no-oping every persist for its bucket.
    final retained = _cachedChannels.where(
      (c) =>
          _slotsToRequery.contains(c.index) &&
          !_channels.any((l) => l.index == c.index),
    );
    _cachedChannels = [..._channels, ...retained];
    unawaited(_channelStore.saveChannels(_channels));

    // Migrate legacy name-keyed mutes to identity keys while the names
    // still match — a lingering name entry would silently mute any FUTURE
    // channel that happens to share the name.
    final settingsService = _appSettingsService;
    if (settingsService != null) {
      for (final c in _channels) {
        if (settingsService.isChannelMuted(c.idKey)) continue;
        if (settingsService.isChannelMuted(c.name) ||
            settingsService.isChannelMuted(c.displayName)) {
          unawaited(settingsService.muteChannel(c.idKey));
          unawaited(settingsService.unmuteChannel(c.name));
          unawaited(settingsService.unmuteChannel(c.displayName));
        }
      }
    }

    // Retry slots that timed out during the pass; their CHANNEL_INFO replies
    // arrive as unsolicited updates.
    for (final idx in _slotsToRequery) {
      unawaited(sendFrame(buildGetChannelFrame(idx)));
    }
    _slotsToRequery.clear();

    // Apply ordering and notify UI
    _applyChannelOrder();
    notifyListeners();
  }

  void _handleChannelMessageTimeout(int channelIndex, String messageId) {
    _channelMessageTimers.remove(messageId);
    _pendingChannelSentQueue.remove(messageId);
    _pendingGenericAckQueue.removeWhere((ack) => ack.channelSendQueueId == messageId);

    final retries = _channelMessageRetries[messageId] ?? 0;
    final maxRetries = _appSettingsService?.settings.maxChannelMessageRetries ?? 1;
    if (retries < maxRetries) {
      _channelMessageRetries[messageId] = retries + 1;
      unawaited(resendChannelMessageById(channelIndex, messageId));
      return;
    }

    markChannelMessageFailed(channelIndex, messageId);
  }

  void markChannelMessageFailed(int channelIndex, String messageId) {
    final channel = _findChannelByIndex(channelIndex);
    if (channel == null) return;
    unawaited(() async {
      final updated = await _channelMessageStore.updateMessage(
        channel.idKey,
        messageId,
        (m) => m.status == ChannelMessageStatus.pending
            ? m.copyWith(status: ChannelMessageStatus.failed)
            : m,
      );
      if (updated) notifyListeners();
    }());
  }

  void _startWaitForRepeatTimer(int channelIndex, String messageId) {
    _channelRepeatTimers[messageId]?.cancel();
    _channelRepeatTimers[messageId] = Timer(const Duration(seconds: 30), () {
      _channelRepeatTimers.remove(messageId);
      final retries = _channelMessageRetries[messageId] ?? 0;
      final maxRetries = _appSettingsService?.settings.maxChannelMessageRetries ?? 1;
      if (retries < maxRetries) {
        appLogger.info('No repeat heard for $messageId, retrying (attempt ${retries + 1})', tag: 'Connector');
        _channelMessageRetries[messageId] = retries + 1;
        unawaited(resendChannelMessageById(channelIndex, messageId));
      } else {
        notifyListeners();
      }
    });
  }

  void _cleanupChannelSync({required bool completed}) {
    if (!completed) {
      // A failed pass leaves _channels partially rebuilt — the map is not
      // trustworthy for filing or sending until a pass completes.
      _channelsVerified = false;
      // A queued follow-up resync dies with the failed pass; reconnect
      // always starts with a fresh full sync anyway.
      _pendingForceChannelResync = false;
      // Never leave a partial table on display: restore the last settled
      // list. verified=false keeps filing and sending gated regardless.
      _channels
        ..clear()
        ..addAll(_previousChannelsCache);
      // Don't strand a deferred queue drain behind the failed pass: run it
      // anyway. Unverified filing is safe — unknown slots buffer.
      if (_pendingQueueSyncAfterChannelSync) {
        _pendingQueueSyncAfterChannelSync = false;
        unawaited(_startQueueSyncNow());
      }
      // A dead pass with the connection still up must retry: verified stays
      // false otherwise and every channel send is gated until reconnect.
      if (isConnected) {
        _channelSyncRetryTimer?.cancel();
        _channelSyncRetryTimer = Timer(const Duration(seconds: 3), () {
          if (isConnected && !_channelsVerified && !_isSyncingChannels) {
            appLogger.warn(
              'Channel sync pass failed — retrying',
              tag: 'Connector',
            );
            unawaited(getChannels(force: true));
          }
        });
      }
    }
    _isSyncingChannels = false;
    _channelSyncInFlight = false;
    _isLoadingChannels = false;
    _channelSyncTimeout?.cancel();
    _channelSyncRetries = 0;
    _nextChannelIndexToRequest = 0;
    _totalChannelsToRequest = 0;

    if (completed) {
      _hasLoadedChannels = true;
      _previousChannelsCache.clear();
    }

    // Fallback: if contact sync was deferred waiting for channel 0 but
    // channel sync finished without triggering it, start contacts now.
    if (_pendingInitialContactsSync && isConnected) {
      _pendingInitialContactsSync = false;
      unawaited(getContacts());
    }

    // Keep cache on failure/disconnection for future attempts
  }

  Future<void> setChannel(int index, String name, Uint8List psk) async {
    if (!isConnected) return;

    // One identity, one slot: a second slot with the same PSK collapses
    // into one history bucket and renders as twin channels.
    final duplicate = _liveChannelByIdKey(Channel.formatPskHex(psk));
    if (duplicate != null && duplicate.index != index) {
      appLogger.warn(
        'Refusing setChannel($index): PSK already lives in slot ${duplicate.index}',
        tag: 'Connector',
      );
      return;
    }

    final existingChannel = channels.firstWhere(
      (c) => c.index == index,
      orElse: () => Channel.empty(index),
    );
    final isNewChannel = existingChannel.name != name ||
        !listEquals(existingChannel.psk, psk);

    await sendFrame(buildSetChannelFrame(index, name, psk));

    if (isNewChannel) {
      // Storage is identity-keyed: the new identity's history is naturally
      // fresh (or restores itself if the same channel is re-added).
      notifyListeners();
    }

    // Refresh channels after setting
    await getChannels(force: true);
  }

  Future<void> deleteChannel(int index) async {
    if (!isConnected) return;

    // Resolve the slot's identity before zeroing it so the right history
    // is deleted with it.
    final channel = _findChannelByIndex(index);
    // Delete by setting empty name and zero PSK
    await sendFrame(buildSetChannelFrame(index, '', Uint8List(16)));
    if (channel != null) {
      await _channelMessageStore.clearChannelMessages(channel.idKey);
    }
    // Refresh channels after deleting
    await getChannels(force: true);
  }

  void _handleFrame(List<int> data) {
    if (data.isEmpty) return;
    _lastRxTime = DateTime.now();

    final frame = Uint8List.fromList(data);
    _receivedFramesController.add(frame);
    _bleDebugLogService?.logFrame(frame, outgoing: false);

    final code = frame[0];
    // debugPrint('RX frame: code=$code len=${frame.length}');

    switch (code) {
      case respCodeOk:
        _handleOk();
        break;
      case respCodeDeviceInfo:
        _handleDeviceInfo(frame);
        break;
      case respCodeSelfInfo:
        debugPrint('Got SELF_INFO');
        _handleSelfInfo(frame);
        break;
      case respCodeContactsStart:
        debugPrint('Got CONTACTS_START');
        if (!_preserveContactsOnRefresh) {
          _contacts.clear();
        }
        if (frame.length >= 5) {
          final reader = BufferReader(frame);
          reader.skipBytes(1);
          _expectedContactsCount = reader.readUInt32LE();
        } else {
          _expectedContactsCount = 0;
        }
        _loadedContactsCount = 0;
        _isLoadingContacts = true;
        notifyListeners();
        break;
      case pushCodeAdvert:
        // Known contact was seen again - just a pub key, update live timestamp
        final pubKeyHex = pubKeyToHex(frame.sublist(1, 33));
        _localDiscoveredTimes[pubKeyHex] = DateTime.now();
        notifyListeners();
        break;
      case pushCodeNewAdvert:
        debugPrint('Got New CONTACT');
        // It's the same format as respCodeContact, so we can reuse the handler
        _handleContact(frame, isContact: false);
        break;
      case respCodeContact:
        debugPrint('Got CONTACT');
        _handleContact(frame);
        break;
      case respCodeEndOfContacts:
        debugPrint('Got END_OF_CONTACTS');
        _isLoadingContacts = false;
        _preserveContactsOnRefresh = false;
        unawaited(updateKnownDiscovered());
        notifyListeners();
        unawaited(_persistContacts());
        if (PlatformInfo.isWeb &&
            _activeTransport == MeshCoreTransportType.bluetooth &&
            _isSyncingChannels &&
            !_channelSyncInFlight) {
          unawaited(_requestNextChannel());
        }
        if (!_didInitialQueueSync || _pendingQueueSync) {
          _didInitialQueueSync = true;
          _pendingQueueSync = false;
          if (_pendingDeferredChannelSyncAfterContacts &&
              (_activeTransport == MeshCoreTransportType.bluetooth ||
                  _activeTransport == MeshCoreTransportType.usb ||
                  _activeTransport == MeshCoreTransportType.tcp)) {
            // Channels FIRST, queue after (still strictly sequential — the
            // device can't serve two request protocols at once). The queue's
            // messages are slot-indexed; draining them before the channel
            // map loaded was the root of every unverified-window bug.
            // force: a reconnect must always re-verify the map.
            _pendingDeferredChannelSyncAfterContacts = false;
            _pendingInitialChannelSync = false;
            _pendingQueueSyncAfterChannelSync = true;
            unawaited(getChannels(force: true));
          } else {
            unawaited(syncQueuedMessages(force: true));
          }
        } else if (_pendingDeferredChannelSyncAfterContacts &&
            (_activeTransport == MeshCoreTransportType.bluetooth ||
                _activeTransport == MeshCoreTransportType.usb ||
                _activeTransport == MeshCoreTransportType.tcp)) {
          _pendingDeferredChannelSyncAfterContacts = false;
          _pendingInitialChannelSync = false;
          unawaited(getChannels());
        }
        break;
      case respCodeContactMsgRecv:
      case respCodeContactMsgRecvV3:
        _handleIncomingMessage(frame);
        break;
      case respCodeChannelMsgRecv:
      case respCodeChannelMsgRecvV3:
        _handleIncomingChannelMessage(frame);
        break;
      case respCodeSent:
        _handleMessageSent(frame);
        break;
      case respCodeNoMoreMessages:
        _handleNoMoreMessages();
        break;
      case pushCodeMsgWaiting:
        unawaited(syncQueuedMessages(force: true));
        break;
      case pushCodeSendConfirmed:
        _handleSendConfirmed(frame);
        break;
      case pushCodePathUpdated:
        _handlePathUpdated(frame);
        break;
      case pushCodeLoginSuccess:
      case pushCodeLoginFail:
      case pushCodeStatusResponse:
        break;
      case pushCodeLogRxData:
        _lastRadioRxTime = DateTime.now();
        _handleRxData(frame);
        _handleLogRxData(frame);
        break;
      case pushCodeControlData:
        _handleControlData(frame);
        break;
      case respCodeChannelInfo:
        _handleChannelInfo(frame);
        break;
      case respCodeAutoAddConfig:
        _handleAutoAddConfig(frame);
        _checkManualAddContacts();
        break;
      case respCodeBattAndStorage:
        _handleBatteryAndStorage(frame);
        break;
      case respCodeStats:
        _handleStatsFrame(frame);
        break;
      case respCodeCustomVars:
        _handleCustomVars(frame);
        break;
      // RESP_CODE_ERR is a defined firmware response (code 1), not an unknown frame.
      case respCodeErr:
        _handleErrorFrame(frame);
        break;
      default:
        debugPrint('Unknown frame code: $code');
    }
  }

  void _handleErrorFrame(Uint8List frame) {
    final errCode = frame.length > 1 ? frame[1] : -1;
    _appDebugLogService?.warn(
      'Firmware responded with error code: $errCode',
      tag: 'Protocol',
    );
    _errorStreamController.add(errCode);

    if (_pendingGenericAckQueue.isEmpty) {
      return;
    }

    final failedAck = _pendingGenericAckQueue.removeAt(0);
    if (failedAck.commandCode != cmdSendChannelTxtMsg ||
        failedAck.channelSendQueueId == null) {
      return;
    }
    _pendingChannelSentQueue.remove(failedAck.channelSendQueueId);
  }

  void _handlePathUpdated(Uint8List frame) {
    // Frame format: [0]=code, [1-32]=pub_key
    if (frame.length >= 33 && _pathHistoryService != null) {
      final pubKey = Uint8List.fromList(frame.sublist(1, 33));
      final contact = _contacts.cast<Contact?>().firstWhere(
        (c) => c != null && listEquals(c.publicKey, pubKey),
        orElse: () => null,
      );

      if (contact != null) {
        _pathHistoryService!.handlePathUpdated(contact);
        // Refresh just this specific contact instead of all contacts.
        // This avoids race conditions with _preserveContactsOnRefresh flag
        // that can occur when using refreshContactsSinceLastmod().
        getContactByKey(pubKey);
      }
    }
  }

  void _handleSelfInfo(Uint8List frame) {
    // SELF_INFO format:
    // [0] = RESP_CODE_SELF_INFO
    // [1] = ADV_TYPE
    // [2] = tx_power_dbm
    // [3] = MAX_LORA_TX_POWER
    // [4-35] = pub_key (32 bytes)
    // [36-39] = lat (int32 LE)
    // [40-43] = lon (int32 LE)
    // [44] = multi_acks
    // [45] = advert_loc_policy
    // [46] = telemetry modes
    // [47] = manual_add_contacts
    // [48-51] = freq (uint32 LE, in Hz)
    // [52-55] = bw (uint32 LE, in Hz)
    // [56] = sf
    // [57] = cr
    // [58+] = node_name
    final wasAwaitingSelfInfo = _awaitingSelfInfo;
    final reader = BufferReader(frame);
    try {
      reader.skipBytes(2);
      _currentTxPower = reader.readInt8();
      _maxTxPower = reader.readInt8();
      _selfPublicKey = reader.readBytes(pubKeySize);
      _selfLatitude = reader.readInt32LE() / 1000000.0;
      _selfLongitude = reader.readInt32LE() / 1000000.0;
      _multiAcks = reader.readByte();
      _advertLocPolicy = reader.readByte();
      final telemetryFlag = reader.readByte();
      _telemetryModeBase = telemetryFlag & 0x03;
      _telemetryModeEnv = telemetryFlag >> 2 & 0x03;
      _telemetryModeLoc = telemetryFlag >> 4 & 0x03;

      _manualAddContacts = reader.readByte() & 0x01 == 0x00;

      _currentFreqHz = reader.readUInt32LE();
      _currentBwHz = reader.readUInt32LE();
      _currentSf = reader.readByte();
      _currentCr = reader.readByte();

      _selfName = reader.readCString();
    } catch (e) {
      _appDebugLogService?.error(
        'Error parsing SELF_INFO frame: $e',
        tag: 'Connector',
      );
    }
    final selfName = _selfName?.trim();
    if (_activeTransport == MeshCoreTransportType.usb &&
        selfName != null &&
        selfName.isNotEmpty) {
      _usbManager.updateConnectedLabel(selfName);
    }

    //set all the stores' public key so they can load the correct data
    _channelMessageStore.setPublicKeyHex = selfPublicKeyHex;
    _messageStore.setPublicKeyHex = selfPublicKeyHex;
    _channelOrderStore.setPublicKeyHex = selfPublicKeyHex;
    _channelSettingsStore.setPublicKeyHex = selfPublicKeyHex;
    _contactSettingsStore.setPublicKeyHex = selfPublicKeyHex;
    _contactStore.setPublicKeyHex = selfPublicKeyHex;
    // Connecting to a DIFFERENT node: none of the previous node's channel
    // state may survive, or its messages merge into this node's stores
    // (shared-PSK channels like Public are the everyday trigger).
    if (_lastLoadedNodeKey != null && _lastLoadedNodeKey != selfPublicKeyHex) {
      _channels.clear();
      _cachedChannels = [];
      _pendingUntrackedChannelMessages.clear();
      _queriedUntrackedChannels.clear();
      _slotsToRequery.clear();
      _processedChannelReactions.clear();
      _channelSmazEnabled.clear();
    }
    _lastLoadedNodeKey = selfPublicKeyHex;

    _channelStore.setPublicKeyHex = selfPublicKeyHex;
    _resubscribeChannelUnreadWatch();

    // Now that we have self info, we can load all the persisted data for this node
    _loadChannelOrder();
    loadContactCache();
    // Settings and messages are keyed by channel identity, so the cached
    // channel list must be in place first.
    loadCachedChannels().then((_) async {
      await loadChannelSettings();
    });
    _loadDiscoveredContactCache();

    _awaitingSelfInfo = false;
    _selfInfoRetryTimer?.cancel();
    _selfInfoRetryTimer = null;
    notifyListeners();

    if (PlatformInfo.isWeb &&
        _activeTransport == MeshCoreTransportType.bluetooth &&
        !wasAwaitingSelfInfo) {
      return;
    }

    // Auto-fetch contacts after getting self info. On web BLE, defer this
    // until after channel 0 so startup writes stay serialized.
    if (PlatformInfo.isWeb &&
        _activeTransport == MeshCoreTransportType.bluetooth) {
      _pendingInitialContactsSync = true;
    } else if (_activeTransport == MeshCoreTransportType.usb ||
        _activeTransport == MeshCoreTransportType.tcp) {
      _pendingDeferredChannelSyncAfterContacts = true;
      getContacts();
    } else {
      getContacts();
    }
    if (_shouldGateInitialChannelSync &&
        _activeTransport != MeshCoreTransportType.usb &&
        _activeTransport != MeshCoreTransportType.tcp) {
      _maybeStartInitialChannelSync();
    }
  }

  void _handleDeviceInfo(Uint8List frame) {
    if (frame.length < 4) return;
    if (_shouldGateInitialChannelSync) {
      _hasReceivedDeviceInfo = true;
    }
    _firmwareVerCode = frame[1];

    if (frame.length >= 80) {
      final chars = <int>[];
      for (int i = 60; i < 80; i++) {
        if (frame[i] == 0) break;
        chars.add(frame[i]);
      }
      _firmwareVersion = String.fromCharCodes(chars);
    }

    // Parse client_repeat from firmware v9+ (byte 80)
    if (frame.length >= 81) {
      _clientRepeat = frame[80] != 0;
    }
    // Path hash mode v10+ (byte 81): width = mode + 1 byte(s) per hop
    if (frame.length >= 82) {
      final mode = (frame[81] & 0xFF).clamp(0, 2);
      _pathHashByteWidth = mode + 1;
      debugPrint("MeshCore INFO: Device info parsed, frame.length=${frame.length}, byte 81=${frame[81]}, pathHashByteWidth set to $_pathHashByteWidth");
    } else {
      _pathHashByteWidth = 1;
      debugPrint("MeshCore INFO: Device info parsed, frame.length=${frame.length} (< 82), pathHashByteWidth forced to 1");
    }

    // Firmware reports MAX_CONTACTS / 2 for v3+ device info.
    final reportedContacts = frame[2];
    final reportedChannels = frame[3];
    final nextMaxContacts = reportedContacts > 0
        ? reportedContacts * 2
        : _maxContacts;
    final nextMaxChannels = reportedChannels > 0
        ? reportedChannels
        : _maxChannels;
    final previousMaxChannels = _maxChannels;
    if (nextMaxContacts != _maxContacts || nextMaxChannels != _maxChannels) {
      _maxContacts = nextMaxContacts;
      _maxChannels = nextMaxChannels;
      if (nextMaxChannels > previousMaxChannels) {
        unawaited(loadChannelSettings(maxChannels: nextMaxChannels));
        if (isConnected &&
            _selfPublicKey != null &&
            (!_shouldGateInitialChannelSync || !_pendingInitialChannelSync)) {
          unawaited(getChannels(maxChannels: nextMaxChannels));
        }
      }
    }
    notifyListeners();
    if (_shouldGateInitialChannelSync) {
      _maybeStartInitialChannelSync();
    }
  }

  void _maybeStartInitialChannelSync() {
    if (!_pendingInitialChannelSync || !isConnected) {
      return;
    }
    if (_selfPublicKey == null || !_hasReceivedDeviceInfo) {
      return;
    }

    _pendingInitialChannelSync = false;
    unawaited(getChannels(maxChannels: _maxChannels));
  }

  void _handleNoMoreMessages() {
    debugPrint('[QueueSync] No more messages, sync complete');
    _queueSyncTimeout?.cancel();
    _isSyncingQueuedMessages = false;
    notifyListeners();
    _queuedMessageSyncInFlight = false;
    _queueSyncRetries = 0;
    if (_pendingChannelSyncAfterQueueSync) {
      _pendingChannelSyncAfterQueueSync = false;
      unawaited(getChannels());
    }
  }

  void _handleQueuedMessageReceived() {
    if (!_isSyncingQueuedMessages) return;
    debugPrint('[QueueSync] Message received, requesting next');
    _queueSyncTimeout?.cancel(); // Cancel timeout - message arrived
    _queuedMessageSyncInFlight = false;
    _queueSyncRetries = 0; // Reset retry counter on successful message
    _queuedMessagesRead++;
    notifyListeners();
    unawaited(_requestNextQueuedMessage());
  }

  void _handleStatsFrame(Uint8List frame) {
    final stats = CompanionRadioStats.tryParse(frame);
    if (stats == null) return;
    final total = stats.txAirSecs + stats.rxAirSecs;
    if (total > _prevTotalAirSecs) {
      (_airtimeBumpStopwatch ??= Stopwatch()).reset();
      _airtimeBumpStopwatch!.start();
    }
    _prevTotalAirSecs = total;
    _latestRadioStats = stats;
    radioStatsNotifier.value = stats;
  }

  void _handleBatteryAndStorage(Uint8List frame) {
    // Frame format from C++:
    // [0] = RESP_CODE_BATT_AND_STORAGE
    // [1-2] = battery_mv (uint16 LE)
    // [3-6] = storage_used_kb (uint32 LE)
    // [7-10] = storage_total_kb (uint32 LE)
    try {
      final reader = BufferReader(frame);
      reader.skipBytes(1);
      _batteryMillivolts = reader.readUInt16LE();
      _storageUsedKb = reader.readUInt32LE();
      _storageTotalKb = reader.readUInt32LE();
      final volts = (_batteryMillivolts! / 1000.0).toStringAsFixed(2);
      _appDebugLogService?.info(
        'Pulled battery: $volts V ($_batteryMillivolts mV)',
        tag: 'Battery',
      );
      notifyListeners();
    } catch (e) {
      _appDebugLogService?.error(
        'Error parsing battery and storage frame: $e',
        tag: 'Connector',
      );
    }
  }

  void _checkManualAddContacts() async {
    // If manual add contacts is enabled, set auto add config and other params.
    // and disable it after
    if (_manualAddContacts) {
      await sendFrame(
        buildSetAutoAddConfigFrame(
          autoAddChat: true,
          autoAddRepeater: true,
          autoAddRoomServer: true,
          autoAddSensor: true,
          overwriteOldest: _overwriteOldest,
        ),
      );
      await sendFrame(
        buildSetOtherParamsFrame(
          (_telemetryModeEnv << 4) |
              (_telemetryModeLoc << 2) |
              (_telemetryModeBase),
          _advertLocPolicy,
          _multiAcks,
        ),
      );
      _manualAddContacts = false;
    }
  }

  /// Estimate single-packet airtime in ms from radio settings, or a fallback.
  int _estimateAirtimeMs(int messageBytes) {
    if (_currentFreqHz != null &&
        _currentBwHz != null &&
        _currentSf != null &&
        _currentCr != null) {
      final cr = _currentCr! <= 4 ? _currentCr! : _currentCr! - 4;
      return calculateLoRaAirtime(
        payloadBytes: messageBytes,
        spreadingFactor: _currentSf!,
        bandwidthHz: _currentBwHz!,
        codingRate: cr,
        lowDataRateOptimize: _currentSf! >= 11,
      );
    }
    return 50; // fallback: ~SF7/BW125 for 100 bytes
  }

  /// Physics-based worst-case timeout (ceiling).
  int _physicsMaxTimeout(int pathLength, int airtime) {
    if (pathLength < 0) {
      // Match firmware: SEND_TIMEOUT_BASE_MILLIS + (FLOOD_SEND_TIMEOUT_FACTOR * airtime)
      return 500 + (16 * airtime);
    } else {
      return 500 + ((airtime * 6 + 250) * (pathLength + 1));
    }
  }

  int _physicsMinTimeout(int pathLength, int airtime) {
    if (pathLength < 0) {
      // Same as max for flood — firmware uses a single formula
      return 500 + (16 * airtime);
    } else {
      return airtime * (pathLength + 1);
    }
  }

  /// Maximum timeout cap per retry attempt — prevents long-hop or slow-SF
  /// paths from making a message appear to be "waiting" for minutes per attempt.
  static const int _maxTimeoutMs = 60000; // 60 seconds

  /// Calculate timeout for a message based on radio settings and path length.
  /// Returns timeout in milliseconds, considering number of hops.
  int calculateTimeout({
    required int pathLength,
    int messageBytes = 100,
    String? contactKey,
  }) {
    final airtime = _estimateAirtimeMs(messageBytes);
    final physicsMin = _physicsMinTimeout(pathLength, airtime);
    final physicsMax = _physicsMaxTimeout(pathLength, airtime);

    // Try ML-based prediction
    final secSinceRx = DateTime.now().difference(_lastRxTime).inSeconds;
    final mlTimeout = _timeoutPredictionService?.predictTimeout(
      contactKey: contactKey,
      pathLength: pathLength,
      messageBytes: messageBytes,
      secondsSinceLastRx: secSinceRx,
    );
    if (mlTimeout != null) {
      if (pathLength < 0) {
        // Flood: trust ML, only enforce firmware formula as floor
        if (mlTimeout < physicsMin) {
          return physicsMin;
        }
      }
      return mlTimeout.clamp(physicsMin, physicsMax).clamp(0, _maxTimeoutMs);
    }

    // No ML data — use firmware formula, capped
    return physicsMax.clamp(0, _maxTimeoutMs);
  }

  void _handleContact(Uint8List frame, {bool isContact = true}) {
    final contactTmp = Contact.fromFrame(frame);
    if (contactTmp != null) {
      if (isContact) {
        _loadedContactsCount++;
      }
      if (listEquals(contactTmp.publicKey, _selfPublicKey)) {
        appLogger.info(
          'Ignoring contact with self public key: ${contactTmp.name}',
          tag: 'Connector',
        );
        removeContact(contactTmp);
        return;
      }
      final contact = getFromDiscovered(contactTmp);
      if (!isContact) {
        _handleDiscovery(contact, frame, noNotify: true, addActive: true);
      }

      if (contact.type == advTypeRepeater) {
      }
      // Check if this is a new contact
      final isNewContact = !_knownContactKeys.contains(contact.publicKeyHex);
      final existingIndex = _contacts.indexWhere(
        (c) => c.publicKeyHex == contact.publicKeyHex,
      );

      if (existingIndex >= 0) {
        final existing = _contacts[existingIndex];
        final mergedLastMessageAt =
            existing.lastMessageAt.isAfter(contact.lastMessageAt)
            ? existing.lastMessageAt
            : contact.lastMessageAt;

        appLogger.info(
          'Refreshing contact ${contact.name}: devicePath=${contact.pathLength}, existingOverride=${existing.pathOverride}',
          tag: 'Connector',
        );

        // Preserve user-selected path settings and previously known GPS when
        // refreshed frames omit coordinates (lat/lon encoded as 0,0).
        _contacts[existingIndex] = contact.copyWith(
          lastMessageAt: mergedLastMessageAt,
          pathOverride: existing.pathOverride, // Preserve user's path choice
          pathOverrideBytes: existing.pathOverrideBytes,
          latitude: contact.latitude ?? existing.latitude,
          longitude: contact.longitude ?? existing.longitude,
          // Device DB rows can be legitimately old, so skew is only assessed
          // on live adverts; carry the last assessment through syncs.
          clockCorrected: existing.clockCorrected,
        );

        appLogger.info(
          'After merge: pathOverride=${_contacts[existingIndex].pathOverride}, devicePath=${_contacts[existingIndex].pathLength}',
          tag: 'Connector',
        );
      } else {
        if ((_autoAddUsers && contact.type == advTypeChat) ||
            (_autoAddRepeaters && contact.type == advTypeRepeater) ||
            (_autoAddRoomServers && contact.type == advTypeRoom) ||
            (_autoAddSensors && contact.type == advTypeSensor) ||
            isContact) {
          _contacts.add(contact);
          appLogger.info(
            'Added new contact ${contact.name}: pathLen=${contact.pathLength}',
            tag: 'Connector',
          );
        } else {
          appLogger.info(
            "Discovered contact ${contact.name} (type ${contact.typeLabel}) not added due to auto-add settings",
            tag: 'Connector',
          );
          return;
        }
      }
      _knownContactKeys.add(contact.publicKeyHex);
      _loadMessagesForContact(contact.publicKeyHex);

      // Add path to history if we have a valid path
      if (_pathHistoryService != null && contact.pathLength >= 0) {
        _pathHistoryService!.handlePathUpdated(contact);
      }

      notifyListeners();

      // Show notification for new contact (advertisement)
      if (isNewContact && _appSettingsService != null) {
        final settings = _appSettingsService!.settings;
        if (settings.notificationsEnabled && settings.notifyOnNewAdvert) {
          _notificationService.showAdvertNotification(
            contactName: contact.name,
            contactType: contact.typeLabel,
            contactId: contact.publicKeyHex,
          );
        }
      }

      if (!_isLoadingContacts) {
        unawaited(_persistContacts());
      }
    }
  }

  void _handleContactAdvert(Contact contact) {
    if (listEquals(contact.publicKey, _selfPublicKey)) {
      return;
    }

    if (contact.type == advTypeRepeater) {
    }
    // Check if this is a new contact
    final isNewContact = !_knownContactKeys.contains(contact.publicKeyHex);
    final existingIndex = _contacts.indexWhere(
      (c) => c.publicKeyHex == contact.publicKeyHex,
    );

    if (existingIndex >= 0) {
      final existing = _contacts[existingIndex];
      final mergedLastMessageAt =
          existing.lastMessageAt.isAfter(contact.lastMessageAt)
          ? existing.lastMessageAt
          : contact.lastMessageAt;

      appLogger.info(
        'Refreshing contact ${contact.name}: devicePath=${contact.pathLength}, existingOverride=${existing.pathOverride}',
        tag: 'Connector',
      );

      // CRITICAL: Preserve user's path override when contact is refreshed from device
      _contacts[existingIndex] = contact.copyWith(
        lastMessageAt: mergedLastMessageAt,
        pathOverride: existing.pathOverride, // Preserve user's path choice
        pathOverrideBytes: existing.pathOverrideBytes,
      );

      appLogger.info(
        'After merge: pathOverride=${_contacts[existingIndex].pathOverride}, devicePath=${_contacts[existingIndex].pathLength}',
        tag: 'Connector',
      );
    } else {
      _contacts.add(contact);
      appLogger.info(
        'Added new contact ${contact.name}: pathLen=${contact.pathLength}',
        tag: 'Connector',
      );
    }
    _knownContactKeys.add(contact.publicKeyHex);
    _loadMessagesForContact(contact.publicKeyHex);

    // Add path to history if we have a valid path
    if (_pathHistoryService != null && contact.pathLength >= 0) {
      _pathHistoryService!.handlePathUpdated(contact);
    }

    notifyListeners();

    // Show notification for new contact (advertisement)
    if (isNewContact && _appSettingsService != null) {
      final settings = _appSettingsService!.settings;
      if (settings.notificationsEnabled && settings.notifyOnNewAdvert) {
        _notificationService.showAdvertNotification(
          contactName: contact.name,
          contactType: contact.typeLabel,
          contactId: contact.publicKeyHex,
        );
      }
    }

    if (!_isLoadingContacts) {
      unawaited(_persistContacts());
    }
  }

  Future<void> _persistContacts() async {
    await _contactStore.saveContacts(_contacts);
  }

  Future<void> _persistDiscoveredContacts() async {
    await _discoveryContactStore.saveContacts(_discoveredContacts);
  }

  int _latestContactLastmod() {
    if (_contacts.isEmpty) return 0;
    var latest = 0;
    for (final contact in _contacts) {
      final seconds = contact.lastSeen.millisecondsSinceEpoch ~/ 1000;
      if (seconds > latest) {
        latest = seconds;
      }
    }
    return latest;
  }

  bool _setContactLastMessageAt(int index, DateTime timestamp) {
    final contact = _contacts[index];
    if (contact.type != advTypeChat) return false;
    if (!timestamp.isAfter(contact.lastMessageAt)) return false;
    _contacts[index] = contact.copyWith(lastMessageAt: timestamp);
    return true;
  }

  void _updateContactLastMessageAt(
    String contactKeyHex,
    DateTime timestamp, {
    bool notify = false,
  }) {
    final index = _contacts.indexWhere((c) => c.publicKeyHex == contactKeyHex);
    if (index < 0) return;
    if (!_setContactLastMessageAt(index, timestamp)) return;
    unawaited(_persistContacts());
    if (notify) {
      notifyListeners();
    }
  }

  void _updateContactLastMessageAtByName(
    String senderName,
    DateTime timestamp, {
    Uint8List? pathBytes,
    bool notify = false,
  }) {
    final normalized = senderName.trim().toLowerCase();
    final hasName = normalized.isNotEmpty && normalized != 'unknown';
    var updated = false;
    var matchedByName = false;

    if (hasName) {
      for (var i = 0; i < _contacts.length; i++) {
        final contact = _contacts[i];
        if (contact.type != advTypeChat) continue;
        if (contact.name.trim().toLowerCase() == normalized) {
          matchedByName = true;
          updated = _setContactLastMessageAt(i, timestamp) || updated;
        }
      }
    }

    if (!matchedByName && pathBytes != null && pathBytes.isNotEmpty) {
      final matches = <int>[];
      for (var i = 0; i < _contacts.length; i++) {
        final contact = _contacts[i];
        if (contact.type != advTypeChat) continue;
        if (_pathMatchesContact(pathBytes, contact.publicKey)) {
          matches.add(i);
        }
      }
      if (matches.length == 1) {
        updated = _setContactLastMessageAt(matches.first, timestamp) || updated;
      }
    }

    if (updated) {
      unawaited(_persistContacts());
      if (notify) {
        notifyListeners();
      }
    }
  }

  bool _pathMatchesContact(Uint8List pathBytes, Uint8List publicKey) {
    final w = _pathHashByteWidth;
    if (pathBytes.isEmpty || publicKey.length < w) return false;
    for (int i = 0; i + w <= pathBytes.length; i += w) {
      final prefix = pathBytes.sublist(i, i + w);
      if (_matchesPrefix(publicKey, prefix)) {
        return true;
      }
    }
    return false;
  }

  void _handleIncomingMessage(Uint8List frame) async {
    if (_selfPublicKey == null) return;

    var message = _parseContactMessage(frame);

    // If message parsing failed due to unknown contact, refresh contacts and retry
    if (message == null && !_isLoadingContacts) {
      final senderPrefix = _extractSenderPrefix(frame);
      if (senderPrefix != null) {
        final hasContact = _contacts.any(
          (c) => _matchesPrefix(c.publicKey, senderPrefix),
        );
        if (!hasContact) {
          debugPrint(
            'Received message from unknown contact, refreshing contacts...',
          );
          await refreshContactsSinceLastmod();
          // Retry parsing after refresh
          message = _parseContactMessage(frame);
          if (message != null) {
            debugPrint('Successfully parsed message after contact refresh');
          }
        }
      }
    }

    if (message != null) {
      if (!message.isOutgoing) {
        _lastContactMsgRxTime = DateTime.now();
      }
      // Ignore messages from self (device hearing its own broadcast)
      // BUT allow repeated messages (pathLength indicates it went through repeater)
      if (_selfPublicKey != null &&
          message.senderKeyHex == pubKeyToHex(_selfPublicKey!) &&
          (message.pathLength == null || message.pathLength == 0)) {
        debugPrint('Ignoring direct message from self');
        return;
      }

      // CLI responses are consumed by the management screens straight off the
      // frame stream; storing them would render them as chat bubbles in room
      // conversations ("00|OK - clock set: ...").
      if (message.isCli) {
        _handleQueuedMessageReceived();
        return;
      }

      final contact = _contacts.cast<Contact?>().firstWhere(
        (c) => c?.publicKeyHex == message!.senderKeyHex,
        orElse: () => null,
      );
      if (contact != null) {
        message = message.copyWith(
          pathLength: contact.pathLength < 0 ? -1 : contact.pathLength,
          pathBytes: contact.pathLength < 0 ? Uint8List(0) : contact.path,
        );
      }
      if (contact != null) {
        _updateContactLastMessageAt(contact.publicKeyHex, message.timestamp);
      }
      // Dedup is the database's unique constraint; unread eligibility is
      // decided inside the ingest.
      _addMessage(message.senderKeyHex, message);
      notifyListeners();

      // Show notification for new incoming message
      if (!message.isOutgoing &&
          !message.isCli &&
          _appSettingsService != null) {
        final settings = _appSettingsService!.settings;
        if (settings.notificationsEnabled && settings.notifyOnNewMessage) {
          if (contact?.type == advTypeChat) {
            _notificationService.showMessageNotification(
              contactName: contact?.name ?? 'Unknown',
              message: message.text,
              contactId: message.senderKeyHex,
              badgeCount: getTotalUnreadCount(),
            );
          } else if (contact?.type == advTypeRoom) {
            _notificationService.showMessageNotification(
              contactName: contact?.name ?? 'Unknown Room',
              message: message.text,
              contactId: message.senderKeyHex,
              badgeCount: getTotalUnreadCount(),
            );
          }
        }
      }
      _handleQueuedMessageReceived();
    } else if (_isSyncingQueuedMessages) {
      _handleQueuedMessageReceived();
    }
  }

  /// Parses the byte layout of a CONTACT_MSG_RECV / _V3 frame:
  /// [code][snr][reserved][reserved][prefix x6][path_len][txt_type][timestamp x4][author prefix x4 if signed][text...]
  /// (the snr/reserved bytes only exist in the V3 frame). Signed messages are
  /// room server posts; their [authorPrefix] holds the first 4 bytes of the
  /// original author's pubkey. Returns null for a non-message code.
  @visibleForTesting
  static ({
    Uint8List senderPrefix,
    int pathLen,
    int txtType,
    int timestampRaw,
    Uint8List? authorPrefix,
    String text,
  })?
  parseContactMsgLayout(Uint8List frame) {
    final reader = BufferReader(frame);
    final code = reader.readByte();
    if (code != respCodeContactMsgRecv && code != respCodeContactMsgRecvV3) {
      return null;
    }
    if (code == respCodeContactMsgRecvV3) {
      reader.skipBytes(3); // Skip SNR byte and reserved bytes
    }
    final senderPrefix = reader.readBytes(6);
    final pathLen = reader.readByte();
    final txtType = reader.readByte();
    final timestampRaw = reader.readUInt32LE();
    Uint8List? authorPrefix;
    if (txtType == txtTypeSigned) {
      authorPrefix = reader.readBytes(4);
    }
    return (
      senderPrefix: senderPrefix,
      pathLen: pathLen,
      txtType: txtType,
      timestampRaw: timestampRaw,
      authorPrefix: authorPrefix,
      text: reader.readCString(),
    );
  }

  Message? _parseContactMessage(Uint8List frame) {
    if (frame.isEmpty) {
      appLogger.warn('Received empty frame, ignoring');
      return null;
    }

    try {
      final layout = parseContactMsgLayout(frame);
      if (layout == null) {
        appLogger.warn(
          'Unexpected message code: ${frame[0]}, expected contact message receive codes',
        );
        return null;
      }

      final txtType = layout.txtType;
      final isPlain = txtType == txtTypePlain;
      final isCli = txtType == txtTypeCliData;
      final isSigned = txtType == txtTypeSigned;
      if (!isPlain && !isCli && !isSigned) {
        appLogger.warn(
          'Unknown message type received: txtType=$txtType',
        );
        return null;
      }

      final msgText = layout.text;
      if (msgText.isEmpty) {
        appLogger.warn('Received message with empty text, ignoring');
        return null;
      }
      final decodedText = isCli
          ? msgText
          : (Smaz.tryDecodePrefixed(msgText) ?? msgText);

      final senderPrefix = layout.senderPrefix;
      final contact = _contacts.cast<Contact?>().firstWhere(
        (c) => c != null && _matchesPrefix(c.publicKey, senderPrefix),
        orElse: () => null,
      );
      if (contact == null) {
        appLogger.warn(
          'Received message from unknown contact with prefix: ${senderPrefix.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join('')}',
        );
        return null;
      }

      return Message(
        senderKey: contact.publicKey,
        text: decodedText,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          layout.timestampRaw * 1000,
        ),
        isOutgoing: false,
        isCli: isCli,
        status: MessageStatus.delivered,
        pathLength: extractPathHopCount(layout.pathLen),
        pathBytes: Uint8List(0),
        fourByteRoomContactKey: layout.authorPrefix,
      );
    } catch (e) {
      appLogger.warn('Error parsing contact direct message: $e');
      return null;
    }
  }

  bool _matchesPrefix(Uint8List fullKey, Uint8List prefix) {
    // An empty prefix must never match: it made room reactions with no
    // author byte "resolve" to whatever contact happened to be listed first.
    if (prefix.isEmpty) return false;
    if (fullKey.length < prefix.length) return false;
    for (int i = 0; i < prefix.length; i++) {
      if (fullKey[i] != prefix[i]) return false;
    }
    return true;
  }

  Uint8List? _extractSenderPrefix(Uint8List frame) {
    if (frame.isEmpty) return null;
    final code = frame[0];
    if (code != respCodeContactMsgRecv && code != respCodeContactMsgRecvV3) {
      return null;
    }

    final prefixOffset = code == respCodeContactMsgRecvV3 ? 4 : 1;
    const prefixLen = 6;

    if (frame.length < prefixOffset + prefixLen) return null;

    return frame.sublist(prefixOffset, prefixOffset + prefixLen);
  }

  void _ensureContactSmazSettingLoaded(String contactKeyHex) {
    if (_contactSmazEnabled.containsKey(contactKeyHex)) return;
    _contactSettingsStore.loadSmazEnabled(contactKeyHex).then((enabled) {
      if (_contactSmazEnabled[contactKeyHex] == enabled) return;
      _contactSmazEnabled[contactKeyHex] = enabled;
      notifyListeners();
    });
  }

  /// Prepares contact outbound text by applying SMAZ encoding if enabled.
  /// This should be used to transform text before computing ACK hashes.
  String prepareContactOutboundText(Contact contact, String text) {
    final trimmed = text.trim();
    final isStructuredPayload =
        trimmed.startsWith('g:') ||
        trimmed.startsWith('m:') ||
        trimmed.startsWith('V1|');
    if (!isStructuredPayload && isContactSmazEnabled(contact.publicKeyHex)) {
      return Smaz.encodeIfSmaller(text);
    }
    return text;
  }

  String prepareChannelOutboundText(int channelIndex, String text) {
    final trimmed = text.trim();
    final isStructuredPayload =
        trimmed.startsWith('g:') || trimmed.startsWith('m:');
    if (!isStructuredPayload && isChannelSmazEnabled(channelIndex)) {
      return Smaz.encodeIfSmaller(text);
    }
    return text;
  }

  String _channelDisplayName(int channelIndex) {
    for (final channel in _channels) {
      if (channel.index != channelIndex) continue;
      return channel.displayName;
    }
    for (final channel in _cachedChannels) {
      if (channel.index != channelIndex) continue;
      return channel.displayName;
    }
    return 'Channel $channelIndex';
  }

  /// True when a channel message was authored by the connected node itself —
  /// e.g. our own send echoed back after the original left the in-memory
  /// window. Own messages must never count as unread or notify.
  bool _isFromSelf(ChannelMessage message) {
    final sender = message.senderKey;
    final self = _selfPublicKey;
    if (sender == null || self == null) return false;
    final n = math.min(sender.length, self.length);
    if (n == 0) return false;
    for (var i = 0; i < n; i++) {
      if (sender[i] != self[i]) return false;
    }
    return true;
  }

  void _maybeNotifyChannelMessage(
    ChannelMessage message, {
    String? channelName,
  }) {
    if (message.isOutgoing || _appSettingsService == null) return;
    if (_isFromSelf(message)) return;
    final channelIndex = message.channelIndex;
    if (channelIndex == null) return;

    final settings = _appSettingsService!.settings;
    if (!settings.notificationsEnabled) return;

    // A mention or reply-to-me outranks the channel-message toggle and the
    // channel's mute — cutting through a muted channel is the entire point.
    // One notification per message: when both would apply, mention wins.
    // Mentioning MYSELF is not a mention (nor is a same-named sender —
    // names aren't unique on the mesh, and the two are indistinguishable).
    final isMention = settings.notifyOnMention &&
        message.senderName != _selfName &&
        ChannelMessage.mentionsUser(message.text, _selfName);
    if (!isMention && !settings.notifyOnNewChannelMessage) return;

    // Blocked senders previously only had their rows hidden in the open
    // channel screen — notifications still fired. Blocked stays absolute:
    // a mention from a blocked sender is still blocked.
    if (_appSettingsService!.isSenderBlocked(message.senderName)) return;

    // The radio decrypts and queues messages for any slot it has keyed,
    // including channels this app never configured. Don't notify for a chat
    // the user can't see; query the slot instead so the channel surfaces in
    // the channel list where it can be muted or deleted.
    if (channelName == null && _findChannelByIndex(channelIndex) == null) {
      appLogger.info(
        'Suppressed notification for untracked channel $channelIndex; querying device for its info',
        tag: 'Connector',
      );
      _queryUntrackedChannel(channelIndex);
      return;
    }

    final label = channelName ?? _channelDisplayName(channelIndex);
    // Mute is keyed by channel identity (pskHex); also honor entries stored
    // under the raw or display name by older versions ('#tag' vs 'tag' —
    // the mismatch that made hashtag mutes silently fail).
    final channel = _findChannelByIndex(channelIndex);
    final settingsService = _appSettingsService!;
    final isMuted = channel != null
        ? (settingsService.isChannelMuted(channel.idKey) ||
              settingsService.isChannelMuted(channel.name) ||
              settingsService.isChannelMuted(channel.displayName))
        : settingsService.isChannelMuted(label);
    if (isMuted && !isMention) return;

    // message.text is the raw on-wire form; a reply carries quote markup
    // ("@[Name]\n><snippet>..\n<body>", or "re:" from older senders) that the
    // chat screen parses away. Show only the body so the notification doesn't
    // leak the mention, the quote prefix, or the snippet's trailing dots.
    final replyInfo = ChannelMessage.parseReply(message.text);
    final notificationText = replyInfo?.actualMessage ?? message.text;

    _notificationService.showChannelMessageNotification(
      channelName: label,
      senderName: message.senderName,
      message: notificationText,
      channelIndex: channelIndex,
      badgeCount: getTotalUnreadCount(),
      mentionMessageId: isMention ? message.messageId : null,
    );
  }

  void _handleIncomingChannelMessage(Uint8List frame) {
    final parsed = ChannelMessage.fromFrame(frame);
    if (parsed != null && parsed.channelIndex != null) {
      if (_shouldDropSelfChannelMessage(parsed.senderName, parsed.pathBytes)) {
        // Dropping the message is right, but the drain still needs telling.
        // Every channel frame is a destructive pop from the radio's offline
        // queue, and this early return never acknowledged one — so a self-echo
        // in the backlog stalled the drain until its 5s watchdog fired, and
        // enough of them in a row aborted it outright.
        _handleQueuedMessageReceived();
        return;
      }
      _lastChannelMsgRxTime = DateTime.now();
      final contentHash = _computeContentHash(
        parsed.channelIndex!,
        parsed.timestamp.millisecondsSinceEpoch ~/ 1000,
        '${parsed.senderName}: ${parsed.text}',
      );
      // fromFrame already decoded path_len fully: the wire byte is
      // (hashSize-1)<<6 | HOP COUNT (firmware Packet.h getPathHashCount),
      // so no rescaling by hash width — dividing again halved every hop
      // count on 2-byte-hash networks.
      final message = parsed.copyWith(
        packetHash: contentHash,
        pathHashSize: (parsed.pathLength == null || parsed.pathLength == -1 || parsed.pathLength == 0)
            ? 1
            : parsed.pathHashSize,
      );
      _updateContactLastMessageAtByName(
        message.senderName,
        message.timestamp,
        pathBytes: message.pathBytes,
      );

      // Never file a message under a slot whose identity is unknown — the
      // wrong channel could be living there. LIVE list only: the cached
      // fallback of _findChannelByIndex carries a previous session's slot
      // layout, which is exactly what must not decide filing. Hold the
      // message until CHANNEL_INFO reveals the slot's channel.
      final channelIndex = message.channelIndex!;
      final liveChannel = _channels.cast<Channel?>().firstWhere(
        (c) => c?.index == channelIndex,
        orElse: () => null,
      );
      // Buffer when the slot is unknown OR the map hasn't been re-verified
      // on this connection — after a BLE reconnect the radio's slots may
      // have been rearranged externally while the old map lived on.
      if (liveChannel == null || !_channelsVerified) {
        _pendingUntrackedChannelMessages
            .putIfAbsent(channelIndex, () => [])
            .add(message);
        _queryUntrackedChannel(channelIndex);
        _handleQueuedMessageReceived();
        return;
      }

      unawaited(() async {
        final isNew = await _ingestChannelMessage(channelIndex, message);
        if (isNew) {
          _maybeNotifyChannelMessage(message);
        }
        _handleQueuedMessageReceived();
      }());
    } else if (_isSyncingQueuedMessages) {
      _handleQueuedMessageReceived();
    }
  }

  void _handleLogRxData(Uint8List frame) {
    if (frame.length < 4) return;
    try {
      final reader = BufferReader(frame);
      reader.skipBytes(3); // Skip header

      final raw = reader.readRemainingBytes();
      final packet = _parseRawPacket(raw);
      if (packet == null || packet.payloadType != _payloadTypeGroupText) return;

      final payload = BufferReader(packet.payload);
      final channelHash = payload.readByte();
      final encrypted = Uint8List.fromList(payload.readRemainingBytes());

      // Only match against the LIVE channel list. Cached channels carry
      // stale slot indexes — filing under one puts the message into
      // whatever channel now occupies that slot. Pre-sync, the radio's own
      // queue delivers these messages with authoritative indexes instead.
      for (final channel in _channels) {
        if (channel.isEmpty) continue;
        final hash = _computeChannelHash(channel.psk);
        if (hash != channelHash) continue;
        try {
          final decryptedBytes = _decryptPayload(channel.psk, encrypted);
          if (decryptedBytes == null || decryptedBytes.length < 6) {
            // 1-byte channel hashes collide (1/256 per pair). This channel
            // matched the hash but failed the MAC — another of our channels
            // may be the real recipient, so keep trying (the firmware scans
            // up to 4 hash matches the same way). Returning here made every
            // channel whose hash collided with a lower slot appear deaf to
            // repeats.
            continue;
          }
          final decrypted = BufferReader(decryptedBytes);

          final timestampRaw = decrypted.readUInt32LE();
          final txtType = decrypted.readByte();
          if ((txtType >> 2) != 0) {
            return;
          }

          final text = decrypted.readCString();
          final parsed = _splitSenderText(text);
          final decodedText =
              Smaz.tryDecodePrefixed(parsed.text) ?? parsed.text;
          if (_shouldDropSelfChannelMessage(
            parsed.senderName,
            packet.pathBytes,
          )) {
            return;
          }

          final pktHash = _computePacketHash(
            packet.payloadType,
            packet.payload,
          );

          final message = ChannelMessage(
            senderKey: null,
            senderName: parsed.senderName,
            text: decodedText,
            timestamp: DateTime.fromMillisecondsSinceEpoch(timestampRaw * 1000),
            isOutgoing: false,
            status: ChannelMessageStatus.sent,
            pathLength: packet.isFlood ? packet.hopCount : 0,
            pathBytes: packet.pathBytes,
            pathHashSize: packet.hashSize,
            channelIndex: channel.index,
            packetHash: pktHash,
          );

          _updateContactLastMessageAtByName(
            parsed.senderName,
            message.timestamp,
            pathBytes: message.pathBytes,
          );
          final label = channel.displayName;
          unawaited(() async {
            final isNew = await _ingestChannelMessage(channel.index, message);
            if (isNew) {
              _maybeNotifyChannelMessage(message, channelName: label);
            }
          }());
          return;
        } catch (e) {
          appLogger.warn('Decryption failed for channel ${channel.index}: $e');
        }
      }
    } catch (e) {
      appLogger.warn('Error handling log RX data frame: $e');
    }
  }

  void _handleControlData(Uint8List frame) {
    if (frame.length < 5) return;
    try {
      final snrRaw = frame[1];
      final snr = (snrRaw > 127 ? snrRaw - 256 : snrRaw) / 4.0;
      final rssiRaw = frame[2]; // ignore: unused_local_variable
      final pathLen = frame[3]; // ignore: unused_local_variable

      final ctlPayload = frame.sublist(4);
      if (ctlPayload.isEmpty) return;

      final ctlType = ctlPayload[0] & 0xF0;
      if (ctlType == ctlTypeNodeDiscoverResp) {
        final nodeType = ctlPayload[0] & 0x0F;
        if (nodeType != advTypeRepeater) return;

        if (ctlPayload.length < 6) return;
        final tag = ByteData.sublistView(ctlPayload, 2, 6).getUint32(0, Endian.little);

        if (_pendingDiscoverTag == null || tag != _pendingDiscoverTag) {
          return;
        }

        final hasFullPubKey = ctlPayload.length >= 6 + 32;
        final Uint8List? pubKey = hasFullPubKey ? ctlPayload.sublist(6, 38) : null;
        final hex = pubKey != null ? pubKeyToHex(pubKey) : null;
        // Discovery responses carry at least an 8-byte pubkey prefix at [6..];
        // keep the on-air hash width of it as the repeater's identity.
        final prefixEnd = math.min(6 + _pathHashByteWidth, ctlPayload.length);
        final pubkeyPrefix = prefixEnd > 6
            ? Uint8List.fromList(ctlPayload.sublist(6, prefixEnd))
            : Uint8List(0);

        String? parsedName;
        if (hasFullPubKey && ctlPayload.length > 38) {
          parsedName = utf8.decode(ctlPayload.sublist(38), allowMalformed: true).trim();
          if (parsedName.isNotEmpty && parsedName.codeUnitAt(parsedName.length - 1) == 0) {
            parsedName = parsedName.substring(0, parsedName.length - 1);
          }
        }

        appLogger.info('Discovered repeater with pubkey prefix 0x${PathHelper.hopHex(pubkeyPrefix)} at SNR $snr dB');

        _directRepeaters.removeWhere((r) => r.isStale());
        final existing = _directRepeaters.where((r) {
          if (r.publicKey != null && hex != null) {
            return pubKeyToHex(r.publicKey!) == hex;
          }
          return r.matchesHash(pubkeyPrefix);
        });

        if (existing.isNotEmpty) {
          existing.first.update(snr);
          existing.first.publicKey ??= pubKey;
          if (parsedName != null && parsedName.isNotEmpty) {
            existing.first.name = parsedName;
          }
        } else {
          if (_directRepeaters.length >= 5) {
            final sorted = List<DirectRepeater>.from(_directRepeaters)..sort(DirectRepeater.compare);
            if (sorted.isNotEmpty) {
              _directRepeaters.remove(sorted.last);
            }
          }
          if (_directRepeaters.length < 5) {
            _directRepeaters.add(DirectRepeater(
              pubkeyPrefix: pubkeyPrefix,
              publicKey: pubKey,
              name: parsedName,
              snr: snr,
            ));
          }
        }

        if (pubKey != null && hex != null) {
          final alreadyKnown = _contacts.any((c) => c.publicKeyHex == hex);
          if (!alreadyKnown) {
            appLogger.info('Discovered repeater is unknown to app contacts. Querying companion database for $hex...');
            unawaited(sendFrame(buildGetContactByKeyFrame(pubKey)));
          }
        }

        if (hasFullPubKey && (_autoAddRepeaters == true)) {
          final alreadyKnown = _contacts.any((c) => c.publicKeyHex == hex!);
          if (!alreadyKnown && !_discoveredContacts.any((c) => c.publicKeyHex == hex!)) {
            final resolvedName = (parsedName != null && parsedName.isNotEmpty)
                ? parsedName
                : 'Repeater ${hex!.substring(0, 4).toUpperCase()}';
            final newContact = Contact(
              publicKey: pubKey!,
              name: resolvedName,
              type: advTypeRepeater,
              pathLength: 0,
              path: Uint8List(0),
              lastSeen: DateTime.now(),
              isActive: true, // Set to true since we are adding it as an active contact
            );
            
            // Route through standard contact handling so it appears in the UI and routing tables
            _handleContactAdvert(newContact);
            _handleDiscovery(newContact, Uint8List(0), noNotify: true, addActive: true);
            
            appLogger.info('Automatically added newly discovered repeater: ${newContact.name} (${newContact.publicKeyHex})');
          }
        }

        notifyListeners();
      }
    } catch (e) {
      appLogger.warn('Error handling control data frame: $e');
    }
  }

  void _handleMessageSent(Uint8List frame) {
    // Frame format from C++:
    // [0] = RESP_CODE_SENT
    // [1] = is_flood (1 or 0)
    // [2-5] = expected_ack_hash (uint32)
    // [6-9] = estimated_timeout_ms (uint32)

    try {
      final reader = BufferReader(frame);
      reader.skipBytes(2); //Skip code and is_flood
      final ackHash = reader.readUInt32LE();
      final timeoutMs = reader.readUInt32LE();

      // Check if this is a CLI command ACK - if so, ignore it
      if (_lastSentWasCliCommand) {
        final ackHashHex = ackHashToHex(ackHash);
        debugPrint('Ignoring CLI command ACK (sent): $ackHashHex');
        _lastSentWasCliCommand = false;
        return;
      }

      if (_handleRepeaterCommandSent(ackHash, timeoutMs)) {
        return;
      }

      final retryService = _retryService;
      if (retryService != null &&
          retryService.updateMessageFromSent(ackHash, timeoutMs)) {
        return;
      }

      if (_markNextPendingChannelMessageSent()) {
        return;
      }

      // Last-resort fallback: if the retry service couldn't match the hash
      // (e.g. self pubkey was null, no hash was pre-computed) and there's no
      // pending channel message, promote the oldest pending DM to 'sent' so
      // the timeout chain begins and the message is never stuck forever.
      unawaited(() async {
        final (updated, key) = await _messageStore.promoteLatestOutgoing(
          from: MessageStatus.pending,
          to: MessageStatus.sent,
        );
        if (updated) {
          appLogger.warn(
            'RESP_CODE_SENT: no retry-service match and no channel msg \u2014 '
            'promoted newest pending DM ($key) to sent',
            tag: 'Connector',
          );
          notifyListeners();
        }
      }());
    } catch (e) {
      appLogger.warn('Error handling message sent frame: $e');
      // Fallback to old behavior
      unawaited(() async {
        final (updated, _) = await _messageStore.promoteLatestOutgoing(
          from: MessageStatus.pending,
          to: MessageStatus.sent,
        );
        if (updated) notifyListeners();
      }());
    }
  }

  bool _markNextPendingChannelMessageSent() {
    while (_pendingChannelSentQueue.isNotEmpty) {
      final queuedMessageId = _pendingChannelSentQueue.removeAt(0);
      if (_isReactionSendQueueId(queuedMessageId)) {
        return true;
      }
      if (_markPendingChannelMessageSentById(queuedMessageId)) {
        return true;
      }
    }
    return false;
  }

  bool _markPendingChannelMessageSentById(String messageId) {
    _channelMessageTimers[messageId]?.cancel();
    _channelMessageTimers.remove(messageId);
    _pendingChannelSentQueue.remove(messageId);
    // The send queue only ever holds our own pending ids, so consuming the
    // entry answers the caller synchronously; the row update is async.
    unawaited(() async {
      final (updated, idKey) = await _channelMessageStore.updateAnyByMessageId(
        messageId,
        (m) => (m.isOutgoing && m.status == ChannelMessageStatus.pending)
            ? m.copyWith(status: ChannelMessageStatus.sent)
            : m,
      );
      if (!updated || idKey == null) return;
      final liveIndex = _liveChannelByIdKey(idKey)?.index;
      if (liveIndex != null) {
        _startWaitForRepeatTimer(liveIndex, messageId);
      }
      notifyListeners();
    }());
    return true;
  }

  void _handleOk() {
    if (_pendingGenericAckQueue.isEmpty) {
      return;
    }

    final pendingAck = _pendingGenericAckQueue.removeAt(0);
    if (pendingAck.commandCode != cmdSendChannelTxtMsg ||
        pendingAck.channelSendQueueId == null) {
      return;
    }

    final queueId = pendingAck.channelSendQueueId!;
    _pendingChannelSentQueue.remove(queueId);
    if (_isReactionSendQueueId(queueId)) {
      return;
    }
    _markPendingChannelMessageSentById(queueId);
  }

  void _handleSendConfirmed(Uint8List frame) {
    // Frame format from C++:
    // [0] = PUSH_CODE_SEND_CONFIRMED
    // [1-4] = ack_hash (uint32)
    // [5-8] = trip_time_ms (uint32)

    try {
      final reader = BufferReader(frame);
      reader.skipBytes(1); // Skip code
      final ackHash = reader.readUInt32LE();
      final tripTimeMs = reader.readUInt32LE();

      // CLI command ACKs are already filtered in _handleMessageSent, so this should only see real messages

      if (_handleRepeaterCommandAck(ackHash, tripTimeMs)) {
        return;
      }

      // Handle ACK in retry service
      if (_retryService != null) {
        _retryService!.handleAckReceived(ackHash, tripTimeMs);
      }
    } catch (e) {
      appLogger.warn('Error handling send confirmed frame: $e');
      // Fallback to old behavior
      unawaited(() async {
        final (updated, _) = await _messageStore.promoteLatestOutgoing(
          from: MessageStatus.sent,
          to: MessageStatus.delivered,
        );
        if (updated) notifyListeners();
      }());
    }
  }

  bool _handleRepeaterCommandSent(int ackHash, int timeoutMs) {
    final ackHashHex = ackHashToHex(ackHash);
    final entry = _pendingRepeaterAcks[ackHashHex];
    if (entry == null) return false;

    entry.timeout?.cancel();
    final effectiveTimeoutMs = timeoutMs > 0
        ? timeoutMs
        : calculateTimeout(
            pathLength: entry.pathLength,
            messageBytes: entry.messageBytes,
          );
    entry.timeout = Timer(Duration(milliseconds: effectiveTimeoutMs), () {
      _recordPathResult(entry.contactKeyHex, entry.selection, false, null);
      _pendingRepeaterAcks.remove(ackHashHex);
    });
    return true;
  }

  bool _handleRepeaterCommandAck(int ackHash, int tripTimeMs) {
    final ackHashHex = ackHashToHex(ackHash);
    final entry = _pendingRepeaterAcks.remove(ackHashHex);
    if (entry == null) return false;
    entry.timeout?.cancel();
    _recordPathResult(entry.contactKeyHex, entry.selection, true, tripTimeMs);
    return true;
  }

  /// Slot [channel.index] is now known to hold [channel]: import any legacy
  /// blobs for its identity, initialize its read watermark, and file the
  /// messages buffered for the slot. No in-memory state — rows and watched
  /// queries carry everything (Phase 3d).
  void _adoptSlotIdentity(Channel channel, {Channel? previous}) {
    // Messages buffered for a slot were received while that slot meant
    // something else. If it has changed hands, they cannot be handed to the
    // new occupant — that is one channel's traffic appearing in another's
    // history, with readable text and the right sender, because the firmware
    // had already decrypted it correctly and only the filing was wrong.
    //
    // Every caller computed `previous` and this method ignored it, so nothing
    // could ever notice. Delete a channel, let another take the freed slot,
    // and the old occupant's backlog landed in the new conversation.
    //
    // They are discarded rather than re-homed: nothing in a slot-keyed buffer
    // records which channel it belonged to, so any other destination would be
    // a guess.
    if (previous != null && previous.idKey != channel.idKey) {
      final orphaned = _pendingUntrackedChannelMessages.remove(channel.index);
      if (orphaned != null && orphaned.isNotEmpty) {
        appLogger.warn(
          'Discarding ${orphaned.length} message(s) buffered for slot '
          '${channel.index}: it now holds ${channel.displayName}, not '
          '${previous.displayName} — they cannot be attributed to either',
          tag: 'Connector',
        );
      }
    }
    unawaited(
      _channelMessageStore
          .migrateLegacyIndexKey(channel.index, channel.idKey)
          .then((_) async {
        await _channelMessageStore.initializeReadMarkIfAbsent(channel.idKey);
        _flushPendingForSlot(channel);
      }),
    );
  }

  /// Keeps the synchronous read-models in step with the database: unread
  /// counts and newest-message-per-channel. DB stays the single writer.
  void _resubscribeChannelUnreadWatch() {
    _channelUnreadSub?.cancel();
    _channelUnreadSub =
        _channelMessageStore.watchUnreadCounts().listen((counts) {
      _channelUnreadByIdKey = counts;
      notifyListeners();
    });
    _channelLatestSub?.cancel();
    _channelLatestSub =
        _channelMessageStore.watchLatestPerChannel().listen((latest) {
      _channelLatestByIdKey = latest;
      notifyListeners();
    });
    _contactUnreadSub?.cancel();
    _contactUnreadSub = _messageStore.watchUnreadCounts().listen((counts) {
      _contactUnreadByKey = counts;
      notifyListeners();
    });
    _contactLatestSub?.cancel();
    _contactLatestSub =
        _messageStore.watchLatestPerContact().listen((latest) {
      _contactLatestByKey = latest;
      notifyListeners();
    });
  }

  /// Newest message for a channel, from the watched query (chats screen
  /// subtitles).
  ChannelMessage? latestChannelMessage(Channel channel) =>
      _channelLatestByIdKey[channel.idKey]?.message;

  /// When that newest channel message ARRIVED — what conversation tiles must
  /// sort by. Sorting on the message's claimed timestamp would undo arrival
  /// ordering at the last step.
  int latestChannelArrivalUs(Channel channel) =>
      _channelLatestByIdKey[channel.idKey]?.arrivalUs ?? 0;

  /// Newest message for a contact, from the watched query.
  Message? latestContactMessage(Contact contact) =>
      _contactLatestByKey[contact.publicKeyHex]?.message;

  /// When that newest DM arrived — the tile sort key.
  int latestContactArrivalUs(Contact contact) =>
      _contactLatestByKey[contact.publicKeyHex]?.arrivalUs ?? 0;

  /// Live stream of a conversation — the UI's ONLY DM read path.
  Stream<List<Message>> watchConversation(
    Contact contact, {
    int limit = 200,
  }) =>
      _messageStore.watchConversation(contact.publicKeyHex, limit: limit);

  /// One-shot conversation read (export, bench, sorting).
  Future<List<Message>> loadMessagesFor(Contact contact) =>
      _messageStore.loadMessages(contact.publicKeyHex);

  void _flushPendingForSlot(Channel channel) {
    final pending = _pendingUntrackedChannelMessages.remove(channel.index);
    if (pending == null || pending.isEmpty) return;
    unawaited(() async {
      for (final message in pending) {
        final isNew = await _ingestChannelMessage(channel.index, message);
        if (isNew) {
          // Parity with the live path — buffered messages were silent.
          _maybeNotifyChannelMessage(
            message,
            channelName: channel.displayName,
          );
        }
      }
    }());
  }

  Channel? _previousIdentityForSlot(int index) {
    for (final c in _previousChannelsCache) {
      if (c.index == index) return c;
    }
    for (final c in _cachedChannels) {
      if (c.index == index) return c;
    }
    return null;
  }

  void _handleChannelInfo(Uint8List frame) {
    final channel = Channel.fromFrame(frame);
    if (channel == null) return;

    debugPrint(
      '[ChannelSync] Received channel ${channel.index}: ${channel.isEmpty ? "empty" : channel.name}',
    );

    if (channel.isEmpty) {
      // Radio says the slot is empty; anything buffered for it is orphaned.
      _pendingUntrackedChannelMessages.remove(channel.index);
      // Allow a fresh query if the slot is configured later this session.
      _queriedUntrackedChannels.remove(channel.index);
    }

    // Preserve unread count from the cached channel with the SAME IDENTITY —
    // matching by index would hand one channel's unread to whatever channel
    // now occupies its old slot.
    final cachedChannel = _cachedChannels.cast<Channel?>().firstWhere(
      (c) => c?.pskHex == channel.pskHex,
      orElse: () => null,
    );
    if (cachedChannel != null) {
      channel.unreadCount = cachedChannel.unreadCount;
    }

    // If we're syncing and this is the channel we're waiting for
    if (_isSyncingChannels && _channelSyncInFlight) {
      if (channel.index == _nextChannelIndexToRequest) {
        // Expected channel arrived
        _channelSyncTimeout?.cancel();
        _channelSyncInFlight = false;
        _channelSyncRetries = 0; // Reset retry counter on success

        // Only add non-empty channels. removeWhere first: a slot exists once
        // by definition — a duplicate reply must never yield twin entries
        // (field report: '#test' listed twice).
        if (!channel.isEmpty) {
          _channels.removeWhere((c) => c.index == channel.index);
          _channels.add(channel);
          _adoptSlotIdentity(
            channel,
            previous: _previousIdentityForSlot(channel.index),
          );
        }

        // Move to next channel
        _nextChannelIndexToRequest++;
        if (PlatformInfo.isWeb &&
            _activeTransport == MeshCoreTransportType.bluetooth &&
            channel.index == 0 &&
            _pendingInitialContactsSync) {
          _pendingInitialContactsSync = false;
          unawaited(getContacts());
          return;
        }
        unawaited(_requestNextChannel());
        return;
      } else {
        // Received a channel but not the one we're waiting for
        // This can happen if device sends unsolicited updates
        debugPrint(
          '[ChannelSync] Received unexpected channel ${channel.index}, expected $_nextChannelIndexToRequest',
        );
        // Add it anyway but don't advance sync
        if (!channel.isEmpty &&
            !_channels.any((c) => c.index == channel.index)) {
          _channels.add(channel);
          _adoptSlotIdentity(
            channel,
            previous: _previousIdentityForSlot(channel.index),
          );
        }
        return;
      }
    }

    // Not syncing, or received unsolicited update - handle normally
    if (!channel.isEmpty) {
      // Update or add channel
      final existingIndex = _channels.indexWhere(
        (c) => c.index == channel.index,
      );
      Channel? previous;
      if (existingIndex >= 0) {
        previous = _channels[existingIndex];
        // Preserve unread count only when it's the same channel
        if (previous.pskHex == channel.pskHex) {
          channel.unreadCount = previous.unreadCount;
        }
        _channels[existingIndex] = channel;
      } else {
        previous = _previousIdentityForSlot(channel.index);
        _channels.add(channel);
      }
      _adoptSlotIdentity(channel, previous: previous);
    }

    // Only notify if not in loading state
    if (!_isLoadingChannels) {
      _applyChannelOrder();
      notifyListeners();
    }
  }

  void _applyChannelOrder() {
    if (_channelOrder.isEmpty) {
      _channels.sort((a, b) => a.index.compareTo(b.index));
      return;
    }

    final orderIndex = <int, int>{};
    for (int i = 0; i < _channelOrder.length; i++) {
      orderIndex[_channelOrder[i]] = i;
    }

    _channels.sort((a, b) {
      final aPos = orderIndex[a.index];
      final bPos = orderIndex[b.index];
      if (aPos != null && bPos != null) return aPos.compareTo(bPos);
      if (aPos != null) return -1;
      if (bPos != null) return 1;
      return a.index.compareTo(b.index);
    });
  }

  Future<void> setChannelOrder(List<int> order) async {
    _channelOrder = List<int>.from(order);
    _applyChannelOrder();
    notifyListeners();
    await _channelOrderStore.saveChannelOrder(_channelOrder);
  }

  bool _shouldTrackUnreadForContactKey(String contactKeyHex) {
    final contact = _contacts.cast<Contact?>().firstWhere(
      (c) => c?.publicKeyHex == contactKeyHex,
      orElse: () => null,
    );
    if (contact == null) return true;
    return contact.type != advTypeRepeater;
  }

  Channel? _findChannelByIndex(int index) {
    return _channels.cast<Channel?>().firstWhere(
          (c) => c?.index == index,
          orElse: () => null,
        ) ??
        _cachedChannels.cast<Channel?>().firstWhere(
          (c) => c?.index == index,
          orElse: () => null,
        );
  }

  final Set<int> _queriedUntrackedChannels = {};

  void _queryUntrackedChannel(int channelIndex) {
    if (channelIndex < 0 || channelIndex >= _maxChannels) return;
    if (!_queriedUntrackedChannels.add(channelIndex)) return;
    unawaited(sendFrame(buildGetChannelFrame(channelIndex)));
  }



  /// Retry-service callback shim — the contract is synchronous, the ingest
  /// is a database write.
  void _addMessage(String pubKeyHex, Message message) {
    unawaited(_ingestContactMessage(pubKeyHex, message));
  }

  bool _contactUnreadEligible(Message message) =>
      !message.isOutgoing &&
      !message.isCli &&
      _shouldTrackUnreadForContactKey(message.senderKeyHex);

  /// Phase 3d ingest for DMs — the database is the only message state.
  Future<void> _ingestContactMessage(String pubKeyHex, Message message) async {
    // Rewrite only BROKEN sender clocks; ordering is arrival-based, so an
    // old-but-plausible time is display truth, not a sorting hazard.
    Message processedMessage = message;
    if (!message.isOutgoing) {
      final sane = sanitizeSenderTimestamp(message.timestamp, DateTime.now());
      if (sane != message.timestamp) {
        processedMessage = message.copyWith(timestamp: sane);
      }
    }

    // Reactions mutate their target row; never a visible message.
    final reactionInfo = Message.parseReaction(processedMessage.text);
    if (reactionInfo != null) {
      // Keyed by reactor: in a room two members reacting with the same emoji
      // are two reactions, not a duplicate of one.
      final reactorName = _resolveReactorName(pubKeyHex, processedMessage);
      _processedContactReactions.putIfAbsent(pubKeyHex, () => {});
      final reactionIdentifier =
          '${reactionInfo.targetHash}_${reactionInfo.emoji}_$reactorName';
      if (_processedContactReactions[pubKeyHex]!.contains(
        reactionIdentifier,
      )) {
        return;
      }
      final history = await _messageStore.loadMessages(pubKeyHex);
      final applied = _processContactReaction(
        history,
        reactionInfo,
        pubKeyHex,
        reactorName,
      );
      if (applied) {
        await _messageStore.upsertMessages(pubKeyHex, history);
      }
      if (applied || reactionInfo.format == ReactionFormat.open) {
        // Unmatched r: text is unambiguously a reaction — drop it. A
        // MeshCore One-shaped message whose hash matches nothing we hold
        // could be a genuine two-line message, so fall through and show it.
        _processedContactReactions[pubKeyHex]!.add(reactionIdentifier);
        notifyListeners();
        return;
      }
    }

    // The unique constraint is the dedup authority; a duplicate id is a
    // no-op (parity with the old recent-scan early return).
    final isNew = await _messageStore.insertIfNew(
      pubKeyHex,
      processedMessage,
      unreadEligible: _contactUnreadEligible(processedMessage),
    );
    if (!isNew) return;
    // Viewing this conversation: the read watermark rides along.
    if (_activeContactKey == pubKeyHex) {
      unawaited(_messageStore.markRead(pubKeyHex));
    }
    notifyListeners();
  }

  bool _processContactReaction(
    List<Message> messages,
    ReactionInfo reactionInfo,
    String contactPubKeyHex,
    String reactorName,
  ) {
    final contact = _contacts.cast<Contact?>().firstWhere(
      (c) => c?.publicKeyHex == contactPubKeyHex,
      orElse: () => null,
    );
    final isRoomServer = contact?.type == advTypeRoom;
    final isOne = reactionInfo.format == ReactionFormat.one;

    return ReactionHelper.applyReaction<Message>(
      messages: messages,
      reactionInfo: reactionInfo,
      reactorName: reactorName,
      // Incoming reactions in 1:1: match against outgoing messages only.
      // MeshCore One hashes are strong (40-bit over full text) and its
      // clients may react to any message, so don't restrict those.
      shouldSkip: (msg) => !isOne && isRoomServer != true && !msg.isOutgoing,
      getTimestampSecs: (msg) => msg.timestamp.millisecondsSinceEpoch ~/ 1000,
      // The sender's wire clock, untouched by the ingest clamp. Outgoing
      // rows get a small forward window: the frame is stamped after send
      // delays, past the row's construction clock.
      getWireTimestampSecs: (msg) {
        final secs = _messageWireSecs(msg);
        return msg.isOutgoing
            ? [secs, secs + 1, secs + 2, secs + 3]
            : [secs];
      },
      // MeshCore One hashes the mention-stripped display text, our rows
      // store the raw text — try both.
      getMessageTextVariants: (msg) => {
        msg.text,
        ChannelMessage.stripLeadingMentions(msg.text),
      }.toList(),
      getSenderName: (msg) =>
          _resolveContactSenderName(msg, contact, isRoomServer == true),
      getMessageText: (msg) => msg.text,
      getReactions: (msg) => msg.reactions,
      getReactionSenders: (msg) => msg.reactionSenders,
      updateMessage: (i, reactions, senders) {
        messages[i] = messages[i].copyWith(
          reactions: reactions,
          reactionSenders: senders,
        );
      },
    );
  }

  /// The ORIGINAL wire timestamp of a DM in seconds — messageId is built at
  /// construction as `<wire-ms>_<senderKeyHex>_<text.hashCode>`, before the
  /// ingest clamp runs (same recovery as [wireTimestampMs] for channels).
  static int _messageWireSecs(Message message) {
    final id = message.messageId;
    final cut = id.indexOf('_');
    if (cut > 0) {
      final parsed = int.tryParse(id.substring(0, cut));
      if (parsed != null) return parsed ~/ 1000;
    }
    return message.timestamp.millisecondsSinceEpoch ~/ 1000;
  }

  void _processOutgoingContactReaction(
    List<Message> messages,
    ReactionInfo reactionInfo,
    Contact contact,
  ) {
    final isRoomServer = contact.type == advTypeRoom;

    ReactionHelper.applyReaction<Message>(
      messages: messages,
      reactionInfo: reactionInfo,
      reactorName: _selfName ?? 'Me',
      // Outgoing reactions in 1:1: match against incoming messages
      shouldSkip: (msg) => !isRoomServer && msg.isOutgoing,
      getTimestampSecs: (msg) => msg.timestamp.millisecondsSinceEpoch ~/ 1000,
      getSenderName: (msg) =>
          _resolveContactSenderName(msg, contact, isRoomServer),
      getMessageText: (msg) => msg.text,
      getReactions: (msg) => msg.reactions,
      getReactionSenders: (msg) => msg.reactionSenders,
      updateMessage: (i, reactions, senders) {
        messages[i] = messages[i].copyWith(
          reactions: reactions,
          reactionSenders: senders,
        );
      },
    );
  }

  Future<void> _setReactionStatus(
    String pubKeyHex,
    ReactionInfo reactionInfo,
    MessageStatus status,
  ) async {
    final messages = await _messageStore.loadMessages(pubKeyHex);
    final contact = _contacts.cast<Contact?>().firstWhere(
      (c) => c?.publicKeyHex == pubKeyHex,
      orElse: () => null,
    );
    final isRoomServer = contact?.type == advTypeRoom;
    for (int i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      final timestampSecs = msg.timestamp.millisecondsSinceEpoch ~/ 1000;
      final msgHash = ReactionHelper.computeReactionHash(
        timestampSecs,
        _resolveContactSenderName(msg, contact, isRoomServer == true),
        msg.text,
      );
      if (msgHash == reactionInfo.targetHash) {
        final statuses = Map<String, MessageStatus>.from(msg.reactionStatuses);
        statuses[reactionInfo.emoji] = status;
        await _messageStore.upsertMessage(
          pubKeyHex,
          msg.copyWith(reactionStatuses: statuses),
        );
        break;
      }
    }
  }

  /// Who sent an incoming DM reaction: the contact itself in 1:1, or the room
  /// member the reaction came from when the contact is a room server.
  String _resolveReactorName(String pubKeyHex, Message reaction) {
    final contact = _contacts.cast<Contact?>().firstWhere(
      (c) => c?.publicKeyHex == pubKeyHex,
      orElse: () => null,
    );
    if (contact?.type == advTypeRoom) {
      final authorPrefix = reaction.fourByteRoomContactKey;
      // Our own post pushed back by the room carries our key prefix;
      // attribute it to ourselves so the send-side entry dedups it.
      final selfKey = _selfPublicKey;
      if (selfKey != null && _matchesPrefix(selfKey, authorPrefix)) {
        return _selfName ?? 'Me';
      }
      final member = allContactsUnfiltered.cast<Contact?>().firstWhere(
        (c) => c != null && _matchesPrefix(c.publicKey, authorPrefix),
        orElse: () => null,
      );
      if (member != null) return member.name;
      // Unresolvable author: never fall back to the room's own name — that
      // fabricates a distinct "person" and inflates the count.
      return 'Unknown';
    }
    return contact?.name ?? 'Unknown';
  }

  String? _resolveContactSenderName(
    Message msg,
    Contact? contact,
    bool isRoomServer,
  ) {
    if (!isRoomServer) return null;
    if (!msg.isOutgoing) {
      // Search discovered contacts too, matching _resolveContactFrom4Bytes.
      final senderContact = allContactsUnfiltered.cast<Contact?>().firstWhere(
        (c) =>
            c != null &&
            _matchesPrefix(c.publicKey, msg.fourByteRoomContactKey),
        orElse: () => null,
      );
      return senderContact?.name;
    }
    return selfName;
  }

  _RawPacket? _parseRawPacket(Uint8List raw) {
    try {
      final reader = BufferReader(raw);
      final header = reader.readByte();
      final routeType = header & _phRouteMask;
      final hasTransport =
          routeType == _routeTransportFlood ||
          routeType == _routeTransportDirect;
      if (hasTransport) {
        // Skip reserved bytes in transport header made up of two u16 fields
        reader.skipBytes(4);
      }
      final pathLenRaw = reader.readByte();
      final pathByteLen = _decodePathByteLen(pathLenRaw);
      final pathBytes = reader.readBytes(pathByteLen);
      final payload = reader.readBytes(reader.remaining);

      return _RawPacket(
        header: header,
        routeType: routeType,
        payloadType: (header >> _phTypeShift) & _phTypeMask,
        payloadVer: (header >> _phVerShift) & _phVerMask,
        pathLenRaw: pathLenRaw,
        pathBytes: pathBytes,
        payload: payload,
      );
    } catch (e) {
      appLogger.warn('Error parsing raw packet: $e');
      return null;
    }
  }

  int _computeChannelHash(Uint8List psk) {
    final digest = crypto.sha256.convert(psk).bytes;
    return digest[0];
  }

  /// Findings from the last post-sync audit of the radio's slot table.
  List<String> get channelHealthWarnings =>
      List.unmodifiable(_channelHealthWarnings);
  final List<String> _channelHealthWarnings = [];

  /// Audit the freshly synced slot table for states known to cause trouble:
  /// the same PSK keyed in two slots (twin channels sharing one history),
  /// channels whose 1-byte on-air hash collides (their repeat echoes are
  /// indistinguishable until the MAC check), and keyed-but-nameless slots.
  void _runChannelHealthCheck() {
    _channelHealthWarnings.clear();

    final byPsk = <String, List<int>>{};
    final byHash = <int, List<Channel>>{};
    for (final c in _channels) {
      if (c.isEmpty) continue;
      byPsk.putIfAbsent(c.pskHex, () => []).add(c.index);
      byHash.putIfAbsent(_computeChannelHash(c.psk), () => []).add(c);
      if (c.name.trim().isEmpty && !c.isPublicChannel) {
        _channelHealthWarnings.add(
          'Slot ${c.index} is keyed but has no name.',
        );
      }
    }

    byPsk.forEach((psk, slots) {
      if (slots.length > 1) {
        _channelHealthWarnings.add(
          'Duplicate channel: slots ${slots.join(", ")} share the same key '
          '(${_channels.firstWhere((c) => c.pskHex == psk).displayName}). '
          'Delete the extra slot.',
        );
      }
    });

    byHash.forEach((hash, group) {
      final distinct = {for (final c in group) c.pskHex};
      if (distinct.length > 1) {
        _channelHealthWarnings.add(
          'Channels ${group.map((c) => c.displayName).join(" and ")} share '
          'an on-air hash — delivery still works, but expect slower '
          'decode and identical-looking traffic to sniffers.',
        );
      }
    });

    for (final warning in _channelHealthWarnings) {
      appLogger.warn('Channel health: $warning', tag: 'ChannelHealth');
    }
  }

  /// Firmware-compatible packet hash: SHA256(payloadType + payload) -> first 8 bytes as hex.
  String _computePacketHash(int payloadType, Uint8List payload) {
    final input = Uint8List(1 + payload.length);
    input[0] = payloadType;
    input.setRange(1, input.length, payload);
    final digest = crypto.sha256.convert(input).bytes;
    return digest
        .sublist(0, 8)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  /// Content-based dedup hash for sync queue messages (no raw payload available).
  /// Prefixed with 'c:' to avoid collisions with packet hashes.
  String _computeContentHash(
    int channelIdx,
    int timestampSecs,
    String fullText,
  ) {
    final textBytes = utf8.encode(fullText);
    final input = Uint8List(5 + textBytes.length);
    input[0] = channelIdx;
    input[1] = timestampSecs & 0xFF;
    input[2] = (timestampSecs >> 8) & 0xFF;
    input[3] = (timestampSecs >> 16) & 0xFF;
    input[4] = (timestampSecs >> 24) & 0xFF;
    input.setRange(5, 5 + textBytes.length, textBytes);
    final digest = crypto.sha256.convert(input).bytes;
    return 'c:${digest.sublist(0, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  Uint8List? _decryptPayload(Uint8List psk, Uint8List encrypted) {
    if (encrypted.length <= _cipherMacSize) return null;
    final mac = encrypted.sublist(0, _cipherMacSize);
    final cipherText = encrypted.sublist(_cipherMacSize);

    final key32 = Uint8List(32);
    final copyLen = psk.length < 32 ? psk.length : 32;
    key32.setRange(0, copyLen, psk);

    final hmac = crypto.Hmac(crypto.sha256, key32).convert(cipherText).bytes;
    if (hmac[0] != mac[0] || hmac[1] != mac[1]) {
      return null;
    }

    if (cipherText.isEmpty || cipherText.length % 16 != 0) return null;
    final key16 = Uint8List(16);
    final keyLen = psk.length < 16 ? psk.length : 16;
    key16.setRange(0, keyLen, psk);

    final cipher = ECBBlockCipher(AESEngine());
    cipher.init(false, KeyParameter(key16));
    final out = Uint8List(cipherText.length);
    for (var i = 0; i < cipherText.length; i += 16) {
      cipher.processBlock(cipherText, i, out, i);
    }
    return out;
  }

  _ParsedText _splitSenderText(String text) {
    final colonIndex = text.indexOf(':');
    if (colonIndex > 0 && colonIndex < text.length - 1 && colonIndex < 50) {
      final potentialSender = text.substring(0, colonIndex);
      if (RegExp(r'[:\[\]]').hasMatch(potentialSender)) {
        return _ParsedText(senderName: 'Unknown', text: text);
      }
      final offset =
          (colonIndex + 1 < text.length && text[colonIndex + 1] == ' ')
          ? colonIndex + 2
          : colonIndex + 1;
      return _ParsedText(
        senderName: potentialSender,
        text: text.substring(offset),
      );
    }
    return _ParsedText(senderName: 'Unknown', text: text);
  }

  /// Phase 3d ingest — the database is the only message state. Inserts or
  /// merges a row; watched queries notify every consumer. Returns true when
  /// the message was NEW (drives notifications; unread is a watched COUNT).
  Future<bool> _ingestChannelMessage(
    int channelIndex,
    ChannelMessage message, {
    ChannelMessage? replyTarget,
    Channel? identity,
  }) async {
    // [identity] bypasses the slot lookup for sends queued while the map is
    // unverified: the caller's Channel came from the last settled table, so
    // its idKey is trusted even though its slot index is not.
    final channel = identity ?? _findChannelByIndex(channelIndex);
    if (channel == null) {
      appLogger.warn(
        'Dropping message for unknown slot $channelIndex',
        tag: 'Connector',
      );
      return false;
    }
    final idKey = channel.idKey;

    // Rewrite only BROKEN sender clocks; ordering is arrival-based, so an
    // old-but-plausible time is display truth, not a sorting hazard.
    ChannelMessage sanitizedMessage = message;
    if (!message.isOutgoing) {
      final sane = sanitizeSenderTimestamp(message.timestamp, DateTime.now());
      if (sane != message.timestamp) {
        sanitizedMessage = message.copyWith(timestamp: sane);
      }
    }

    // Reactions mutate their target row; never a visible message.
    final reactionInfo = ChannelMessage.parseReaction(sanitizedMessage.text);
    if (reactionInfo != null) {
      // Keyed by reactor: the same emoji from two people is two reactions,
      // while a repeater echo of one person's reaction is still one.
      final reactorName = sanitizedMessage.senderName;
      _processedChannelReactions.putIfAbsent(idKey, () => {});
      final reactionIdentifier =
          '${reactionInfo.targetHash}_${reactionInfo.emoji}_$reactorName';
      if (_processedChannelReactions[idKey]!.contains(reactionIdentifier)) {
        return false;
      }
      final history = await _channelMessageStore.loadChannelMessages(idKey);
      final applied = _processReaction(history, reactionInfo, reactorName);
      if (applied) {
        await _channelMessageStore.upsertMessages(idKey, history);
      }
      if (applied || reactionInfo.format == ReactionFormat.open) {
        // Unmatched r: text is unambiguously a reaction — drop it. A
        // MeshCore One-shaped message whose hash matches nothing we hold
        // could be a genuine two-line message, so fall through and show it.
        _processedChannelReactions[idKey]!.add(reactionIdentifier);
        notifyListeners();
        return false;
      }
    }

    // Repeat/echo by packet hash: one targeted row update via the index.
    final incomingHash = sanitizedMessage.packetHash;
    if (incomingHash != null) {
      final existing = await _channelMessageStore.findByPacketHash(
        idKey,
        incomingHash,
      );
      if (existing != null) {
        await _mergeChannelRepeat(idKey, existing, sanitizedMessage);
        return false;
      }
    }

    // Resolve reply metadata. On the wire a reply is
    // "@[Name]\n><snippet>..\n<text>" (see ChannelMessage.parseReply, which
    // also reads the older "re:" dialect) — human-readable on other apps.
    final replyInfo = ChannelMessage.parseReply(sanitizedMessage.text);
    ChannelMessage processedMessage = sanitizedMessage;

    if (replyTarget != null) {
      // Our own outgoing reply — we know the exact message being replied to,
      // so quote it precisely regardless of the snippet.
      final displayText =
          replyInfo?.actualMessage ??
          _stripLeadingMention(sanitizedMessage.text, replyTarget.senderName);
      processedMessage = _withReplyMetadata(
        sanitizedMessage,
        text: displayText,
        replyToMessageId: replyTarget.messageId,
        replyToSenderName: replyTarget.senderName,
        replyToText: replyTarget.text,
      );
    } else if (replyInfo != null) {
      // Incoming reply — locate the quoted message by sender + snippet prefix.
      // If we don't have it, still show a quote bubble using the snippet text.
      final originalMessage = _findMessageBySenderAndSnippet(
        await _channelMessageStore.loadChannelMessages(idKey),
        replyInfo.mentionedNode,
        replyInfo.snippet,
      );
      processedMessage = _withReplyMetadata(
        sanitizedMessage,
        text: replyInfo.actualMessage,
        replyToMessageId: originalMessage?.messageId,
        replyToSenderName: originalMessage?.senderName ?? replyInfo.mentionedNode,
        replyToText: originalMessage?.text ?? replyInfo.snippet,
      );
    }

    // Heuristic echo match (no packet hash on our original, second-truncated
    // ids on the wire): compare against the newest rows exactly like the old
    // in-memory pass did — else our own send comes back as a new message.
    final recent = await _channelMessageStore
        .watchChannelMessages(idKey, limit: 80)
        .first;
    for (final existing in recent.reversed) {
      if (_isChannelRepeat(existing, processedMessage)) {
        await _mergeChannelRepeat(idKey, existing, processedMessage);
        return false;
      }
    }

    final unreadEligible = !processedMessage.isOutgoing &&
        !_isFromSelf(processedMessage) &&
        !(_appSettingsService?.isSenderBlocked(processedMessage.senderName) ??
            false);
    final isNew = await _channelMessageStore.insertIfNew(
      idKey,
      processedMessage,
      unreadEligible: unreadEligible,
    );
    if (!isNew) {
      // Same content-derived id: an echo whose packet hash we didn't know.
      final existing = await _channelMessageStore.findByMessageId(
        idKey,
        processedMessage.messageId,
      );
      if (existing != null) {
        await _mergeChannelRepeat(idKey, existing, processedMessage);
      }
      return false;
    }
    // Viewing this channel: the read watermark rides along so the message
    // never accrues as unread (parity with the old active-channel rule).
    if (_activeChannelIndex != null &&
        _findChannelByIndex(_activeChannelIndex!)?.idKey == idKey) {
      unawaited(_channelMessageStore.markRead(idKey));
    }
    notifyListeners();
    return true;
  }

  /// Repeat/echo bookkeeping: merge paths, bump the repeat count, flip our
  /// own echoed sends to delivered — one targeted row update.
  Future<void> _mergeChannelRepeat(
    String idKey,
    ChannelMessage existing,
    ChannelMessage incoming,
  ) async {
    final mergedPathBytes = _selectPreferredPathBytes(
      existing.pathBytes,
      incoming.pathBytes,
    );
    // The hash size must travel WITH the bytes it describes: a queue-first
    // insert stores hashSize 1 with no bytes, and keeping it while the
    // RX-log copy's 2-byte-hash path merges in would render every hop as
    // garbage single-byte hashes.
    final mergedHashSize = identical(mergedPathBytes, incoming.pathBytes)
        ? incoming.pathHashSize
        : existing.pathHashSize;
    final mergedPathVariants = _mergePathVariants(
      existing.pathVariants,
      incoming.pathVariants,
    );
    final mergedPathLength = _mergePathLength(
      existing.pathLength,
      incoming.pathLength,
      mergedPathBytes,
      mergedHashSize,
    );
    await _channelMessageStore.updateMessage(
      idKey,
      existing.messageId,
      (m) => m.copyWith(
        repeatCount: m.repeatCount + 1,
        pathLength: mergedPathLength,
        pathBytes: mergedPathBytes,
        pathHashSize: mergedHashSize,
        pathVariants: mergedPathVariants,
        packetHash: m.packetHash ?? incoming.packetHash,
        status: m.isOutgoing ? ChannelMessageStatus.delivered : m.status,
      ),
    );
    _pendingChannelSentQueue.remove(existing.messageId);
    appLogger.info(
      'Matched repeat for ${existing.messageId}, cancelling timer',
      tag: 'Connector',
    );
    _channelRepeatTimers[existing.messageId]?.cancel();
    _channelRepeatTimers.remove(existing.messageId);
    _channelMessageTimers[existing.messageId]?.cancel();
    _channelMessageTimers.remove(existing.messageId);
    notifyListeners();
  }

  /// Finds the most recent message from [mentionedNode] whose text starts with
  /// [snippet] (both flattened/lower-cased). Includes our own messages so a
  /// reply to something we sent still links.
  ChannelMessage? _findMessageBySenderAndSnippet(
    List<ChannelMessage> messages,
    String mentionedNode,
    String snippet,
  ) {
    // Compare with leading mentions stripped from BOTH sides: the replying
    // app builds its snippet from the parent as it displays it (mention
    // stripped), while our stored text keeps the mention — so a reply to
    // "@[Bob] hello" carried a snippet the raw text could never start with.
    // Comparison-time copies only; stored text and display are untouched.
    String norm(String s) => ChannelMessage.stripLeadingMentions(s)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    final needle = norm(snippet);
    for (int i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      if (m.senderName != mentionedNode) continue;
      if (needle.isEmpty) return m;
      if (norm(m.text).startsWith(needle)) return m;
    }
    return null;
  }

  String _stripLeadingMention(String text, String name) {
    // Tolerate either a space or a newline after the mention, since replies
    // fall back to "@[Name]\n<text>" for cleaner rendering on other apps.
    for (final sep in const [' ', '\n']) {
      final prefix = '@[$name]$sep';
      if (text.startsWith(prefix)) return text.substring(prefix.length);
    }
    return text;
  }

  /// Returns a copy of [base] with a new [text] and reply metadata attached.
  ChannelMessage _withReplyMetadata(
    ChannelMessage base, {
    required String text,
    String? replyToMessageId,
    required String replyToSenderName,
    required String replyToText,
  }) {
    return ChannelMessage(
      senderKey: base.senderKey,
      senderName: base.senderName,
      text: text,
      timestamp: base.timestamp,
      isOutgoing: base.isOutgoing,
      status: base.status,
      repeats: base.repeats,
      repeatCount: base.repeatCount,
      sendRetryCount: base.sendRetryCount,
      sentWireSecs: base.sentWireSecs,
      pathLength: base.pathLength,
      pathBytes: base.pathBytes,
      pathHashSize: base.pathHashSize,
      pathVariants: base.pathVariants,
      channelIndex: base.channelIndex,
      messageId: base.messageId,
      packetHash: base.packetHash,
      reactions: base.reactions,
      reactionSenders: base.reactionSenders,
      replyToMessageId: replyToMessageId,
      replyToSenderName: replyToSenderName,
      replyToText: replyToText,
    );
  }

  bool _processReaction(
    List<ChannelMessage> messages,
    ReactionInfo reactionInfo,
    String reactorName,
  ) {
    return ReactionHelper.applyReaction<ChannelMessage>(
      messages: messages,
      reactionInfo: reactionInfo,
      reactorName: reactorName,
      shouldSkip: (_) => false,
      getTimestampSecs: (msg) => msg.timestamp.millisecondsSinceEpoch ~/ 1000,
      // MeshCore One hashes are computed over the sender's wire clock. For
      // our own rows the wire frame was stamped moments after the row was
      // built, so also try the next second.
      getWireTimestampSecs: (msg) {
        final secs = wireTimestampMs(msg) ~/ 1000;
        if (!msg.isOutgoing) return [secs];
        // Outgoing: the frame is stamped after radio-quiet waits, seconds
        // past the row's construction clock. Recorded stamps are exact
        // (incl. retries); the t..t+3 window covers rows sent before
        // recording existed (field case: gap was exactly 2).
        return {
          secs,
          secs + 1,
          secs + 2,
          secs + 3,
          ...msg.sentWireSecs,
        }.toList();
      },
      // MeshCore One hashes the mention-stripped display text, our rows
      // store the raw text — try both.
      getMessageTextVariants: (msg) => {
        msg.text,
        ChannelMessage.stripLeadingMentions(msg.text),
      }.toList(),
      getSenderName: (msg) => msg.senderName,
      getMessageText: (msg) => msg.text,
      getReactions: (msg) => msg.reactions,
      getReactionSenders: (msg) => msg.reactionSenders,
      updateMessage: (i, reactions, senders) {
        messages[i] = messages[i].copyWith(
          reactions: reactions,
          reactionSenders: senders,
        );
        notifyListeners();
      },
    );
  }

  /// Display timestamps come from the sender's clock; ORDER comes from
  /// arrival (receivedAtUs). Keep the claimed time unless the clock is
  /// broken: more than a minute ahead of us, or more than 30 days behind
  /// (a dead RTC reads 1970). A backlog drained after a night — or a day —
  /// away keeps its real send times.
  @visibleForTesting
  static DateTime sanitizeSenderTimestamp(DateTime timestamp, DateTime now) {
    if (timestamp.isAfter(now.add(const Duration(minutes: 1))) ||
        timestamp.isBefore(now.subtract(const Duration(days: 30)))) {
      return now;
    }
    return timestamp;
  }

  /// The ORIGINAL wire timestamp of a message, in ms — even after the ingest
  /// clamp has rewritten the stored [ChannelMessage.timestamp].
  ///
  /// messageId is built at construction as
  /// `<wire-ms>_<senderName.hashCode>_<text.hashCode>`, before the clamp
  /// runs, and copyWith preserves it. So the id's leading field IS the wire
  /// time, recoverable for every stored row with no schema change.
  @visibleForTesting
  static int wireTimestampMs(ChannelMessage message) {
    final id = message.messageId;
    final cut = id.indexOf('_');
    if (cut > 0) {
      final parsed = int.tryParse(id.substring(0, cut));
      if (parsed != null && parsed > 0) return parsed;
    }
    return message.timestamp.millisecondsSinceEpoch;
  }

  bool _isChannelRepeat(ChannelMessage existing, ChannelMessage incoming) {
    if (existing.text != incoming.text) return false;

    // Compare WIRE times, never stored ones. The ingest clamp rewrites any
    // timestamp older than ten minutes to "now", so a retransmitted copy
    // drained from a radio's offline queue hours later carried a stored time
    // hours away from its original — the 5-minute window could not see them
    // as the same message, and the copy filed as a duplicate. That was the
    // field report: switch companions for a day, come home, messages double.
    final diffMs =
        (wireTimestampMs(existing) - wireTimestampMs(incoming)).abs();
    // Allow up to 5 minutes difference to account for resent messages
    if (diffMs > 300000) {
      appLogger.info('Repeat rejected for time diff: $diffMs ms', tag: 'Connector');
      return false;
    }

    if (existing.senderName == incoming.senderName) {
      appLogger.info('Repeat matched exactly on sender: ${existing.senderName}', tag: 'Connector');
      return true;
    }

    if (existing.isOutgoing && !incoming.isOutgoing) {
      final selfName = _selfName ?? 'Me';
      if (incoming.senderName == selfName || existing.senderName == selfName) {
        appLogger.info('Repeat matched on selfName: $selfName', tag: 'Connector');
        return true;
      }
    }

    return false;
  }

  bool _shouldDropSelfChannelMessage(String senderName, Uint8List pathBytes) {
    final trimmed = senderName.trim();
    if (trimmed.isEmpty) return false;

    final selfName = _selfName?.trim();
    if (selfName == null || selfName.isEmpty) return false;

    // If sender name doesn't match, keep the message
    if (trimmed != selfName) return false;

    // Name matches - this is from self
    // Drop only if pathBytes is empty (direct broadcast)
    // Keep if pathBytes has data (repeated through another node)
    if (pathBytes.isEmpty) {
      appLogger.info('Dropping self-message (direct broadcast, 0 hops)', tag: 'Connector');
      return true;
    }
    
    appLogger.info('Keeping self-message (repeated, ${pathBytes.length} path bytes)', tag: 'Connector');
    return false;
  }

  Uint8List _selectPreferredPathBytes(Uint8List existing, Uint8List incoming) {
    if (incoming.isEmpty) return existing;
    if (existing.isEmpty) return incoming;
    if (incoming.length > existing.length) return incoming;
    return existing;
  }

  int? _mergePathLength(int? existing, int? incoming, Uint8List mergedPathBytes, int hashSize) {
    if (mergedPathBytes.isNotEmpty) {
      return PathHelper.getHopCount(mergedPathBytes, stride: hashSize);
    }
    // Fall back to max TTL recorded if we lack bytes
    if (existing == null) return incoming;
    if (incoming == null) return existing;
    return existing >= incoming ? existing : incoming;
  }

  List<Uint8List> _mergePathVariants(
    List<Uint8List> existing,
    List<Uint8List> incoming,
  ) {
    if (incoming.isEmpty) return existing;
    if (existing.isEmpty) return incoming;

    final merged = <Uint8List>[...existing];
    for (final candidate in incoming) {
      var already = false;
      for (final current in merged) {
        if (_pathsEqual(current, candidate)) {
          already = true;
          break;
        }
      }
      if (!already && candidate.isNotEmpty) {
        merged.add(candidate);
      }
    }
    return merged;
  }

  bool _pathsEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _handleDisconnection() {
    _stopBatteryPolling();
    _gpsPollTimer?.cancel();
    _gpsPollTimer = null;
    _stopRadioStatsPolling();
    _latestRadioStats = null;
    radioStatsNotifier.value = null;
    _prevTotalAirSecs = 0;
    _airtimeBumpStopwatch?.stop();
    _airtimeBumpStopwatch = null;

    for (final entry in _pendingRepeaterAcks.values) {
      entry.timeout?.cancel();
    }
    _pendingRepeaterAcks.clear();

    _notifySubscription?.cancel();
    _notifySubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;

    _device = null;
    _rxCharacteristic = null;
    _txCharacteristic = null;
    // Preserve deviceId and displayName for UI display during reconnection
    // They're only cleared on manual disconnect via disconnect() method
    _hasReceivedDeviceInfo = false;
    _pendingInitialChannelSync = false;
    _pendingInitialContactsSync = false;
    _maxContacts = _defaultMaxContacts;
    _maxChannels = _defaultMaxChannels;
    _isSyncingQueuedMessages = false;
    _queuedMessageSyncInFlight = false;
    _didInitialQueueSync = false;
    _pendingQueueSync = false;
    _pendingChannelSyncAfterQueueSync = false;
    _isSyncingChannels = false;
    _channelSyncInFlight = false;
    _isLoadingChannels = false;
    // The slot map is untrusted from ANY disconnect (this is the
    // unexpected-drop path; disconnect() covers the manual one) until a
    // channel sync completes on the next connection. hasLoaded must fall with
    // verified: the reconnect fetches without force, so leaving it set skips
    // the sync entirely and the map never re-verifies.
    _hasLoadedChannels = false;
    _channelsVerified = false;
    _failStrandedUnverifiedSends();
    // Pending buffers KEPT (see disconnect()): dropping them lost radio-queue
    // messages that are never redelivered.
    _queriedUntrackedChannels.clear();
    _slotsToRequery.clear();
    _pendingChannelSentQueue.clear();
    _pendingGenericAckQueue.clear();
    _reactionSendQueueSequence = 0;
    
    for (final timer in _channelMessageTimers.values) {
      timer.cancel();
    }
    _channelMessageTimers.clear();

    for (final timer in _channelRepeatTimers.values) {
      timer.cancel();
    }
    _channelRepeatTimers.clear();
    _channelMessageRetries.clear();

    _setState(MeshCoreConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _trackPendingGenericAck(
    Uint8List data, {
    String? channelSendQueueId,
    required bool expectsGenericAck,
  }) {
    if (!expectsGenericAck || data.isEmpty) return;
    _pendingGenericAckQueue.add(
      _PendingCommandAck(
        commandCode: data[0],
        channelSendQueueId: channelSendQueueId,
      ),
    );
  }

  String _nextReactionSendQueueId() {
    _reactionSendQueueSequence++;
    return '$_reactionSendQueuePrefix$_reactionSendQueueSequence';
  }

  bool _isReactionSendQueueId(String queueId) {
    return queueId.startsWith(_reactionSendQueuePrefix);
  }

  Map<String, String> _parseKeyValueString(String input) {
    final result = <String, String>{};

    // Split on commas first – empty entries are ignored.
    for (final pair in input.split(',')) {
      final trimmedPair = pair.trim();
      if (trimmedPair.isEmpty) continue;

      // Each pair must contain exactly one ':'.
      final separatorIndex = trimmedPair.indexOf(':');
      if (separatorIndex == -1) continue; // malformed, skip

      final key = trimmedPair.substring(0, separatorIndex).trim();
      final value = trimmedPair.substring(separatorIndex + 1).trim();

      if (key.isNotEmpty) {
        result[key] = value;
      }
    }

    return result;
  }

  void _handleCustomVars(Uint8List frame) {
    final buf = BufferReader(frame.sublist(1));
    try {
      _currentCustomVars = _parseKeyValueString(buf.readCString());
      _updateGpsPolling();
    } catch (e) {
      appLogger.warn('Malformed custom vars frame: $e', tag: 'Connector');
    }
  }

  void _setState(MeshCoreConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  void markNotifyDirty() {
    if (_notifyListenersDirty && _notifyListenersTimer != null) {
      return;
    }

    _notifyListenersDirty = true;
    _notifyListenersTimer ??= Timer(
      _notifyListenersDebounce,
      _flushBatchedNotify,
    );
  }

  void _flushBatchedNotify() {
    _notifyListenersTimer = null;
    if (!_notifyListenersDirty) {
      return;
    }

    _notifyListenersDirty = false;
    super.notifyListeners();

    if (_notifyListenersDirty && _notifyListenersTimer == null) {
      _notifyListenersTimer = Timer(
        _notifyListenersDebounce,
        _flushBatchedNotify,
      );
    }
  }

  @override
  void notifyListeners() {
    if (isConnected &&
        !_initialSyncComplete &&
        _hasReceivedDeviceInfo &&
        !_awaitingSelfInfo &&
        !_isLoadingContacts &&
        !_isLoadingChannels &&
        !_isSyncingQueuedMessages &&
        !_pendingInitialChannelSync &&
        !_pendingInitialContactsSync &&
        !_pendingQueueSync &&
        !_pendingDeferredChannelSyncAfterContacts &&
        !_pendingChannelSyncAfterQueueSync) {
      _initialSyncComplete = true;
    }
    markNotifyDirty();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _usbFrameSubscription?.cancel();
    _notifySubscription?.cancel();
    _notifyListenersTimer?.cancel();
    _reconnectTimer?.cancel();
    _batteryPollTimer?.cancel();
    _gpsPollTimer?.cancel();
    _radioStatsPollTimer?.cancel();
    for (final timer in _channelMessageTimers.values) {
      timer.cancel();
    }
    _channelMessageTimers.clear();
    radioStatsNotifier.dispose();
    _receivedFramesController.close();
    _usbManager.dispose();
    _tcpConnector.dispose();

    super.dispose();
  }

  void _handleRxData(Uint8List frame) {
    final packet = BufferReader(frame);
    try {
      packet.skipBytes(1); // Skip frame type byte
      final snr = packet.readInt8() / 4.0;
      packet.skipBytes(1); // Skip RSSI byte
      //final rssi = packet.readByte();
      final header = packet.readByte();
      final routeType = header & 0x03;
      final payloadType = (header >> 2) & 0x0F;
      if (routeType == _routeTransportFlood ||
          routeType == _routeTransportDirect) {
        packet.skipBytes(4); // Skip transport-specific bytes
      }
      //final payloadVer = (header >> 6) & 0x03;
      final pathLenRaw = packet.readByte();
      final pathByteLen = _decodePathByteLen(pathLenRaw);
      final pathBytes = packet.readBytes(pathByteLen);
      final payload = packet.readBytes(packet.remaining);

      final rawPacket = frame.sublist(3);
      switch (payloadType) {
        case payloadTypeADVERT:
          _handlePayloadAdvertReceived(
            rawPacket,
            payload,
            pathBytes,
            pathLenRaw,
            routeType,
            snr,
          );
          break;
        default:
      }
    } catch (e) {
      appLogger.warn('Malformed RX frame: $e', tag: 'Connector');
      return;
    }
  }

  /// Syncs a list of restored contacts from a JSON backup to the device.
  /// Skips the self-node and adds a small delay between frames to prevent
  /// buffer overflows on the BLE/serial connection.
  Future<void> restoreContacts(List<Contact> importedContacts) async {
    int successCount = 0;
    for (final contact in importedContacts) {
      if (contact.publicKeyHex == selfPublicKeyHex) continue;

      final frame = buildUpdateContactPathFrame(
        contact.publicKey,
        contact.pathOverrideBytes ?? contact.path,
        contact.pathOverride ?? contact.pathLength,
        contact.pathOverrideBytes != null ? _pathHashByteWidth : contact.pathHashSize,
        type: contact.type,
        flags: contact.flags,
        name: contact.name,
        lat: contact.latitude,
        lon: contact.longitude,
        lastModified: contact.lastSeen,
      );

      appLogger.info('Restoring contact ${contact.name}: type=${contact.type}, flags=${contact.flags}, isFavorite=${contact.isFavorite}', tag: 'Connector');
      await sendFrame(frame, expectsGenericAck: true);
      successCount++;
      // Small delay to let the device process and write to flash
      await Future.delayed(const Duration(milliseconds: 100));
    }
    appLogger.info('Successfully restored $successCount contacts to device', tag: 'Connector');
    
    // Refresh the local cache after restoring
    await getContacts();
  }

  void importContact(Uint8List frame) {
    final packet = BufferReader(frame);
    int payloadType = 0;
    Uint8List pathBytes = Uint8List(0);
    int hopCount = -1;
    int hashSize = 1;
    try {
      packet.skipBytes(1); // Skip frame type byte
      packet.skipBytes(1); // Skip SNR byte
      packet.skipBytes(1); // Skip RSSI byte
      final header = packet.readByte();
      final routeType = header & 0x03;
      payloadType = (header >> 2) & 0x0F;
      if (routeType == _routeTransportFlood ||
          routeType == _routeTransportDirect) {
        packet.skipBytes(4); // Skip transport-specific bytes
      }
      //final payloadVer = (header >> 6) & 0x03;
      final pathLenRaw = packet.readByte();
      hopCount = extractPathHopCount(pathLenRaw);
      hashSize = extractPathHashSize(pathLenRaw);
      final pathByteLen = _decodePathByteLen(pathLenRaw);
      pathBytes = packet.readBytes(pathByteLen);
    } catch (e) {
      appLogger.warn('Malformed RX frame: $e', tag: 'Connector');
      return;
    }
    double? latitude;
    double? longitude;
    String name = '';
    Uint8List publicKey = Uint8List(0);
    int type = 0;
    int timestamp = 0;
    bool hasLocation = false;
    bool hasName = false;
    if (payloadType != payloadTypeADVERT) {
      appLogger.warn('Unexpected payload type: $payloadType', tag: 'Connector');
      return;
    }
    try {
      publicKey = packet.readBytes(32);
      timestamp = packet.readInt32LE();
      //TODO add signature verification
      packet.skipBytes(64); // Skip signature for now
      final flags = packet.readByte();
      type = flags & 0x0F;
      hasLocation = (flags & 0x10) != 0;
      // For future use:
      //final hasFeature1 = (flags & 0x20) != 0;
      //final hasFeature2 = (flags & 0x40) != 0;
      hasName = (flags & 0x80) != 0;
      if (hasLocation && packet.remaining >= 8) {
        latitude = packet.readInt32LE() / 1e6;
        longitude = packet.readInt32LE() / 1e6;
      }
      if (hasName && packet.remaining > 0) {
        name = packet.readCString();
      }
    } catch (e) {
      appLogger.warn('Malformed advert frame: $e', tag: 'Connector');
      return;
    }

    final advertTime = _parseAdvertTimestamp(timestamp);
    importDiscoveredContact(
      Contact(
        rawPacket: frame,
        publicKey: publicKey,
        name: name,
        type: type,
        pathLength: pathBytes.isEmpty ? -1 : hopCount,
        pathHashSize: hashSize,
        path: Uint8List.fromList(
          PathHelper.getHops(pathBytes, stride: hashSize).reversed.expand((h) => h).toList(),
        ), // Store path in reverse for easier use in outgoing messages
        latitude: latitude,
        longitude: longitude,
        lastSeen: advertTime.time,
        clockCorrected: advertTime.corrected,
      ),
    );
  }

  bool hasValidLocation(double? latitude, double? longitude) {
    const double epsilon = 1e-6;
    final lat = latitude ?? 0.0;
    final lon = longitude ?? 0.0;
    return (lat.abs() > epsilon || lon.abs() > epsilon) &&
        lat >= -90.0 &&
        lat <= 90.0 &&
        lon >= -180.0 &&
        lon <= 180.0;
  }

  static const Duration _maxAdvertClockSkew = Duration(minutes: 5);

  /// An advert heard live can't be older (or newer) than mesh transit time,
  /// so a timestamp outside [_maxAdvertClockSkew] means the sender's clock is
  /// wrong: use the receive time instead and flag the correction.
  ({DateTime time, bool corrected}) _parseAdvertTimestamp(int timestampSeconds) {
    final claimed = DateTime.fromMillisecondsSinceEpoch(timestampSeconds * 1000);
    final now = DateTime.now();
    if (claimed.difference(now).abs() > _maxAdvertClockSkew) {
      return (time: now, corrected: true);
    }
    return (time: claimed, corrected: false);
  }

  void _handlePayloadAdvertReceived(
    Uint8List rawPacket,
    Uint8List payload,
    Uint8List path,
    int pathLenRaw,
    int routeType,
    double snr,
  ) {
    final advert = BufferReader(payload);
    double? latitude;
    double? longitude;
    String name = '';
    String contactKeyHex = '';
    Uint8List publicKey = Uint8List(0);
    int type = 0;
    int timestamp = 0;
    bool hasLocation = false;
    bool hasName = false;
    try {
      publicKey = advert.readBytes(32);
      contactKeyHex = publicKey
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      timestamp = advert.readInt32LE();
      //TODO add signature verification
      advert.skipBytes(64); // Skip signature for now
      final flags = advert.readByte();
      type = flags & 0x0F;
      hasLocation = (flags & 0x10) != 0;
      // For future use:
      //final hasFeature1 = (flags & 0x20) != 0;
      //final hasFeature2 = (flags & 0x40) != 0;
      hasName = (flags & 0x80) != 0;
      if (hasLocation && advert.remaining >= 8) {
        latitude = advert.readInt32LE() / 1e6;
        longitude = advert.readInt32LE() / 1e6;
      }
      // Validate location values if present
      hasLocation = hasValidLocation(latitude, longitude);

      if (hasName && advert.remaining > 0) {
        name = advert.readCString();
      }
    } catch (e) {
      appLogger.warn('Malformed advert frame: $e', tag: 'Connector');
      return;
    }

    // Update our own location if the companion sends its advert, but ignore it as a contact
    if (listEquals(publicKey, _selfPublicKey)) {
      if (hasLocation && hasValidLocation(latitude, longitude)) {
        if (_selfLatitude != latitude || _selfLongitude != longitude) {
          _selfLatitude = latitude;
          _selfLongitude = longitude;
          notifyListeners();
        }
      }
      return;
    }

    // Check if this is a new contact
    final isNewContact = !_knownContactKeys.contains(contactKeyHex);

    final hopCount = extractPathHopCount(pathLenRaw);
    final hashSize = extractPathHashSize(pathLenRaw);
    final advertTime = _parseAdvertTimestamp(timestamp);

    if (!_isLoadingContacts) {
      _localDiscoveredTimes[contactKeyHex] = DateTime.now();
    }

    if (isNewContact) {
      final newContact = Contact(
        rawPacket: rawPacket,
        publicKey: publicKey,
        name: name,
        type: type,
        pathLength: path.isEmpty ? -1 : hopCount,
        pathHashSize: hashSize,
        path: Uint8List.fromList(
          PathHelper.getHops(path, stride: hashSize).reversed.expand((h) => h).toList(),
        ), // Store path in reverse for easier use in outgoing messages
        latitude: latitude,
        longitude: longitude,
        lastSeen: advertTime.time,
        clockCorrected: advertTime.corrected,
      );
      if ((_autoAddUsers && type == advTypeChat) ||
          (_autoAddRepeaters && type == advTypeRepeater) ||
          (_autoAddRoomServers && type == advTypeRoom) ||
          (_autoAddSensors && type == advTypeSensor)) {
        _handleContactAdvert(newContact);
        _handleDiscovery(
          newContact,
          rawPacket,
          noNotify: true,
          addActive: true,
        );
      } else {
        _handleDiscovery(newContact, rawPacket);
      }
      _updateDirectRepeater(newContact, snr, path, pathLenRaw);
      return;
    }

    final existingIndex = _contacts.indexWhere(
      (c) => c.publicKeyHex == contactKeyHex,
    );

    if (existingIndex >= 0) {
      final existing = _contacts[existingIndex];
      final mergedLastMessageAt = existing.lastMessageAt.isAfter(DateTime.now())
          ? DateTime.now()
          : existing.lastMessageAt;

      appLogger.info(
        'Refreshing contact ${existing.name}: devicePath=${existing.pathLength}, existingOverride=${existing.pathOverride}',
        tag: 'Connector',
      );

      // CRITICAL: Preserve user's path override when contact is refreshed from device
      _contacts[existingIndex] = existing.copyWith(
        latitude: hasLocation ? latitude : existing.latitude,
        longitude: hasLocation ? longitude : existing.longitude,
        name: hasName ? name : existing.name,
        pathHashSize: hashSize,
        path: Uint8List.fromList(
          PathHelper.getHops(path, stride: hashSize).reversed.expand((h) => h).toList(),
        ),
        pathLength: path.isEmpty ? -1 : hopCount,
        lastMessageAt: mergedLastMessageAt,
        lastSeen: advertTime.time,
        clockCorrected: advertTime.corrected,
        pathOverride: existing.pathOverride, // Preserve user's path choice
        pathOverrideBytes: existing.pathOverrideBytes,
      );

      // Add path to history if we have a valid path
      if (_pathHistoryService != null &&
          _contacts[existingIndex].pathLength >= 0) {
        _pathHistoryService!.handlePathUpdated(_contacts[existingIndex]);
      }

      _updateDirectRepeater(_contacts[existingIndex], snr, path, pathLenRaw);

      appLogger.info(
        'After merge: pathOverride=${_contacts[existingIndex].pathOverride}, devicePath=${_contacts[existingIndex].pathLength}',
        tag: 'Connector',
      );
    }
  }

  void _updateDirectRepeater(
    Contact contact,
    double snr,
    Uint8List path,
    int pathLenRaw,
  ) {
    final hashSize = extractPathHashSize(pathLenRaw);
    // The direct (last) hop's full hash identifies the repeater we heard.
    final lastHopTake = math.min(hashSize, path.length);
    final pubkeyPrefix = path.isNotEmpty
        ? Uint8List.fromList(path.sublist(path.length - lastHopTake))
        : PathHelper.pubKeyPrefix(contact.publicKey, stride: hashSize);

    _directRepeaters.removeWhere((r) => r.isStale());

    //We can use adverts from chat and sensor nodes, but only if the advert has a path to get the last hop.
    if ((contact.type == advTypeChat || contact.type == advTypeSensor) &&
        path.isEmpty) {
      notifyListeners();
      return;
    }

    Uint8List? lastHopPublicKey;
    if (path.isEmpty) {
      lastHopPublicKey = contact.publicKey;
    } else {
      final int take = math.min(hashSize, path.length);
      final lastHopBytes = path.sublist(path.length - take);
      Contact? match;
      for (final c in _contacts) {
        if (c.type != advTypeRepeater && c.type != advTypeRoom) continue;
        if (c.publicKey.length >= take) {
          bool isMatch = true;
          for (int i = 0; i < take; i++) {
            if (c.publicKey[i] != lastHopBytes[i]) {
              isMatch = false;
              break;
            }
          }
          if (isMatch) {
            match = c;
            break;
          }
        }
      }
      if (match == null) {
        for (final c in _discoveredContacts) {
          if (c.type != advTypeRepeater && c.type != advTypeRoom) continue;
          if (c.publicKey.length >= take) {
            bool isMatch = true;
            for (int i = 0; i < take; i++) {
              if (c.publicKey[i] != lastHopBytes[i]) {
                isMatch = false;
                break;
              }
            }
            if (isMatch) {
              match = c;
              break;
            }
          }
        }
      }
      if (match != null) {
        lastHopPublicKey = match.publicKey;
      }
    }

    final isTracked = _directRepeaters.where((r) {
      if (r.publicKey != null && lastHopPublicKey != null) {
        return pubKeyToHex(r.publicKey!) == pubKeyToHex(lastHopPublicKey);
      }
      return r.matchesHash(pubkeyPrefix);
    });

    final sortedRepeaters = List<DirectRepeater>.from(_directRepeaters)
      ..sort(DirectRepeater.compare);
    final weakestRepeater = sortedRepeaters.isNotEmpty
        ? sortedRepeaters.last
        : null;

    if (_directRepeaters.length >= 5 &&
        weakestRepeater != null &&
        isTracked.isEmpty) {
      _directRepeaters.remove(weakestRepeater);
    }

    if (isTracked.isNotEmpty) {
      final repeater = isTracked.first;
      repeater.update(snr);
      if (repeater.publicKey == null && lastHopPublicKey != null) {
        repeater.publicKey = lastHopPublicKey;
      }
    } else if (_directRepeaters.length < 5) {
      _directRepeaters.add(
        DirectRepeater(
          pubkeyPrefix: pubkeyPrefix,
          publicKey: lastHopPublicKey,
          snr: snr,
        ),
      );
    }
    notifyListeners();
  }

  void _handleAutoAddConfig(Uint8List frame) {
    final reader = BufferReader(frame);
    try {
      reader.skipBytes(1); // Skip the response code byte
      final flags = reader.readByte();
      _autoAddUsers = (flags & autoAddChatFlag) != 0;
      _autoAddRepeaters = (flags & autoAddRepeaterFlag) != 0;
      _autoAddRoomServers = (flags & autoAddRoomServerFlag) != 0;
      _autoAddSensors = (flags & autoAddSensorFlag) != 0;
      _overwriteOldest = (flags & autoAddOverwriteOldestFlag) != 0;
    } catch (e) {
      appLogger.error('Failed to parse auto-add config: $e', tag: 'Connector');
    }
  }

  void _handleDiscovery(
    Contact contact,
    Uint8List rawPacket, {
    bool noNotify = false,
    bool addActive = false,
  }) {
    appLogger.info('Discovered new contact: ${contact.name}', tag: 'Connector');

    final existingIndex = _discoveredContacts.indexWhere(
      (c) => c.publicKeyHex == contact.publicKeyHex,
    );

    final strippedFlags = contact.flags & ~contactFlagFavorite;

    // Update existing contact
    if (existingIndex >= 0) {
      _discoveredContacts[existingIndex] = _discoveredContacts[existingIndex]
          .copyWith(
            rawPacket: rawPacket,
            name: contact.name,
            type: contact.type,
            pathLength: contact.pathLength,
            path: contact.path,
            latitude: contact.latitude,
            longitude: contact.longitude,
            lastSeen: contact.lastSeen,
            flags: strippedFlags,
            isActive: addActive,
          );
      notifyListeners();
      unawaited(_persistDiscoveredContacts());
      return;
    }

    final disContact = Contact(
      rawPacket: rawPacket,
      publicKey: contact.publicKey,
      name: contact.name,
      type: contact.type,
      pathLength: contact.pathLength,
      path: contact.path,
      latitude: contact.latitude,
      longitude: contact.longitude,
      lastSeen: contact.lastSeen,
      lastMessageAt: contact.lastMessageAt,
      isActive: addActive,
      flags: strippedFlags,
    );
    _discoveredContacts.add(disContact);

    unawaited(_persistDiscoveredContacts());

    // Show notification for new contact (advertisement)
    if (_appSettingsService != null && !noNotify) {
      final settings = _appSettingsService!.settings;
      if (settings.notificationsEnabled && settings.notifyOnNewAdvert) {
        _notificationService.showAdvertNotification(
          contactName: contact.name,
          contactType: contact.typeLabel,
          contactId: contact.publicKeyHex,
        );
      }
    }
  }

  void removeAllDiscoveredContacts({bool includeRepeaters = false}) {
    if (!includeRepeaters) {
      _discoveredContacts.removeWhere((c) => c.type != advTypeRepeater);
    } else {
      _discoveredContacts.clear();
    }
    unawaited(_persistDiscoveredContacts());
    notifyListeners();
  }

  void removeDiscoveredContactsOlderThan(Duration maxAge, {bool includeRepeaters = false}) {
    final cutoff = DateTime.now().subtract(maxAge);
    _discoveredContacts.removeWhere((c) {
      if (!includeRepeaters && c.type == advTypeRepeater) return false;
      return c.lastSeen.isBefore(cutoff);
    });
    unawaited(_persistDiscoveredContacts());
    notifyListeners();
  }

  Future<void> removeRepeaters({Duration? maxAge}) async {
    if (!isConnected) return;
    final cutoff = maxAge != null ? DateTime.now().subtract(maxAge) : null;

    final toRemove = _contacts
        .where((c) =>
            c.type == advTypeRepeater &&
            !c.isFavorite &&
            (cutoff == null || c.lastSeen.isBefore(cutoff)))
        .toList();

    for (final contact in toRemove) {
      await sendFrame(buildRemoveContactFrame(contact.publicKey));
      await Future.delayed(const Duration(milliseconds: 50));
      _contacts.removeWhere((c) => c.publicKeyHex == contact.publicKeyHex);
      _knownContactKeys.remove(contact.publicKeyHex);


      _messageStore.clearMessages(contact.publicKeyHex);
    }

    _discoveredContacts.removeWhere((c) =>
        c.type == advTypeRepeater &&
        !c.isFavorite &&
        (cutoff == null || c.lastSeen.isBefore(cutoff)));

    unawaited(_persistContacts());
    unawaited(_persistDiscoveredContacts());
    notifyListeners();
  }


  Future<void> shareContactZeroHop(Uint8List contactPubKey) async {
    if (!isConnected) return;
    final payload = Uint8List(33);
    payload[0] = cmdShareContact;
    payload.setRange(1, 33, contactPubKey);
    await sendFrame(payload);
  }

  void clearMessagesForContact(Contact contact) {
    final contactKeyHex = contact.publicKeyHex;
    unawaited(_messageStore.clearMessages(contactKeyHex));
    markContactRead(contactKeyHex);
    notifyListeners();
  }

  void clearMessagesForChannel(int channelIndex) {
    // Explicit user clear — the only whole-history deletion besides
    // deleting the channel itself.
    final channel = _findChannelByIndex(channelIndex);
    if (channel == null) return;
    unawaited(_channelMessageStore.clearChannelMessages(channel.idKey));
    markChannelRead(channelIndex);
    notifyListeners();
  }

  void deleteAllPaths() {
    _pathHistoryService?.clearAllHistories();
  }

  Future<void> enableOverwriteOldest() async {
    if (!isConnected) return;
    _overwriteOldest = true;
    await sendFrame(
      buildSetAutoAddConfigFrame(
        autoAddChat: _autoAddUsers,
        autoAddRepeater: _autoAddRepeaters,
        autoAddRoomServer: _autoAddRoomServers,
        autoAddSensor: _autoAddSensors,
        overwriteOldest: true,
      ),
    );
    notifyListeners();
  }
}

const int _phRouteMask = 0x03;
const int _phTypeShift = 2;
const int _phTypeMask = 0x0F;
const int _phVerShift = 6;
const int _phVerMask = 0x03;

const int _routeTransportFlood = 0x00;
const int _routeFlood = 0x01;
const int _routeTransportDirect = 0x03;

const int _payloadTypeGroupText = 0x05;
const int _cipherMacSize = 2;

/// Decodes the firmware's encoded path_len byte into actual byte length.
/// Bits 0-5: hash count (0-63), Bits 6-7: hash size code (0=1byte, 1=2bytes, 2=3bytes).
int _decodePathByteLen(int pathLenRaw) {
  final hashCount = pathLenRaw & 63;
  final hashSize = ((pathLenRaw >> 6) & 0x03) + 1;
  return hashCount * hashSize;
}

class _RawPacket {
  final int header;
  final int routeType;
  final int payloadType;
  final int payloadVer;
  final int pathLenRaw;
  final Uint8List pathBytes;
  final Uint8List payload;

  _RawPacket({
    required this.header,
    required this.routeType,
    required this.payloadType,
    required this.payloadVer,
    required this.pathLenRaw,
    required this.pathBytes,
    required this.payload,
  });

  bool get isFlood =>
      routeType == _routeFlood || routeType == _routeTransportFlood;

  int get hopCount => pathLenRaw & 63;
  
  int get hashSize => extractPathHashSize(pathLenRaw);
}

class _ParsedText {
  final String senderName;
  final String text;

  _ParsedText({required this.senderName, required this.text});
}

class _RepeaterAckContext {
  final String contactKeyHex;
  final PathSelection selection;
  final int pathLength;
  final int messageBytes;
  Timer? timeout;

  _RepeaterAckContext({
    required this.contactKeyHex,
    required this.selection,
    required this.pathLength,
    required this.messageBytes,
  });
}

class _PendingCommandAck {
  final int commandCode;
  final String? channelSendQueueId;

  _PendingCommandAck({required this.commandCode, this.channelSendQueueId});
}
