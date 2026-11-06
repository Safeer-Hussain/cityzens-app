import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_feedback.dart';
import '../attendance/attendance_provider.dart';
import '../library/library_provider.dart';
import '../library/widgets/book_detail_sheet.dart';
import 'scanner_provider.dart';

class ScannerHubView extends StatefulWidget {
  const ScannerHubView({super.key});

  @override
  State<ScannerHubView> createState() => _ScannerHubViewState();
}

class _ScannerHubViewState extends State<ScannerHubView> with SingleTickerProviderStateMixin {
  late final AnimationController _laserAnimController;
  late final Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.08, end: 0.92).animate(
      CurvedAnimation(parent: _laserAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
    super.dispose();
  }

  Future<void> _handleOpticalScan(
    ScannerProvider scannerProvider,
  ) async {
    final payload = await scannerProvider.scanPayload();
    if (payload == null || !mounted) return;

    if (payload.type == 'attendance_qr') {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final courseCode = payload.courseCode ?? 'CS-401';
      final success = await attendanceProvider.checkInWithQr(
        courseCode: courseCode,
        qrPayload: '${payload.code} - ${payload.room}',
      );
      if (!mounted) return;
      if (success) {
        AppFeedback.showSuccess(
          context,
          'QR Verified: Checked in to $courseCode (${payload.room}) with hardware checksum ${payload.checksum}.',
        );
      }
    } else if (payload.type == 'library_isbn') {
      final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
      final isbn = payload.isbn ?? '978-0134494166';
      final book = await libraryProvider.repository.getBookByIsbn(isbn);
      if (!mounted) return;
      if (book != null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => BookDetailSheet(book: book, provider: libraryProvider),
        );
      }
    } else if (payload.type == 'student_id') {
      if (!mounted) return;
      AppFeedback.showSuccess(
        context,
        'Verified Badge: ${payload.name} (${payload.clearance}). Security token active.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Consumer<ScannerProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: colors.surface,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_camera_capture',
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            elevation: 3,
            icon: provider.isScanning
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.onPrimary),
                  )
                : const Icon(Icons.camera_rounded, size: 20),
            label: Text(
              provider.isScanning ? 'Decoding...' : 'Capture & Verify',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            onPressed: provider.isScanning ? null : () => _handleOpticalScan(provider),
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
    ScannerProvider provider,
    ColorScheme colors,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildModeSelector(provider, colors),
        const SizedBox(height: 14),
        _buildOpticalViewfinder(context, provider, colors, height: 260),
        const SizedBox(height: 14),
        _buildSensorControls(provider, colors),
        const SizedBox(height: 14),
        _buildScannedPayloadResult(provider, colors),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    ScannerProvider provider,
    ColorScheme colors,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left pane: Viewfinder
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                _buildModeSelector(provider, colors),
                const SizedBox(height: 8),
                _buildOpticalViewfinder(context, provider, colors, height: 200),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
        // Right pane: Controls and Scanned payload
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                _buildSensorControls(provider, colors),
                const SizedBox(height: 8),
                _buildScannedPayloadResult(provider, colors),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector(ScannerProvider provider, ColorScheme colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ScannerMode.values.map((mode) {
          final isSelected = provider.selectedMode == mode;
          IconData icon;
          switch (mode) {
            case ScannerMode.attendanceQr:
              icon = Icons.qr_code_2_rounded;
              break;
            case ScannerMode.libraryIsbn:
              icon = Icons.barcode_reader;
              break;
            case ScannerMode.studentId:
              icon = Icons.badge_outlined;
              break;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              avatar: Icon(
                icon,
                size: 16,
                color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
              label: Text(mode.label),
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
              onSelected: (_) => provider.setMode(mode),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOpticalViewfinder(
    BuildContext context,
    ScannerProvider provider,
    ColorScheme colors, {
    required double height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant, width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Optical background grid lines
          CustomPaint(
            size: Size.infinite,
            painter: _OpticalGridPainter(gridColor: colors.outlineVariant.withValues(alpha: 0.35)),
          ),
          // Viewfinder Target Frame with corner reticles
          Container(
            width: height * 0.75,
            height: height * 0.75,
            decoration: BoxDecoration(
              border: Border.all(color: colors.primary.withValues(alpha: 0.8), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                // Corner targeting reticles
                Positioned(top: 0, left: 0, child: _buildCornerReticle(colors, 0)),
                Positioned(top: 0, right: 0, child: _buildCornerReticle(colors, 90)),
                Positioned(bottom: 0, right: 0, child: _buildCornerReticle(colors, 180)),
                Positioned(bottom: 0, left: 0, child: _buildCornerReticle(colors, 270)),
                // Animated laser scan-line
                AnimatedBuilder(
                  animation: _laserAnimation,
                  builder: (context, _) {
                    return Positioned(
                      top: _laserAnimation.value * (height * 0.75),
                      left: 4,
                      right: 4,
                      child: Container(
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: colors.secondary,
                          boxShadow: [
                            BoxShadow(
                              color: colors.secondary.withValues(alpha: 0.7),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Center watermark icon
          Icon(
            provider.selectedMode == ScannerMode.attendanceQr
                ? Icons.qr_code_2_rounded
                : provider.selectedMode == ScannerMode.libraryIsbn
                    ? Icons.barcode_reader
                    : Icons.badge_outlined,
            size: 40,
            color: colors.primary.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerReticle(ColorScheme colors, double angleDegrees) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.secondary, width: 3),
          left: BorderSide(color: colors.secondary, width: 3),
        ),
      ),
    );
  }

  Widget _buildSensorControls(ScannerProvider provider, ColorScheme colors) {
    final sensor = provider.sensorInfo['sensor'] ?? 'Sony IMX Optical Bridge';
    final fps = provider.sensorInfo['fps'] ?? 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: colors.secondary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sensor.toString(),
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '1080p @ ${fps}FPS  •  Hardware CRC Verification',
                    style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              provider.isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: provider.isTorchOn ? colors.secondary : colors.onSurfaceVariant,
              size: 20,
            ),
            onPressed: () => provider.toggleTorch(),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedPayloadResult(ScannerProvider provider, ColorScheme colors) {
    final payload = provider.lastPayload;
    if (payload == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colors.onSurfaceVariant, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Align lecture hall QR, book ISBN-13, or campus badge inside targeting reticle and tap "Capture & Verify".',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.secondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_rounded, color: colors.secondary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Verified Optical Payload',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  payload.checksum,
                  style: TextStyle(
                    color: colors.onSecondaryContainer,
                    fontSize: 9,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (payload.type == 'attendance_qr') ...[
            Text('Token: ${payload.code}', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
            Text('Course: ${payload.courseCode} - ${payload.courseTitle}', style: TextStyle(color: colors.onSurface, fontSize: 12)),
            Text('Room: ${payload.room}', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
          ] else if (payload.type == 'library_isbn') ...[
            Text('ISBN-13: ${payload.isbn}', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
            Text('Title: ${payload.title}', style: TextStyle(color: colors.onSurface, fontSize: 12)),
            Text('Author: ${payload.author}', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
          ] else ...[
            Text('Student ID: ${payload.studentId}', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
            Text('Name: ${payload.name}', style: TextStyle(color: colors.onSurface, fontSize: 12)),
            Text('Security Clearance: ${payload.clearance}', style: TextStyle(color: colors.secondary, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}

class _OpticalGridPainter extends CustomPainter {
  final Color gridColor;

  _OpticalGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OpticalGridPainter oldDelegate) => false;
}
