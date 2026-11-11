class FlashcardDeckModel {
  final String id;
  final String title;
  final String category;
  final String description;
  final int cardCount;
  final double masteryPercentage;
  final String colorHex;
  final int createdAt;

  const FlashcardDeckModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    this.cardCount = 0,
    this.masteryPercentage = 0.0,
    required this.colorHex,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'card_count': cardCount,
      'mastery_percentage': masteryPercentage,
      'color_hex': colorHex,
      'created_at': createdAt,
    };
  }

  factory FlashcardDeckModel.fromMap(Map<String, dynamic> map) {
    return FlashcardDeckModel(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      description: map['description'] as String,
      cardCount: (map['card_count'] as num?)?.toInt() ?? 0,
      masteryPercentage: (map['mastery_percentage'] as num?)?.toDouble() ?? 0.0,
      colorHex: map['color_hex'] as String,
      createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
    );
  }

  FlashcardDeckModel copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    int? cardCount,
    double? masteryPercentage,
    String? colorHex,
    int? createdAt,
  }) {
    return FlashcardDeckModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      cardCount: cardCount ?? this.cardCount,
      masteryPercentage: masteryPercentage ?? this.masteryPercentage,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
