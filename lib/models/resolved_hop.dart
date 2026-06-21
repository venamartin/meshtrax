import 'package:latlong2/latlong.dart';
import 'contact.dart';

class ResolvedHop {
  final int index;
  final String fullPrefixLabel;
  final Contact? contact;
  final LatLng? position;
  final LatLng? inferredPosition;

  const ResolvedHop({
    required this.index,
    required this.fullPrefixLabel,
    this.contact,
    this.position,
    this.inferredPosition,
  });

  bool get hasLocation => position != null || inferredPosition != null;
  LatLng? get effectivePosition => position ?? inferredPosition;
}
