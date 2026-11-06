import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_feedback.dart';
import '../../data/models/academic_transcript.dart';
import 'gpa_calculator_provider.dart';

class GpaCalculatorView extends StatelessWidget {
  const GpaCalculatorView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Consumer<GpaCalculatorProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.transcripts.isEmpty) {
          return Scaffold(
            backgroundColor: colors.surface,
            appBar: _buildAppBar(context, colors, isLandscape),
            body: Center(child: CircularProgressIndicator(color: colors.primary)),
          );
        }

        return Scaffold(
          backgroundColor: colors.surface,
          appBar: _buildAppBar(context, colors, isLandscape),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_gpa_simulate', // Unique Hero Tag
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            elevation: 3,
            icon: const Icon(Icons.playlist_add_check_rounded, size: 20),
            label: const Text(
              'Commit Semester',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            onPressed: () => _showCommitDialog(context, provider),
          ),
          body: isLandscape
              ? _buildLandscapeLayout(context, provider, colors)
              : _buildPortraitLayout(context, provider, colors),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ColorScheme colors, bool isLandscape) {
    return PreferredSize(
      preferredSize: Size.fromHeight(isLandscape ? 36.0 : 48.0),
      child: AppBar(
        toolbarHeight: isLandscape ? 36.0 : 48.0,
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'Semester GPA & CGPA What-If Simulator',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: isLandscape ? 13 : 16,
          ),
        ),
        actions: [
          Consumer<GpaCalculatorProvider>(
            builder: (context, prov, _) {
              return IconButton(
                tooltip: 'Reset Simulation to Defaults',
                icon: Icon(Icons.refresh_rounded, size: isLandscape ? 16 : 20, color: colors.onSurfaceVariant),
                onPressed: () {
                  prov.resetSimulation();
                  AppFeedback.showInfo(context, 'Reset simulation to default course load.');
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    GpaCalculatorProvider provider,
    ColorScheme colors,
  ) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildSummaryGaugeCard(provider, colors),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'WHAT-IF COURSE SIMULATION (${provider.simulatedCourses.length} COURSES)',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(Icons.add_rounded, size: 16, color: colors.primary),
              label: Text(
                'Add Course',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => _showAddCourseSheet(context, provider),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...provider.simulatedCourses.map((c) => _buildCourseCard(c, provider, colors)),
        const SizedBox(height: 14),
        _buildHistoricalTranscriptsSection(provider, colors),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    GpaCalculatorProvider provider,
    ColorScheme colors,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left pane: Summary gauge and past transcripts
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryGaugeCard(provider, colors),
                const SizedBox(height: 12),
                _buildHistoricalTranscriptsSection(provider, colors),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
        // Right pane: What-if course simulator cards
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'WHAT-IF COURSE PROJECTIONS',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Icon(Icons.add_rounded, size: 14, color: colors.primary),
                      label: Text(
                        'Add Course',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () => _showAddCourseSheet(context, provider),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...provider.simulatedCourses.map((c) => _buildCourseCard(c, provider, colors)),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryGaugeCard(
    GpaCalculatorProvider provider,
    ColorScheme colors,
  ) {
    final priorCgpa = provider.priorCgpa;
    final projectedCgpa = provider.projectedCgpa;
    final simGpa = provider.simulatedSemesterGpa;
    final isHigher = projectedCgpa >= priorCgpa;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (projectedCgpa / 4.0).clamp(0.0, 1.0),
                      strokeWidth: 8,
                      backgroundColor: colors.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        projectedCgpa >= 3.75 ? colors.secondary : colors.primary,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          projectedCgpa.toStringAsFixed(2),
                          style: TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'CGPA',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        provider.honorsClassification,
                        style: TextStyle(
                          color: colors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          'Prior: ${priorCgpa.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isHigher ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                              size: 14,
                              color: isHigher ? colors.secondary : colors.error,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${(projectedCgpa - priorCgpa >= 0 ? "+" : "")}${(projectedCgpa - priorCgpa).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isHigher ? colors.secondary : colors.error,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Term: ${simGpa.toStringAsFixed(2)} GPA (${provider.simulatedCredits} Cr)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 11,
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
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  label: 'Prior Credits',
                  value: '${provider.priorCredits}',
                  colors: colors,
                ),
              ),
              Container(width: 1, height: 24, color: colors.outlineVariant),
              Expanded(
                child: _buildMetricItem(
                  label: 'Term Credits',
                  value: '+${provider.simulatedCredits}',
                  colors: colors,
                ),
              ),
              Container(width: 1, height: 24, color: colors.outlineVariant),
              Expanded(
                child: _buildMetricItem(
                  label: 'Total Credits',
                  value: '${provider.projectedTotalCredits} / 140',
                  colors: colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required ColorScheme colors,
  }) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(
    WhatIfCourseSimulation course,
    GpaCalculatorProvider provider,
    ColorScheme colors,
  ) {
    const grades = ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'F'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  course.courseCode,
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${course.creditHours} cr',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  '${course.gradePointValue.toStringAsFixed(1)} pts (${course.totalQualityPoints} QP)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              if (provider.simulatedCourses.length > 1) ...[
                const SizedBox(width: 4),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.close_rounded, size: 16, color: colors.onSurfaceVariant),
                  onPressed: () => provider.removeCourse(course.id),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            course.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: grades.map((grade) {
                final isSelected = course.expectedGrade == grade;
                return Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => provider.updateCourseGrade(course.id, grade),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.primary : colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? colors.primary : colors.outlineVariant,
                        ),
                      ),
                      child: Text(
                        grade,
                        style: TextStyle(
                          color: isSelected ? colors.onPrimary : colors.onSurface,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalTranscriptsSection(
    GpaCalculatorProvider provider,
    ColorScheme colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Historical SQLite Records',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${provider.transcripts.length} Semesters',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.transcripts.length,
            separatorBuilder: (_, _) => Divider(color: colors.outlineVariant, height: 1),
            itemBuilder: (context, idx) {
              final item = provider.transcripts[idx];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.semesterName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${item.creditHours} Credits  •  ${item.qualityPoints} QP',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.gpa.toStringAsFixed(2)} GPA',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddCourseSheet(BuildContext context, GpaCalculatorProvider provider) {
    final colors = Theme.of(context).colorScheme;
    final codeController = TextEditingController();
    final titleController = TextEditingController();
    int credits = 3;
    String selectedGrade = 'A';

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
                        'Add Course to What-If Simulation',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: codeController,
                        decoration: InputDecoration(
                          labelText: 'Course Code',
                          hintText: 'e.g. CS-450',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Course Title',
                          hintText: 'e.g. Autonomous Robotic Systems',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Text(
                            'Credit Hours: $credits',
                            style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w700),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [1, 2, 3, 4, 5].map((c) {
                              final isSel = credits == c;
                              return Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: ChoiceChip(
                                  label: Text('$c'),
                                  selected: isSel,
                                  onSelected: (_) => setModalState(() => credits = c),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          final code = codeController.text.trim();
                          final title = titleController.text.trim();
                          if (code.isEmpty || title.isEmpty) return;

                          provider.addCustomCourse(
                            courseCode: code,
                            title: title,
                            credits: credits,
                            grade: selectedGrade,
                          );

                          Navigator.of(sheetContext).pop();
                          AppFeedback.showSuccess(context, 'Added $code ($credits cr) to simulation.');
                        },
                        child: const Text('Add to Simulation', style: TextStyle(fontWeight: FontWeight.w700)),
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

  void _showCommitDialog(BuildContext context, GpaCalculatorProvider provider) {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Commit Semester to SQLite?',
            style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'This will permanently record Semester 8 (${provider.simulatedSemesterGpa.toStringAsFixed(2)} GPA, ${provider.simulatedCredits} credits) into your official university transcript ledger.',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: colors.onSurfaceVariant)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final success = await provider.commitSemesterToTranscript();
                if (success && context.mounted) {
                  AppFeedback.showSuccess(
                    context,
                    'Semester 8 committed to SQLite. Projected CGPA: ${provider.projectedCgpa.toStringAsFixed(2)}.',
                  );
                }
              },
              child: const Text('Commit Record', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }
}
