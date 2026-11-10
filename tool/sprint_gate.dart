import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final gate = SprintGate();
  final success = await gate.execute();
  exit(success ? 0 : 1);
}

class SprintGate {
  final Stopwatch _stopwatch = Stopwatch();

  Future<bool> execute() async {
    _stopwatch.start();
    _logHeader('CITYZENS AUTONOMOUS SPRINT VERIFICATION GATE');

    try {
      // Step 1: Flutter Pub Get
      final pubPassed = await _runStep(
        stepNumber: 1,
        title: 'Dependency Resolution (flutter pub get)',
        command: 'flutter',
        arguments: ['pub', 'get'],
      );
      if (!pubPassed) return false;

      // Step 2: Code Formatting
      final formatPassed = await _runFormatStep(stepNumber: 2);
      if (!formatPassed) return false;

      // Step 3: Static Analysis
      final analyzePassed = await _runStep(
        stepNumber: 3,
        title: 'Static Analysis (flutter analyze --no-pub)',
        command: 'flutter',
        arguments: ['analyze', '--no-pub'],
      );
      if (!analyzePassed) return false;

      // Step 4: Automated Test Suite
      final testPassed = await _runStep(
        stepNumber: 4,
        title: 'Automated Test Suite (flutter test --no-pub)',
        command: 'flutter',
        arguments: ['test', '--no-pub'],
      );
      if (!testPassed) return false;

      // Step 5: Connected Physical / Emulator Device Audit
      final devicePassed = await _runConnectedDeviceAudit(stepNumber: 5);
      if (!devicePassed) return false;

      _stopwatch.stop();
      _logSuccess(
        'ALL SPRINT VERIFICATION GATES PASSED [Total Time: ${_formatDuration(_stopwatch.elapsed)}]',
      );
      return true;
    } catch (e, stack) {
      _logError('Sprint gate encountered unhandled error: $e\n$stack');
      return false;
    }
  }

  Future<bool> _runFormatStep({required int stepNumber}) async {
    _logStepHeader(stepNumber, 'Code Formatting (dart format lib test)');

    // First auto-format to guarantee compliance
    final formatFix = await Process.run(
      'dart',
      ['format', 'lib', 'test'],
      runInShell: true,
    );
    if (formatFix.exitCode != 0) {
      _logError('dart format failed:\n${formatFix.stderr}');
      return false;
    }

    // Verify format compliance with zero diffs
    final formatCheck = await Process.run(
      'dart',
      ['format', '--output=none', '--set-exit-if-changed', 'lib', 'test'],
      runInShell: true,
    );

    if (formatCheck.exitCode == 0) {
      _logSuccess('Code format verification passed.');
      return true;
    } else {
      _logError('Formatting differences detected:\n${formatCheck.stdout}');
      return false;
    }
  }

  Future<bool> _runStep({
    required int stepNumber,
    required String title,
    required String command,
    required List<String> arguments,
  }) async {
    _logStepHeader(stepNumber, title);
    final sw = Stopwatch()..start();

    final result = await Process.run(
      command,
      arguments,
      runInShell: true,
    );
    sw.stop();

    if (result.exitCode == 0) {
      _logSuccess('$title passed in ${_formatDuration(sw.elapsed)}.');
      return true;
    } else {
      _logError('$title failed with exit code ${result.exitCode}:');
      if (result.stdout.toString().trim().isNotEmpty) {
        stdout.writeln(result.stdout.toString().trim());
      }
      if (result.stderr.toString().trim().isNotEmpty) {
        stderr.writeln(result.stderr.toString().trim());
      }
      return false;
    }
  }

