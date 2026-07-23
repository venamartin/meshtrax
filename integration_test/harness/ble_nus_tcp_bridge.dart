import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:meshtrax/services/usb_serial_frame_codec.dart';
import 'package:win_ble/win_ble.dart';
import 'package:win_ble/win_file.dart';

import 'bench.dart';
import 'bench_config.dart';

/// Relays the MeshCore Nordic UART Service to a localhost TCP socket.
///
/// flutter_blue_plus has no Windows implementation, so the connector under
/// test cannot reach the BLE radio directly on this bench. The app's TCP
/// transport speaks the exact `<`/`>` serial framing over the socket, so this
/// bridge lets a stock MeshCoreConnector drive the BLE radio through its real
/// connectTcp() path: app frame (0x3c) in -> raw bytes to NUS RX; NUS TX
/// notification -> radio frame (0x3e) out.
class BleNusTcpBridge {
  static bool _winBleInitialized = false;

  String? _address;
  ServerSocket? _server;
  Socket? _client;
  final UsbSerialFrameDecoder _decoder = UsbSerialFrameDecoder();
  StreamSubscription<dynamic>? _notifySub;
  StreamSubscription<bool>? _connectionSub;
  Future<void> _pendingWrite = Future<void>.value();
  bool _stopping = false;
  bool _bleUp = false;
  int _droppedWhileNoClient = 0;

  bool get bleConnected => _bleUp;

  void _log(String msg) => blog('[bridge] $msg');

  /// win_ble is a dev dependency, so its BLEServer.exe asset is not bundled
  /// into the integration-test app — load it straight from the pub cache.
  Future<String> _bleServerPath() async {
    final pubCache = Platform.environment['PUB_CACHE'] ??
        '${Platform.environment['LOCALAPPDATA']}\\Pub\\Cache';
    final hosted = Directory('$pubCache\\hosted\\pub.dev');
    if (hosted.existsSync()) {
      final candidates = hosted
          .listSync()
          .whereType<Directory>()
          .where((d) => d.path.contains('win_ble-'))
          .map((d) => File('${d.path}\\lib\\assets\\BLEServer.exe'))
          .where((f) => f.existsSync())
          .map((f) => f.path)
          .toList()
        ..sort();
      if (candidates.isNotEmpty) return candidates.last;
    }
    return WinServer.path();
  }

  Future<void> start() async {
    if (!_winBleInitialized) {
      final serverPath = await _bleServerPath();
      _log('BLE server: $serverPath');
      await WinBle.initialize(serverPath: serverPath);
      _winBleInitialized = true;
    }

    _address = await _scanForRadio();
    _log('found ${BenchConfig.bleName} at $_address');
    await Future<void>.delayed(const Duration(milliseconds: 500));

    await _connectBle();
    await _subscribeWithPairFallback();

    try {
      final mtu = await WinBle.getMaxMtuSize(_address!);
      _log('negotiated MTU: $mtu');
      if (mtu is int && mtu < 175) {
        _log('WARNING: MTU $mtu cannot carry a full 172-byte frame '
            '(needs 175 with ATT overhead); large frames may fail');
      }
    } catch (e) {
      _log('MTU query failed (non-fatal): $e');
    }

    _connectionSub = WinBle.connectionStreamOf(_address!).listen((up) {
      _bleUp = up;
      if (!up && !_stopping) {
        _log('BLE link dropped — reconnecting…');
        unawaited(_reconnectLoop());
      }
    });

    _server = await ServerSocket.bind(
      InternetAddress.loopbackIPv4,
      BenchConfig.bridgePort,
    );
    _server!.listen(_onClient);
    _log('listening on 127.0.0.1:${BenchConfig.bridgePort}');
  }

