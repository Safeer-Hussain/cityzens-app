class CampusCommentModel {
  final String id;
  final String postId;
  final String authorName;
  final String authorRole;
  final String content;
  final int timestamp;

  const CampusCommentModel({
    required this.id,
    required this.postId,
    required this.authorName,
    required this.authorRole,
    required this.content,
    required this.timestamp,
  });

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_id': postId,
      'author_name': authorName,
      'author_role': authorRole,
      'content': content,
      'timestamp': timestamp,
    };
  }

  factory CampusCommentModel.fromMap(Map<String, dynamic> map) {
    return CampusCommentModel(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      authorName: map['author_name'] as String,
      authorRole: map['author_role'] as String,
      content: map['content'] as String,
      timestamp: (map['timestamp'] as num).toInt(),
    );
  }
}
