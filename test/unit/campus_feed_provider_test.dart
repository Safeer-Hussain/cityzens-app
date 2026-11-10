import 'package:flutter_test/flutter_test.dart';
import 'package:cityzens_app/data/repositories/campus_feed_repository.dart';
import 'package:cityzens_app/presentation/campus/campus_feed_provider.dart';

import '../helpers/test_database.dart';

void main() {
  group('CampusFeedProvider Tests', () {
    late CampusFeedProvider provider;
    late CampusFeedRepository repository;

    setUp(() async {
      final db = await createTestDatabase();
      repository = CampusFeedRepository(database: db);
      provider = CampusFeedProvider(repository: repository);
      await provider.loadFeed();
    });

    test('Initializes with seeded campus posts', () {
      expect(provider.posts.isNotEmpty, isTrue);
      expect(provider.posts.first.title, contains('Distributed Consensus'));
      expect(provider.posts.first.likesCount, equals(10));
      expect(provider.posts.first.isLiked, isFalse);
    });

    test(
      'toggleLike optimistically increments like count and toggles state',
      () async {
        final postId = provider.posts.first.id;
        final initialCount = provider.posts.first.likesCount;

        await provider.toggleLike(postId);
        expect(provider.posts.first.isLiked, isTrue);
        expect(provider.posts.first.likesCount, equals(initialCount + 1));

        // Toggle off
        await provider.toggleLike(postId);
        expect(provider.posts.first.isLiked, isFalse);
        expect(provider.posts.first.likesCount, equals(initialCount));
      },
    );

    test('toggleBookmark toggles post bookmark flag', () async {
      final postId = provider.posts.first.id;
      expect(provider.posts.first.isBookmarked, isFalse);

      await provider.toggleBookmark(postId);
      expect(provider.posts.first.isBookmarked, isTrue);

      await provider.toggleBookmark(postId);
      expect(provider.posts.first.isBookmarked, isFalse);
    });

    test('addComment creates comment and increments commentsCount', () async {
      final postId = provider.posts.first.id;
      final initialComments = provider.posts.first.commentsCount;

      final success = await provider.addComment(
        postId: postId,
        content: 'Is this workshop open to juniors as well?',
      );

      expect(success, isTrue);
      expect(provider.posts.first.commentsCount, equals(initialComments + 1));
      final comments = provider.getComments(postId);
      expect(comments.any((c) => c.content.contains('juniors')), isTrue);
    });

    test(
      'publishNotice prepends newly created dispatch to posts list',
      () async {
        final initialCount = provider.posts.length;

        final success = await provider.publishNotice(
          title: 'Impeller Engine Optimization Seminar',
          content: 'Technical analysis of Metal & Vulkan pipeline caching.',
          category: 'Research Group',
        );

        expect(success, isTrue);
        expect(provider.posts.length, equals(initialCount + 1));
        expect(
          provider.posts.first.title,
          equals('Impeller Engine Optimization Seminar'),
        );
      },
    );
  });
}
