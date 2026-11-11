import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/utils/sm2_algorithm.dart';
import '../models/flashcard.dart';
import '../models/flashcard_deck.dart';
import '../models/flashcard_review.dart';

class FlashcardRepository {
  final AppDatabase database;

  FlashcardRepository({required this.database});

  Database get _db => database.db;

  Future<List<FlashcardDeckModel>> getDecks() async {
    final results = await _db.query(
      'flashcard_decks',
      orderBy: 'created_at ASC',
    );
    return results.map((m) => FlashcardDeckModel.fromMap(m)).toList();
  }

  Future<FlashcardDeckModel?> getDeckById(String deckId) async {
    final results = await _db.query(
      'flashcard_decks',
      where: 'id = ?',
      whereArgs: [deckId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return FlashcardDeckModel.fromMap(results.first);
  }

  Future<List<FlashcardModel>> getCardsForDeck(String deckId) async {
    final results = await _db.query(
      'flashcards',
      where: 'deck_id = ?',
      whereArgs: [deckId],
      orderBy: 'next_review_date ASC',
    );
    return results.map((m) => FlashcardModel.fromMap(m)).toList();
  }

  Future<List<FlashcardModel>> getDueCardsForDeck(String deckId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final results = await _db.query(
      'flashcards',
      where: 'deck_id = ? AND next_review_date <= ?',
      whereArgs: [deckId, now],
      orderBy: 'next_review_date ASC',
    );
    return results.map((m) => FlashcardModel.fromMap(m)).toList();
  }

  Future<List<FlashcardModel>> getAllDueCards() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final results = await _db.query(
      'flashcards',
      where: 'next_review_date <= ?',
      whereArgs: [now],
      orderBy: 'next_review_date ASC',
    );
    return results.map((m) => FlashcardModel.fromMap(m)).toList();
  }

  Future<void> createDeck(FlashcardDeckModel deck) async {
    await _db.insert(
      'flashcard_decks',
      deck.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addCard(FlashcardModel card) async {
    await _db.insert(
      'flashcards',
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _recalculateDeckMetrics(card.deckId);
  }

  Future<void> recordCardReview({
    required String cardId,
    required String deckId,
    required int quality,
    required Sm2Result sm2Result,
  }) async {
    final now = DateTime.now();

    // 1. Update card in SQLite
    await _db.update(
      'flashcards',
      {
        'repetitions': sm2Result.repetitions,
        'interval_days': sm2Result.intervalDays,
        'ease_factor': sm2Result.easeFactor,
        'next_review_date': sm2Result.nextReviewDate.millisecondsSinceEpoch,
        'last_reviewed_date': now.millisecondsSinceEpoch,
        'mastery_level': sm2Result.masteryLevel,
      },
      where: 'id = ?',
      whereArgs: [cardId],
    );

    // 2. Insert review log
    final review = FlashcardReviewModel(
      id: 'rev_${now.microsecondsSinceEpoch}_${Random().nextInt(1000)}',
      cardId: cardId,
      deckId: deckId,
      quality: quality,
      intervalDays: sm2Result.intervalDays,
      easeFactor: sm2Result.easeFactor,
      reviewedAt: now.millisecondsSinceEpoch,
    );
    await _db.insert('flashcard_reviews', review.toMap());

    // 3. Recalculate deck stats
    await _recalculateDeckMetrics(deckId);
  }

  Future<void> _recalculateDeckMetrics(String deckId) async {
    final cards = await getCardsForDeck(deckId);
    if (cards.isEmpty) {
      await _db.update(
        'flashcard_decks',
        {'card_count': 0, 'mastery_percentage': 0.0},
        where: 'id = ?',
        whereArgs: [deckId],
      );
      return;
    }

    final totalCards = cards.length;
    final masteredCount = cards
        .where((c) => c.masteryLevel == 'mastered')
        .length;
    final masteryPercentage = double.parse(
      ((masteredCount / totalCards) * 100.0).toStringAsFixed(1),
    );

    await _db.update(
      'flashcard_decks',
      {'card_count': totalCards, 'mastery_percentage': masteryPercentage},
      where: 'id = ?',
      whereArgs: [deckId],
    );
  }

  Future<Map<String, dynamic>> getRetentionStats() async {
    final allCardsResult = await _db.query('flashcards');
    final allCards = allCardsResult
        .map((m) => FlashcardModel.fromMap(m))
        .toList();

    final allReviewsResult = await _db.query('flashcard_reviews');
    final allReviews = allReviewsResult
        .map((m) => FlashcardReviewModel.fromMap(m))
        .toList();

    final totalCards = allCards.length;
    final masteredCards = allCards
        .where((c) => c.masteryLevel == 'mastered')
        .length;
    final reviewingCards = allCards
        .where((c) => c.masteryLevel == 'reviewing')
        .length;
    final learningCards = allCards
        .where((c) => c.masteryLevel == 'learning')
        .length;
    final dueCards = allCards.where((c) => c.isDueForReview).length;

    final double avgEaseFactor;
    if (allCards.isNotEmpty) {
      final sumEf = allCards.fold<double>(0.0, (acc, c) => acc + c.easeFactor);
      avgEaseFactor = double.parse((sumEf / totalCards).toStringAsFixed(2));
    } else {
      avgEaseFactor = 2.5;
    }

    final double retentionRate;
    if (allReviews.isNotEmpty) {
      final passingReviews = allReviews.where((r) => r.quality >= 3).length;
      retentionRate = double.parse(
        ((passingReviews / allReviews.length) * 100.0).toStringAsFixed(1),
      );
    } else {
      retentionRate = 100.0;
    }

    // Daily reviews distribution over last 7 days
    final now = DateTime.now();
    final List<Map<String, dynamic>> weeklyReviews = [];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));
      final nextDay = day.add(const Duration(days: 1));

      final dayCount = allReviews.where((r) {
        final reviewDate = DateTime.fromMillisecondsSinceEpoch(r.reviewedAt);
        return reviewDate.isAfter(day) && reviewDate.isBefore(nextDay);
      }).length;

      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final weekdayStr = dayNames[day.weekday - 1];

      weeklyReviews.add({'day': weekdayStr, 'count': dayCount});
    }

    return {
      'totalCards': totalCards,
      'masteredCards': masteredCards,
      'reviewingCards': reviewingCards,
      'learningCards': learningCards,
      'dueCards': dueCards,
      'avgEaseFactor': avgEaseFactor,
      'retentionRate': retentionRate,
      'weeklyReviews': weeklyReviews,
    };
  }
}
