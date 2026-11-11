import 'package:flutter_test/flutter_test.dart';
import 'package:cityzens_app/data/repositories/flashcard_repository.dart';
import 'package:cityzens_app/presentation/flashcards/flashcard_provider.dart';

import '../helpers/test_database.dart';

void main() {
  group('FlashcardProvider & Repository SM-2 Tests', () {
    late FlashcardRepository repository;
    late FlashcardProvider provider;

    setUp(() async {
      final db = await createTestDatabase();
      repository = FlashcardRepository(database: db);
      provider = FlashcardProvider(repository: repository);
    });

    test(
      'Loads pre-seeded category decks and computes initial metrics',
      () async {
        await provider.loadData();

        expect(provider.decks.length, greaterThanOrEqualTo(3));
        final algoDeck = provider.decks.firstWhere((d) => d.id == 'deck_algo');
        expect(algoDeck.title, 'Algorithms & Complexity');
        expect(algoDeck.category, 'Algorithms');
        expect(algoDeck.cardCount, greaterThan(0));

        expect(provider.selectedDeckId, 'deck_algo');
        expect(provider.currentDeckCards.isNotEmpty, true);
      },
    );

    test('Switching selected deck loads associated cards correctly', () async {
      await provider.loadData();
      provider.selectDeck('deck_dist');

      expect(provider.selectedDeckId, 'deck_dist');
      expect(provider.selectedDeck?.title, 'Distributed Systems & Consensus');
      for (final card in provider.currentDeckCards) {
        expect(card.deckId, 'deck_dist');
      }
    });

    test(
      'Creating a new deck persists to SQLite and can be selected',
      () async {
        await provider.loadData();

        final created = await provider.createDeck(
          title: 'Machine Learning & Neural Nets',
          category: 'Artificial Intelligence',
          description: 'Transformers, Backpropagation, and Attention heads',
          colorHex: '0xFF8B5CF6',
        );

        expect(created, true);
        expect(provider.selectedDeck?.title, 'Machine Learning & Neural Nets');
        expect(provider.currentDeckCards, isEmpty);
      },
    );

    test(
      'Adding a card to current deck updates card count and deck metrics',
      () async {
        await provider.loadData();
        provider.selectDeck('deck_mobile');

        final initialCount = provider.currentDeckCards.length;
        final added = await provider.addCard(
          front: 'What is SkSL warming in legacy Skia?',
          back:
              'Pre-warming shader binaries to reduce runtime compilation jank.',
          hint: 'Replaced by Impeller.',
        );

        expect(added, true);
        expect(provider.currentDeckCards.length, initialCount + 1);
        final newCard = provider.currentDeckCards.firstWhere(
          (c) => c.front.contains('SkSL'),
        );
        expect(newCard.hint, 'Replaced by Impeller.');
        expect(newCard.repetitions, 0);
        expect(newCard.masteryLevel, 'learning');
      },
    );

    test(
      'Review session advances card, updates SM-2 metrics and persists review',
      () async {
        await provider.loadData();
        provider.selectDeck('deck_algo');

        provider.startReviewSession(deckId: 'deck_algo');
        expect(provider.isReviewing, true);
        expect(provider.activeReviewCards.isNotEmpty, true);
        expect(provider.isAnswerRevealed, false);

        provider.toggleRevealAnswer();
        expect(provider.isAnswerRevealed, true);

        final currentCardId = provider.currentReviewCard!.id;
        // Grade quality 5 (Perfect)
        await provider.submitCardGrade(5);

        expect(provider.sessionCardsReviewed, 1);
        expect(provider.isAnswerRevealed, false);

        // Verify card was updated in database
        final updatedCards = await repository.getCardsForDeck('deck_algo');
        final updatedCard = updatedCards.firstWhere(
          (c) => c.id == currentCardId,
        );
        expect(updatedCard.repetitions, greaterThanOrEqualTo(1));
        expect(updatedCard.easeFactor, greaterThan(2.0));
      },
    );

    test(
      'Retention stats calculate accurate metrics across SQLite records',
      () async {
        await provider.loadData();

        final stats = provider.retentionStats;
        expect(stats.containsKey('totalCards'), true);
        expect(stats.containsKey('retentionRate'), true);
        expect(stats.containsKey('avgEaseFactor'), true);
        expect(stats.containsKey('weeklyReviews'), true);

        expect((stats['totalCards'] as int), greaterThanOrEqualTo(5));
        expect((stats['retentionRate'] as double), greaterThan(0.0));
        expect((stats['avgEaseFactor'] as double), greaterThanOrEqualTo(1.3));
      },
    );
  });
}
