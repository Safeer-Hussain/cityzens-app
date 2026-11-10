import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/utils/citation_generator.dart';
import '../../data/models/book.dart';
import '../../data/repositories/library_repository.dart';

class LibraryProvider extends ChangeNotifier {
  final LibraryRepository repository;

  bool _isLoading = false;
  List<BookModel> _books = [];
  List<LibraryLoanItem> _activeLoans = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String? _errorMessage;
  CitationStyle _selectedCitationStyle = CitationStyle.bibtex;

  LibraryProvider({required this.repository});

  bool get isLoading => _isLoading;
  List<BookModel> get books => _books;
  List<LibraryLoanItem> get activeLoans => _activeLoans;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  CitationStyle get selectedCitationStyle => _selectedCitationStyle;

  double get totalOverdueFines {
    return _activeLoans.fold(
      0.0,
      (acc, item) => acc + item.loan.calculatedFine,
    );
  }

  int get borrowedCount => _activeLoans.length;

  Future<void> loadLibraryData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _books = await repository.getBooks(
        query: _searchQuery,
        category: _selectedCategory,
      );
      _activeLoans = await repository.getActiveLoans();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    loadBooksOnly();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadBooksOnly();
  }

  Future<void> loadBooksOnly() async {
    try {
      _books = await repository.getBooks(
        query: _searchQuery,
        category: _selectedCategory,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> renewLoan(String loanId) async {
    try {
      final updatedLoan = await repository.renewLoan(loanId);
      // Mutate list immediately via copyWith and notifyListeners
      final index = _activeLoans.indexWhere((item) => item.loan.id == loanId);
      if (index != -1) {
        final currentItem = _activeLoans[index];
        _activeLoans[index] = LibraryLoanItem(
          loan: updatedLoan,
          book: currentItem.book,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> returnBook(String loanId, String bookId) async {
    try {
      await repository.returnBook(loanId, bookId);
      _activeLoans.removeWhere((item) => item.loan.id == loanId);
      final bookIndex = _books.indexWhere((b) => b.id == bookId);
      if (bookIndex != -1) {
        final b = _books[bookIndex];
        _books[bookIndex] = b.copyWith(availableCopies: b.availableCopies + 1);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleReserve(String bookId) async {
    try {
      final updated = await repository.toggleReserveBook(bookId);
      final index = _books.indexWhere((b) => b.id == bookId);
      if (index != -1) {
        _books[index] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkoutBook(String bookId, String borrowerId) async {
    try {
      await repository.checkoutBook(bookId: bookId, borrowerId: borrowerId);
      await loadLibraryData();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setCitationStyle(CitationStyle style) {
    if (_selectedCitationStyle == style) return;
    _selectedCitationStyle = style;
    notifyListeners();
  }

  String getCitation(BookModel book, [CitationStyle? style]) {
    return CitationGenerator.format(book, style ?? _selectedCitationStyle);
  }

  String generateBatchBibliography({
    List<BookModel>? customBooks,
    CitationStyle? style,
  }) {
    final targetBooks = customBooks ?? _books;
    return CitationGenerator.generateMarkdownBibliography(
      books: targetBooks,
      style: style ?? _selectedCitationStyle,
    );
  }

  Future<void> copyCitationToClipboard(
    BookModel book, [
    CitationStyle? style,
  ]) async {
    final text = getCitation(book, style);
    await Clipboard.setData(ClipboardData(text: text));
  }

  Future<void> copyTextToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
