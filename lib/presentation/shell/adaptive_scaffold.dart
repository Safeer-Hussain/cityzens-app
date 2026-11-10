import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/connectivity_service.dart';
import '../../core/theme/theme_provider.dart';
import '../attendance/attendance_view.dart';
import '../library/library_view.dart';
import '../scanner/scanner_hub_view.dart';
import '../ai_tutor/ai_academic_tutor_view.dart';
import '../campus/campus_feed_view.dart';
import 'recruiter_debug_drawer.dart';

class AdaptiveScaffold extends StatefulWidget {
  const AdaptiveScaffold({super.key});

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> _titles = [
    'Attendance & Schedule Hub',
    'Digital Library Records',
    'Native Optical Scanner',
    'AI Academic Companion',
    'Campus Feed & ID Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final connectivity = Provider.of<ConnectivityService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final screens = [
      AttendanceView(
        onNavigateToScanner: () => setState(() => _currentIndex = 2),
      ),
      const LibraryView(),
      const ScannerHubView(),
      const AiAcademicTutorView(),
      CampusFeedView(
        onOpenDebugDrawer: () => _scaffoldKey.currentState?.openEndDrawer(),
      ),
    ];

    return GestureDetector(
      // Global unfocus tap safety rule
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: colors.surface,
        endDrawer: const RecruiterDebugDrawer(),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isLandscape ? 36.0 : 48.0),
          child: AppBar(
            toolbarHeight: isLandscape ? 36.0 : 48.0,
            backgroundColor: colors.surface,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: isLandscape ? 20 : 24,
                  height: isLandscape ? 20 : 24,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _titles[_currentIndex],
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: isLandscape ? 12 : 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Toggle Dark/Light Mode',
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  size: isLandscape ? 16 : 20,
                  color: colors.onSurfaceVariant,
                ),
                onPressed: () => themeProvider.toggleTheme(),
              ),
              IconButton(
                tooltip: 'Recruiter Telemetry Hub',
                icon: Icon(
                  Icons.tune_rounded,
                  size: isLandscape ? 16 : 20,
                  color: colors.primary,
                ),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Animated Offline Banner
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: connectivity.isOffline
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  border: Border(
                    bottom: BorderSide(
                      color: colors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 14,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Offline Mode - Serving Local SQLite Library & Attendance Ledger',
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
            Expanded(
              child: isLandscape
                  ? Row(
                      children: [
                        _buildLandscapeNavRail(colors),
                        VerticalDivider(width: 1, color: colors.outlineVariant),
                        Expanded(child: screens[_currentIndex]),
                      ],
                    )
                  : screens[_currentIndex],
            ),
          ],
        ),
        bottomNavigationBar: isLandscape ? null : _buildBottomNavBar(colors),
      ),
    );
  }

  Widget _buildBottomNavBar(ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: colors.surface,
        indicatorColor: colors.primaryContainer,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.fact_check_outlined,
              color: colors.onSurfaceVariant,
              size: 20,
            ),
            selectedIcon: Icon(
              Icons.fact_check,
              color: colors.primary,
              size: 20,
            ),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.auto_stories_outlined,
              color: colors.onSurfaceVariant,
              size: 20,
            ),
            selectedIcon: Icon(
              Icons.auto_stories,
              color: colors.primary,
              size: 20,
            ),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.center_focus_strong_outlined,
              color: colors.onSurfaceVariant,
              size: 20,
            ),
            selectedIcon: Icon(
              Icons.center_focus_strong,
              color: colors.primary,
              size: 20,
            ),
            label: 'Scanner',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.psychology_outlined,
              color: colors.onSurfaceVariant,
              size: 20,
            ),
            selectedIcon: Icon(
              Icons.psychology,
              color: colors.primary,
              size: 20,
            ),
            label: 'AI Tutor',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.hub_outlined,
              color: colors.onSurfaceVariant,
              size: 20,
            ),
            selectedIcon: Icon(Icons.hub, color: colors.primary, size: 20),
            label: 'Campus',
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeNavRail(ColorScheme colors) {
    // Critical landscape rule: minWidth: 56, labelType: none, wrapped in SingleChildScrollView + IntrinsicHeight
    // so 5+ destinations NEVER overflow vertically on 360dp height screens!
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 300),
        child: IntrinsicHeight(
          child: NavigationRail(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
            minWidth: 56,
            labelType: NavigationRailLabelType.none,
            backgroundColor: colors.surface,
            indicatorColor: colors.primaryContainer,
            destinations: [
              NavigationRailDestination(
                icon: Icon(
                  Icons.fact_check_outlined,
                  color: colors.onSurfaceVariant,
                  size: 18,
                ),
                selectedIcon: Icon(
                  Icons.fact_check,
                  color: colors.primary,
                  size: 18,
                ),
                label: const Text('Attendance'),
              ),
              NavigationRailDestination(
                icon: Icon(
                  Icons.auto_stories_outlined,
                  color: colors.onSurfaceVariant,
                  size: 18,
                ),
                selectedIcon: Icon(
                  Icons.auto_stories,
                  color: colors.primary,
                  size: 18,
                ),
                label: const Text('Library'),
              ),
              NavigationRailDestination(
                icon: Icon(
                  Icons.center_focus_strong_outlined,
                  color: colors.onSurfaceVariant,
                  size: 18,
                ),
                selectedIcon: Icon(
                  Icons.center_focus_strong,
                  color: colors.primary,
                  size: 18,
                ),
                label: const Text('Scanner'),
              ),
              NavigationRailDestination(
                icon: Icon(
                  Icons.psychology_outlined,
                  color: colors.onSurfaceVariant,
                  size: 18,
                ),
                selectedIcon: Icon(
                  Icons.psychology,
                  color: colors.primary,
                  size: 18,
                ),
                label: const Text('AI Tutor'),
              ),
              NavigationRailDestination(
                icon: Icon(
                  Icons.hub_outlined,
                  color: colors.onSurfaceVariant,
                  size: 18,
                ),
                selectedIcon: Icon(Icons.hub, color: colors.primary, size: 18),
                label: const Text('Campus'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
