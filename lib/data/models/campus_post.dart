class CampusPostModel {
  final String id;
  final String authorName;
  final String authorRole;
  final String authorAvatar;
  final String title;
  final String content;
  final String category;
  final int timestamp;
  final int likesCount;
  final bool isLiked;
  final int commentsCount;
  final bool isBookmarked;

  const CampusPostModel({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.authorAvatar,
    required this.title,
    required this.content,
    required this.category,
    required this.timestamp,
    required this.likesCount,
    required this.isLiked,
    required this.commentsCount,
    required this.isBookmarked,
  });

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  CampusPostModel copyWith({
    String? id,
    String? authorName,
    String? authorRole,
    String? authorAvatar,
    String? title,
    String? content,
    String? category,
    int? timestamp,
    int? likesCount,
    bool? isLiked,
    int? commentsCount,
    bool? isBookmarked,
  }) {
    return CampusPostModel(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      commentsCount: commentsCount ?? this.commentsCount,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'author_name': authorName,
      'author_role': authorRole,
      'author_avatar': authorAvatar,
      'title': title,
      'content': content,
      'category': category,
      'timestamp': timestamp,
      'likes_count': likesCount,
      'is_liked': isLiked ? 1 : 0,
      'comments_count': commentsCount,
      'is_bookmarked': isBookmarked ? 1 : 0,
    };
  }

  factory CampusPostModel.fromMap(Map<String, dynamic> map) {
    return CampusPostModel(
      id: map['id'] as String,
      authorName: map['author_name'] as String,
      authorRole: map['author_role'] as String,
      authorAvatar: (map['author_avatar'] ?? 'SH') as String,
      title: map['title'] as String,
      content: map['content'] as String,
      category: map['category'] as String,
      timestamp: (map['timestamp'] as num).toInt(),
      likesCount: (map['likes_count'] as num).toInt(),
      isLiked: (map['is_liked'] as num?) == 1,
      commentsCount: (map['comments_count'] as num).toInt(),
      isBookmarked: (map['is_bookmarked'] as num?) == 1,
    );
  }
}
