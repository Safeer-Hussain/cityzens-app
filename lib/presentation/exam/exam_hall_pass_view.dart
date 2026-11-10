import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/utils/exam_cryptography.dart';
import '../../data/models/exam_hall_pass.dart';
import 'exam_provider.dart';

class ExamHallPassView extends StatefulWidget {
  const ExamHallPassView({super.key});

  @override
  State<ExamHallPassView> createState() => _ExamHallPassViewState();
}

class _ExamHallPassViewState extends State<ExamHallPassView> {
  int _selectedTabIndex = 0; // 0: Admission Pass, 1: Seat Finder, 2: Timetable

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ExamProvider>(context, listen: false);
      if (provider.passes.isEmpty) {
        provider.loadPasses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Consumer<ExamProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.passes.isEmpty) {
          return Scaffold(
            backgroundColor: colors.surface,
            appBar: _buildAppBar(context, colors, isLandscape, provider),
            body: Center(child: CircularProgressIndicator(color: colors.primary)),
          );
        }

        final activePass = provider.selectedPass;

        return Scaffold(
          backgroundColor: colors.surface,
          appBar: _buildAppBar(context, colors, isLandscape, provider),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_exam_reminder_toggle',
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            elevation: 3,
            icon: Icon(
              activePass?.isReminderSet == true
                  ? Icons.alarm_on_rounded
                  : Icons.alarm_add_rounded,
              size: 20,
            ),
            label: Text(
              activePass?.isReminderSet == true
                  ? 'Alarm Armed (60m)'
                  : 'Set Exam Alarm',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            onPressed: activePass != null
                ? () async {
                    final isNowArmed = !activePass.isReminderSet;
                    final ok = await provider.togglePassReminder(activePass.id);
                    if (!mounted || !ok) return;
                    if (isNowArmed) {
                      AppFeedback.showSuccess(
                        this.context,
                        'Offline exam reminder scheduled 60m before ${activePass.courseCode}.',
                      );
                    } else {
                      AppFeedback.showInfo(
                        this.context,
                        'Exam reminder disarmed for ${activePass.courseCode}.',
                      );
                    }
                  }
                : null,
          ),
          body: isLandscape
              ? _buildLandscapeLayout(context, provider, colors)
              : _buildPortraitLayout(context, provider, colors),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ColorScheme colors,
    bool isLandscape,
    ExamProvider provider,
  ) {
    return PreferredSize(
      preferredSize: Size.fromHeight(isLandscape ? 36.0 : 48.0),
      child: AppBar(
        toolbarHeight: isLandscape ? 36.0 : 48.0,
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'Exam Hall Seat Finder & Digital Pass',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: isLandscape ? 13 : 16,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Reload Exam Passes',
            icon: Icon(
              Icons.refresh_rounded,
              size: isLandscape ? 16 : 20,
              color: colors.onSurfaceVariant,
            ),
            onPressed: () async {
              await provider.loadPasses();
              if (context.mounted) {
                AppFeedback.showInfo(context, 'Exam passes updated from SQLite registry.');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    ExamProvider provider,
    ColorScheme colors,
  ) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildExamSelectorBar(provider, colors),
        const SizedBox(height: 12),
        _buildSegmentedTabs(colors),
        const SizedBox(height: 12),
        if (_selectedTabIndex == 0) ...[
          _buildDigitalAdmissionPassCard(provider, colors),
        ] else if (_selectedTabIndex == 1) ...[
          _buildSeatAssignmentMatrix(provider, colors),
        ] else ...[
          _buildExamTimetableList(provider, colors),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    ExamProvider provider,
    ColorScheme colors,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left pane: Admission Slip & Cryptographic Seal
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildExamSelectorBar(provider, colors),
                const SizedBox(height: 10),
                _buildDigitalAdmissionPassCard(provider, colors),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
        // Right pane: Interactive Seat Matrix & Timetable
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSeatAssignmentMatrix(provider, colors),
                const SizedBox(height: 14),
                _buildExamTimetableList(provider, colors),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExamSelectorBar(ExamProvider provider, ColorScheme colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: provider.passes.map((pass) {
          final isSelected = provider.selectedPass?.id == pass.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                '${pass.courseCode} (${pass.deskNumber})',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => provider.selectPass(pass),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSegmentedTabs(ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabItem(title: 'Admission Pass', index: 0, colors: colors),
          _buildTabItem(title: 'Seat Finder', index: 1, colors: colors),
          _buildTabItem(title: 'Timetable', index: 2, colors: colors),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required String title,
    required int index,
    required ColorScheme colors,
  }) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalAdmissionPassCard(ExamProvider provider, ColorScheme colors) {
    final pass = provider.selectedPass;
    if (pass == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'No examination pass selected.',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      );
    }

    final isVerified = pass.isVerified;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified ? colors.secondary : colors.outlineVariant,
          width: isVerified ? 1.5 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Official Academic Pass Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isVerified
                    ? [colors.secondary, colors.primary]
                    : [colors.primary, colors.surfaceContainerHighest],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isVerified ? Icons.verified_user_rounded : Icons.shield_outlined,
                        color: colors.onPrimary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'CITYZENS ADMISSION SLIP',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  pass.countdownFormatted,
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
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
                // Candidate and Course Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pass.courseCode,
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pass.courseTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pass.examType,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // High-contrast Desk Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.primary),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'DESK',
                            style: TextStyle(
                              color: colors.onPrimaryContainer,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            pass.deskNumber,
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
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
                // Session Metadata Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildPassMetaItem(
                        icon: Icons.meeting_room_outlined,
                        label: 'Examination Hall',
                        value: pass.hallName,
                        colors: colors,
                      ),
                    ),
                    Expanded(
                      child: _buildPassMetaItem(
                        icon: Icons.event_seat_outlined,
                        label: 'Seat Assignment',
                        value: pass.seatDesignation,
                        colors: colors,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildPassMetaItem(
                        icon: Icons.schedule_rounded,
                        label: 'Date & Duration',
                        value: '${pass.durationMinutes} Minutes',
                        colors: colors,
                      ),
                    ),
                    Expanded(
                      child: _buildPassMetaItem(
                        icon: Icons.person_outline_rounded,
                        label: 'Chief Invigilator',
                        value: pass.invigilatorName,
                        colors: colors,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Optical Pass Visual Matrix Representation
                _buildOpticalTokenBox(pass, colors),
                const SizedBox(height: 12),
                // Cryptographic Seal Section
                _buildCryptographicSealBox(pass, provider, colors),
                const SizedBox(height: 12),
                // Instructions Checklist
                Text(
                  'EXAMINATION HALL REGULATIONS',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                ...pass.instructions.map((ins) => _buildInstructionItem(ins, colors)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassMetaItem({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colors,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOpticalTokenBox(ExamHallPassModel pass, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          // Optical matrix visualizer block
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Icon(
              Icons.qr_code_2_rounded,
              size: 40,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.nfc_rounded, size: 14, color: colors.secondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'OPTICAL ADMISSION TOKEN',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.secondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  pass.opticalToken,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCryptographicSealBox(
    ExamHallPassModel pass,
    ExamProvider provider,
    ColorScheme colors,
  ) {
    final isVerified = pass.isVerified;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified ? colors.secondary : colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isVerified ? Icons.check_circle_rounded : Icons.lock_clock_rounded,
                      size: 15,
                      color: isVerified ? colors.secondary : colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'SHA-256 REGISTRY CHECKSUM',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isVerified
                      ? colors.secondary.withValues(alpha: 0.15)
                      : colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isVerified ? 'VERIFIED' : 'PENDING GATE',
                  style: TextStyle(
                    color: isVerified ? colors.secondary : colors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ExamCryptography.formatChecksumBlocks(pass.cryptographicChecksum),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 9,
              fontFamily: 'monospace',
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              side: BorderSide(color: colors.outlineVariant),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: provider.isVerifying
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                  )
                : Icon(Icons.security_rounded, size: 14, color: colors.primary),
            label: Text(
              provider.isVerifying ? 'Authenticating...' : 'Validate Cryptographic Token',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            onPressed: provider.isVerifying
                ? null
                : () async {
                    final valid = await provider.verifyCurrentPass();
                    if (!mounted) return;
                    if (valid) {
                      AppFeedback.showSuccess(
                        context,
                        'Admissions Token authenticated: Checksum matches SQLite signature.',
                      );
                    } else {
                      AppFeedback.showError(
                        context,
                        'Token verification failure: Checksum tampering detected.',
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 13, color: colors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatAssignmentMatrix(ExamProvider provider, ColorScheme colors) {
    final hall = provider.selectedHall;
    final seats = provider.currentHallMatrix;
    final userSeat = provider.userAssignedSeat;
    final inspectedSeat = provider.selectedSeat ?? userSeat;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hall Switcher & Capacity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hall.name,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${hall.building} (${hall.floor})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
                    ),
                  ],
                ),
              ),
              // Hall Switcher Menu
              PopupMenuButton<ExamHall>(
                tooltip: 'Switch Examination Hall',
                icon: Icon(Icons.swap_horiz_rounded, color: colors.primary),
                onSelected: (h) => provider.selectHall(h),
                itemBuilder: (_) => ExamHall.defaultHalls.map((h) {
                  return PopupMenuItem(
                    value: h,
                    child: Text(
                      '${h.name} (${h.totalCapacity} Seats)',
                      style: TextStyle(
                        fontWeight: h.name == hall.name ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Stage / Podium Indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.outlineVariant),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.co_present_rounded, size: 14, color: colors.onSurfaceVariant),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'EXAMINATION PODIUM & PROCTOR STAGE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Legend Row
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              _buildLegendPill('Your Seat', colors.primary, colors),
              _buildLegendPill('Occupied', colors.surfaceContainerHighest, colors),
              _buildLegendPill('Available', colors.outlineVariant, colors),
              _buildLegendPill('Priority/Accessible', colors.tertiary, colors),
            ],
          ),
          const SizedBox(height: 12),
          // Visual Seat Matrix Scrollable Grid
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: hall.rows.map((row) {
                final rowSeats = seats.where((s) => s.row == row).toList();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      // Row letter label
                      Container(
                        width: 18,
                        alignment: Alignment.center,
                        child: Text(
                          row,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Row seat cells
                      ...rowSeats.map((seat) {
                        return _buildSeatCell(seat, provider, colors);
                      }),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Inspected Seat Details Panel
          if (inspectedSeat != null) ...[
            _buildInspectedSeatCard(inspectedSeat, colors),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendPill(String label, Color color, ColorScheme colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildSeatCell(
    ExamSeat seat,
    ExamProvider provider,
    ColorScheme colors,
  ) {
    Color bg;
    Color border;
    Color textColor;

    if (seat.isUserSeat) {
      bg = colors.primary;
      border = colors.primary;
      textColor = colors.onPrimary;
    } else if (seat.isAccessible) {
      bg = colors.tertiary.withValues(alpha: 0.15);
      border = colors.tertiary;
      textColor = colors.tertiary;
    } else if (seat.isOccupied) {
      bg = colors.surfaceContainerHighest;
      border = colors.outlineVariant.withValues(alpha: 0.5);
      textColor = colors.onSurfaceVariant.withValues(alpha: 0.6);
    } else {
      bg = colors.surfaceContainer;
      border = colors.outlineVariant;
      textColor = colors.onSurface;
    }

    final isSelected = provider.selectedSeat?.deskCode == seat.deskCode;

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(5),
        onTap: () => provider.selectSeat(seat),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: isSelected ? colors.secondary : border,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '${seat.number}',
            style: TextStyle(
              color: textColor,
              fontWeight: seat.isUserSeat ? FontWeight.w900 : FontWeight.w600,
              fontSize: 9,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInspectedSeatCard(ExamSeat seat, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: seat.isUserSeat ? colors.primary : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Desk ${seat.deskCode}',
                    style: TextStyle(
                      color: seat.isUserSeat ? colors.onPrimary : colors.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seat.isUserSeat
                            ? 'Your Assigned Examination Desk'
                            : seat.isOccupied
                                ? 'Candidate: ${seat.assignedCandidateMasked ?? "Occupied"}'
                                : seat.isAccessible
                                    ? 'Priority Mobility Desk'
                                    : 'Vacant Desk',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${seat.hallName}  •  Row ${seat.row}, Seat ${seat.number}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (seat.isUserSeat) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'YOUR DESK',
                style: TextStyle(
                  color: colors.secondary,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExamTimetableList(ExamProvider provider, ColorScheme colors) {
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
                  'Registered Examination Timetable',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${provider.passes.length} Sessions',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.passes.length,
            separatorBuilder: (_, _) => Divider(color: colors.outlineVariant, height: 1),
            itemBuilder: (_, idx) {
              final pass = provider.passes[idx];
              final isCurrent = provider.selectedPass?.id == pass.id;

              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  provider.selectPass(pass);
                  setState(() => _selectedTabIndex = 0);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCurrent ? colors.primary : colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          pass.courseCode,
                          style: TextStyle(
                            color: isCurrent ? colors.onPrimary : colors.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pass.courseTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${pass.hallName} (${pass.deskNumber})  •  ${pass.countdownFormatted}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 1-Tap Offline Reminder Toggle Switch
                      Switch(
                        value: pass.isReminderSet,
                        activeThumbColor: colors.primary,
                        onChanged: (_) async {
                          final ok = await provider.togglePassReminder(pass.id);
                          if (!mounted || !ok) return;
                          if (!pass.isReminderSet) {
                            AppFeedback.showSuccess(
                              context,
                              'Alarm armed 60m before ${pass.courseCode}.',
                            );
                          } else {
                            AppFeedback.showInfo(
                              context,
                              'Alarm disarmed for ${pass.courseCode}.',
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
