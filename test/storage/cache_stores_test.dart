import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/channel_store.dart';
import 'package:meshtrax/storage/contact_discovery_store.dart';
import 'package:meshtrax/storage/contact_store.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The cache stores (contacts, discovered contacts, cached channel slots)
// mirror radio/app state where whole-list replacement is the correct write.
// These tests pin the Drift conversion: roundtrip fidelity, node-scope
// isolation, and one-time legacy prefs import with key removal.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Contact contact(int seed, {String? name}) {
    return Contact(
      publicKey: Uint8List.fromList(List.filled(32, seed)),
      name: name ?? 'Contact $seed',
      type: 1,
      pathLength: -1,
      path: Uint8List(0),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(1753000000000 + seed),
    );
  }

  Channel channel(int index, {String? name}) {
    return Channel(
      index: index,
      name: name ?? 'Channel $index',
      psk: Uint8List.fromList(List.filled(16, index + 1)),
    );
  }

  String contactBlob(List<Contact> contacts) {
    return jsonEncode([
      for (final c in contacts)
        {
          'publicKey': base64Encode(c.publicKey),
          'name': c.name,
          'type': c.type,
          'flags': c.flags,
          'pathLength': c.pathLength,
          'path': base64Encode(c.path),
          'lastSeen': c.lastSeen.millisecondsSinceEpoch,
          'lastMessageAt': c.lastMessageAt.millisecondsSinceEpoch,
        },
    ]);
  }

  String channelBlob(List<Channel> channels) {
    return jsonEncode([
      for (final ch in channels)
        {
          'index': ch.index,
          'name': ch.name,
          'psk': base64Encode(ch.psk),
          'unreadCount': ch.unreadCount,
        },
    ]);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  group('ContactStore', () {
    late ContactStore store;

    setUp(() {
      store = ContactStore();
      store.setPublicKeyHex = 'deadbeef00cafe';
    });

    test('roundtrips saved contacts', () async {
      await store.saveContacts([contact(1), contact(2)]);

      final loaded = await store.loadContacts();

      expect(loaded, hasLength(2));
      final byName = {for (final c in loaded) c.name: c};
      expect(byName['Contact 1']!.publicKeyHex, contact(1).publicKeyHex);
      expect(byName['Contact 1']!.lastSeen, contact(1).lastSeen);
    });

    test('save replaces the whole list (radio-mirror semantics)', () async {
      await store.saveContacts([contact(1), contact(2)]);
      await store.saveContacts([contact(2, name: 'Renamed')]);

      final loaded = await store.loadContacts();

      expect(loaded, hasLength(1));
      expect(loaded.single.name, 'Renamed');
    });

    test('contacts are isolated per node scope', () async {
      await store.saveContacts([contact(1)]);

      final other = ContactStore();
      other.setPublicKeyHex = 'feedface00beef';

      expect(await other.loadContacts(), isEmpty);
      expect(await store.loadContacts(), hasLength(1));
    });

    test('does nothing without a node scope', () async {
      final unscoped = ContactStore();
      await unscoped.saveContacts([contact(1)]);
      expect(await unscoped.loadContacts(), isEmpty);
    });

    test('imports legacy scoped blob once and removes the key', () async {
      final prefs = PrefsManager.instance;
      await prefs.setString(store.keyFor, contactBlob([contact(1)]));

      final loaded = await store.loadContacts();

      expect(loaded.single.name, 'Contact 1');
      expect(prefs.getString(store.keyFor), isNull);

      // A second load must not duplicate or resurrect anything.
      expect(await store.loadContacts(), hasLength(1));
    });

    test('imports legacy unscoped blob when scoped key is absent', () async {
      final prefs = PrefsManager.instance;
      await prefs.setString('contacts', contactBlob([contact(3)]));

      final loaded = await store.loadContacts();

      expect(loaded.single.name, 'Contact 3');
      expect(prefs.getString('contacts'), isNull);
    });

    test('legacy blob never overwrites existing rows', () async {
      await store.saveContacts([contact(1)]);
      final prefs = PrefsManager.instance;
      await prefs.setString(store.keyFor, contactBlob([contact(9)]));

      final loaded = await store.loadContacts();

      expect(loaded.single.name, 'Contact 1');
      expect(prefs.getString(store.keyFor), isNull);
    });
  });

  group('ContactDiscoveryStore', () {
    late ContactDiscoveryStore store;

    setUp(() {
      store = ContactDiscoveryStore();
    });

    test('roundtrips discovered contacts', () async {
      await store.saveContacts([contact(4), contact(5)]);

      final loaded = await store.loadContacts();

      expect(loaded.map((c) => c.name), containsAll(['Contact 4', 'Contact 5']));
    });

    test('discovery results are shared across store instances', () async {
      await store.saveContacts([contact(4)]);

      expect(await ContactDiscoveryStore().loadContacts(), hasLength(1));
    });

    test('save replaces the whole list', () async {
      await store.saveContacts([contact(4), contact(5)]);
      await store.saveContacts([contact(5)]);

      expect(await store.loadContacts(), hasLength(1));
    });

    test('imports legacy blob once and removes the key', () async {
      final prefs = PrefsManager.instance;
      await prefs.setString('discovered_contacts', contactBlob([contact(6)]));

      final loaded = await store.loadContacts();

      expect(loaded.single.name, 'Contact 6');
      expect(prefs.getString('discovered_contacts'), isNull);
      expect(await store.loadContacts(), hasLength(1));
    });
  });

  group('ChannelStore', () {
    late ChannelStore store;

    setUp(() {
      store = ChannelStore();
      store.setPublicKeyHex = 'deadbeef00cafe';
    });

    test('roundtrips channels ordered by slot index', () async {
      await store.saveChannels([channel(3), channel(0), channel(1)]);

      final loaded = await store.loadChannels();

      expect(loaded.map((c) => c.index), [0, 1, 3]);
      expect(loaded.first.psk, channel(0).psk);
    });

    test('save replaces the whole slot table', () async {
      await store.saveChannels([channel(0), channel(1)]);
      await store.saveChannels([channel(1, name: 'Renamed')]);

      final loaded = await store.loadChannels();

      expect(loaded, hasLength(1));
      expect(loaded.single.name, 'Renamed');
    });

    test('channels are isolated per node scope', () async {
      await store.saveChannels([channel(0)]);

      final other = ChannelStore();
      other.setPublicKeyHex = 'feedface00beef';

      expect(await other.loadChannels(), isEmpty);
    });

    test('does nothing without a node scope', () async {
      final unscoped = ChannelStore();
      await unscoped.saveChannels([channel(0)]);
      expect(await unscoped.loadChannels(), isEmpty);
    });

    test('imports legacy scoped blob once and removes the key', () async {
      final prefs = PrefsManager.instance;
      await prefs.setString(store.keyFor, channelBlob([channel(0), channel(2)]));

      final loaded = await store.loadChannels();

      expect(loaded.map((c) => c.index), [0, 2]);
      expect(prefs.getString(store.keyFor), isNull);
      expect(await store.loadChannels(), hasLength(2));
    });

    test('imports legacy unscoped blob when scoped key is absent', () async {
      final prefs = PrefsManager.instance;
      await prefs.setString('channels', channelBlob([channel(1)]));

      final loaded = await store.loadChannels();

      expect(loaded.single.index, 1);
      expect(prefs.getString('channels'), isNull);
    });

    test('legacy blob never overwrites existing rows', () async {
      await store.saveChannels([channel(0, name: 'Live')]);
      final prefs = PrefsManager.instance;
      await prefs.setString(store.keyFor, channelBlob([channel(0, name: 'Stale')]));

      final loaded = await store.loadChannels();

      expect(loaded.single.name, 'Live');
      expect(prefs.getString(store.keyFor), isNull);
    });
  });
}
