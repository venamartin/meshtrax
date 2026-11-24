import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bluez/bluez.dart';

// The companion's Nordic UART service: frames for the radio go to RX, and
// the radio's frames come as notifications from TX.
final _service = BlueZUUID.fromString('6e400001-b5a3-f393-e0a9-e50e24dcca9e');
final _rx = BlueZUUID.fromString('6e400002-b5a3-f393-e0a9-e50e24dcca9e');
final _tx = BlueZUUID.fromString('6e400003-b5a3-f393-e0a9-e50e24dcca9e');

/// A companion radio over Bluetooth, through BlueZ: a frame per write and
/// per notification. The radio must be paired already.
class BleLink {
  BleLink._(this._client, this._device, this._rxChar, this._txChar);

  final BlueZClient _client;
  final BlueZDevice _device;
  final BlueZGattCharacteristic _rxChar;
  final BlueZGattCharacteristic _txChar;

  /// Connects to the paired radio called [name], or "MeshCore-[name]".
  static Future<BleLink> open(String name) async {
    final client = BlueZClient();
    await client.connect();
    try {
      final device =
          client.devices
              .where((d) => d.name == name || d.name == 'MeshCore-$name')
              .firstOrNull ??
          (throw StateError(
            'no paired radio called "$name" (pair it with bluetoothctl)',
          ));
      if (!device.connected) await _connect(client, device);
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (!device.servicesResolved) {
        if (DateTime.now().isAfter(deadline)) {
          throw StateError('its services never showed up');
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      final service =
          device.gattServices.where((s) => s.uuid == _service).firstOrNull ??
          (throw StateError('it has no companion service'));
      BlueZGattCharacteristic find(BlueZUUID uuid) =>
          service.characteristics.firstWhere((c) => c.uuid == uuid);
      final tx = find(_tx);
      await tx.startNotify();
      return BleLink._(client, device, find(_rx), tx);
    } catch (_) {
      await client.close();
      rethrow;
    }
  }

  /// An LE radio that isn't connected may need a scan before it connects.
  static Future<void> _connect(BlueZClient client, BlueZDevice device) async {
    try {
      await device.connect();
      return;
    } on Object {
      final adapter = client.adapters.first;
      await adapter.startDiscovery();
      await Future<void>.delayed(const Duration(seconds: 8));
      await adapter.stopDiscovery();
    }
    await device.connect();
  }

  /// The radio's frames.
  Stream<Uint8List> get frames => _txChar.propertiesChanged
      .where((names) => names.contains('Value'))
      .map((_) => Uint8List.fromList(_txChar.value));

  /// Writes [frame] to the radio. A failed write shows, and the command it
  /// carried times out.
  void send(Uint8List frame) => unawaited(
    _rxChar
        .writeValue(frame, type: BlueZGattCharacteristicWriteType.request)
        .catchError((Object e) => stdout.writeln('Bluetooth write failed: $e')),
  );

  /// Lets the radio go, as BlueZ would keep it connected.
  Future<void> close() async {
    try {
      await _txChar.stopNotify();
      await _device.disconnect();
    } on Object {
      // Gone already.
    }
    await _client.close();
  }
}
