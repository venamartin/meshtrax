import 'dart:convert';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:gpx/gpx.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../utils/platform_info.dart';
import '../helpers/meshcore_qr.dart';

import 'package:share_plus/share_plus.dart';

class ContactExport {
  final String name;
  final double lat;
  final double lon;
  final String desc;
  final double? ele;
  final String url;
  ContactExport({
    required this.name,
    required this.lat,
    required this.lon,
    required this.desc,
    required this.url,
    this.ele,
  });
}

const int gpxExportFailed = -1;
const int gpxExportSuccess = 1;
const int gpxExportNoContacts = 2;
const int gpxExportCancelled = 3;
const int gpxExportNotAvailable = 4;

class GpxExport {
  final MeshCoreConnector _connector;
  final List<ContactExport> _contacts = [];

  GpxExport(this._connector);

  void _addContact(
    String name,
    double lat,
    double lon,
    String url,
    String desc, [
    double? ele,
  ]) {
    _contacts.add(
      ContactExport(
        name: name.trim(),
        lat: lat,
        lon: lon,
        desc: desc.trim(),
        ele: ele,
        url: url,
      ),
    );
  }

  void addRepeaters() {
    final contacts = _connector.allContacts.where(
      (c) => c.type == advTypeRepeater || c.type == advTypeRoom,
    );
    for (var contact in contacts) {
      if (contact.latitude == null || contact.longitude == null) {
        continue;
      }
      final url = MeshCoreQr.encodeContact(
        contact.name,
        contact.publicKeyHex,
        contact.type,
      );
      _addContact(
        contact.name,
        contact.latitude!,
        contact.longitude!,
        "Type: ${contact.typeLabel}\nPublic Key: ${contact.publicKeyHex}",
        url,
      );
    }
  }

  void addContacts() {
    final contacts = _connector.allContacts.where((c) => c.type == advTypeChat);
    for (var contact in contacts) {
      if (contact.latitude == null || contact.longitude == null) {
        continue;
      }
      final url = MeshCoreQr.encodeContact(
        contact.name,
        contact.publicKeyHex,
        contact.type,
      );
      _addContact(
        contact.name,
        contact.latitude!,
        contact.longitude!,
        "Type: ${contact.typeLabel}\nPublic Key: ${contact.publicKeyHex}",
        url,
      );
    }
  }

  void addAll() {
    final contacts = _connector.allContacts;
    for (var contact in contacts) {
      if (contact.latitude == null || contact.longitude == null) {
        continue;
      }
      final url = MeshCoreQr.encodeContact(
        contact.name,
        contact.publicKeyHex,
        contact.type,
      );
      _addContact(
        contact.name,
        contact.latitude ?? 0.0,
        contact.longitude ?? 0.0,
        "Type: ${contact.typeLabel}\nPublic Key: ${contact.publicKeyHex}",
        url,
      );
    }
  }

  Future<int> exportGPX(
    String name,
    String description,
    String filename,
    String shareText,
    String subject,
  ) async {
    if (PlatformInfo.isWeb) {
      debugPrint("GPX export is not supported on Web.");
      return gpxExportNotAvailable;
    }
    if (_contacts.isEmpty) {
      debugPrint("No repeaters to export – nothing to share.");
      return gpxExportNoContacts;
    }

    try {
      // 1. Build GPX content (your existing logic – unchanged here)
      final gpx = Gpx()
        ..version = '1.1'
        ..creator = 'MeshTrax exporter'
        ..metadata = Metadata(
          name: name,
          desc: description,
          time: DateTime.now().toUtc(),
        );

      gpx.wpts = _contacts
          .map(
            (c) => Wpt(
              lat: c.lat,
              lon: c.lon,
              ele: c.ele,
              name: c.name,
              desc: c.desc,
              extensions: {
                "meshtrax": {"url": c.url},
              },
            ),
          )
          .toList();

      final xml = GpxWriter().asString(gpx, pretty: true);

      // 2. Save to file
      final timestamp = DateTime.now()
          .toUtc()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .split('T')
          .join('_');

      // On Windows the share call fails ("unavailable") and leaves the app
      // window disabled, so every later click is ignored. Save it instead.
      if (PlatformInfo.isWindows) {
        final saved = await FileSaver.instance.saveAs(
          name: '$filename$timestamp',
          bytes: Uint8List.fromList(utf8.encode(xml)),
          fileExtension: 'gpx',
          mimeType: MimeType.custom,
          customMimeType: 'application/gpx+xml',
        );
        return saved == null || saved.isEmpty
            ? gpxExportCancelled
            : gpxExportSuccess;
      }

      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$filename$timestamp.gpx';

      final file = File(path);
      await file.writeAsString(xml);

      final result = await SharePlus.instance.share(
        ShareParams(text: shareText, subject: subject, files: [XFile(path)]),
      );

      await file.delete();

      switch (result.status) {
        case ShareResultStatus.success:
          debugPrint('Share successful – user completed the action.');
          return gpxExportSuccess;
        case ShareResultStatus.dismissed:
          debugPrint('Share sheet was dismissed / cancelled by user.');
          return gpxExportCancelled;
        case ShareResultStatus.unavailable:
          debugPrint('Sharing is not available on this platform / context.');
          return gpxExportNotAvailable;
      }
    } catch (e, stack) {
      debugPrint('Export or share failed: $e\n$stack');
    }
    return gpxExportFailed;
  }
}