  Future<String> _scanForRadio() async {
    final completer = Completer<String>();
    // Emoji in the advertised name can arrive encoding-mangled, so compare
    // on the plain-text stem ("meshcore-gwq") and reject the '-T' sibling.
    final wantedName = BenchConfig.bleName.toLowerCase();
    final wantedStem = wantedName.split(' ').first;
    final wantedMac = BenchConfig.bleMacPrefix
        .toLowerCase()
        .replaceAll(RegExp('[^0-9a-f]'), '');
    final sub = WinBle.scanStream.listen((device) {
      final mac = device.address
          .toLowerCase()
          .replaceAll(RegExp('[^0-9a-f]'), '');
      final name = device.name.toLowerCase();
      final macHit = wantedMac.isNotEmpty && mac.startsWith(wantedMac);
      final nameHit = name == wantedName ||
          name == wantedStem ||
          (name.startsWith(wantedStem) &&
              name.length > wantedStem.length &&
              name[wantedStem.length] != '-');
      if (macHit || nameHit) {
        _log('scan hit: "${device.name}" ${device.address} '
            '(${macHit ? 'mac' : 'name'} match)');
        if (!completer.isCompleted) completer.complete(device.address);
      }
    });
    WinBle.startScanning();
    try {
      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          // Not advertising — typically an orphaned link from an unclean
          // shutdown. The device is paired: direct connect works anyway.
          _log('scan timed out — falling back to known address '
              '${BenchConfig.bleKnownAddress}');
          return BenchConfig.bleKnownAddress;
        },
      );
    } finally {
      WinBle.stopScanning();
      await sub.cancel();
    }
  }

  /// win_ble's connect() reports link failure on a stream instead of
  /// throwing, and Windows BLE connects are flaky right after a scan — so
  /// verify with a forced service discovery and retry the whole thing.
  Future<void> _connectBle() async {
    Object? lastError;
    for (var attempt = 1; attempt <= 4; attempt++) {
      try {
        await WinBle.connect(_address!);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        final services =
            await WinBle.discoverServices(_address!, forceRefresh: true);
        if (services.isEmpty) {
          throw StateError('link came up empty — connect failed silently');
        }
        final hasNus = services.any(
          (s) => s.toLowerCase().contains('6e400001'),
        );
        if (!hasNus) {
          throw StateError(
            'no Nordic UART Service (services: $services) — not a MeshCore '
            'companion?',
          );
        }
        _bleUp = true;
        return;
      } catch (e) {
        lastError = e;
        _log('BLE connect attempt $attempt/4 failed: $e');
        try {
          await WinBle.disconnect(_address!);
        } catch (_) {}
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    throw StateError('BLE connect gave up after 4 attempts: $lastError');
  }

  Future<void> _subscribeWithPairFallback() async {
    try {
      await _subscribe();
      return;
    } catch (e) {
      _log('subscribe failed ($e) — the radio likely requires pairing.');
    }

    _log('==========================================================');
    _log('ACTION NEEDED: accept the Windows Bluetooth pairing prompt');
    _log('for "${BenchConfig.bleName}" and enter the radio\'s BLE PIN');
    _log('(MeshCore default: 123456). Waiting up to 60s…');
    _log('==========================================================');
    try {
      await WinBle.pair(_address!);
    } catch (e) {
      _log('pair() returned: $e (prompt may still be pending)');
    }

    for (var attempt = 1; attempt <= 12; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 5));
      try {
        await _subscribe();
        _log('paired and subscribed on attempt $attempt');
        return;
      } catch (_) {
        _log('waiting for pairing… ($attempt/12)');
      }
    }
    throw StateError(
      'Could not subscribe to NUS notifications after pairing attempts. '
      'Pair "${BenchConfig.bleName}" in Windows Bluetooth settings, then '
      're-run the harness.',
    );
  }

  Future<void> _subscribe() async {
    await WinBle.subscribeToCharacteristic(
      address: _address!,
      serviceId: BenchConfig.nusService,
      characteristicId: BenchConfig.nusTxChar,
    );
    await _notifySub?.cancel();
    _notifySub = WinBle.characteristicValueStreamOf(
      address: _address!,
      serviceId: BenchConfig.nusService,
      characteristicId: BenchConfig.nusTxChar,
    ).listen(_onRadioFrame);
  }

  void _onRadioFrame(dynamic value) {
    final bytes = Uint8List.fromList(List<int>.from(value as List));
    final client = _client;
    if (client == null) {
      _droppedWhileNoClient++;
      return;
    }
    final packet = Uint8List(usbSerialHeaderLength + bytes.length);
    packet[0] = usbSerialRxFrameStart;
    packet[1] = bytes.length & 0xff;
    packet[2] = (bytes.length >> 8) & 0xff;
    packet.setRange(usbSerialHeaderLength, packet.length, bytes);
    try {
      client.add(packet);
    } catch (e) {
      _log('client write failed: $e');
    }
  }

  void _onClient(Socket socket) {
    if (_client != null) {
      _log('new client replaces existing one');
      try {
        _client!.destroy();
      } catch (_) {}
    }
    _client = socket;
    _decoder.reset();
    if (_droppedWhileNoClient > 0) {
      _log('note: $_droppedWhileNoClient radio frames dropped while no '
          'client was attached (push hints; queued messages are safe)');
      _droppedWhileNoClient = 0;
    }
    _log('app connected from ${socket.remotePort}');

    socket.listen(
      (data) {
        for (final packet in _decoder.ingest(Uint8List.fromList(data))) {
          if (packet.frameStart != usbSerialTxFrameStart) continue;
          _enqueueBleWrite(packet.payload);
        }
      },
      onError: (Object e) {
        _log('client socket error: $e');
        _dropClient(socket);
      },
      onDone: () {
        _log('app disconnected');
        _dropClient(socket);
      },
    );
  }

  void _dropClient(Socket socket) {
    if (_client == socket) {
      _client = null;
      _decoder.reset();
    }
    try {
      socket.destroy();
    } catch (_) {}
  }

  void _enqueueBleWrite(Uint8List payload) {
    _pendingWrite = _pendingWrite.then((_) async {
      await WinBle.write(
        address: _address!,
        service: BenchConfig.nusService,
        characteristic: BenchConfig.nusRxChar,
        data: payload,
        writeWithResponse: true,
      );
    }).catchError((Object e) {
      _log('BLE write failed (frame len=${payload.length}): $e');
    });
  }

  Future<void> _reconnectLoop() async {
    // Patient enough for multi-hour monitor runs (~10 min of attempts).
    for (var attempt = 1; attempt <= 300 && !_stopping; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      try {
        await _connectBle();
        await _subscribe();
        _log('BLE reconnected on attempt $attempt');
        return;
      } catch (e) {
        _log('BLE reconnect attempt $attempt failed: $e');
      }
    }
    if (!_stopping) {
      _log('BLE reconnect gave up after 30 attempts');
    }
  }

  Future<void> stop() async {
    _stopping = true;
    await _connectionSub?.cancel();
    await _notifySub?.cancel();
    try {
      _client?.destroy();
    } catch (_) {}
    _client = null;
    await _server?.close();
    _server = null;
    if (_address != null) {
      try {
        await WinBle.disconnect(_address!);
      } catch (_) {}
    }
  }
}
