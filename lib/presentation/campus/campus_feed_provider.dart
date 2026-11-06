import 'package:flutter/foundation.dart';
import '../../data/models/campus_post.dart';
import '../../data/models/campus_comment.dart';
import '../../data/repositories/campus_feed_repository.dart';

class CampusFeedProvider extends ChangeNotifier {
  final CampusFeedRepository repository;

  bool _isLoading = false;
  List<CampusPostModel> _allPosts = [];
  String _selectedCategory = 'All';
  final Map<String, List<CampusCommentModel>> _commentsCache = {};
  String? _errorMessage;

  CampusFeedProvider({required this.repository});

  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String? get errorMessage => _errorMessage;

  List<CampusPostModel> get posts {
    if (_selectedCategory == 'All') return _allPosts;
    return _allPosts.where((p) => p.category == _selectedCategory).toList();
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> loadFeed() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allPosts = await repository.getPosts();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String postId) async {
    final index = _allPosts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final current = _allPosts[index];
    final optimisticLiked = !current.isLiked;
    final optimisticCount = optimisticLiked ? current.likesCount + 1 : current.likesCount - 1;

    // 1. Immediate optimistic UI mutation
    _allPosts[index] = current.copyWith(
      isLiked: optimisticLiked,
      likesCount: optimisticCount < 0 ? 0 : optimisticCount,
    );
    notifyListeners();

    // 2. Persist in background
    try {
      final updated = await repository.toggleLike(postId);
      _allPosts[index] = updated;
      notifyListeners();
    } catch (e) {
      // Revert if failed
      _allPosts[index] = current;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleBookmark(String postId) async {
    final index = _allPosts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final current = _allPosts[index];
    _allPosts[index] = current.copyWith(isBookmarked: !current.isBookmarked);
    notifyListeners();

    try {
      final updated = await repository.toggleBookmark(postId);
      _allPosts[index] = updated;
      notifyListeners();
    } catch (e) {
      _allPosts[index] = current;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  List<CampusCommentModel> getComments(String postId) {
    return _commentsCache[postId] ?? [];
  }

  Future<void> loadComments(String postId) async {
    try {
      final list = await repository.getComments(postId);
      _commentsCache[postId] = list;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> addComment({
    required String postId,
    required String content,
    String authorName = 'Safeer Hussain',
    String authorRole = 'Senior Mobile Architect / CS Honours',
  }) async {
    try {
      final comment = await repository.addComment(
        postId: postId,
        authorName: authorName,
        authorRole: authorRole,
        content: content,
      );

      final existing = _commentsCache[postId] ?? [];
      _commentsCache[postId] = [...existing, comment];

      final postIndex = _allPosts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final p = _allPosts[postIndex];
        _allPosts[postIndex] = p.copyWith(commentsCount: p.commentsCount + 1);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> publishNotice({
    required String title,
    required String content,
    required String category,
  }) async {
    try {
      final post = await repository.createPost(
        title: title,
        content: content,
        category: category,
        authorName: 'Safeer Hussain',
        authorRole: 'Senior Mobile Architect / CS Honours',
      );

      _allPosts.insert(0, post);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
