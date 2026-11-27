import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vedic_math_app/data/vedic_catalog.dart';
import 'package:vedic_math_app/database/db_helper.dart';
import 'package:vedic_math_app/main.dart';
import 'package:vedic_math_app/models/vedic_models.dart';
import 'package:vedic_math_app/screens/exercise_screen.dart';
import 'package:vedic_math_app/screens/players_screen.dart';
import 'package:vedic_math_app/screens/progress_screen.dart';
import 'package:vedic_math_app/screens/theory_screen.dart';

void main() {
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('vedic_ui_test_');
    await databaseFactory.setDatabasesPath(tempDir.path);
    await DatabaseHelper.instance.resetForTesting();
  });

  tearDown(() async {
    await DatabaseHelper.instance.resetForTesting();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> flushRealAsync(WidgetTester tester) async {
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('First launch shows PlayerInitScreen and transitions to Home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const VedicMathApp());
    await flushRealAsync(tester);

    expect(find.text('Welcome to Vedic Math'), findsOneWidget);

    // Empty name validation
    await tester.tap(find.text('Start Learning'));
    await tester.pump();
    expect(find.text('Please enter a player name'), findsOneWidget);

    // Create first player
    await tester.enterText(find.byType(TextFormField), 'Aarav');
    await tester.tap(find.text('Start Learning'));
    await flushRealAsync(tester);

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
    final player = await tester.runAsync(
      () => DatabaseHelper.instance.createPlayer('Tester'),
    );
    final s1 = vedicCatalog.first;

    await tester.pumpWidget(
      MaterialApp(
        home: ExerciseScreen(item: s1, player: player!),
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
    await tester.runAsync(() => DatabaseHelper.instance.createPlayer('Alice'));
    bool callbackFired = false;

    await tester.pumpWidget(
      MaterialApp(
        home: PlayersScreen(onPlayersChanged: () => callbackFired = true),
      ),
    );
    await flushRealAsync(tester);

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
    await flushRealAsync(tester);

    expect(find.text('Bob'), findsOneWidget);
    expect(callbackFired, isTrue);

    // Delete Bob
    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await flushRealAsync(tester);

    expect(find.text('Bob'), findsNothing);
  });

  testWidgets('ProgressScreen renders LineChart with player scores', (
    WidgetTester tester,
  ) async {
    final player = await tester.runAsync(() async {
      final p = await DatabaseHelper.instance.createPlayer('ChartUser');
      await DatabaseHelper.instance.saveSessionResult(
        SessionRecord(
          playerId: p.id!,
          itemId: 's1',
          itemTitle: 'Ekadhikena Purvena',
          score: 200,
          correctCount: 20,
          totalQuestions: 25,
          durationSeconds: 40,
          completedAt: DateTime(2026, 11, 26),
        ),
      );
      return p;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProgressScreen(player: player!)),
      ),
    );
    await flushRealAsync(tester);

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
