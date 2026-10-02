String normalizeUsbPortName(String portLabel) {
  final separatorIndex = portLabel.indexOf(' - ');
  final normalized = separatorIndex >= 0
      ? portLabel.substring(0, separatorIndex)
      : portLabel;
  return normalized.trim();
}

/// Returns a human-readable name for a serial port label.
///
/// The native flserial library encodes port info as a ` - `-separated string:
///   `"<port> - <description> - <hardware_id>"`
///
/// This function extracts the *description* field (index 1) and discards the
/// raw hardware_id, which is not user-friendly. If the description is missing
/// or unhelpful (e.g. "n/a"), it falls back to the raw port name.
String friendlyUsbPortName(String portLabel) {
  final parts = portLabel.split(' - ');
  if (parts.length < 2) {
    return portLabel.trim();
  }
  // parts[0] = port name, parts[1] = description, parts[2+] = hardware id
  final description = parts[1].trim();
  if (description.isEmpty || description.toLowerCase() == 'n/a') {
    return parts[0].trim();
  }
  return description;
}

/// Keyed by lowercase `vid:pid` hex.
const Map<String, String> knownUsbProductNames = <String, String>{
  '2886:1667': 'Seeed Wio Tracker L1',
};

/// Keyed by lowercase vid hex. Names the chip family when the exact board
/// is unknown.
const Map<String, String> knownUsbVendorNames = <String, String>{
  '303a': 'Espressif ESP32',
  '239a': 'nRF52 (Adafruit)',
  '2886': 'Seeed',
  '10c4': 'Silicon Labs CP210x',
  '1a86': 'WCH CH34x',
  '0403': 'FTDI',
  '2e8a': 'RP2040',
};

String? describeUsbVidPid(String vid, String pid) {
  final v = vid.toLowerCase();
  return knownUsbProductNames['$v:${pid.toLowerCase()}'] ??
      knownUsbVendorNames[v];
}

String describeWebUsbPort({
  required int? vendorId,
  required int? productId,
  String requestPortLabel = 'Choose USB Device',
  String fallbackDeviceName = 'Web Serial Device',
  Map<String, String> knownUsbNames = const <String, String>{},
}) {
  if (vendorId == null && productId == null) {
    return requestPortLabel;
  }

  final vendorHex = vendorId?.toRadixString(16).padLeft(4, '0').toUpperCase();
  final productHex = productId?.toRadixString(16).padLeft(4, '0').toUpperCase();
  final knownName = (vendorHex != null && productHex != null)
      ? knownUsbNames['${vendorHex.toLowerCase()}:${productHex.toLowerCase()}']
      : null;

  final parts = <String>[knownName ?? fallbackDeviceName];
  if (vendorHex != null) {
    parts.add('VID:$vendorHex');
  }
  if (productHex != null) {
    parts.add('PID:$productHex');
  }
  return '${parts.first} (${parts.skip(1).join(' ')})';
}

String buildUsbDisplayLabel({
  required String basePortLabel,
  String? deviceName,
}) {
  final trimmedName = deviceName?.trim() ?? '';
  if (trimmedName.isEmpty) {
    return basePortLabel;
  }
  return '$basePortLabel - $trimmedName';
}
