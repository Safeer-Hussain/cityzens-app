class BookLoanModel {
  final String id;
  final String bookId;
  final String borrowerId;
  final int borrowDate;
  final int dueDate;
  final bool isReturned;
  final int renewalCount;
  final double overdueFine;

  const BookLoanModel({
    required this.id,
    required this.bookId,
    required this.borrowerId,
    required this.borrowDate,
    required this.dueDate,
    required this.isReturned,
    required this.renewalCount,
    required this.overdueFine,
  });

  DateTime get borrowDateTime =>
      DateTime.fromMillisecondsSinceEpoch(borrowDate);
  DateTime get dueDateTime => DateTime.fromMillisecondsSinceEpoch(dueDate);

  int get daysRemaining {
    final now = DateTime.now();
    final difference = dueDateTime.difference(now).inHours / 24.0;
    return difference.ceil();
  }

  bool get isOverdue => daysRemaining < 0 && !isReturned;

  double get calculatedFine {
    if (isReturned) return overdueFine;
    final now = DateTime.now();
    if (now.isAfter(dueDateTime)) {
      final daysLate = (now.difference(dueDateTime).inHours / 24.0).ceil();
      return double.parse((daysLate * 0.50).toStringAsFixed(2));
    }
    return 0.0;
  }

  BookLoanModel copyWith({
    String? id,
    String? bookId,
    String? borrowerId,
    int? borrowDate,
    int? dueDate,
    bool? isReturned,
    int? renewalCount,
    double? overdueFine,
  }) {
    return BookLoanModel(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      borrowerId: borrowerId ?? this.borrowerId,
      borrowDate: borrowDate ?? this.borrowDate,
      dueDate: dueDate ?? this.dueDate,
      isReturned: isReturned ?? this.isReturned,
      renewalCount: renewalCount ?? this.renewalCount,
      overdueFine: overdueFine ?? this.overdueFine,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'borrower_id': borrowerId,
      'borrow_date': borrowDate,
      'due_date': dueDate,
      'is_returned': isReturned ? 1 : 0,
      'renewal_count': renewalCount,
      'overdue_fine': overdueFine,
    };
  }

  factory BookLoanModel.fromMap(Map<String, dynamic> map) {
    return BookLoanModel(
      id: map['id'] as String,
      bookId: map['book_id'] as String,
      borrowerId: map['borrower_id'] as String,
      borrowDate: (map['borrow_date'] as num).toInt(),
      dueDate: (map['due_date'] as num).toInt(),
      isReturned: (map['is_returned'] as num?) == 1,
      renewalCount: (map['renewal_count'] as num).toInt(),
      overdueFine: (map['overdue_fine'] as num).toDouble(),
    );
  }
}
