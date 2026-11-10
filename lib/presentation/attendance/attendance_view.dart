import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_feedback.dart';
import '../../data/models/course_attendance.dart';
import '../exam/exam_hall_pass_view.dart';
import 'attendance_provider.dart';
import 'widgets/attendance_trend_chart.dart';

class AttendanceView extends StatelessWidget {
  final VoidCallback? onNavigateToScanner;

  const AttendanceView({super.key, this.onNavigateToScanner});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Consumer<AttendanceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.courses.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: colors.primary),
          );
        }

        return Scaffold(
          backgroundColor: colors.surface,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_attendance_checkin',
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            elevation: 3,
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
            label: Text(
              provider.isStudentMode ? 'Check In' : 'Take Attendance',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            onPressed: () => _showCheckInOptionsModal(context, provider),
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
    AttendanceProvider provider,
    ColorScheme colors,
  ) {
    return RefreshIndicator(
      color: colors.primary,
      onRefresh: () => provider.loadAttendanceData(),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildRoleSwitcher(context, provider, colors),
          const SizedBox(height: 12),
          _buildAnalyticsCard(context, provider, colors),
          const SizedBox(height: 14),
          _buildTrendCard(context, provider, colors),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExamHallPassView()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_seat_rounded, color: colors.secondary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Midterm & Final Exam Hall Passes',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Digital admission slips, cryptographic seals & desk matrix',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 12, color: colors.onSurfaceVariant),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'ENROLLED COURSES (${provider.courses.length})',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
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
                icon: Icon(Icons.note_add_outlined, size: 16, color: colors.primary),
                label: Text(
                  'Submit Leave',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => _showLeaveRequestModal(context, provider),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...provider.courses.map((course) => _buildCourseCard(context, course, provider, colors)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    AttendanceProvider provider,
    ColorScheme colors,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left pane: Analytics and Trendline
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRoleSwitcher(context, provider, colors),
                const SizedBox(height: 8),
                _buildAnalyticsCard(context, provider, colors),
                const SizedBox(height: 8),
                _buildTrendCard(context, provider, colors),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
        // Right pane: Course Breakdown list
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
                        'COURSE BREAKDOWN',
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
                      icon: Icon(Icons.note_add_outlined, size: 14, color: colors.primary),
                      label: Text(
                        'Submit Leave',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => _showLeaveRequestModal(context, provider),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...provider.courses.map((course) => _buildCourseCard(context, course, provider, colors)),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSwitcher(
    BuildContext context,
    AttendanceProvider provider,
    ColorScheme colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: provider.isStudentMode ? null : () => provider.toggleRoleMode(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: provider.isStudentMode ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 15,
                      color: provider.isStudentMode ? colors.onPrimary : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Student View',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: provider.isStudentMode ? colors.onPrimary : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: !provider.isStudentMode ? null : () => provider.toggleRoleMode(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !provider.isStudentMode ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.badge_rounded,
                      size: 15,
                      color: !provider.isStudentMode ? colors.onPrimary : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Faculty View',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: !provider.isStudentMode ? colors.onPrimary : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    BuildContext context,
    AttendanceProvider provider,
    ColorScheme colors,
  ) {
    final overall = provider.overallAttendancePercentage;
    final isGood = overall >= 75.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (overall / 100).clamp(0.0, 1.0),
                      strokeWidth: 7,
                      backgroundColor: colors.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isGood ? colors.secondary : colors.error,
                      ),
                    ),
                    Text(
                      '${overall.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Overall Standing',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isGood
                                ? colors.secondary.withValues(alpha: 0.15)
                                : colors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isGood ? 'ELIGIBLE' : 'ATTENDANCE RISK',
                            style: TextStyle(
                              color: isGood ? colors.secondary : colors.error,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.isStudentMode
                          ? 'Minimum 75.0% required for final examination access.'
                          : 'Aggregated student cohort attendance verification ledger.',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildStatChip('Present', '${provider.totalPresentCount}', colors.secondary, colors),
                        _buildStatChip('Absent', '${provider.totalAbsentCount}', colors.error, colors),
                        _buildStatChip('Excused', '${provider.totalExcusedCount}', colors.tertiary, colors),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$value $label',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(
    BuildContext context,
    AttendanceProvider provider,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '6-Week Attendance Trajectory',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Goal: >= 75%',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AttendanceTrendChart(
            currentPercentage: provider.overallAttendancePercentage,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    CourseModel course,
    AttendanceProvider provider,
    ColorScheme colors,
  ) {
    final percent = course.attendancePercentage;
    final isRisk = course.isAtRisk;
    final needed = course.calculateClassesNeeded(75.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRisk ? colors.error.withValues(alpha: 0.6) : colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  course.code,
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  color: isRisk ? colors.error : colors.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            course.title,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 14, color: colors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                course.instructor,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
              ),
              const SizedBox(width: 12),
              Icon(Icons.room_outlined, size: 14, color: colors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  course.room,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isRisk ? colors.error : colors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Text(
                '${course.presentCount}P • ${course.absentCount}A • ${course.excusedCount}E',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isRisk)
                Text(
                  'Needs $needed class${needed > 1 ? "es" : ""}',
                  style: TextStyle(
                    color: colors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Text(
                  'Good Standing',
                  style: TextStyle(
                    color: colors.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCheckInOptionsModal(BuildContext context, AttendanceProvider provider) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  'Attendance Verification Hub',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select high-speed automated verification method',
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.qr_code_scanner_rounded, color: colors.primary, size: 22),
                  ),
                  title: Text(
                    'Scan Hall QR Code',
                    style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Optical viewfinder camera scanner with hardware checksum',
                    style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    if (onNavigateToScanner != null) {
                      onNavigateToScanner!();
                    }
                  },
                ),
                Divider(color: colors.outlineVariant),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.pin_rounded, color: colors.secondary, size: 22),
                  ),
                  title: Text(
                    'Enter 6-Digit Lecture PIN',
                    style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Manual passcode provided on the lecture projection screen',
                    style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showManualPinModal(context, provider);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showManualPinModal(BuildContext context, AttendanceProvider provider) {
    final colors = Theme.of(context).colorScheme;
    final pinController = TextEditingController();
    String selectedCourse = provider.courses.isNotEmpty ? provider.courses.first.code : 'CS-401';
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
                        'Manual Lecture PIN Verification',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCourse,
                        decoration: InputDecoration(
                          labelText: 'Select Course',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: provider.courses.map((c) {
                          return DropdownMenuItem(
                            value: c.code,
                            child: Text('${c.code} - ${c.title}', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedCourse = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: pinController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          labelText: '6-Digit Lecture PIN',
                          hintText: 'e.g. 892014',
                          errorText: errorText,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final pin = pinController.text.trim();
                          if (pin.length != 6) {
                            setModalState(() {
                              errorText = 'PIN must be exactly 6 digits';
                            });
                            return;
                          }

                          final success = await provider.checkInWithPin(
                            courseCode: selectedCourse,
                            pin: pin,
                          );

                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }

                          if (success && context.mounted) {
                            AppFeedback.showSuccess(
                              context,
                              'Verified attendance in $selectedCourse via Lecture PIN $pin.',
                            );
                          }
                        },
                        child: const Text('Verify & Record Attendance', style: TextStyle(fontWeight: FontWeight.w700)),
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

  void _showLeaveRequestModal(BuildContext context, AttendanceProvider provider) {
    final colors = Theme.of(context).colorScheme;
    final reasonController = TextEditingController();
    String selectedCourse = provider.courses.isNotEmpty ? provider.courses.first.code : 'CS-401';
    DateTime selectedDate = DateTime.now();
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
                        'Submit Absence / Leave Request',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Formal leave request approved into the SQLite ledger',
                        style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCourse,
                        decoration: InputDecoration(
                          labelText: 'Select Course',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: provider.courses.map((c) {
                          return DropdownMenuItem(
                            value: c.code,
                            child: Text('${c.code} - ${c.title}', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedCourse = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Reason for Excused Absence',
                          hintText: 'e.g. Medical appointment with formal physician certificate.',
                          errorText: errorText,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final reason = reasonController.text.trim();
                          if (reason.length < 5) {
                            setModalState(() {
                              errorText = 'Please provide a valid explanation (min 5 characters)';
                            });
                            return;
                          }

                          final success = await provider.submitLeaveRequest(
                            courseCode: selectedCourse,
                            reason: reason,
                            date: selectedDate,
                          );

                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }

                          if (success && context.mounted) {
                            AppFeedback.showSuccess(
                              context,
                              'Excused leave sanctioned for $selectedCourse. Ledger updated.',
                            );
                          }
                        },
                        child: const Text('Submit Official Leave', style: TextStyle(fontWeight: FontWeight.w700)),
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
