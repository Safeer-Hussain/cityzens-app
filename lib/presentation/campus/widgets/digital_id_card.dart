import 'package:flutter/material.dart';

import '../../gpa_calculator/gpa_calculator_view.dart';
import '../../exam/exam_hall_pass_view.dart';
import '../../study_room/study_room_booking_view.dart';
import '../../flashcards/flashcard_deck_builder_view.dart';

class DigitalIdCard extends StatelessWidget {
  final VoidCallback? onLongPressVersion;

  const DigitalIdCard({super.key, this.onLongPressVersion});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.secondary],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: colors.onPrimary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'CITYZENS SMART CAMPUS ID',
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                Text(
                  'ACADEMIC 2026/2027',
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: 0.9),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Avatar
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.primary, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'SH',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Safeer Hussain',
                                style: TextStyle(
                                  color: colors.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: colors.secondary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Senior Mobile Architect  •  CS Honours',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: CTZ-2026-8842',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: colors.outlineVariant),
                const SizedBox(height: 8),
                // CGPA & Honors row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const GpaCalculatorView(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: _buildIdStat(
                          label: 'Cumulative CGPA',
                          value: '3.94 / 4.00',
                          subtext: 'Tap for What-If',
                          colors: colors,
                          color: colors.secondary,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: colors.outlineVariant,
                    ),
                    _buildIdStat(
                      label: 'Security Tier',
                      value: 'Tier 1 Clearance',
                      subtext: '24/7 Lab Access',
                      colors: colors,
                      color: colors.primary,
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: colors.outlineVariant,
                    ),
                    _buildIdStat(
                      label: 'Total Credits',
                      value: '136 / 140',
                      subtext: 'Senior Thesis Done',
                      colors: colors,
                      color: colors.tertiary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // What-If Simulator Shortcut Action
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const GpaCalculatorView(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calculate_outlined,
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Open Semester GPA & Honors Simulator',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Exam Hall Pass & Seat Finder Shortcut Action
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ExamHallPassView(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.secondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 14,
                          color: colors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Exam Hall Pass & Seat Finder',
                          style: TextStyle(
                            color: colors.secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Peer Study Room Booking Shortcut Action
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StudyRoomBookingView(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.tertiary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.tertiary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.meeting_room_outlined,
                          size: 14,
                          color: colors.tertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Peer Study Room Booking (Floors 1-4)',
                          style: TextStyle(
                            color: colors.tertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Quick Access 4: Flashcard Deck Builder (SM-2 Spaced Repetition)
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FlashcardDeckBuilderView(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.secondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          size: 14,
                          color: colors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Flashcard Deck Builder (SuperMemo-2 Spaced Repetition)',
                          style: TextStyle(
                            color: colors.secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: colors.outlineVariant),
                const SizedBox(height: 4),
                // Long-press version bar
                GestureDetector(
                  onLongPress: onLongPressVersion,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    alignment: Alignment.center,
                    child: Text(
                      'Cityzens v1.0.0+1 (Android SDK 36 • Impeller Safe) [Long Press for Recruiter Hub]',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdStat({
    required String label,
    required String value,
    required String subtext,
    required ColorScheme colors,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 9),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        Text(
          subtext,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 8),
        ),
      ],
    );
  }
}
