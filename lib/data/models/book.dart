import 'dart:convert';

class BookModel {
  final String id;
  final String isbn;
  final String title;
  final String author;
  final String category;
  final String shelfLocation;
  final int totalCopies;
  final int availableCopies;
  final bool isReserved;
  final String abstractText;
  final List<String> tableOfContents;
  final String coverAsset;

  const BookModel({
    required this.id,
    required this.isbn,
    required this.title,
    required this.author,
    required this.category,
    required this.shelfLocation,
    required this.totalCopies,
    required this.availableCopies,
    required this.isReserved,
    required this.abstractText,
    required this.tableOfContents,
    required this.coverAsset,
  });

  bool get isAvailable => availableCopies > 0;

  BookModel copyWith({
    String? id,
    String? isbn,
    String? title,
    String? author,
    String? category,
    String? shelfLocation,
    int? totalCopies,
    int? availableCopies,
    bool? isReserved,
    String? abstractText,
    List<String>? tableOfContents,
    String? coverAsset,
  }) {
    return BookModel(
      id: id ?? this.id,
      isbn: isbn ?? this.isbn,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      shelfLocation: shelfLocation ?? this.shelfLocation,
      totalCopies: totalCopies ?? this.totalCopies,
      availableCopies: availableCopies ?? this.availableCopies,
      isReserved: isReserved ?? this.isReserved,
      abstractText: abstractText ?? this.abstractText,
      tableOfContents: tableOfContents ?? this.tableOfContents,
      coverAsset: coverAsset ?? this.coverAsset,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isbn': isbn,
      'title': title,
      'author': author,
      'category': category,
      'shelf_location': shelfLocation,
      'total_copies': totalCopies,
      'available_copies': availableCopies,
      'is_reserved': isReserved ? 1 : 0,
      'abstract': abstractText,
      'table_of_contents': jsonEncode(tableOfContents),
      'cover_asset': coverAsset,
    };
  }

  factory BookModel.fromMap(Map<String, dynamic> map) {
    List<String> toc = [];
    final tocRaw = map['table_of_contents'];
    if (tocRaw is String) {
      try {
        final decoded = jsonDecode(tocRaw);
        if (decoded is List) {
          toc = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        toc = [tocRaw];
      }
    } else if (tocRaw is List) {
      toc = tocRaw.map((e) => e.toString()).toList();
    }

    return BookModel(
      id: map['id'] as String,
      isbn: map['isbn'] as String,
      title: map['title'] as String,
      author: map['author'] as String,
      category: map['category'] as String,
      shelfLocation: map['shelf_location'] as String,
      totalCopies: (map['total_copies'] as num).toInt(),
      availableCopies: (map['available_copies'] as num).toInt(),
      isReserved: (map['is_reserved'] as num?) == 1,
      abstractText: (map['abstract'] ?? '') as String,
      tableOfContents: toc,
      coverAsset: (map['cover_asset'] ?? 'assets/images/book_clean_architecture.png') as String,
    );
  }
}
