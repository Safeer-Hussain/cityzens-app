import 'dart:math';

/// Result data structure for a SuperMemo-2 (SM-2) algorithm evaluation.
class Sm2Result {
  final int repetitions;
  final int intervalDays;
  final double easeFactor;
  final DateTime nextReviewDate;
  final String masteryLevel;

  const Sm2Result({
    required this.repetitions,
    required this.intervalDays,
    required this.easeFactor,
    required this.nextReviewDate,
    required this.masteryLevel,
  });
}

/// SuperMemo-2 (SM-2) spaced repetition algorithm implementation.
///
/// Features:
/// - Response grade quality q in range 0..5
/// - Ease Factor (EF) modification with a hard floor of 1.3
/// - Interval calculation: 1 day, 6 days, or previous_interval * EF
/// - Automatic mastery level state resolution ('learning', 'reviewing', 'mastered')
class Sm2Algorithm {
  static const double initialEaseFactor = 2.5;
  static const double minEaseFactor = 1.3;
  static const int minPassingGrade = 3;

  Sm2Algorithm._();

  /// Calculates the next spaced repetition schedule given the user's recall quality [quality].
  ///
  /// [quality]:
  /// - 5: Perfect recall
  /// - 4: Correct response after hesitation
  /// - 3: Correct response with serious difficulty
  /// - 2: Incorrect response; correct answer seemed easy
  /// - 1: Incorrect response; remembered upon seeing answer
  /// - 0: Complete blackout
  static Sm2Result calculate({
    required int quality,
    required int currentRepetitions,
    required int currentIntervalDays,
    required double currentEaseFactor,
    DateTime? baseDate,
  }) {
    final clampedQuality = quality.clamp(0, 5);
    final now = baseDate ?? DateTime.now();

    // 1. Calculate updated Ease Factor (EF)
    // Formula: EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    final qDiff = 5 - clampedQuality;
    final newEaseFactorCalculated =
        currentEaseFactor + (0.1 - (qDiff * (0.08 + (qDiff * 0.02))));
    final updatedEaseFactor = max(minEaseFactor, newEaseFactorCalculated);

    // 2. Calculate interval and repetition count
    int updatedRepetitions;
    int updatedIntervalDays;

    if (clampedQuality < minPassingGrade) {
      // Failed recall: reset repetitions and schedule for tomorrow
      updatedRepetitions = 0;
      updatedIntervalDays = 1;
    } else {
      // Successful recall: increment repetitions and compute interval
      if (currentRepetitions == 0) {
        updatedIntervalDays = 1;
      } else if (currentRepetitions == 1) {
        updatedIntervalDays = 6;
      } else {
        updatedIntervalDays = max(
          1,
          (currentIntervalDays * updatedEaseFactor).round(),
        );
      }
      updatedRepetitions = currentRepetitions + 1;
    }

    // 3. Resolve mastery level
    final String masteryLevel;
    if (updatedRepetitions == 0 || clampedQuality < minPassingGrade) {
      masteryLevel = 'learning';
    } else if (updatedRepetitions < 3) {
      masteryLevel = 'reviewing';
    } else {
      masteryLevel = 'mastered';
    }

    final nextReviewDate = now.add(Duration(days: updatedIntervalDays));

    return Sm2Result(
      repetitions: updatedRepetitions,
      intervalDays: updatedIntervalDays,
      easeFactor: double.parse(updatedEaseFactor.toStringAsFixed(2)),
      nextReviewDate: nextReviewDate,
      masteryLevel: masteryLevel,
    );
  }
}