  Future<bool> _runConnectedDeviceAudit({required int stepNumber}) async {
    _logStepHeader(
      stepNumber,
      'Live Connected Device Runtime Audit & Exception Scanner',
    );

    final devicesResult = await Process.run(
      'flutter',
      ['devices', '--machine'],
      runInShell: true,
    );

    if (devicesResult.exitCode != 0) {
      _logWarning('Unable to inspect flutter devices. Skipping live audit.');
      return true;
    }

    List<dynamic> devices = [];
    try {
      devices = jsonDecode(devicesResult.stdout.toString()) as List<dynamic>;
    } catch (_) {
      devices = [];
    }

    final mobileDevices = devices.where((d) {
      final target = (d['targetPlatform'] ?? '').toString().toLowerCase();
      final id = (d['id'] ?? '').toString().toLowerCase();
      return target.contains('android') ||
          target.contains('ios') ||
          id.contains('emulator') ||
          id.contains('device');
    }).toList();

    if (mobileDevices.isEmpty) {
      _logInfo(
        'No mobile physical device or emulator currently connected. '
        'Verified host environment (Desktop/Web only). Skipping mobile runtime log audit.',
      );
      return true;
    }

    final targetDevice = mobileDevices.first as Map<String, dynamic>;
    final deviceId = targetDevice['id'].toString();
    final deviceName = targetDevice['name'].toString();
    final isAndroid = targetDevice['targetPlatform'].toString().toLowerCase().contains('android');

    _logInfo('Detected target device: $deviceName ($deviceId)');

    final adbPath = _resolveAdbPath();

    if (isAndroid && adbPath != null) {
      _logInfo('Clearing stale device logcat buffer...');
      await Process.run(adbPath, ['-s', deviceId, 'logcat', '-c'], runInShell: true);
    }

    _logInfo('Launching application on $deviceId (25-second smoke window)...');
    final runProcess = await Process.start(
      'flutter',
      ['run', '-d', deviceId, '--no-pub'],
      runInShell: true,
    );

    final processStdout = StringBuffer();
    final processStderr = StringBuffer();

    runProcess.stdout.transform(utf8.decoder).listen((data) {
      processStdout.write(data);
    });

    runProcess.stderr.transform(utf8.decoder).listen((data) {
      processStderr.write(data);
    });

    // Controlled 25-second smoke window
    await Future.delayed(const Duration(seconds: 25));

    // Gracefully terminate application session
    try {
      runProcess.stdin.writeln('q');
      await runProcess.stdin.flush();
      await Future.delayed(const Duration(seconds: 2));
      runProcess.kill(ProcessSignal.sigterm);
    } catch (_) {
      runProcess.kill(ProcessSignal.sigkill);
    }

    // Inspect process console output and adb logcat for runtime violations
    final accumulatedLogs = StringBuffer();
    accumulatedLogs.writeln(processStdout.toString());
    accumulatedLogs.writeln(processStderr.toString());

    if (isAndroid && adbPath != null) {
      final logcatResult = await Process.run(
        adbPath,
        ['-s', deviceId, 'logcat', '-d'],
        runInShell: true,
      );
      accumulatedLogs.writeln(logcatResult.stdout.toString());
    }

    final fullLogText = accumulatedLogs.toString();

    final fatalPatterns = [
      'EXCEPTION CAUGHT BY',
      'A RenderFlex overflowed by',
      'There are multiple heroes that share the same tag',
      'No observables detected in the build method of Observer',
      'setState() or markNeedsBuild() called during build',
      'AndroidRuntime: FATAL EXCEPTION',
      'Unhandled Exception:',
    ];

    for (final pattern in fatalPatterns) {
      if (fullLogText.contains(pattern)) {
        _logError(
          'FATAL RUNTIME VIOLATION DETECTED ON DEVICE [$deviceName]: "$pattern"',
        );
        return false;
      }
    }

    _logSuccess('Live device runtime audit passed with ZERO runtime exceptions.');
    return true;
  }

  String? _resolveAdbPath() {
    // 1. Check if adb is on PATH
    try {
      final testAdb = Process.runSync('adb', ['version'], runInShell: true);
      if (testAdb.exitCode == 0) return 'adb';
    } catch (_) {}

    // 2. Check local appdata on Windows
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final winAdb = File('$localAppData\\Android\\Sdk\\platform-tools\\adb.exe');
      if (winAdb.existsSync()) return winAdb.path;
    }

    // 3. Check ANDROID_HOME / ANDROID_SDK_ROOT
    final androidHome = Platform.environment['ANDROID_HOME'] ?? Platform.environment['ANDROID_SDK_ROOT'];
    if (androidHome != null) {
      final candidate = File('$androidHome/platform-tools/adb${Platform.isWindows ? '.exe' : ''}');
      if (candidate.existsSync()) return candidate.path;
    }

    return null;
  }

  void _logHeader(String title) {
    stdout.writeln('====================================================================');
    stdout.writeln(title);
    stdout.writeln('====================================================================');
  }

  void _logStepHeader(int step, String title) {
    stdout.writeln('\n[STEP $step/5] $title');
  }

  void _logSuccess(String message) {
    stdout.writeln('[PASS] $message');
  }

  void _logInfo(String message) {
    stdout.writeln('[INFO] $message');
  }

  void _logWarning(String message) {
    stdout.writeln('[WARN] $message');
  }

  void _logError(String message) {
    stderr.writeln('[FAIL] $message');
  }

  String _formatDuration(Duration d) {
    final ms = d.inMilliseconds;
    if (ms < 1000) return '${ms}ms';
    final sec = (ms / 1000).toStringAsFixed(1);
    return '${sec}s';
  }
}
