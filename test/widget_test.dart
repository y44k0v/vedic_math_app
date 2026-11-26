import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vedic_math_app/data/vedic_catalog.dart';
import 'package:vedic_math_app/engine/exercise_generator.dart';
import 'package:vedic_math_app/models/vedic_models.dart';
import 'package:vedic_math_app/screens/theory_screen.dart';

void main() {
  test('All 29 modules generate 25 unique exercises per session', () {
    final generator = ExerciseGenerator();

    expect(vedicCatalog.length, 29);

    for (final item in vedicCatalog) {
      final session = generator.generateSession(item.id, count: 25);
      expect(session.length, 25);
      final uniquePrompts = session.map((p) => p.prompt).toSet();
      expect(uniquePrompts.length, 25, reason: 'Duplicate in ${item.id}');
    }
  });

  testWidgets('TheoryScreen renders Sutra details and drill button', (
    WidgetTester tester,
  ) async {
    final firstSutra = vedicCatalog.first;
    final dummyPlayer = Player(
      id: 1,
      uuid: '00000000-0000-4000-8000-000000000001',
      name: 'Tester',
      isActive: true,
      createdAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TheoryScreen(item: firstSutra, player: dummyPlayer),
      ),
    );

    expect(find.text('Sutra 1'), findsOneWidget);
    expect(find.text(firstSutra.sanskritName), findsOneWidget);
    expect(find.text('Start 25 Exercises'), findsOneWidget);
  });
}
