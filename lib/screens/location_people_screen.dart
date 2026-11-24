import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../services/trax_service.dart';
import '../services/trip_service.dart';
import '../widgets/my_location_button.dart';
import '../widgets/trax_dialogs.dart';

int _byName(Contact a, Contact b) =>
    a.name.toLowerCase().compareTo(b.name.toLowerCase());

Widget _initial(BuildContext context, Contact contact) => CircleAvatar(
  radius: 18,
  child: Text(contact.name.isEmpty ? '?' : contact.name.characters.first),
);

/// The people who may ask this radio where it is, picked one by one, with
/// the trip's members while Trip setup lets them. Never "all contacts" as
/// a choice: a radio saves strangers by itself (Martin, 2026-11-21).
class LocationPeopleScreen extends StatelessWidget {
  const LocationPeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.watch<MeshCoreConnector>();
    final trip = context.watch<TripService?>();
    final until = context.watch<TraxService?>()?.setup.until;
    final everyone = locationLookOf(c).everyone;
    final fromTrip = trip != null && trip.active
        ? {for (final m in trip.memberContacts) m.publicKeyHex}
        : const <String>{};
    final people = c.contacts.where(c.sharesPositionWith).toList()
      ..sort(_byName);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myLocation_peopleWho), centerTitle: true),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(l10n.myLocation_peopleHint),
          ),
          if (everyone) ...[
            ListTile(
              title: Text(
                l10n.myLocation_allSaved(people.length),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => unawaited(pickPeopleInstead(c)),
                  child: Text(l10n.myLocation_pickPeople),
                ),
              ),
            ),
          ] else ...[
            for (final person in people)
              ListTile(
                leading: _initial(context, person),
                title: Text(
                  person.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle:
                    fromTrip.contains(person.publicKeyHex) && until != null
                    ? Text(l10n.trax_until(traxTimeText(context, until)))
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.common_remove,
                  onPressed: () {
                    // Trip setup would give a member it back: the trip lets
                    // them go instead.
                    if (fromTrip.contains(person.publicKeyHex)) {
                      trip!.removeMember(person);
                    } else {
                      unawaited(
                        c.setContactFlags(
                          person,
                          teleBase: false,
                          teleLoc: false,
                        ),
                      );
                    }
                  },
                ),
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(l10n.myLocation_addSomeone),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _AddPersonScreen()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Someone to add: by search, or from the favourites and the latest
/// conversations, which come first.
class _AddPersonScreen extends StatefulWidget {
  const _AddPersonScreen();

  @override
  State<_AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends State<_AddPersonScreen> {
  String _query = '';

  static const _recentCount = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.watch<MeshCoreConnector>();
    final saved = c.contacts
        .where((x) => x.type == advTypeChat && x.isActive)
        .toList();
    final query = _query.trim().toLowerCase();
    final List<Widget> rows;
    if (query.isNotEmpty) {
      rows = [
        for (final x
            in saved.where((x) => x.name.toLowerCase().contains(query)).toList()
              ..sort(_byName))
          _row(context, c, x),
      ];
    } else {
      final favourites = saved.where((x) => x.isFavorite).toList()
        ..sort(_byName);
      final recent = [
        for (final x in saved)
          if (!x.isFavorite)
            if (c.latestContactMessage(x) case final m?) (x, m.timestamp),
      ]..sort((a, b) => b.$2.compareTo(a.$2));
      rows = [
        if (favourites.isNotEmpty) ...[
          _header(context, l10n.listFilter_favorites),
          for (final x in favourites) _row(context, c, x),
        ],
        if (recent.isNotEmpty) ...[
          _header(context, l10n.myLocation_recent),
          for (final (x, _) in recent.take(_recentCount)) _row(context, c, x),
        ],
      ];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myLocation_addSomeone),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              autofocus: false,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.myLocation_search(saved.length),
                border: const OutlineInputBorder(),
              ),
              onChanged: (text) => setState(() => _query = text),
            ),
          ),
          Expanded(child: ListView(children: rows)),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );

  Widget _row(BuildContext context, MeshCoreConnector c, Contact contact) {
    final can = c.sharesPositionWith(contact);
    return ListTile(
      leading: _initial(context, contact),
      title: Text(contact.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: can ? Text(context.l10n.myLocation_canAsk) : null,
      enabled: !can,
      onTap: () async {
        await c.setContactFlags(contact, teleBase: true, teleLoc: true);
        await allowAskingByContact(c);
        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}
