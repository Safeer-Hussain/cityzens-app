import 'package:sqflite/sqflite.dart';
import '../../core/database/app_database.dart';
import '../models/campus_post.dart';
import '../models/campus_comment.dart';

class CampusFeedRepository {
  final AppDatabase database;

  CampusFeedRepository({required this.database});

  Database get _db => database.db;

  Future<List<CampusPostModel>> getPosts() async {
    final results = await _db.query('campus_posts', orderBy: 'timestamp DESC');
    return results.map((m) => CampusPostModel.fromMap(m)).toList();
  }

  Future<CampusPostModel?> getPostById(String id) async {
    final results = await _db.query('campus_posts', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) return null;
    return CampusPostModel.fromMap(results.first);
  }

  Future<CampusPostModel> toggleLike(String postId) async {
    final post = await getPostById(postId);
    if (post == null) throw Exception('Post not found: $postId');

    final newIsLiked = !post.isLiked;
    final newLikesCount = newIsLiked ? post.likesCount + 1 : post.likesCount - 1;

    final updated = post.copyWith(
      isLiked: newIsLiked,
      likesCount: newLikesCount < 0 ? 0 : newLikesCount,
    );

    await _db.update(
      'campus_posts',
      {
        'is_liked': updated.isLiked ? 1 : 0,
        'likes_count': updated.likesCount,
      },
      where: 'id = ?',
      whereArgs: [postId],
    );

    return updated;
  }

  Future<CampusPostModel> toggleBookmark(String postId) async {
    final post = await getPostById(postId);
    if (post == null) throw Exception('Post not found: $postId');

    final updated = post.copyWith(isBookmarked: !post.isBookmarked);

    await _db.update(
      'campus_posts',
      {'is_bookmarked': updated.isBookmarked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [postId],
    );

    return updated;
  }

  Future<List<CampusCommentModel>> getComments(String postId) async {
    final results = await _db.query(
      'campus_comments',
      where: 'post_id = ?',
      whereArgs: [postId],
      orderBy: 'timestamp ASC',
    );
    return results.map((m) => CampusCommentModel.fromMap(m)).toList();
  }

  Future<CampusCommentModel> addComment({
    required String postId,
    required String authorName,
    required String authorRole,
    required String content,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final commentId = 'comm_${DateTime.now().microsecondsSinceEpoch}';

    final comment = CampusCommentModel(
      id: commentId,
      postId: postId,
      authorName: authorName,
      authorRole: authorRole,
      content: content,
      timestamp: now,
    );

    await _db.transaction((txn) async {
      await txn.insert('campus_comments', comment.toMap());

      // Update post comments count
      final postRaw = await txn.query('campus_posts', where: 'id = ?', whereArgs: [postId]);
      if (postRaw.isNotEmpty) {
        final currentCount = (postRaw.first['comments_count'] as num).toInt();
        await txn.update(
          'campus_posts',
          {'comments_count': currentCount + 1},
          where: 'id = ?',
          whereArgs: [postId],
        );
      }
    });

    return comment;
  }

  Future<CampusPostModel> createPost({
    required String title,
    required String content,
    required String category,
    required String authorName,
    required String authorRole,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final postId = 'post_${DateTime.now().microsecondsSinceEpoch}';
    final avatar = authorName
        .split(' ')
        .take(2)
        .map((s) => s.isNotEmpty ? s[0].toUpperCase() : '')
        .join();

    final post = CampusPostModel(
      id: postId,
      authorName: authorName,
      authorRole: authorRole,
      authorAvatar: avatar.isEmpty ? 'SH' : avatar,
      title: title,
      content: content,
      category: category,
      timestamp: now,
      likesCount: 0,
      isLiked: false,
      commentsCount: 0,
      isBookmarked: false,
    );

    await _db.insert('campus_posts', post.toMap());
    return post;
  }
}
