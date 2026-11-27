import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vedic_math_app/data/vedic_catalog.dart';
import 'package:vedic_math_app/database/db_helper.dart';
import 'package:vedic_math_app/main.dart';
import 'package:vedic_math_app/models/vedic_models.dart';
import 'package:vedic_math_app/screens/exercise_screen.dart';
import 'package:vedic_math_app/screens/players_screen.dart';
import 'package:vedic_math_app/screens/progress_screen.dart';
import 'package:vedic_math_app/screens/theory_screen.dart';

class FakeDatabaseHelper extends DatabaseHelper {
  FakeDatabaseHelper() : super.forTesting();

  int _nextId = 1;
  final List<Player> _players = [];
  final List<SessionRecord> _sessions = [];

  @override
  Future<Player> createPlayer(String name, {bool setActive = true}) async {
    if (setActive) {
      for (int i = 0; i < _players.length; i++) {
        _players[i] = Player(
          id: _players[i].id,
          uuid: _players[i].uuid,
          name: _players[i].name,
          isActive: false,
          createdAt: _players[i].createdAt,
        );
      }
    }
    final id = _nextId++;
    final player = Player(
      id: id,
      uuid: 'test-uuid-$id',
      name: name.trim(),
      isActive: setActive,
      createdAt: DateTime(2026),
    );
    _players.add(player);
    return player;
  }

  @override
  Future<List<Player>> getAllPlayers() async => List.of(_players);

  @override
  Future<Player?> getActivePlayer() async {
    for (final p in _players) {
      if (p.isActive) return p;
    }
    return _players.isNotEmpty ? _players.first : null;
  }

  @override
  Future<void> setActivePlayer(int playerId) async {
    for (int i = 0; i < _players.length; i++) {
      _players[i] = Player(
        id: _players[i].id,
        uuid: _players[i].uuid,
        name: _players[i].name,
        isActive: _players[i].id == playerId,
        createdAt: _players[i].createdAt,
      );
    }
  }

  @override
  Future<void> updatePlayerName(int playerId, String newName) async {
    for (int i = 0; i < _players.length; i++) {
      if (_players[i].id == playerId) {
        _players[i] = Player(
          id: _players[i].id,
          uuid: _players[i].uuid,
          name: newName.trim(),
          isActive: _players[i].isActive,
          createdAt: _players[i].createdAt,
        );
      }
    }
  }

  @override
  Future<void> deletePlayer(int playerId) async {
    final wasActive = _players.any((p) => p.id == playerId && p.isActive);
    _players.removeWhere((p) => p.id == playerId);
    _sessions.removeWhere((s) => s.playerId == playerId);
    if (wasActive && _players.isNotEmpty) {
      await setActivePlayer(_players.first.id!);
    }
  }

  @override
  Future<void> saveSessionResult(SessionRecord record) async {
    _sessions.add(record);
  }

  @override
  Future<List<SessionRecord>> getSessionHistory(int playerId) async =>
      _sessions.where((s) => s.playerId == playerId).toList();

  @override
  Future<Map<String, Map<String, dynamic>>> getAllItemProgress(
    int playerId,
  ) async {
    final map = <String, Map<String, dynamic>>{};
    for (final s in _sessions.where((s) => s.playerId == playerId)) {
      final prev = map[s.itemId];
      if (prev == null) {
        map[s.itemId] = {'best_score': s.score, 'attempts': 1};
      } else {
        final best = prev['best_score'] as int;
        map[s.itemId] = {
          'best_score': s.score > best ? s.score : best,
          'attempts': (prev['attempts'] as int) + 1,
        };
      }
    }
    return map;
  }

  @override
  Future<int> getTotalScore(int playerId) async => _sessions
      .where((s) => s.playerId == playerId)
      .fold<int>(0, (sum, s) => sum + s.score);

  @override
  Future<Map<int, int>> getAllPlayersTotalScores() async {
    final map = <int, int>{};
    for (final s in _sessions) {
      map[s.playerId] = (map[s.playerId] ?? 0) + s.score;
    }
    return map;
  }
}

