import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../flashcard_provider.dart';

class FlashcardStudyModal extends StatefulWidget {
  const FlashcardStudyModal({super.key});

  @override
  State<FlashcardStudyModal> createState() => _FlashcardStudyModalState();
}

class _FlashcardStudyModalState extends State<FlashcardStudyModal> {
  bool _showHint = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Consumer<FlashcardProvider>(
      builder: (context, provider, _) {
        final card = provider.currentReviewCard;
        final totalCards = provider.activeReviewCards.length;
        final currentIndex = provider.currentReviewCardIndex;

        // If review session completed
        if (!provider.isReviewing || card == null) {
          return Dialog(
            backgroundColor: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.military_tech_rounded,
                      color: colors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Review Session Complete',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All scheduled cards have been processed with SuperMemo-2 optimal intervals.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryStat(
                          label: 'Cards Reviewed',
                          value: '${provider.sessionCardsReviewed}',
                          color: colors.primary,
                          colors: colors,
                        ),
                        _buildSummaryStat(
                          label: 'Next Interval',
                          value: 'Adaptive',
                          color: colors.secondary,
                          colors: colors,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        provider.exitReviewSession();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Return to Deck Hub'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Dialog(
          backgroundColor: colors.surface,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 32 : 16,
            vertical: isLandscape ? 12 : 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: isLandscape ? 330 : 650,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Navigation Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Card ${currentIndex + 1} of $totalCards',
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: colors.outlineVariant),
                          ),
                          child: Text(
                            'EF: ${card.easeFactor.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: colors.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () {
                            provider.exitReviewSession();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Linear Progress Indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalCards > 0 ? (currentIndex + 1) / totalCards : 0,
                    minHeight: 4,
                    backgroundColor: colors.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(colors.primary),
                  ),
                ),
                const SizedBox(height: 12),

                // Card Content Area (Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card Container
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'QUESTION PROMPT',
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getMasteryColor(
                                        card.masteryLevel,
                                        colors,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      card.masteryLevel.toUpperCase(),
                                      style: TextStyle(
                                        color: _getMasteryColor(
                                          card.masteryLevel,
                                          colors,
                                        ),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                card.front,
                                style: TextStyle(
                                  color: colors.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                              if (card.hint.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _showHint = !_showHint;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _showHint
                                              ? Icons.visibility_off_outlined
                                              : Icons.lightbulb_outline_rounded,
                                          size: 13,
                                          color: colors.tertiary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _showHint ? 'Hide Hint' : 'View Hint',
                                          style: TextStyle(
                                            color: colors.tertiary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_showHint) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: colors.outlineVariant,
                                      ),
                                    ),
                                    child: Text(
                                      card.hint,
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ],

                              // Answer Section
                              if (provider.isAnswerRevealed) ...[
                                const SizedBox(height: 16),
                                Divider(color: colors.outlineVariant),
                                const SizedBox(height: 10),
                                Text(
                                  'DETAILED SOLUTION',
                                  style: TextStyle(
                                    color: colors.secondary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  card.back,
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Action Controls Bottom Area
                if (!provider.isAnswerRevealed) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        provider.toggleRevealAnswer();
                      },
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: const Text('Reveal Solution'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GRADE RECALL ACCURACY (SM-2 QUALITY)',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildGradeChip(
                            quality: 0,
                            label: '0: Blackout',
                            color: colors.error,
                            colors: colors,
                            onTap: () => _handleGrade(0, provider),
                          ),
                          _buildGradeChip(
                            quality: 1,
                            label: '1: Wrong',
                            color: colors.error,
                            colors: colors,
                            onTap: () => _handleGrade(1, provider),
                          ),
                          _buildGradeChip(
                            quality: 2,
                            label: '2: Hard Fail',
                            color: colors.error.withValues(alpha: 0.8),
                            colors: colors,
                            onTap: () => _handleGrade(2, provider),
                          ),
                          _buildGradeChip(
                            quality: 3,
                            label: '3: Hard Pass',
                            color: colors.tertiary,
                            colors: colors,
                            onTap: () => _handleGrade(3, provider),
                          ),
                          _buildGradeChip(
                            quality: 4,
                            label: '4: Good',
                            color: colors.primary,
                            colors: colors,
                            onTap: () => _handleGrade(4, provider),
                          ),
                          _buildGradeChip(
                            quality: 5,
                            label: '5: Perfect',
                            color: colors.secondary,
                            colors: colors,
                            onTap: () => _handleGrade(5, provider),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleGrade(int quality, FlashcardProvider provider) {
    setState(() {
      _showHint = false;
    });
    provider.submitCardGrade(quality);
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

  Widget _buildGradeChip({
    required int quality,
    required String label,
    required Color color,
    required ColorScheme colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStat({
    required String label,
    required String value,
    required Color color,
    required ColorScheme colors,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
        ),
      ],
    );
  }
}
