import 'dart:io';

/// The USB device behind a Linux serial port. Ids are lowercase hex, as
/// sysfs writes them.
typedef LinuxUsbDevice = ({
  String vid,
  String pid,
  String? serialNumber,
  String? product,
});

/// Reads the USB device behind [port] (e.g. `/dev/ttyACM0`) from sysfs, or
/// null when the port is not on USB.
///
/// flserial lists Linux ports by path only, and a path can change when a
/// radio is plugged in again; the ids and serial number do not.
LinuxUsbDevice? readLinuxUsbDevice(String port, {String sysfsRoot = '/sys'}) {
  final name = port.split('/').last;
  try {
    var dir = Directory(
      Directory('$sysfsRoot/class/tty/$name/device').resolveSymbolicLinksSync(),
    );
    // ttyACM ports hang off the USB interface and ttyUSB ports one level
    // below it; the ids live on the device above the interface.
    for (var level = 0; level < 4; level++) {
      final vid = _readAttribute(dir, 'idVendor');
      final pid = _readAttribute(dir, 'idProduct');
      if (vid != null && pid != null) {
        return (
          vid: vid,
          pid: pid,
          serialNumber: _readAttribute(dir, 'serial'),
          product: _readAttribute(dir, 'product'),
        );
      }
      dir = dir.parent;
    }
  } on FileSystemException {
    // No device behind the port.
  }
  return null;
}

String? _readAttribute(Directory dir, String name) {
  final file = File('${dir.path}/$name');
  if (!file.existsSync()) return null;
  final value = file.readAsStringSync().trim();
  return value.isEmpty ? null : value;
}
