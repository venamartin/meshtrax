import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/services/path_graph/graph_book.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/widgets/pathfinder_mesh_banner.dart';
import 'package:path_graph/path_graph.dart';
import 'package:provider/provider.dart';

// The chats list says when the repeaters heard look like another mesh on
// the same preset, and offers a new graph or the one that knows them.
class _Service extends PathGraphService {
  MeshSuggestion? suggestion;
  String? acceptedName;
  var accepted = 0;
  var dismissed = 0;

  @override
  MeshSuggestion? get meshSuggestion => suggestion;

  @override
  Future<void> acceptMeshSuggestion({String? name}) async {
    accepted++;
    acceptedName = name;
  }

  @override
  Future<void> dismissMeshSuggestion() async => dismissed++;
}

const _mesh = MeshId(freqHz: 910525000, bwHz: 62500, sf: 7, cr: 5);
const _monterey = GraphEntry(id: 'm910525000_62500_7_5', mesh: _mesh, name: 'Monterey Bay');
const _washington =
    GraphEntry(id: 'm910525000_62500_7_5_g2', mesh: _mesh, name: 'Washington');

void main() {
  Future<_Service> pump(WidgetTester tester, MeshSuggestion? suggestion) async {
    final service = _Service()..suggestion = suggestion;
    await tester.pumpWidget(ChangeNotifierProvider<PathGraphService>.value(
      value: service,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PathfinderMeshBanner()),
      ),
    ));
    return service;
  }

  testWidgets('nothing to suggest, nothing shown', (tester) async {
    await pump(tester, null);
    expect(find.text('A different mesh?'), findsNothing);
  });

  testWidgets('new repeaters: name a new graph', (tester) async {
    final service = await pump(
        tester,
        const MeshSuggestion(current: _monterey, heard: 6, unknown: 6));
    expect(
        find.text('6 of 6 repeaters heard since connecting are new to the '
            'Pathfinder graph “Monterey Bay”. Start a new graph for this '
            'area? The old one stays, and you can switch back on the '
            'Pathfinder screen.'),
        findsOneWidget);
    await tester.tap(find.text('New graph'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Washington ');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(service.accepted, 1);
    expect(service.acceptedName, 'Washington');
  });

  testWidgets('a graph that knows them: switch, or keep this one',
      (tester) async {
    final service = await pump(
        tester,
        const MeshSuggestion(
            current: _washington, heard: 6, unknown: 6, other: _monterey));
    expect(
        find.text('Most repeaters heard since connecting are in the '
            'Pathfinder graph “Monterey Bay”, not “Washington”. Switch to it?'),
        findsOneWidget);
    await tester.tap(find.text('Switch'));
    await tester.pumpAndSettle();
    expect((service.accepted, service.acceptedName), (1, null));

    await tester.tap(find.text('Keep this one'));
    expect(service.dismissed, 1);
  });
}
