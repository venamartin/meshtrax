import 'dart:async';
import 'dart:io';

import 'package:flserial/flserial.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_debug_log_service.dart';
import '../utils/macos_usb_device_names.dart';
import '../utils/platform_info.dart';
import '../utils/usb_port_labels.dart';
import 'usb_serial_frame_codec.dart';

/// Wraps the native flserial plugin to expose a stream of raw bytes for the
/// MeshCore connector to consume.
class UsbSerialService {
  UsbSerialService();

  static const MethodChannel _androidMethodChannel = MethodChannel(
    'meshtrax/android_usb_serial',
  );
  static const EventChannel _androidEventChannel = EventChannel(
    'meshtrax/android_usb_serial_events',
  );
  final StreamController<Uint8List> _frameController =
      StreamController<Uint8List>.broadcast();
  final UsbSerialFrameDecoder _frameDecoder = UsbSerialFrameDecoder();
  StreamSubscription<dynamic>? _androidDataSubscription;
  StreamSubscription<SerialEvent>? _dataSubscription;
  UsbSerialStatus _status = UsbSerialStatus.disconnected;
  String? _connectedPortKey;
  String? _connectedPortLabel;
  FlSerial? _serial;
  AppDebugLogService? _debugLogService;

  UsbSerialStatus get status => _status;
  String? get activePortKey => _connectedPortKey;
  String? get activePortDisplayLabel =>
      _connectedPortLabel ?? _connectedPortKey;
  Stream<Uint8List> get frameStream => _frameController.stream;
  bool get _useAndroidUsbHost =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _useDesktopFlSerial =>
      PlatformInfo.isWindows || PlatformInfo.isLinux || PlatformInfo.isMacOS;
  bool get _isSupportedPlatform => _useAndroidUsbHost || _useDesktopFlSerial;
  // Always-fresh: do NOT use ??= here – a cached FlSerial retains stale
  // native handle state (flh) from a prior failed open, causing subsequent
  // open attempts to fail with "port not exist" even when the device is present.
  FlSerial _freshSerial() => FlSerial();

  bool get isConnected {
    if (!_isSupportedPlatform) {
      return false;
    }
    // Trust _status as the authoritative connection state. Polling
    // _serial?.isOpen() via the native FL_CTRL_IS_PORT_OPEN query is
    // unreliable during the brief USB re-enumeration window that many
    // microcontrollers (e.g. NRF52) trigger in response to DTR assertion.
    // Actual port drops are handled by the onDone / onError callbacks on the
    // serial data stream subscription, which update _status correctly.
    return _status == UsbSerialStatus.connected;
  }

  Future<List<String>> listPorts() async {
    if (!_isSupportedPlatform) {
      return const <String>[];
    }
    if (_useAndroidUsbHost) {
      final ports = await _androidMethodChannel.invokeListMethod<String>(
        'listPorts',
      );
      return ports ?? <String>[];
    }
    final ports = await FlSerial.availablePorts();
    final rawPorts = ports.map((e) => e.path).toList();
    // On macOS, flserial's native device-name lookup is broken on macOS
    // 10.15+ because the IOKit class name changed from IOUSBDevice to
    // IOUSBHostDevice. We resolve names ourselves via ioreg and rewrite any
    // "port - n/a" entries with the real product name.
    if (Platform.isMacOS && rawPorts.isNotEmpty) {
      return _annotateMacOsPorts(rawPorts);
    }
    return rawPorts;
  }

  /// Rewrites the flserial port list on macOS by substituting real USB device
  /// names (obtained via [ioreg]) for the "n/a" placeholders that flserial
  /// returns when it can't find the deprecated IOUSBDevice parent.
  Future<List<String>> _annotateMacOsPorts(List<String> rawPorts) async {
    final deviceNames = await queryMacOsUsbDeviceNames();
    if (deviceNames.isEmpty) return rawPorts;
    return rawPorts.map((entry) {
      // entry format from fl_ports: "port - description - hardware_id"
      final port = normalizeUsbPortName(entry); // e.g. /dev/cu.usbmodem1101
      final knownName = deviceNames[port]; // e.g. "Nordic NRF52 DK"
      if (knownName == null) return entry; // non-USB port, keep as-is
      // Replace description field only; preserve hardware_id for device
      // identity (used by normalizeUsbPortName).
      final segments = entry.split(' - ');
      final hardwareId = segments.length >= 3 ? segments.last : 'n/a';
      return '$port - $knownName - $hardwareId';
    }).toList();
  }

  void setDebugLogService(AppDebugLogService? service) {
    _debugLogService = service;
  }

