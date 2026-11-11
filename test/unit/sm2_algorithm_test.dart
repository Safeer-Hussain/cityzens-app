import 'package:flutter_test/flutter_test.dart';
import 'package:cityzens_app/core/utils/sm2_algorithm.dart';

void main() {
  group('SuperMemo-2 (SM-2) Spaced Repetition Algorithm Tests', () {
    final fixedBaseDate = DateTime(2026, 11, 11, 10, 0);

    test('Initial review with perfect quality (q=5) yields 1 day interval', () {
      final result = Sm2Algorithm.calculate(
        quality: 5,
        currentRepetitions: 0,
        currentIntervalDays: 1,
        currentEaseFactor: 2.5,
        baseDate: fixedBaseDate,
      );

      expect(result.repetitions, 1);
      expect(result.intervalDays, 1);
      expect(result.easeFactor, 2.6); // 2.5 + (0.1 - 0)
      expect(result.masteryLevel, 'reviewing');
      expect(result.nextReviewDate, fixedBaseDate.add(const Duration(days: 1)));
    });

    test(
      'Second consecutive successful review (n=1, q=4) yields 6 days interval',
      () {
        final result = Sm2Algorithm.calculate(
          quality: 4,
          currentRepetitions: 1,
          currentIntervalDays: 1,
          currentEaseFactor: 2.6,
          baseDate: fixedBaseDate,
        );

        expect(result.repetitions, 2);
        expect(result.intervalDays, 6);
        // q=4 => qDiff=1 => 2.6 + (0.1 - 1 * (0.08 + 0.02)) = 2.6 + 0.0 = 2.6
        expect(result.easeFactor, 2.6);
        expect(result.masteryLevel, 'reviewing');
        expect(
          result.nextReviewDate,
          fixedBaseDate.add(const Duration(days: 6)),
        );
      },
    );

    test(
      'Third consecutive successful review (n=2, q=5) advances to mastered',
      () {
        final result = Sm2Algorithm.calculate(
          quality: 5,
          currentRepetitions: 2,
          currentIntervalDays: 6,
          currentEaseFactor: 2.6,
          baseDate: fixedBaseDate,
        );

        expect(result.repetitions, 3);
        // Interval = round(6 * 2.7) = 16
        expect(result.intervalDays, 16);
        expect(result.easeFactor, 2.7);
        expect(result.masteryLevel, 'mastered');
        expect(
          result.nextReviewDate,
          fixedBaseDate.add(const Duration(days: 16)),
        );
      },
    );

    test(
      'Failed recall (q < 3) resets repetitions to 0 and interval to 1 day',
      () {
        final result = Sm2Algorithm.calculate(
          quality: 1,
          currentRepetitions: 4,
          currentIntervalDays: 30,
          currentEaseFactor: 2.5,
          baseDate: fixedBaseDate,
        );

        expect(result.repetitions, 0);
        expect(result.intervalDays, 1);
        expect(result.masteryLevel, 'learning');
        expect(result.easeFactor, lessThan(2.5));
        expect(
          result.nextReviewDate,
          fixedBaseDate.add(const Duration(days: 1)),
        );
      },
    );

    test(
      'Repeated poor recall strictly enforces minimum Ease Factor floor of 1.3',
      () {
        double ef = 1.4;
        for (int i = 0; i < 5; i++) {
          final result = Sm2Algorithm.calculate(
            quality: 0,
            currentRepetitions: 0,
            currentIntervalDays: 1,
            currentEaseFactor: ef,
            baseDate: fixedBaseDate,
          );
          ef = result.easeFactor;
        }

        expect(ef, 1.3);
      },
    );

    test('Hard pass (q=3) decrements Ease Factor but increments interval', () {
      final result = Sm2Algorithm.calculate(
        quality: 3,
        currentRepetitions: 2,
        currentIntervalDays: 6,
        currentEaseFactor: 2.5,
        baseDate: fixedBaseDate,
      );

      expect(result.repetitions, 3);
      // qDiff = 2 => EF' = 2.5 + (0.1 - 2 * (0.08 + 2 * 0.02)) = 2.5 + (0.1 - 0.24) = 2.36
      expect(result.easeFactor, 2.36);
      expect(result.intervalDays, (6 * 2.36).round());
      expect(result.masteryLevel, 'mastered');
    });
  });
}
