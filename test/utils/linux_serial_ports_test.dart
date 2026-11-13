// The fake sysfs tree needs symlinks.
@TestOn('!windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/utils/linux_serial_ports.dart';

void main() {
  late Directory sysfs;

  setUp(() => sysfs = Directory.systemTemp.createTempSync('sysfs'));
  tearDown(() => sysfs.deleteSync(recursive: true));

  void usbDevice(String dir, Map<String, String> attributes) {
    Directory('${sysfs.path}/$dir').createSync(recursive: true);
    attributes.forEach(
      (name, value) =>
          File('${sysfs.path}/$dir/$name').writeAsStringSync('$value\n'),
    );
  }

  void tty(String name, String deviceDir) {
    Directory('${sysfs.path}/$deviceDir').createSync(recursive: true);
    Directory('${sysfs.path}/class/tty/$name').createSync(recursive: true);
    Link('${sysfs.path}/class/tty/$name/device')
        .createSync('${sysfs.path}/$deviceDir');
  }

  test('reads the device above a ttyACM port, with its serial number', () {
    usbDevice('devices/usb1/1-1', {
      'idVendor': '2886',
      'idProduct': '1667',
      'serial': 'F00DCAFE12345678',
      'product': 'Wio Tracker L1',
    });
    tty('ttyACM0', 'devices/usb1/1-1/1-1:1.0');

    expect(readLinuxUsbDevice('/dev/ttyACM0', sysfsRoot: sysfs.path), (
      vid: '2886',
      pid: '1667',
      serialNumber: 'F00DCAFE12345678',
      product: 'Wio Tracker L1',
    ));
  });

  test('reads the device two levels above a ttyUSB port', () {
    usbDevice('devices/usb1/1-2', {
      'idVendor': '1a86',
      'idProduct': '7523',
      'product': 'USB Serial',
    });
    tty('ttyUSB0', 'devices/usb1/1-2/1-2:1.0/ttyUSB0');

    expect(readLinuxUsbDevice('/dev/ttyUSB0', sysfsRoot: sysfs.path), (
      vid: '1a86',
      pid: '7523',
      serialNumber: null,
      product: 'USB Serial',
    ));
  });

  test('null for a port that is not on USB or not known at all', () {
    tty('ttyS0', 'devices/platform/serial8250');

    expect(readLinuxUsbDevice('/dev/ttyS0', sysfsRoot: sysfs.path), isNull);
    expect(readLinuxUsbDevice('/dev/ttyACM9', sysfsRoot: sysfs.path), isNull);
  });
}
