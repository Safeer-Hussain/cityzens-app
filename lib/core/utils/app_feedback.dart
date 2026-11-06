import 'package:flutter/material.dart';

class AppFeedback {
  AppFeedback._();

  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context: context,
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      textColor: Theme.of(context).colorScheme.onSecondary,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _showSnackBar(
      context: context,
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      textColor: Theme.of(context).colorScheme.onTertiary,
    );
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context: context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: Theme.of(context).colorScheme.error,
      textColor: Theme.of(context).colorScheme.onError,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackBar(
      context: context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      textColor: Theme.of(context).colorScheme.onSurface,
    );
  }

  static void _showSnackBar({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger == null) return;

    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: backgroundColor,
        duration: const Duration(milliseconds: 3200),
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