  Future<void> connect({
    required String portName,
    int baudRate = 115200,
  }) async {
    if (_status == UsbSerialStatus.connected ||
        _status == UsbSerialStatus.connecting) {
      throw StateError('USB serial transport is already active');
    }
    if (!_isSupportedPlatform) {
      throw UnsupportedError('USB serial is not supported on this platform.');
    }

    _status = UsbSerialStatus.connecting;
    var normalizedPortName = normalizeUsbPortName(portName);
    _frameDecoder.reset();

    if (_useAndroidUsbHost) {
      try {
        await _androidMethodChannel.invokeMethod<void>('connect', {
          'portName': normalizedPortName,
          'baudRate': baudRate,
        });
        _debugLogService?.info(
          'USB serial opened port=$normalizedPortName on Android via USB host bridge',
          tag: 'USB Serial',
        );
      } on PlatformException catch (error) {
        _status = UsbSerialStatus.disconnected;
        final msg = error.message ?? error.code;
        _debugLogService?.error(
          'Android connect failed: $msg',
          tag: 'USB Serial',
        );
        rethrow;
      }
    } else {
      // On macOS, flserial lists both cu.* and tty.* device nodes.
      // When a cu.* open fails, try the tty.* variant as a fallback 
      // (and vice-versa) before giving up.
      final candidates = _buildPortCandidates(normalizedPortName);
      Exception? lastError;
      bool opened = false;

      for (final candidate in candidates) {
        final serial = _freshSerial();
        try {
          final openStatus = await serial.open(candidate, SerialConfig(baudRate: baudRate));
          if (!openStatus) {
            final msg = 'Failed to open USB port $candidate';
            _debugLogService?.error(msg, tag: 'USB Serial');
            _status = UsbSerialStatus.disconnected;
            throw StateError(msg);
          }
          serial.setRTS(false);
          // Toggle DTR low→high so the device sees a fresh connection even
          // if the previous disconnect didn't cleanly signal DTR drop.
          serial.setDTR(false);
          await Future<void>.delayed(const Duration(milliseconds: 50));
          serial.setDTR(true);
          _serial = serial;
          // Update the normalized port name to whichever candidate succeeded.
          normalizedPortName = candidate;
          
          final modem = serial.getModemStatus();
          _debugLogService?.info(
            'USB serial opened port=$candidate cts=${modem['CTS']} dsr=${modem['DSR']} dtr=true rts=false',
            tag: 'USB Serial',
          );
          opened = true;
          break;
        } catch (error, stackTrace) {
          _debugLogService?.warn(
            'Failed to open $candidate: $error\n$stackTrace',
            tag: 'USB Serial',
          );
          lastError = error is Exception ? error : Exception(error.toString());
        }
      }

      if (!opened) {
        _status = UsbSerialStatus.disconnected;
        final primary = candidates.first;
        final msg = lastError != null
            ? 'Failed to open USB port $primary: $lastError'
            : 'Failed to open USB port $primary';
        _debugLogService?.error(msg, tag: 'USB Serial');
        throw StateError(msg);
      }
    }

    _connectedPortKey = normalizedPortName;
    _connectedPortLabel = normalizedPortName;
    if (_useAndroidUsbHost) {
      _androidDataSubscription = _androidEventChannel
          .receiveBroadcastStream()
          .listen(
            _handleAndroidData,
            onError: _handleSerialError,
            onDone: _handleSerialDone,
          );
    } else {
      _dataSubscription = _serial!.events.listen(
        _handleSerialEvent,
        onError: _handleSerialError,
        onDone: _handleSerialDone,
      );
    }
    _status = UsbSerialStatus.connected;
  }

  Future<void> writeRaw(Uint8List data) async {
    if (!isConnected) {
      throw StateError('USB serial port is not open');
    }
    if (_useAndroidUsbHost) {
      try {
        await _androidMethodChannel.invokeMethod<void>('write', {'data': data});
      } on PlatformException catch (error) {
        throw StateError(error.message ?? error.code);
      }
    } else {
      _serial!.write(data);
    }
  }

  Future<void> write(Uint8List data) async {
    if (!isConnected) {
      throw StateError('USB serial port is not open');
    }
    final packet = wrapUsbSerialTxFrame(data);
    if (_useAndroidUsbHost) {
      try {
        await _androidMethodChannel.invokeMethod<void>('write', {
          'data': packet,
        });
      } on PlatformException catch (error) {
        throw StateError(error.message ?? error.code);
      }
    } else {
      _serial!.write(packet);
    }
  }

