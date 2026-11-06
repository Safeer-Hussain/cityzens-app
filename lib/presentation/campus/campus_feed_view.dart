import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_feedback.dart';
import '../../data/models/campus_post.dart';
import 'campus_feed_provider.dart';
import 'widgets/digital_id_card.dart';

class CampusFeedView extends StatelessWidget {
  final VoidCallback? onOpenDebugDrawer;

  const CampusFeedView({super.key, this.onOpenDebugDrawer});

  static const List<String> _categories = [
    'All',
    'Faculty Announcement',
    'Research Group',
    'Campus Event',
    'Lab Access',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Consumer<CampusFeedProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: colors.surface,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_campus_post', // Unique Hero Tag
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            elevation: 3,
            icon: const Icon(Icons.add_comment_rounded, size: 20),
            label: const Text(
              'Publish Notice',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            onPressed: () => _showPublishNoticeSheet(context, provider),
          ),
          body: isLandscape
              ? _buildLandscapeLayout(context, provider, colors)
              : _buildPortraitLayout(context, provider, colors),
        );
      },
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    CampusFeedProvider provider,
    ColorScheme colors,
  ) {
    return RefreshIndicator(
      color: colors.primary,
      onRefresh: () => provider.loadFeed(),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          DigitalIdCard(onLongPressVersion: onOpenDebugDrawer),
          const SizedBox(height: 14),
          _buildCategoryFilters(provider, colors),
          const SizedBox(height: 12),
          Text(
            'CAMPUS DISPATCH & RESEARCH NOTICES (${provider.posts.length})',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          ...provider.posts.map((post) => _buildPostCard(context, post, provider, colors)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    CampusFeedProvider provider,
    ColorScheme colors,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left pane: ID Card & Category Filters
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DigitalIdCard(onLongPressVersion: onOpenDebugDrawer),
                const SizedBox(height: 10),
                _buildCategoryFilters(provider, colors),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
        // Right pane: Feed Notices
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'CAMPUS NOTICES & DISPATCH',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                ...provider.posts.map((post) => _buildPostCard(context, post, provider, colors)),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters(CampusFeedProvider provider, ColorScheme colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = provider.selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(cat),
              labelStyle: TextStyle(
                color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              selected: isSelected,
              selectedColor: colors.primary,
              backgroundColor: colors.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? colors.primary : colors.outlineVariant,
                ),
              ),
              showCheckmark: false,
              onSelected: (_) => provider.setCategory(cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPostCard(
    BuildContext context,
    CampusPostModel post,
    CampusFeedProvider provider,
    ColorScheme colors,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colors.primaryContainer,
                    child: Text(
                      post.authorAvatar,
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        post.authorRole,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  post.category,
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.title,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            post.content,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: colors.outlineVariant),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Like action (Reactive mutation with instant heart color & count)
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => provider.toggleLike(post.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 18,
                        color: post.isLiked ? colors.error : colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.likesCount}',
                        style: TextStyle(
                          color: post.isLiked ? colors.error : colors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Comment action
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _showCommentsSheet(context, post, provider),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 18, color: colors.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        '${post.commentsCount}',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bookmark action
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  post.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  size: 18,
                  color: post.isBookmarked ? colors.primary : colors.onSurfaceVariant,
                ),
                onPressed: () => provider.toggleBookmark(post.id),
              ),
              // Share action
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.share_outlined, size: 18, color: colors.onSurfaceVariant),
                onPressed: () => _showShareSheet(context, post),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCommentsSheet(
    BuildContext context,
    CampusPostModel post,
    CampusFeedProvider provider,
  ) {
    final colors = Theme.of(context).colorScheme;
    final commentController = TextEditingController();
    provider.loadComments(post.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Consumer<CampusFeedProvider>(
          builder: (context, feedProv, _) {
            final comments = feedProv.getComments(post.id);

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Discussion on "${post.title}"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (comments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No comments yet. Be the first to share an academic insight.',
                            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: comments.length,
                          separatorBuilder: (_, _) => Divider(color: colors.outlineVariant),
                          itemBuilder: (context, idx) {
                            final comm = comments[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        comm.authorName,
                                        style: TextStyle(
                                          color: colors.primary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        comm.authorRole,
                                        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    comm.content,
                                    style: TextStyle(color: colors.onSurface, fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: 'Write a verified response...',
                              hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                              filled: true,
                              fillColor: colors.surfaceContainer,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: colors.outlineVariant),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                          ),
                          icon: const Icon(Icons.send_rounded, size: 18),
                          onPressed: () async {
                            final text = commentController.text.trim();
                            if (text.isEmpty) return;
                            commentController.clear();
                            await feedProv.addComment(
                              postId: post.id,
                              content: text,
                            );
                            if (context.mounted) {
                              AppFeedback.showSuccess(context, 'Comment posted to SQLite ledger.');
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showShareSheet(BuildContext context, CampusPostModel post) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Share Campus Notice',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: Icon(Icons.copy_rounded, color: colors.primary),
                  title: Text('Copy Notice Content', style: TextStyle(color: colors.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: '${post.title}\n\n${post.content}'));
                    Navigator.of(sheetContext).pop();
                    AppFeedback.showSuccess(context, 'Notice copied to device clipboard.');
                  },
                ),
                Divider(color: colors.outlineVariant),
                ListTile(
                  leading: Icon(Icons.repeat_rounded, color: colors.secondary),
                  title: Text('Repost to Campus Feed', style: TextStyle(color: colors.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    AppFeedback.showSuccess(context, 'Reposted "${post.title}" to campus stream.');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPublishNoticeSheet(BuildContext context, CampusFeedProvider provider) {
    final colors = Theme.of(context).colorScheme;
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedCat = 'Faculty Announcement';
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Publish Campus Dispatch',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCat,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: _categories.where((c) => c != 'All').map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedCat = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Notice Title',
                          hintText: 'e.g. Graduate Seminar on Zero-Knowledge Proofs',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: contentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Dispatch Content',
                          hintText: 'Detailed syllabus, venue requirements, or lab clearance details.',
                          errorText: errorText,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final title = titleController.text.trim();
                          final content = contentController.text.trim();
                          if (title.length < 4 || content.length < 8) {
                            setModalState(() {
                              errorText = 'Title min 4 chars, content min 8 chars';
                            });
                            return;
                          }

                          final success = await provider.publishNotice(
                            title: title,
                            content: content,
                            category: selectedCat,
                          );

                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }

                          if (success && context.mounted) {
                            AppFeedback.showSuccess(
                              context,
                              'Notice "$title" published to campus feed.',
                            );
                          }
                        },
                        child: const Text('Publish to Campus Feed', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
