class FlashcardModel {
  final String id;
  final String deckId;
  final String front;
  final String back;
  final String hint;
  final int repetitions;
  final int intervalDays;
  final double easeFactor;
  final int nextReviewDate;
  final int? lastReviewedDate;
  final String masteryLevel; // 'learning', 'reviewing', 'mastered'
  final int createdAt;

  const FlashcardModel({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.hint,
    this.repetitions = 0,
    this.intervalDays = 1,
    this.easeFactor = 2.5,
    required this.nextReviewDate,
    this.lastReviewedDate,
    this.masteryLevel = 'learning',
    required this.createdAt,
  });

  bool get isDueForReview {
    final now = DateTime.now().millisecondsSinceEpoch;
    return nextReviewDate <= now;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deck_id': deckId,
      'front': front,
      'back': back,
      'hint': hint,
      'repetitions': repetitions,
      'interval_days': intervalDays,
      'ease_factor': easeFactor,
      'next_review_date': nextReviewDate,
      'last_reviewed_date': lastReviewedDate,
      'mastery_level': masteryLevel,
      'created_at': createdAt,
    };
  }

  factory FlashcardModel.fromMap(Map<String, dynamic> map) {
    return FlashcardModel(
      id: map['id'] as String,
      deckId: map['deck_id'] as String,
      front: map['front'] as String,
      back: map['back'] as String,
      hint: (map['hint'] as String?) ?? '',
      repetitions: (map['repetitions'] as num?)?.toInt() ?? 0,
      intervalDays: (map['interval_days'] as num?)?.toInt() ?? 1,
      easeFactor: (map['ease_factor'] as num?)?.toDouble() ?? 2.5,
      nextReviewDate: (map['next_review_date'] as num?)?.toInt() ?? 0,
      lastReviewedDate: (map['last_reviewed_date'] as num?)?.toInt(),
      masteryLevel: (map['mastery_level'] as String?) ?? 'learning',
      createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
    );
  }

  FlashcardModel copyWith({
    String? id,
    String? deckId,
    String? front,
    String? back,
    String? hint,
    int? repetitions,
    int? intervalDays,
    double? easeFactor,
    int? nextReviewDate,
    int? lastReviewedDate,
    String? masteryLevel,
    int? createdAt,
  }) {
    return FlashcardModel(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      hint: hint ?? this.hint,
      repetitions: repetitions ?? this.repetitions,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewedDate: lastReviewedDate ?? this.lastReviewedDate,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
