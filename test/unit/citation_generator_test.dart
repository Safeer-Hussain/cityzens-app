import 'package:flutter_test/flutter_test.dart';
import 'package:cityzens_app/core/utils/citation_generator.dart';
import 'package:cityzens_app/data/models/book.dart';
import 'package:cityzens_app/data/repositories/library_repository.dart';

import '../helpers/test_database.dart';

void main() {
  group('CitationGenerator Format Compliance Tests', () {
    const cleanArchBook = BookModel(
      id: 'book_01',
      isbn: '978-0134494166',
      title: "Clean Architecture: A Craftsman's Guide to Software Structure",
      author: 'Robert C. Martin',
      category: 'Software Engineering',
      shelfLocation: 'FLOOR-2 / AISLE-A / BAY-01',
      totalCopies: 6,
      availableCopies: 4,
      isReserved: false,
      abstractText: 'Universal rules of software architecture.',
      tableOfContents: ['Chapter 1', 'Chapter 2'],
      coverAsset: 'assets/images/book_clean_architecture.png',
    );

    test(
      'formatBibTeX produces valid BibTeX @book entry with required tags',
      () {
        final bibtex = CitationGenerator.formatBibTeX(cleanArchBook);

        expect(bibtex.startsWith('@book{'), isTrue);
        expect(bibtex.contains('martin2017clean'), isTrue);
        expect(bibtex.contains('author    = {Robert C. Martin}'), isTrue);
        expect(
          bibtex.contains(
            'title     = {Clean Architecture: A Craftsman\'s Guide to Software Structure}',
          ),
          isTrue,
        );
        expect(bibtex.contains('year      = {2017}'), isTrue);
        expect(bibtex.contains('publisher = {Prentice Hall}'), isTrue);
        expect(bibtex.contains('isbn      = {978-0134494166}'), isTrue);
        expect(bibtex.contains('keywords  = {Software Engineering}'), isTrue);
        expect(bibtex.trim().endsWith('}'), isTrue);
      },
    );

    test('formatApa produces valid APA 7th Edition citation', () {
      final apa = CitationGenerator.formatApa(cleanArchBook);

      expect(apa.startsWith('Martin, R. C.'), isTrue);
      expect(apa.contains('(2017).'), isTrue);
      expect(apa.contains('Prentice Hall.'), isTrue);
      expect(apa.contains('https://isbnsearch.org/isbn/9780134494166'), isTrue);
    });

    test('formatIeee produces valid IEEE reference format', () {
      final ieee = CitationGenerator.formatIeee(
        cleanArchBook,
        referenceIndex: 1,
      );

      expect(ieee.startsWith('[1] R. C. Martin,'), isTrue);
      expect(ieee.contains('Prentice Hall, 2017.'), isTrue);
      expect(ieee.contains('ISBN: 978-0134494166.'), isTrue);
    });

    test(
      'formatChicago produces valid Chicago 17th Edition bibliography entry',
      () {
        final chicago = CitationGenerator.formatChicago(cleanArchBook);

        expect(chicago.startsWith('Martin, Robert C.'), isTrue);
        expect(chicago.contains('Boston: Prentice Hall, 2017.'), isTrue);
      },
    );

    test('formatHarvard produces valid Harvard referencing entry', () {
      final harvard = CitationGenerator.formatHarvard(cleanArchBook);

      expect(harvard.startsWith('Martin, R. C.'), isTrue);
      expect(harvard.contains('(2017)'), isTrue);
      expect(harvard.contains('London: Prentice Hall.'), isTrue);
    });

    test('generateCiteKey handles multi-author and titles gracefully', () {
      const mlBook = BookModel(
        id: 'book_05',
        isbn: '978-0262035613',
        title: 'Deep Learning',
        author: 'Ian Goodfellow, Yoshua Bengio, Aaron Courville',
        category: 'AI & ML',
        shelfLocation: 'FLOOR-1',
        totalCopies: 4,
        availableCopies: 2,
        isReserved: false,
        abstractText: 'An introduction to deep learning.',
        tableOfContents: ['Ch 1'],
        coverAsset: 'assets/images/book_applied_ai.png',
      );

      final key = CitationGenerator.generateCiteKey(mlBook);
      expect(key.contains('courville'), isTrue);
      expect(key.contains('2016'), isTrue);
      expect(key.contains('deep'), isTrue);
    });

    test('generateMarkdownBibliography formats multi-volume reading list', () {
      final md = CitationGenerator.generateMarkdownBibliography(
        books: [cleanArchBook],
        style: CitationStyle.apa7,
        title: 'Software Engineering Syllabus',
      );

      expect(md.contains('# Software Engineering Syllabus'), isTrue);
      expect(md.contains('Total Volumes Referenced: 1'), isTrue);
      expect(md.contains('Citation Standard: APA 7th'), isTrue);
      expect(md.contains('1. Martin, R. C.'), isTrue);
    });
  });

  group('Catalog Completeness & Batch Citation Tests', () {
    late LibraryRepository repository;

    setUp(() async {
      final db = await createTestDatabase();
      repository = LibraryRepository(database: db);
    });

    test('All seeded catalog books generate valid non-empty citations across all styles', () async {
      final books = await repository.getBooks(category: 'All');
      expect(books.isNotEmpty, isTrue);

      for (final book in books) {
        for (final style in CitationStyle.values) {
          final citation = CitationGenerator.format(book, style);
          expect(
            citation.trim().isNotEmpty,
            isTrue,
            reason: 'Empty citation for ${book.title} in ${style.displayName}',
          );
          expect(
            citation.contains(book.isbn) ||
                citation.contains(book.isbn.replaceAll('-', '')),
            isTrue,
          );
        }
      }
    });

    test(
      'BibTeX batch bibliography outputs well-formed fenced code block',
      () async {
        final books = await repository.getBooks(category: 'All');
        final bibtexDoc = CitationGenerator.generateMarkdownBibliography(
          books: books,
          style: CitationStyle.bibtex,
        );

        expect(bibtexDoc.contains('```bibtex'), isTrue);
        expect(bibtexDoc.contains('```'), isTrue);
        expect(bibtexDoc.contains('@book{'), isTrue);
      },
    );
  });
}
