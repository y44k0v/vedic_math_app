import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vedic_math_app/data/vedic_catalog.dart';
import 'package:vedic_math_app/engine/exercise_generator.dart';
import 'package:vedic_math_app/models/vedic_models.dart';

void main() {
  group('Vedic Catalog Integrity', () {
    test('Contains all 16 Sutras and 13 Sub-Sutras with unique IDs', () {
      expect(vedicCatalog.length, 29);

      final sutras = vedicCatalog
          .where((e) => e.category == VedicCategory.sutra)
          .toList();
      final subSutras = vedicCatalog
          .where((e) => e.category == VedicCategory.subSutra)
          .toList();

      expect(sutras.length, 16);
      expect(subSutras.length, 13);

      final ids = vedicCatalog.map((e) => e.id).toSet();
      expect(ids.length, 29);

      for (final item in vedicCatalog) {
        expect(item.sanskritName, isNotEmpty);
        expect(item.translation, isNotEmpty);
        expect(item.theory, isNotEmpty);
        expect(item.examples, isNotEmpty);
      }
    });
  });

  group('ExerciseGenerator Uniqueness & Anti-Repetition', () {
    test('All 29 modules produce 25 unique exercises in a session', () {
      final generator = ExerciseGenerator();

      for (final item in vedicCatalog) {
        final session = generator.generateSession(item.id, count: 25);
        expect(session.length, 25, reason: '${item.id} did not return 25');

        final uniquePrompts = session.map((p) => p.prompt).toSet();
        expect(
          uniquePrompts.length,
          25,
          reason: '${item.id} produced duplicate prompts inside one session',
        );

        for (final p in session) {
          expect(p.primaryAnswer, isNotEmpty);
          expect(p.solutionSteps, isNotEmpty);
          expect(p.hint, isNotEmpty);
        }
      }
    });

    test(
      'Consecutive sessions do not repeat identical questions immediately',
      () {
        final generator = ExerciseGenerator();
        for (final id in ['s1', 's3', 's10', 'ss7', 'ss12']) {
          final s1 = generator.generateSession(id, count: 25);
          final s2 = generator.generateSession(id, count: 25);
          final set1 = s1.map((e) => e.prompt).toSet();
          final set2 = s2.map((e) => e.prompt).toSet();
          final overlap = set1.intersection(set2);
          expect(
            overlap.length,
            lessThan(10),
            reason: 'Too much overlap between consecutive sessions for $id',
          );
        }
      },
    );
  });

  group('Mathematical Correctness Verification', () {
    final generator = ExerciseGenerator();

    test('s1 (Ekadhikena) squares match N*N', () {
      for (final p in generator.generateSession('s1', count: 25)) {
        final n = int.parse(
          RegExp(r'Compute (\d+)²').firstMatch(p.prompt)!.group(1)!,
        );
        expect(n % 10, 5);
        expect(int.parse(p.primaryAnswer), n * n);
      }
    });

    test('s2 (Nikhilam Subtraction) matches base - sub', () {
      for (final p in generator.generateSession('s2', count: 25)) {
        final m = RegExp(r'Compute (\d+) - (\d+)').firstMatch(p.prompt)!;
        final base = int.parse(m.group(1)!);
        final sub = int.parse(m.group(2)!);
        expect(int.parse(p.primaryAnswer), base - sub);
      }
    });

    test(
      's3, s13, s14, ss1, ss4, ss6, ss8 multiplication products are exact',
      () {
        for (final id in ['s3', 's13', 's14', 'ss1', 'ss4', 'ss6', 'ss8']) {
          for (final p in generator.generateSession(id, count: 25)) {
            final m = RegExp(r'(\d+)\s*×\s*(\d+)').firstMatch(p.prompt)!;
            final a = int.parse(m.group(1)!);
            final b = int.parse(m.group(2)!);
            expect(int.parse(p.primaryAnswer), a * b, reason: 'Failed on $id');
          }
        }
      },
    );

    test('s4 (Paravartya) division satisfies dividend = divisor * Q + R', () {
      for (final p in generator.generateSession('s4', count: 25)) {
        expect(p.answerType, AnswerType.quotientRemainder);
        final m = RegExp(r'Divide: (\d+) ÷ (\d+)').firstMatch(p.prompt)!;
        final dividend = int.parse(m.group(1)!);
        final divisor = int.parse(m.group(2)!);
        final q = int.parse(p.primaryAnswer);
        final r = int.parse(p.secondaryAnswer!);
        expect(divisor * q + r, dividend);
        expect(r, inInclusiveRange(0, divisor - 1));
      }
    });

    test('s10 (Cubing) and ss7 (Squaring) powers are exact', () {
      for (final p in generator.generateSession('s10', count: 25)) {
        final n = int.parse(
          RegExp(r'Compute (\d+)³').firstMatch(p.prompt)!.group(1)!,
        );
        expect(int.parse(p.primaryAnswer), n * n * n);
      }
      for (final p in generator.generateSession('ss7', count: 25)) {
        final n = int.parse(
          RegExp(r'Square: (\d+)²').firstMatch(p.prompt)!.group(1)!,
        );
        expect(int.parse(p.primaryAnswer), n * n);
      }
    });

    test('ss5 (Vestanam) Yes/No matches modulo divisibility', () {
      for (final p in generator.generateSession('ss5', count: 25)) {
        expect(p.answerType, AnswerType.booleanYesNo);
        final m = RegExp(r'Is (\d+) divisible by (\d+)\?')
            .firstMatch(p.prompt)!;
        final n = int.parse(m.group(1)!);
        final d = int.parse(m.group(2)!);
        expect(p.primaryAnswer, n % d == 0 ? 'Yes' : 'No');
      }
    });

    test('ss12 (Vilokanam) exact square and cube roots match', () {
      for (final p in generator.generateSession('ss12', count: 25)) {
        final ans = int.parse(p.primaryAnswer);
        if (p.prompt.contains('√')) {
          final sq = int.parse(
            RegExp(r'√(\d+)').firstMatch(p.prompt)!.group(1)!,
          );
          expect(ans * ans, sq);
        } else {
          final cube = int.parse(
            RegExp(r'∛(\d+)').firstMatch(p.prompt)!.group(1)!,
          );
          expect(pow(ans, 3), cube);
        }
      }
    });

    test('MathProblem JSON serialization round-trip preserves all fields', () {
      final original = generator.generateSession('s4', count: 1).first;
      final restored = MathProblem.fromJson(original.toJson());
      expect(restored.prompt, original.prompt);
      expect(restored.answerType, original.answerType);
      expect(restored.primaryAnswer, original.primaryAnswer);
      expect(restored.secondaryAnswer, original.secondaryAnswer);
      expect(restored.solutionSteps, original.solutionSteps);
      expect(restored.hint, original.hint);
    });
  });
}