  Future<void> disconnect() async {
    if (_status == UsbSerialStatus.disconnected) return;

    final portLabel = _connectedPortLabel ?? _connectedPortKey;
    _debugLogService?.info(
      'USB disconnect starting port=${portLabel ?? 'unknown'}',
      tag: 'USB Serial',
    );
    _status = UsbSerialStatus.disconnecting;
    _connectedPortKey = null;
    _connectedPortLabel = null;
    _frameDecoder.reset();

    if (_useAndroidUsbHost) {
      await _androidDataSubscription?.cancel();
      _androidDataSubscription = null;
      try {
        await _androidMethodChannel.invokeMethod<void>('disconnect');
      } catch (_) {
        // Ignore errors while closing.
      }
    } else {
      final serial = _serial;
      _serial = null;
      try {
        serial?.setDTR(false);
        await serial?.close();
      } catch (_) {
        // Ignore errors while closing.
      }

      await _dataSubscription?.cancel();
      _dataSubscription = null;
    }
    _status = UsbSerialStatus.disconnected;
    _debugLogService?.info(
      'USB disconnect complete port=${portLabel ?? 'unknown'}',
      tag: 'USB Serial',
    );
  }

  void setRequestPortLabel(String label) {
    // Native implementations do not use a synthetic chooser row.
  }

  void setFallbackDeviceName(String label) {
    // Native implementations use OS-provided device names.
  }

  void updateConnectedLabel(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _connectedPortLabel = buildUsbDisplayLabel(
      basePortLabel: _connectedPortKey ?? trimmed,
      deviceName: trimmed,
    );
  }

  void dispose() {
    if (_useDesktopFlSerial) {
      final serial = _serial;
      try {
        serial?.setDTR(false);
        unawaited(serial?.close());
      } catch (_) {}
    }
    unawaited(disconnect().whenComplete(_closeFrameController));
  }

  void _handleSerialEvent(SerialEvent event) {
    if (event.type == SerialEventType.data) {
      try {
        final bytes = event.data as Uint8List;
        if (bytes.isNotEmpty) {
          _ingestRawBytes(bytes);
        }
      } catch (error, stack) {
        _addFrameError(error, stack);
      }
    } else if (event.type == SerialEventType.disconnected) {
      _handleSerialDone();
    } else if (event.type == SerialEventType.error) {
      _handleSerialError(StateError(event.data.toString()));
    }
  }

  void _handleAndroidData(dynamic data) {
    if (data is Uint8List) {
      _ingestRawBytes(data);
      return;
    }
    if (data is ByteData) {
      _ingestRawBytes(data.buffer.asUint8List());
      return;
    }
    _addFrameError(
      StateError('Unexpected Android USB event payload: ${data.runtimeType}'),
    );
  }

  void _handleSerialError(Object error, [StackTrace? stackTrace]) {
    _addFrameError(error, stackTrace);
  }

  void _handleSerialDone() {
    unawaited(disconnect());
  }

  void _ingestRawBytes(Uint8List bytes) {
    for (final packet in _frameDecoder.ingest(bytes)) {
      if (!packet.isRxFrame) {
        _debugLogService?.info(
          'USB ignored packet start=0x${packet.frameStart.toRadixString(16).padLeft(2, '0')} len=${packet.payload.length}',
          tag: 'USB Serial',
        );
        continue;
      }
      _addFrame(packet.payload);
    }
  }

  void _addFrame(Uint8List payload) {
    if (_frameController.isClosed) {
      return;
    }
    _frameController.add(payload);
  }

  void _addFrameError(Object error, [StackTrace? stackTrace]) {
    if (_frameController.isClosed) {
      return;
    }
    _frameController.addError(error, stackTrace);
  }

  Future<void> _closeFrameController() async {
    if (_frameController.isClosed) {
      return;
    }
    await _frameController.close();
  }

  List<String> _buildPortCandidates(String normalizedPort) {
    if (!Platform.isMacOS) return [normalizedPort];
    const cuPrefix = '/dev/cu.';
    const ttyPrefix = '/dev/tty.';
    if (normalizedPort.startsWith(cuPrefix)) {
      final suffix = normalizedPort.substring(cuPrefix.length);
      return [normalizedPort, '$ttyPrefix$suffix'];
    }
    if (normalizedPort.startsWith(ttyPrefix)) {
      final suffix = normalizedPort.substring(ttyPrefix.length);
      return [normalizedPort, '$cuPrefix$suffix'];
    }
    return [normalizedPort];
  }
}

enum UsbSerialStatus { disconnected, connecting, connected, disconnecting }
