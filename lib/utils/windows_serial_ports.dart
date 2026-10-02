import 'dart:io';

/// A present serial port on Windows, with its USB ids when it is a USB device.
class WindowsSerialPort {
  const WindowsSerialPort(this.port, {this.vid, this.pid});

  final String port;
  final String? vid;
  final String? pid;
}

/// Lists present serial ports via the registry, skipping Bluetooth SPP links.
///
/// flserial reads the same SERIALCOMM key but throws away the device name
/// (which tells Bluetooth from USB) and never looks up USB ids. Returns null
/// if either query fails so the caller can fall back to flserial.
Future<List<WindowsSerialPort>?> queryWindowsSerialPorts() async {
  assert(Platform.isWindows);
  try {
    final results = await Future.wait([
      Process.run('reg', ['query', r'HKLM\HARDWARE\DEVICEMAP\SERIALCOMM']),
      Process.run('reg', [
        'query',
        r'HKLM\SYSTEM\CurrentControlSet\Enum\USB',
        '/s',
        '/v',
        'PortName',
      ]),
    ]);
    if (results[0].exitCode != 0) return null;
    final ports = parseSerialComm(results[0].stdout as String);
    final usbIds = results[1].exitCode == 0
        ? parseUsbEnumPortNames(results[1].stdout as String)
        : const <String, (String, String)>{};
    return [
      for (final port in ports)
        WindowsSerialPort(port, vid: usbIds[port]?.$1, pid: usbIds[port]?.$2),
    ];
  } catch (_) {
    return null;
  }
}

/// Parses `reg query ...\SERIALCOMM` output into COM names, dropping
/// `\Device\BthModemN` (Bluetooth SPP) entries.
List<String> parseSerialComm(String output) {
  final ports = <String>[];
  for (final match in _kRegSzLine.allMatches(output)) {
    if (match.group(1)!.toLowerCase().startsWith(r'\device\bthmodem')) {
      continue;
    }
    ports.add(match.group(2)!.trim());
  }
  return ports;
}

/// Parses `reg query ...\Enum\USB /s /v PortName` output into
/// COM name → (vid, pid). Includes devices no longer present; callers only
/// look up ports SERIALCOMM reports as present.
Map<String, (String, String)> parseUsbEnumPortNames(String output) {
  final result = <String, (String, String)>{};
  (String, String)? currentIds;
  for (final line in output.split(RegExp(r'\r?\n'))) {
    if (line.startsWith('HKEY_')) {
      final ids = _kVidPid.firstMatch(line);
      currentIds = ids == null
          ? null
          : (ids.group(1)!.toUpperCase(), ids.group(2)!.toUpperCase());
      continue;
    }
    final portName = _kPortNameLine.firstMatch(line);
    if (portName != null && currentIds != null) {
      result[portName.group(1)!.trim()] = currentIds;
    }
  }
  return result;
}

final RegExp _kRegSzLine = RegExp(
  r'^\s+(\S+)\s+REG_SZ\s+(.+?)\s*$',
  multiLine: true,
);
final RegExp _kVidPid = RegExp(r'VID_([0-9A-Fa-f]{4})&PID_([0-9A-Fa-f]{4})');
final RegExp _kPortNameLine = RegExp(r'^\s+PortName\s+REG_SZ\s+(.+?)\s*$');
