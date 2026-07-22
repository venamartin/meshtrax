/// Hardware facts for the two-radio bench. Edit these when the bench changes.
class BenchConfig {
  /// Companion 1: USB serial.
  static const String usbPortName = 'COM14';

  /// Companion 2: BLE advertised name.
  /// NOTE: this PC also knows "MeshCore-GWQ-T" — the scanner matches the MAC
  /// prefix or this exact name (minus emoji), never names continuing with '-'.
  static const String bleName = 'MeshCore-GWQ 🚀';

  /// First octets of the BLE radio's MAC; the most reliable disambiguator.
  static const String bleMacPrefix = '90:70:69:85:22';

  /// Localhost port the BLE-NUS bridge listens on; the connector under test
  /// reaches the BLE radio via its real connectTcp() path through this port.
  static const int bridgePort = 58223;

  /// Off-mesh bench frequency (matches repeater "F857 GWQ MOBILE").
  /// CMD_SET_RADIO_PARAMS takes kHz: 920.000 MHz = 920000.
  static const int targetFreqKhz = 920000;

  /// These radios are dedicated to the bench (owner's explicit call):
  /// every non-Public slot is wiped at S0 so runs start deterministic.
  /// Set false if the harness ever drives radios with real channels on them.
  static const bool radiosAreDedicated = true;

  /// Nordic UART Service.
  static const String nusService = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';

  /// Write to radio.
  static const String nusRxChar = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';

  /// Notify from radio.
  static const String nusTxChar = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  /// LoRa air time plus queue/push latency between two desk radios.
  static const Duration messageTimeout = Duration(seconds: 45);

  /// Full connect + contact sync + channel sync handshake.
  static const Duration handshakeTimeout = Duration(seconds: 90);

  /// Gap between consecutive sends so the air interface is not saturated.
  static const Duration interSendGap = Duration(seconds: 3);
}
