import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vedic_math_app/data/vedic_catalog.dart';
import 'package:vedic_math_app/engine/exercise_generator.dart';
import 'package:vedic_math_app/screens/theory_screen.dart';

void main() {
  test('All 29 Sutras and Sub-Sutras generate 25 valid exercises', () {
    final generator = ExerciseGenerator();

    expect(vedicCatalog.length, 29);

    for (final item in vedicCatalog) {
      for (int i = 0; i < 25; i++) {
        final problem = generator.generate(item.id, i);
        expect(problem.prompt, isNotEmpty);
        expect(problem.primaryAnswer, isNotEmpty);
        expect(problem.solutionSteps, isNotEmpty);
      }
    }
  });

  testWidgets('TheoryScreen renders Sutra details and drill button', (
    WidgetTester tester,
  ) async {
    final firstSutra = vedicCatalog.first;

    await tester.pumpWidget(MaterialApp(home: TheoryScreen(item: firstSutra)));

    expect(find.text('Sutra 1'), findsOneWidget);
    expect(find.text(firstSutra.sanskritName), findsOneWidget);
    expect(find.text('Start 25 Exercises'), findsOneWidget);
  });
}
