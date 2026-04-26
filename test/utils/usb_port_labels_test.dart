import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/utils/usb_port_labels.dart';

void main() {
  test('normalizeUsbPortName strips friendly suffix from composite label', () {
    expect(
      normalizeUsbPortName(
        'COM6 - USB Serial Device (COM6) - USB\\VID_2886&PID_1667',
      ),
      'COM6',
    );
  });

  test(
    'friendlyUsbPortName returns only description, not hardware_id (3-part label)',
    () {
      expect(
        friendlyUsbPortName(
          'COM6 - USB Serial Device (COM6) - USB\\VID_2886&PID_1667',
        ),
        'USB Serial Device (COM6)',
      );
    },
  );

  test(
    'friendlyUsbPortName works for macOS-style 3-part label with USB product name',
    () {
      expect(
        friendlyUsbPortName(
          '/dev/cu.usbmodem1101 - Nordic Semiconductor nRF52 DK - USB VID:PID=1915:520f SNR=ABCDEF',
        ),
        'Nordic Semiconductor nRF52 DK',
      );
    },
  );

  test('friendlyUsbPortName works for Linux-style label', () {
    expect(
      friendlyUsbPortName(
        '/dev/ttyACM0 - RAK4631 - USB VID:PID=239A:8029 SER=xxxxxxxx',
      ),
      'RAK4631',
    );
  });

  test('friendlyUsbPortName trims whitespace from label parts', () {
    expect(
      friendlyUsbPortName(' /dev/ttyS0  -  My Serial Port   -  n/a '),
      'My Serial Port',
    );
  });

  test(
    'friendlyUsbPortName falls back to port name when description is n/a',
    () {
      expect(
        friendlyUsbPortName('/dev/cu.Bluetooth-Incoming-Port - n/a - n/a'),
        '/dev/cu.Bluetooth-Incoming-Port',
      );
    },
  );

  test(
    'friendlyUsbPortName handles 2-part label (no hardware_id) correctly',
    () {
      expect(
        friendlyUsbPortName('COM6 - USB Serial Device (COM6)'),
        'USB Serial Device (COM6)',
      );
    },
  );

  test('describeWebUsbPort uses known VID/PID names when available', () {
    expect(
      describeWebUsbPort(
        vendorId: 0x2886,
        productId: 0x1667,
        knownUsbNames: const <String, String>{
          '2886:1667': 'Seeed Wio Tracker L1',
        },
      ),
      'Seeed Wio Tracker L1 (VID:2886 PID:1667)',
    );
  });

  test('describeWebUsbPort falls back to generic label for unknown device', () {
    expect(
      describeWebUsbPort(vendorId: 0x1234, productId: 0x5678),
      'Web Serial Device (VID:1234 PID:5678)',
    );
  });

  test('describeWebUsbPort returns chooser label when no usb ids exist', () {
    expect(
      describeWebUsbPort(vendorId: null, productId: null),
      'Choose USB Device',
    );
  });

  test('describeWebUsbPort uses caller-provided chooser label', () {
    expect(
      describeWebUsbPort(
        vendorId: null,
        productId: null,
        requestPortLabel: 'Select a USB device',
      ),
      'Select a USB device',
    );
  });

  test('buildUsbDisplayLabel appends device-reported name when available', () {
    expect(
      buildUsbDisplayLabel(
        basePortLabel: 'Seeed Wio Tracker L1 (VID:2886 PID:1667)',
        deviceName: 'KD3CGK mesh-utility.org',
      ),
      'Seeed Wio Tracker L1 (VID:2886 PID:1667) - KD3CGK mesh-utility.org',
    );
  });

  test('buildUsbDisplayLabel keeps base label when custom name is blank', () {
    expect(
      buildUsbDisplayLabel(
        basePortLabel: 'Seeed Wio Tracker L1 (VID:2886 PID:1667)',
        deviceName: '   ',
      ),
      'Seeed Wio Tracker L1 (VID:2886 PID:1667)',
    );
  });
}
