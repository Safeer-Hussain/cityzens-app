import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Cryptographic utilities for generating and verifying tamper-evident
/// optical examination passes and admission slip tokens.
class ExamCryptography {
  static const String _secretSalt = 'CITYZENS_ACADEMIC_REGISTRY_2026_SECURE_SALT';

  /// Generates a tamper-evident SHA-256 cryptographic checksum for an examination pass.
  static String generateChecksum({
    required String passId,
    required String studentId,
    required String courseCode,
    required String hallName,
    required String deskNumber,
    required int examTimestamp,
  }) {
    final rawPayload = '$passId|$studentId|$courseCode|$hallName|$deskNumber|$examTimestamp|$_secretSalt';
    final bytes = utf8.encode(rawPayload);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies if a given checksum matches the pass metadata.
  static bool verifyChecksum({
    required String passId,
    required String studentId,
    required String courseCode,
    required String hallName,
    required String deskNumber,
    required int examTimestamp,
    required String expectedChecksum,
  }) {
    final calculated = generateChecksum(
      passId: passId,
      studentId: studentId,
      courseCode: courseCode,
      hallName: hallName,
      deskNumber: deskNumber,
      examTimestamp: examTimestamp,
    );
    return calculated.toLowerCase() == expectedChecksum.toLowerCase();
  }

  /// Generates an encoded optical pass payload string suitable for QR / optical scanning.
  static String generateOpticalPayload({
    required String passId,
    required String studentId,
    required String courseCode,
    required String deskNumber,
    required String checksum,
  }) {
    final shortChecksum = checksum.length >= 16 ? checksum.substring(0, 16) : checksum;
    return 'CITYZENS:EXAM:$passId:$studentId:$courseCode:$deskNumber:$shortChecksum';
  }

  /// Formats a 64-character SHA-256 string into a human-readable spaced block format:
  /// e.g. "7F8A 94B2 E1C3 4D0F ... 8A2E"
  static String formatChecksumBlocks(String checksum) {
    final upper = checksum.toUpperCase();
    final blocks = <String>[];
    for (int i = 0; i < upper.length; i += 4) {
      final end = (i + 4 <= upper.length) ? i + 4 : upper.length;
      blocks.add(upper.substring(i, end));
    }
    return blocks.join(' ');
  }
}