void main() {
  late FakeDatabaseHelper fakeDb;

  setUp(() {
    fakeDb = FakeDatabaseHelper();
    DatabaseHelper.instance = fakeDb;
  });

  testWidgets('First launch shows PlayerInitScreen and transitions to Home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VedicMathApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Vedic Math'), findsOneWidget);

    // Empty name validation
    await tester.tap(find.text('Start Learning'));
    await tester.pump();
    expect(find.text('Please enter a player name'), findsOneWidget);

    // Create first player
    await tester.enterText(find.byType(TextFormField), 'Aarav');
    await tester.tap(find.text('Start Learning'));
    await tester.pumpAndSettle();

    expect(find.text('Vedic Mathematics'), findsOneWidget);
    expect(find.textContaining('Aarav'), findsWidgets);

    // Filter chips work
    await tester.tap(find.text('13 Sub-Sutras'));
    await tester.pumpAndSettle();
    expect(find.text('Anurupyena'), findsOneWidget);
    expect(find.text('Ekadhikena Purvena'), findsNothing);
  });

  testWidgets('ExerciseScreen scores +10 pts, runs timer, and opens Solution', (
    WidgetTester tester,
  ) async {
    final player = await fakeDb.createPlayer('Tester');
    final s1 = vedicCatalog.first;

    await tester.pumpWidget(
      MaterialApp(
        home: ExerciseScreen(item: s1, player: player),
      ),
    );
    await tester.pump();

    expect(find.text('Q 1 / 25'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);

    // Advance timer 2 seconds
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('00:02'), findsOneWidget);

    // Parse Q1 prompt and enter exact correct answer
    final promptFinder = find.textContaining('Compute ');
    final promptText = tester.widget<Text>(promptFinder).data!;
    final n = int.parse(
      RegExp(r'Compute (\d+)²').firstMatch(promptText)!.group(1)!,
    );

    await tester.enterText(find.byType(TextField), '${n * n}');
    await tester.tap(find.text('Check Answer'));
    await tester.pump();

    expect(find.text('Correct! +10 points!'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);

    // Advance to Q2 and open Solution sheet
    await tester.tap(find.text('Next Question'));
    await tester.pump();
    expect(find.text('Q 2 / 25'), findsOneWidget);

    await tester.tap(find.text('Solution'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Vedic Solution'), findsOneWidget);
  });

  testWidgets('PlayersScreen CRUD & Edit -> Cancel does not crash', (
    WidgetTester tester,
  ) async {
    await fakeDb.createPlayer('Alice');
    bool callbackFired = false;

    await tester.pumpWidget(
      MaterialApp(
        home: PlayersScreen(onPlayersChanged: () => callbackFired = true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);

    // Regression test: Edit -> Cancel must not throw controller disposed error
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Alice'), findsOneWidget);

    // Create a second player
    await tester.tap(find.text('Add Player'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Bob');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Bob'), findsOneWidget);
    expect(callbackFired, isTrue);

    // Rename Bob -> Bobby
    await tester.tap(find.byIcon(Icons.edit_outlined).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Bobby');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Bobby'), findsOneWidget);

    // Delete Bobby
    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Bobby'), findsNothing);
  });

  testWidgets('ProgressScreen renders LineChart with player scores', (
    WidgetTester tester,
  ) async {
    final player = await fakeDb.createPlayer('ChartUser');
    await fakeDb.saveSessionResult(
      SessionRecord(
        playerId: player.id!,
        itemId: 's1',
        itemTitle: 'Ekadhikena Purvena',
        score: 200,
        correctCount: 20,
        totalQuestions: 25,
        durationSeconds: 40,
        completedAt: DateTime(2026, 11, 26),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProgressScreen(player: player)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('200'), findsWidgets);
    expect(find.text('Ekadhikena Purvena'), findsOneWidget);
  });

  testWidgets('TheoryScreen shows Sutra background and launch button', (
    WidgetTester tester,
  ) async {
    final dummyPlayer = Player(
      id: 1,
      uuid: '00000000-0000-4000-8000-000000000001',
      name: 'Tester',
      isActive: true,
      createdAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TheoryScreen(item: vedicCatalog.first, player: dummyPlayer),
      ),
    );

    expect(find.text('Sutra 1'), findsOneWidget);
    expect(find.text('Theoretical Background'), findsOneWidget);
    expect(find.text('Start 25 Exercises'), findsOneWidget);
  });
}
