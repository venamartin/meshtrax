/// A report's airtime at the mesh's own preset: 37 bytes on air (a 29-byte
/// report sealed for the channel) at 62.5 kHz, SF7, CR 4/5, with the
/// firmware's 32-symbol preamble.
const referenceReportAirtimeMs = 214;

/// How often each member's MeshTrax sends its location in TRAX mode: 30 s
/// per member, so every minute for two, and longer as the group grows. A
/// report that takes longer on air than at the mesh's own preset stretches
/// it by as much, so the group's share of the air stays the same; a faster
/// preset doesn't shorten it. Field tests decide the figure, and this is
/// the only place it lives.
Duration beaconInterval({required int members, required int reportAirtimeMs}) {
  const perMemberMs = 30000;
  final n = members < 2 ? 2 : members;
  final stretch = reportAirtimeMs > referenceReportAirtimeMs
      ? reportAirtimeMs / referenceReportAirtimeMs
      : 1.0;
  return Duration(milliseconds: (perMemberMs * n * stretch).round());
}
