import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// A class that connects to the BLE server and sends/receives messages
/// Make sure to call [initialize] before using [invokeMethod]
class WinConnector {
  int _requestId = 0;
  StreamSubscription? _stdoutSubscription;
  StreamSubscription? _stderrSubscription;
  Process? _bleServer;
  final _responseStreamController = StreamController.broadcast();

  Future<void> initialize({
    Function(dynamic)? onData,
    required String serverPath,
  }) async {
    File bleFile = File(serverPath);
    _bleServer = await Process.start(bleFile.path, []);
    _stdoutSubscription = _bleServer?.stdout.listen((event) {
      var listData = _dataParser(event);
      for (var data in listData) {
        _handleResponse(data);
        onData?.call(data);
      }
    });

    _stderrSubscription = _bleServer?.stderr.listen((event) {
      throw String.fromCharCodes(event);
    });
  }

  Future invokeMethod(
    String method, {
    Map<String, dynamic>? args,
    bool waitForResult = true,
  }) async {
    Map<String, dynamic> result = args ?? {};
    // If we don't need to wait for the result, just send the message and return
    if (!waitForResult) {
      _sendMessage(method: method, args: result);
      return;
    }
    // If we need to wait for the result, we need to generate a unique ID
    int uniqID = _requestId++;
    result["_id"] = uniqID;
    _sendMessage(method: method, args: result);
    var data = await _responseStreamController.stream.firstWhere(
      (element) => element["id"] == uniqID,
    );
    if (data["error"] != null) throw data["error"];
    return data['result'];
  }

  void dispose() {
    _stderrSubscription?.cancel();
    _stdoutSubscription?.cancel();
    _bleServer?.kill();
  }

  void _handleResponse(response) {
    try {
      if (response["_type"] == "response") {
        _responseStreamController.add({
          "id": response["_id"],
          "result": response["result"],
          "error": response["error"]
        });
      }
    } catch (_) {}
  }

  void _sendMessage({
    required String method,
    Map<String, dynamic>? args,
  }) {
    Map<String, dynamic> result = {"cmd": method};
    if (args != null) result.addAll(args);
    String data = json.encode(result);
    List<int> dataBufInt = utf8.encode(data);
    List<int> lenBufInt = _createUInt32LE(dataBufInt.length);
    _bleServer?.stdin.add(lenBufInt);
    _bleServer?.stdin.add(dataBufInt);
  }

  List<int> _createUInt32LE(int value) {
    final result = Uint8List(4);
    for (int i = 0; i < 4; i++, value >>= 8) {
      result[i] = value & 0xFF;
    }
    return result;
  }

  // MESHTRAX PATCH: the upstream parser treated every stdout chunk as a
  // whole number of frames AND mixed byte offsets (length prefixes) with
  // string offsets (payload substring). A frame split across reads threw
  // RangeError, and any multi-byte UTF-8 payload (e.g. a device name with
  // an emoji) desynced the cursor into garbage lengths, killing long bench
  // runs. This version buffers bytes across reads and decodes per frame.
  final BytesBuilder _rxBuffer = BytesBuilder();

  List<dynamic> _dataParser(List<int> event) {
    _rxBuffer.add(event);
    final list = <dynamic>[];
    final bytes = _rxBuffer.toBytes();
    var cursor = 0;
    while (bytes.length - cursor >= 4) {
      final length = _fromBytesToInt32(bytes[cursor + 0], bytes[cursor + 1],
          bytes[cursor + 2], bytes[cursor + 3]);
      if (length < 0 || length > 16 * 1024 * 1024) {
        // Unrecoverable desync: drop the buffer instead of spinning.
        _rxBuffer.clear();
        return list;
      }
      if (bytes.length - cursor - 4 < length) break; // partial frame
      final payloadBytes = bytes.sublist(cursor + 4, cursor + 4 + length);
      cursor += 4 + length;
      try {
        list.add(json.decode(utf8.decode(payloadBytes)));
      } catch (_) {
        // Skip an unparsable frame; framing stays intact.
      }
    }
    final remaining = bytes.sublist(cursor);
    _rxBuffer.clear();
    if (remaining.isNotEmpty) _rxBuffer.add(remaining);
    return list;
  }

  int _fromBytesToInt32(int b3, int b2, int b1, int b0) {
    final int8List = Int8List(4)
      ..[3] = b3
      ..[2] = b2
      ..[1] = b1
      ..[0] = b0;
    return int8List.buffer.asByteData().getInt32(0);
  }
}
