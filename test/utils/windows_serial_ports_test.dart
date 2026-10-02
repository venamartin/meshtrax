import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/utils/windows_serial_ports.dart';

const _serialComm =
    '\r\n'
    'HKEY_LOCAL_MACHINE\\HARDWARE\\DEVICEMAP\\SERIALCOMM\r\n'
    '    \\Device\\BthModem2    REG_SZ    COM9\r\n'
    '    \\Device\\BthModem3    REG_SZ    COM16\r\n'
    '    \\Device\\BthModem0    REG_SZ    COM7\r\n'
    '    \\Device\\BthModem1    REG_SZ    COM17\r\n'
    '    \\Device\\USBSER000    REG_SZ    COM14\r\n'
    '\r\n';

const _usbEnum =
    '\r\n'
    'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Enum\\USB\\VID_239A&PID_8029&MI_00\\6&2234e523&0&0000\\Device Parameters\r\n'
    '    PortName    REG_SZ    COM4\r\n'
    '\r\n'
    'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Enum\\USB\\VID_2672&PID_0052\\C3441325930648\\Device Parameters\r\n'
    '    PortName    REG_SZ    COM3\r\n'
    '\r\n'
    'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Enum\\USB\\VID_303A&PID_0002&MI_00\\7&67ed0f2&0&0000\\Device Parameters\r\n'
    '    PortName    REG_SZ    COM14\r\n'
    '\r\n'
    'End of search: 3 match(es) found.\r\n';

void main() {
  test('parseSerialComm drops Bluetooth SPP ports', () {
    expect(parseSerialComm(_serialComm), ['COM14']);
  });

  test('parseSerialComm keeps on-board and USB-bridge ports', () {
    expect(
      parseSerialComm(
        '    \\Device\\Serial0    REG_SZ    COM1\r\n'
        '    \\Device\\Silabser0    REG_SZ    COM5\r\n',
      ),
      ['COM1', 'COM5'],
    );
  });

  test('parseUsbEnumPortNames maps COM names to VID/PID', () {
    final ids = parseUsbEnumPortNames(_usbEnum);
    expect(ids['COM14'], ('303A', '0002'));
    expect(ids['COM4'], ('239A', '8029'));
    expect(ids['COM3'], ('2672', '0052'));
    expect(ids.containsKey('COM9'), isFalse);
  });
}
