class FlashcardReviewModel {
  final String id;
  final String cardId;
  final String deckId;
  final int quality;
  final int intervalDays;
  final double easeFactor;
  final int reviewedAt;

  const FlashcardReviewModel({
    required this.id,
    required this.cardId,
    required this.deckId,
    required this.quality,
    required this.intervalDays,
    required this.easeFactor,
    required this.reviewedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_id': cardId,
      'deck_id': deckId,
      'quality': quality,
      'interval_days': intervalDays,
      'ease_factor': easeFactor,
      'reviewed_at': reviewedAt,
    };
  }

  factory FlashcardReviewModel.fromMap(Map<String, dynamic> map) {
    return FlashcardReviewModel(
      id: map['id'] as String,
      cardId: map['card_id'] as String,
      deckId: map['deck_id'] as String,
      quality: (map['quality'] as num).toInt(),
      intervalDays: (map['interval_days'] as num).toInt(),
      easeFactor: (map['ease_factor'] as num).toDouble(),
      reviewedAt: (map['reviewed_at'] as num).toInt(),
    );
  }
}
