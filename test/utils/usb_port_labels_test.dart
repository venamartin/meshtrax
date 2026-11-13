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

  test('describeUsbVidPid prefers exact product over vendor name', () {
    expect(describeUsbVidPid('2886', '1667'), 'Seeed Wio Tracker L1');
    expect(describeUsbVidPid('2886', '0001'), 'Seeed');
    expect(describeUsbVidPid('303A', '0002'), 'Espressif ESP32');
    expect(describeUsbVidPid('1234', '5678'), isNull);
  });

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

  group('usbHardwareId', () {
    test('takes the ids at the end of a label', () {
      expect(
        usbHardwareId(
          '/dev/ttyACM0 - Seeed Wio Tracker L1 - VID:2886 PID:1667 SN:F00D',
        ),
        'VID:2886 PID:1667 SN:F00D',
      );
      expect(
        usbHardwareId('COM6 - Seeed Wio Tracker L1 - VID:2886 PID:1667'),
        'VID:2886 PID:1667',
      );
    });

    test('null for labels without ids', () {
      expect(usbHardwareId('/dev/ttyS0'), isNull);
      expect(usbHardwareId('/dev/cu.usbmodem1101 - Radio - n/a'), isNull);
    });
  });

  group('findLastUsbPort', () {
    const radio = '/dev/ttyACM1 - Radio - VID:2886 PID:1667 SN:F00D';
    const other = '/dev/ttyACM0 - Radio - VID:2886 PID:1667 SN:BEEF';

    test('finds the radio by its ids after its port name changed', () {
      expect(
        findLastUsbPort(
          [other, radio, '/dev/ttyS0'],
          path: '/dev/ttyACM0',
          hardwareId: 'VID:2886 PID:1667 SN:F00D',
        ),
        '/dev/ttyACM1',
      );
    });

    test('null when the radio is not plugged in', () {
      expect(
        findLastUsbPort(
          [other],
          path: '/dev/ttyACM0',
          hardwareId: 'VID:2886 PID:1667 SN:F00D',
        ),
        isNull,
      );
    });

    test('ids shared by several ports: only the last path counts', () {
      const ports = [
        'COM3 - Seeed - VID:2886 PID:1667',
        'COM4 - Seeed - VID:2886 PID:1667',
      ];
      expect(
        findLastUsbPort(ports, path: 'COM4', hardwareId: 'VID:2886 PID:1667'),
        'COM4',
      );
      expect(
        findLastUsbPort(ports, path: 'COM5', hardwareId: 'VID:2886 PID:1667'),
        isNull,
      );
    });

    test('without ids the path decides', () {
      const ports = ['/dev/cu.usbmodem1101 - Radio - n/a'];
      expect(
        findLastUsbPort(ports, path: '/dev/cu.usbmodem1101'),
        '/dev/cu.usbmodem1101',
      );
      expect(findLastUsbPort(ports, path: '/dev/cu.usbmodem1201'), isNull);
    });
  });
}
