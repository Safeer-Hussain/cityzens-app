import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/utils/sm2_algorithm.dart';
import '../../data/models/flashcard.dart';
import '../../data/models/flashcard_deck.dart';
import '../../data/repositories/flashcard_repository.dart';

class FlashcardProvider extends ChangeNotifier {
  final FlashcardRepository repository;

  bool _isLoading = false;
  List<FlashcardDeckModel> _decks = [];
  String? _selectedDeckId;
  Map<String, List<FlashcardModel>> _deckCardsMap = {};
  List<FlashcardModel> _allDueCards = [];
  Map<String, dynamic> _retentionStats = {};
  String? _errorMessage;

  // Review session state
  bool _isReviewing = false;
  int _currentReviewCardIndex = 0;
  List<FlashcardModel> _activeReviewCards = [];
  bool _isAnswerRevealed = false;
  int _sessionCardsReviewed = 0;

  FlashcardProvider({required this.repository});

  bool get isLoading => _isLoading;
  List<FlashcardDeckModel> get decks => _decks;
  String? get selectedDeckId => _selectedDeckId;
  List<FlashcardModel> get currentDeckCards =>
      _deckCardsMap[_selectedDeckId] ?? [];
  List<FlashcardModel> get allDueCards => _allDueCards;
  Map<String, dynamic> get retentionStats => _retentionStats;
  String? get errorMessage => _errorMessage;

  bool get isReviewing => _isReviewing;
  int get currentReviewCardIndex => _currentReviewCardIndex;
  List<FlashcardModel> get activeReviewCards => _activeReviewCards;
  bool get isAnswerRevealed => _isAnswerRevealed;
  int get sessionCardsReviewed => _sessionCardsReviewed;

  FlashcardDeckModel? get selectedDeck {
    if (_selectedDeckId == null || _decks.isEmpty) return null;
    return _decks.firstWhere(
      (d) => d.id == _selectedDeckId,
      orElse: () => _decks.first,
    );
  }

  List<FlashcardModel> get dueCardsForSelectedDeck {
    return currentDeckCards.where((c) => c.isDueForReview).toList();
  }

  FlashcardModel? get currentReviewCard {
    if (!_isReviewing || _activeReviewCards.isEmpty) return null;
    if (_currentReviewCardIndex >= _activeReviewCards.length) return null;
    return _activeReviewCards[_currentReviewCardIndex];
  }

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _decks = await repository.getDecks();
      if (_decks.isNotEmpty && _selectedDeckId == null) {
        _selectedDeckId = _decks.first.id;
      }

      final Map<String, List<FlashcardModel>> cardsMap = {};
      for (final deck in _decks) {
        cardsMap[deck.id] = await repository.getCardsForDeck(deck.id);
      }
      _deckCardsMap = cardsMap;

      _allDueCards = await repository.getAllDueCards();
      _retentionStats = await repository.getRetentionStats();
    } catch (e) {
      _errorMessage = 'Failed to load flashcard decks: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDeck(String deckId) {
    if (_selectedDeckId == deckId) return;
    _selectedDeckId = deckId;
    notifyListeners();
  }

  Future<bool> createDeck({
    required String title,
    required String category,
    required String description,
    required String colorHex,
  }) async {
    if (title.trim().isEmpty || category.trim().isEmpty) {
      _errorMessage = 'Deck title and category are required.';
      notifyListeners();
      return false;
    }

    try {
      final now = DateTime.now();
      final newDeck = FlashcardDeckModel(
        id: 'deck_${now.microsecondsSinceEpoch}_${Random().nextInt(1000)}',
        title: title.trim(),
        category: category.trim(),
        description: description.trim(),
        cardCount: 0,
        masteryPercentage: 0.0,
        colorHex: colorHex,
        createdAt: now.millisecondsSinceEpoch,
      );

      await repository.createDeck(newDeck);
      _selectedDeckId = newDeck.id;
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create deck: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addCard({
    required String front,
    required String back,
    required String hint,
    String? deckId,
  }) async {
    final targetDeckId = deckId ?? _selectedDeckId;
    if (targetDeckId == null) {
      _errorMessage = 'No deck selected.';
      notifyListeners();
      return false;
    }

    if (front.trim().isEmpty || back.trim().isEmpty) {
      _errorMessage = 'Card question (front) and answer (back) are required.';
      notifyListeners();
      return false;
    }

    try {
      final now = DateTime.now();
      final newCard = FlashcardModel(
        id: 'fc_${now.microsecondsSinceEpoch}_${Random().nextInt(1000)}',
        deckId: targetDeckId,
        front: front.trim(),
        back: back.trim(),
        hint: hint.trim(),
        repetitions: 0,
        intervalDays: 1,
        easeFactor: 2.5,
        nextReviewDate: now.millisecondsSinceEpoch,
        masteryLevel: 'learning',
        createdAt: now.millisecondsSinceEpoch,
      );

      await repository.addCard(newCard);
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add card: $e';
      notifyListeners();
      return false;
    }
  }

  void startReviewSession({String? deckId}) {
    final targetCards = deckId != null
        ? currentDeckCards.where((c) => c.isDueForReview).toList()
        : _allDueCards;

    // If no due cards, review all cards in current deck to practice
    final sessionCards = targetCards.isNotEmpty
        ? List<FlashcardModel>.from(targetCards)
        : List<FlashcardModel>.from(currentDeckCards);

    if (sessionCards.isEmpty) return;

    _activeReviewCards = sessionCards;
    _currentReviewCardIndex = 0;
    _isAnswerRevealed = false;
    _sessionCardsReviewed = 0;
    _isReviewing = true;
    notifyListeners();
  }

  void toggleRevealAnswer() {
    _isAnswerRevealed = !_isAnswerRevealed;
    notifyListeners();
  }

  Future<void> submitCardGrade(int quality) async {
    final card = currentReviewCard;
    if (card == null) return;

    final sm2Result = Sm2Algorithm.calculate(
      quality: quality,
      currentRepetitions: card.repetitions,
      currentIntervalDays: card.intervalDays,
      currentEaseFactor: card.easeFactor,
    );

    await repository.recordCardReview(
      cardId: card.id,
      deckId: card.deckId,
      quality: quality,
      sm2Result: sm2Result,
    );

    _sessionCardsReviewed++;
    _isAnswerRevealed = false;

    if (_currentReviewCardIndex + 1 < _activeReviewCards.length) {
      _currentReviewCardIndex++;
    } else {
      // Completed all cards in session
      _isReviewing = false;
      await loadData();
    }
    notifyListeners();
  }

  void exitReviewSession() {
    _isReviewing = false;
    _activeReviewCards = [];
    _currentReviewCardIndex = 0;
    _isAnswerRevealed = false;
    notifyListeners();
  }
}
