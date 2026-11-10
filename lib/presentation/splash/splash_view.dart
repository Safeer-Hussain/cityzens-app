import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/database/app_database.dart';
import '../../core/di/service_locator.dart';
import '../attendance/attendance_provider.dart';
import '../library/library_provider.dart';
import '../campus/campus_feed_provider.dart';
import '../gpa_calculator/gpa_calculator_provider.dart';
import '../exam/exam_provider.dart';
import '../scanner/scanner_provider.dart';
import '../shell/adaptive_scaffold.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  String _statusText = 'Starting Cityzens Campus Kernel...';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));

    _animController.forward();

    // Critical physical device rule: Defer heavy operations & precache into postFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executeKernelBootSequence();
    });
  }

  Future<void> _executeKernelBootSequence() async {
    try {
      // 1. Initialize SQLite Database
      if (mounted) {
        setState(() {
          _statusText = 'Initializing SQLite library & attendance ledger...';
        });
      }
      final db = sl<AppDatabase>();
      await db.init();

      if (!mounted) return;

      // 2. Pre-cache imagery safely outside initState
      await precacheImage(
        const AssetImage('assets/icons/app_icon.png'),
        context,
      );
      if (!mounted) return;
      await precacheImage(
        const AssetImage('assets/images/book_clean_architecture.png'),
        context,
      );

      if (!mounted) return;

      // 3. Mount Native Camera Bridge
      setState(() {
        _statusText = 'Mounting native camera & QR optical bridge...';
      });

      final scannerProvider = Provider.of<ScannerProvider>(
        context,
        listen: false,
      );
      await scannerProvider.initializeCamera();

      if (!mounted) return;

      // 4. Load Initial Data into Providers
      final attendanceProvider = Provider.of<AttendanceProvider>(
        context,
        listen: false,
      );
      final libraryProvider = Provider.of<LibraryProvider>(
        context,
        listen: false,
      );
      final campusFeedProvider = Provider.of<CampusFeedProvider>(
        context,
        listen: false,
      );
      final gpaProvider = Provider.of<GpaCalculatorProvider>(
        context,
        listen: false,
      );
      final examProvider = Provider.of<ExamProvider>(context, listen: false);

      await Future.wait([
        attendanceProvider.loadAttendanceData(),
        libraryProvider.loadLibraryData(),
        campusFeedProvider.loadFeed(),
        gpaProvider.loadTranscripts(),
        examProvider.loadPasses(),
      ]);

      if (!mounted) return;

      setState(() {
        _statusText = 'Cityzens Campus Ready.';
      });

      await Future.delayed(const Duration(milliseconds: 400));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, _, _) => const AdaptiveScaffold(),
            transitionsBuilder: (_, animation, _, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = 'Startup initialized with local state.';
        });
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdaptiveScaffold()),
        );
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.25),
                          blurRadius: 36,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'CITYZENS',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Smart Campus & Academic Ecosystem',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
