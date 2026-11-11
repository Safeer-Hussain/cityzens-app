import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/app_feedback.dart';
import '../../data/models/flashcard.dart';
import '../../data/models/flashcard_deck.dart';
import 'flashcard_provider.dart';
import 'widgets/flashcard_study_modal.dart';
import 'widgets/retention_analytics_card.dart';

class FlashcardDeckBuilderView extends StatefulWidget {
  const FlashcardDeckBuilderView({super.key});

  @override
  State<FlashcardDeckBuilderView> createState() =>
      _FlashcardDeckBuilderViewState();
}

class _FlashcardDeckBuilderViewState extends State<FlashcardDeckBuilderView> {
  final ScrollController _leftScrollController = ScrollController();
  final ScrollController _rightScrollController = ScrollController();
  final ScrollController _portraitScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FlashcardProvider>();
      if (provider.decks.isEmpty) {
        provider.loadData();
      }
    });
  }

  @override
  void dispose() {
    _leftScrollController.dispose();
    _rightScrollController.dispose();
    _portraitScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isLandscape ? 36.0 : 48.0),
        child: AppBar(
          toolbarHeight: isLandscape ? 36.0 : 48.0,
          backgroundColor: colors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              size: isLandscape ? 18 : 22,
              color: colors.onSurface,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'SM-2 Flashcard Deck Builder',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: isLandscape ? 13 : 16,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'New Deck',
              icon: Icon(
                Icons.create_new_folder_outlined,
                size: isLandscape ? 16 : 20,
                color: colors.primary,
              ),
              onPressed: () => _showCreateDeckDialog(context),
            ),
            IconButton(
              tooltip: 'Spaced Review All Due',
              icon: Icon(
                Icons.play_circle_outline_rounded,
                size: isLandscape ? 16 : 20,
                color: colors.secondary,
              ),
              onPressed: () => _launchReviewSession(context),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_flashcard_deck_builder',
        onPressed: () => _showAddCardDialog(context),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Add Card',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Consumer<FlashcardProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.decks.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: colors.primary),
            );
          }

          if (isLandscape) {
            return _buildLandscapeMasterDetail(context, provider, colors);
          }

          return _buildPortraitLayout(context, provider, colors);
        },
      ),
    );
  }

  Widget _buildLandscapeMasterDetail(
    BuildContext context,
    FlashcardProvider provider,
    ColorScheme colors,
  ) {
    return Row(
      children: [
        // Left Master Pane: Deck Selector
        SizedBox(
          width: 280,
          child: SingleChildScrollView(
            controller: _leftScrollController,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DECKS & CATEGORIES',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    InkWell(
                      onTap: () => _showCreateDeckDialog(context),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 14,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'New',
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...provider.decks.map(
                  (deck) => _buildDeckSelectorCard(
                    context: context,
                    deck: deck,
                    isSelected: deck.id == provider.selectedDeckId,
                    provider: provider,
                    colors: colors,
                  ),
                ),
              ],
            ),
          ),
        ),
        VerticalDivider(width: 1, color: colors.outlineVariant),

        // Right Detail Pane: Selected Deck & Cards & Analytics
        Expanded(
          child: SingleChildScrollView(
            controller: _rightScrollController,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDeckHeaderBanner(context, provider, colors),
                const SizedBox(height: 12),
                RetentionAnalyticsCard(stats: provider.retentionStats),
                const SizedBox(height: 12),
                _buildCardListHeader(context, provider, colors),
                const SizedBox(height: 8),
                _buildCardsGrid(provider, colors),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    FlashcardProvider provider,
    ColorScheme colors,
  ) {
    return SingleChildScrollView(
      controller: _portraitScrollController,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Horizontal Deck Selector Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: provider.decks.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final deck = provider.decks[index];
                final isSelected = deck.id == provider.selectedDeckId;
                return FilterChip(
                  selected: isSelected,
                  onSelected: (_) => provider.selectDeck(deck.id),
                  avatar: Icon(
                    Icons.style_outlined,
                    size: 14,
                    color: isSelected ? colors.onPrimary : colors.primary,
                  ),
                  label: Text('${deck.title} (${deck.cardCount})'),
                  labelStyle: TextStyle(
                    color: isSelected ? colors.onPrimary : colors.onSurface,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11,
                  ),
                  backgroundColor: colors.surfaceContainer,
                  selectedColor: colors.primary,
                  side: BorderSide(
                    color: isSelected ? colors.primary : colors.outlineVariant,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildDeckHeaderBanner(context, provider, colors),
          const SizedBox(height: 14),
          RetentionAnalyticsCard(stats: provider.retentionStats),
          const SizedBox(height: 14),
          _buildCardListHeader(context, provider, colors),
          const SizedBox(height: 8),
          _buildCardsGrid(provider, colors),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDeckSelectorCard({
    required BuildContext context,
    required FlashcardDeckModel deck,
    required bool isSelected,
    required FlashcardProvider provider,
    required ColorScheme colors,
  }) {
    return InkWell(
      onTap: () => provider.selectDeck(deck.id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryContainer.withValues(alpha: 0.3)
              : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.primary : colors.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _parseColor(deck.colorHex),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    deck.title,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              deck.category,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${deck.cardCount} cards',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${deck.masteryPercentage.toStringAsFixed(0)}% Mastered',
                  style: TextStyle(
                    color: colors.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckHeaderBanner(
    BuildContext context,
    FlashcardProvider provider,
    ColorScheme colors,
  ) {
    final deck = provider.selectedDeck;
    if (deck == null) return const SizedBox.shrink();

    final dueCount = provider.dueCardsForSelectedDeck.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  deck.category.toUpperCase(),
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (dueCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: colors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.alarm_rounded, size: 12, color: colors.error),
                      const SizedBox(width: 4),
                      Text(
                        '$dueCount Due for Review',
                        style: TextStyle(
                          color: colors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            deck.title,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            deck.description,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: FilledButton.icon(
                  onPressed: () =>
                      _launchReviewSession(context, deckId: deck.id),
                  icon: const Icon(Icons.psychology_outlined, size: 16),
                  label: Text(
                    dueCount > 0
                        ? 'Review ($dueCount)'
                        : 'Practice (${deck.cardCount})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddCardDialog(context, deckId: deck.id),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: const Text(
                    'Add Card',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardListHeader(
    BuildContext context,
    FlashcardProvider provider,
    ColorScheme colors,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.view_carousel_outlined,
                size: 16,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'ACTIVE FLASHCARDS (${provider.currentDeckCards.length})',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'SM-2 Repetitions',
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildCardsGrid(FlashcardProvider provider, ColorScheme colors) {
    if (provider.currentDeckCards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(
              Icons.style_outlined,
              size: 32,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'No flashcards in this deck yet',
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "Add Card" to begin composing spaced repetition cards.',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return Column(
      children: provider.currentDeckCards.map((card) {
        return _buildCardItem(card, colors);
      }).toList(),
    );
  }

  Widget _buildCardItem(FlashcardModel card, ColorScheme colors) {
    final masteryColor = _getMasteryColor(card.masteryLevel, colors);
    final isDue = card.isDueForReview;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDue
              ? colors.error.withValues(alpha: 0.5)
              : colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: masteryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  card.masteryLevel.toUpperCase(),
                  style: TextStyle(
                    color: masteryColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDue)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'DUE',
                        style: TextStyle(
                          color: colors.error,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  Text(
                    'Interval: ${card.intervalDays}d • EF: ${card.easeFactor.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            card.front,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            card.back,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getMasteryColor(String level, ColorScheme colors) {
    switch (level) {
      case 'mastered':
        return colors.secondary;
      case 'reviewing':
        return colors.tertiary;
      default:
        return colors.primary;
    }
  }

  Color _parseColor(String hex) {
    try {
      final value = int.parse(hex);
      return Color(value);
    } catch (_) {
      return const Color(0xFF0D9488);
    }
  }

  void _launchReviewSession(BuildContext context, {String? deckId}) {
    final provider = context.read<FlashcardProvider>();
    provider.startReviewSession(deckId: deckId);

    if (provider.activeReviewCards.isEmpty) {
      AppFeedback.showInfo(
        context,
        'No cards available in this deck to review.',
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FlashcardStudyModal(),
    );
  }

  void _showCreateDeckDialog(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final titleController = TextEditingController();
    final categoryController = TextEditingController(text: 'Algorithms');
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Create Flashcard Deck',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Deck Title',
                      hintText: 'e.g. Distributed Consensus',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Deck title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      hintText: 'e.g. Distributed Systems',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Category is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Core concepts covered in this deck',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final provider = context.read<FlashcardProvider>();
                  final success = await provider.createDeck(
                    title: titleController.text,
                    category: categoryController.text,
                    description: descController.text,
                    colorHex: '0xFF0D9488',
                  );
                  if (dialogCtx.mounted) {
                    Navigator.of(dialogCtx).pop();
                    if (success) {
                      AppFeedback.showSuccess(
                        context,
                        'Flashcard deck created successfully.',
                      );
                    }
                  }
                }
              },
              child: const Text('Create Deck'),
            ),
          ],
        );
      },
    );
  }

  void _showAddCardDialog(BuildContext context, {String? deckId}) {
    final colors = Theme.of(context).colorScheme;
    final provider = context.read<FlashcardProvider>();
    final targetDeckId = deckId ?? provider.selectedDeckId;

    if (targetDeckId == null && provider.decks.isEmpty) {
      AppFeedback.showWarning(context, 'Please create a deck first.');
      return;
    }

    final frontController = TextEditingController();
    final backController = TextEditingController();
    final hintController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Add Flashcard',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: frontController,
                    decoration: const InputDecoration(
                      labelText: 'Question Prompt (Front)',
                      hintText: 'What is the amortized complexity...',
                    ),
                    maxLines: 2,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Question is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: backController,
                    decoration: const InputDecoration(
                      labelText: 'Solution / Answer (Back)',
                      hintText: 'Detailed explanation...',
                    ),
                    maxLines: 3,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Answer is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: hintController,
                    decoration: const InputDecoration(
                      labelText: 'Hint (Optional)',
                      hintText: 'e.g. Consider aggregate analysis',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final success = await provider.addCard(
                    front: frontController.text,
                    back: backController.text,
                    hint: hintController.text,
                    deckId: targetDeckId,
                  );
                  if (dialogCtx.mounted) {
                    Navigator.of(dialogCtx).pop();
                    if (success) {
                      AppFeedback.showSuccess(
                        context,
                        'Flashcard added to deck with SM-2 schedule.',
                      );
                    }
                  }
                }
              },
              child: const Text('Add Card'),
            ),
          ],
        );
      },
    );
  }
}
