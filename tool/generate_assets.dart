import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  Directory('assets/icons').createSync(recursive: true);
  Directory('assets/images').createSync(recursive: true);

  print('Generating Cityzens production assets...');

  // 1. App Icon (512x512)
  generateAppIcon();

  // 2. Book Covers (400x600)
  generateBookCover(
    'assets/images/book_clean_architecture.png',
    'CLEAN ARCHITECTURE',
    'DOMAIN-DRIVEN SYSTEMS',
    const [0x1E, 0x1B, 0x4B], // Indigo 950
    const [0x0F, 0x17, 0x2A], // Slate 900
    const [0x10, 0xB9, 0x81], // Emerald 500
    1,
  );

  generateBookCover(
    'assets/images/book_mobile_systems.png',
    'MOBILE SYSTEMS',
    'SCALABLE KERNEL ARCHITECTURE',
    const [0x0C, 0x4A, 0x6E], // Sky 900
    const [0x02, 0x2C, 0x43], // Deep Sapphire
    const [0x38, 0xBD, 0xF8], // Sky 400
    2,
  );

  generateBookCover(
    'assets/images/book_applied_ai.png',
    'APPLIED AI & AGENTS',
    'DEEP REINFORCEMENT & LLMS',
    const [0x06, 0x4E, 0x3B], // Emerald 900
    const [0x02, 0x2B, 0x21], // Deep Obsidian
    const [0x34, 0xD3, 0x99], // Mint 400
    3,
  );

  generateBookCover(
    'assets/images/book_distributed_databases.png',
    'DISTRIBUTED DATABASES',
    'CONSENSUS & HIGH AVAILABILITY',
    const [0x4C, 0x1D, 0x95], // Violet 900
    const [0x2E, 0x10, 0x65], // Deep Purple
    const [0xF5, 0x9E, 0x0B], // Amber 500
    4,
  );

  // 3. Smart Campus ID Badge (600x380)
  generateCampusIdBadge();

  // 4. Lecture Halls (600x400)
  generateLectureHall(
    'assets/images/lecture_hall_turing.png',
    'TURING HALL 302',
    const [0x1E, 0x29, 0x3B],
    const [0x0F, 0x17, 0x2A],
    const [0x63, 0x66, 0xF1],
  );

  generateLectureHall(
    'assets/images/lecture_hall_hopper.png',
    'HOPPER AUDITORIUM 101',
    const [0x11, 0x18, 0x27],
    const [0x03, 0x07, 0x12],
    const [0x10, 0xB9, 0x81],
  );

  print('All assets generated successfully!');
}

void generateAppIcon() {
  final image = img.Image(width: 512, height: 512);

  // Background gradient: Slate 950 to Royal Indigo
  for (int y = 0; y < 512; y++) {
    final t = y / 512.0;
    final r = (15 * (1 - t) + 30 * t).toInt();
    final g = (23 * (1 - t) + 27 * t).toInt();
    final b = (42 * (1 - t) + 75 * t).toInt();
    for (int x = 0; x < 512; x++) {
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  // Draw circular badge ring
  final cx = 256;
  final cy = 256;
  final radius = 210;

  for (int angle = 0; angle < 360; angle++) {
    final rad = angle * pi / 180.0;
    for (int dr = -8; dr <= 8; dr++) {
      final r = radius + dr;
      final px = (cx + r * cos(rad)).round();
      final py = (cy + r * sin(rad)).round();
      if (px >= 0 && px < 512 && py >= 0 && py < 512) {
        // Emerald to Indigo accent
        final t = (angle % 180) / 180.0;
        final cr = (16 * t + 99 * (1 - t)).toInt();
        final cg = (185 * t + 102 * (1 - t)).toInt();
        final cb = (129 * t + 241 * (1 - t)).toInt();
        image.setPixelRgba(px, py, cr, cg, cb, 255);
      }
    }
  }

  // Inner shield polygon / crest
  for (int y = 110; y <= 390; y++) {
    final relY = (y - 110) / 280.0;
    final halfW = (relY < 0.6)
        ? 140.0
        : 140.0 * (1.0 - (relY - 0.6) / 0.4 * (relY - 0.6) / 0.4);
    for (int x = (cx - halfW).toInt(); x <= (cx + halfW).toInt(); x++) {
      if (x >= 0 && x < 512 && y >= 0 && y < 512) {
        final distRatio = (x - cx).abs() / 140.0;
        final innerR = (30 + distRatio * 20).toInt();
        final innerG = (34 + distRatio * 30).toInt();
        final innerB = (80 + distRatio * 50).toInt();
        image.setPixelRgba(x, y, innerR, innerG, innerB, 255);
      }
    }
  }

  // Central Open Book & Scanner Reticle
  // Left page
  for (int x = cx - 110; x <= cx - 10; x++) {
    for (int y = 200; y <= 320; y++) {
      final curve = ((x - (cx - 110)) / 100.0) * 12.0;
      if (y >= 200 - curve && y <= 320 - curve) {
        image.setPixelRgba(x, y, 226, 232, 240, 255); // Slate 200
      }
    }
  }

  // Right page
  for (int x = cx + 10; x <= cx + 110; x++) {
    for (int y = 200; y <= 320; y++) {
      final curve = ((cx + 110 - x) / 100.0) * 12.0;
      if (y >= 200 - curve && y <= 320 - curve) {
        image.setPixelRgba(x, y, 248, 250, 252, 255); // Slate 50
      }
    }
  }

  // Emerald optical scan line across the book
  for (int x = cx - 130; x <= cx + 130; x++) {
    for (int dy = -4; dy <= 4; dy++) {
      final y = 260 + dy;
      final alpha = (1.0 - (dy.abs() / 5.0));
      final r = (16 * alpha + 15 * (1 - alpha)).toInt();
      final g = (185 * alpha + 23 * (1 - alpha)).toInt();
      final b = (129 * alpha + 42 * (1 - alpha)).toInt();
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  File('assets/icons/app_icon.png').writeAsBytesSync(img.encodePng(image));
}

void generateBookCover(
  String path,
  String title,
  String subtitle,
  List<int> bgTop,
  List<int> bgBottom,
  List<int> accent,
  int patternType,
) {
  final image = img.Image(width: 400, height: 600);

  // Gradient background
  for (int y = 0; y < 600; y++) {
    final t = y / 600.0;
    final r = (bgTop[0] * (1 - t) + bgBottom[0] * t).toInt();
    final g = (bgTop[1] * (1 - t) + bgBottom[1] * t).toInt();
    final b = (bgTop[2] * (1 - t) + bgBottom[2] * t).toInt();
    for (int x = 0; x < 400; x++) {
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  // Spine line on left edge
  for (int x = 0; x < 28; x++) {
    for (int y = 0; y < 600; y++) {
      final shade = (x < 24) ? 0.75 : 1.3;
      final cur = image.getPixel(x, y);
      image.setPixelRgba(
        x,
        y,
        (cur.r * shade).clamp(0, 255).toInt(),
        (cur.g * shade).clamp(0, 255).toInt(),
        (cur.b * shade).clamp(0, 255).toInt(),
        255,
      );
    }
  }

  // Geometric Pattern in middle zone (y: 200 to 450)
  for (int i = 0; i < 6; i++) {
    final yPos = 240 + i * 32;
    for (int x = 50; x < 350; x++) {
      if ((x ~/ 20) % 2 == (patternType % 2)) {
        for (int dy = 0; dy < 3; dy++) {
          final cur = image.getPixel(x, yPos + dy);
          image.setPixelRgba(
            x,
            yPos + dy,
            (cur.r * 0.4 + accent[0] * 0.6).toInt(),
            (cur.g * 0.4 + accent[1] * 0.6).toInt(),
            (cur.b * 0.4 + accent[2] * 0.6).toInt(),
            255,
          );
        }
      }
    }
  }

  // Accent band top
  for (int y = 40; y < 48; y++) {
    for (int x = 40; x < 360; x++) {
      image.setPixelRgba(x, y, accent[0], accent[1], accent[2], 255);
    }
  }

  // Bottom emblem block
  for (int y = 490; y < 550; y++) {
    for (int x = 50; x < 150; x++) {
      if (y == 490 || y == 549 || x == 50 || x == 149) {
        image.setPixelRgba(x, y, accent[0], accent[1], accent[2], 200);
      }
    }
  }

  File(path).writeAsBytesSync(img.encodePng(image));
}

void generateCampusIdBadge() {
  final image = img.Image(width: 600, height: 380);

  // Background deep dark navy gradient
  for (int y = 0; y < 380; y++) {
    final t = y / 380.0;
    final r = (15 * (1 - t) + 24 * t).toInt();
    final g = (23 * (1 - t) + 36 * t).toInt();
    final b = (42 * (1 - t) + 64 * t).toInt();
    for (int x = 0; x < 600; x++) {
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  // Header band with emerald accent
  for (int y = 0; y < 45; y++) {
    for (int x = 0; x < 600; x++) {
      image.setPixelRgba(x, y, 16, 185, 129, 255);
    }
  }

  // Holographic Smart Chip block (x: 50..130, y: 120..190)
  for (int y = 120; y < 190; y++) {
    for (int x = 50; x < 130; x++) {
      final t = ((x + y) % 30) / 30.0;
      final cr = (212 * t + 245 * (1 - t)).toInt();
      final cg = (175 * t + 158 * (1 - t)).toInt();
      final cb = (55 * t + 11 * (1 - t)).toInt();
      image.setPixelRgba(x, y, cr, cg, cb, 255);
    }
  }

  // Security barcode at right side
  for (int x = 460; x < 550; x += 4) {
    final barW = ((x * 13) % 3) + 1;
    for (int y = 260; y < 330; y++) {
      for (int dx = 0; dx < barW; dx++) {
        if (x + dx < 560) {
          image.setPixelRgba(x + dx, y, 226, 232, 240, 255);
        }
      }
    }
  }

  File('assets/images/campus_id_badge.png').writeAsBytesSync(img.encodePng(image));
}

void generateLectureHall(
  String path,
  String name,
  List<int> bgTop,
  List<int> bgBottom,
  List<int> accent,
) {
  final image = img.Image(width: 600, height: 400);

  // Gradient background
  for (int y = 0; y < 400; y++) {
    final t = y / 400.0;
    final r = (bgTop[0] * (1 - t) + bgBottom[0] * t).toInt();
    final g = (bgTop[1] * (1 - t) + bgBottom[1] * t).toInt();
    final b = (bgTop[2] * (1 - t) + bgBottom[2] * t).toInt();
    for (int x = 0; x < 600; x++) {
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  // Lecture screen at top center
  for (int y = 40; y < 180; y++) {
    for (int x = 120; x < 480; x++) {
      if (y == 40 || y == 179 || x == 120 || x == 479) {
        image.setPixelRgba(x, y, accent[0], accent[1], accent[2], 255);
      } else {
        final val = ((x + y) % 40 < 20) ? 25 : 35;
        image.setPixelRgba(x, y, val, val + 5, val + 15, 255);
      }
    }
  }

  // Tiered seats curved lines
  for (int tier = 0; tier < 4; tier++) {
    final baseY = 230 + tier * 40;
    for (int x = 60; x < 540; x++) {
      final curve = (1 - ((x - 300).abs() / 240.0)) * 15;
      final y = (baseY - curve).round();
      for (int dy = -2; dy <= 2; dy++) {
        if (y + dy >= 0 && y + dy < 400) {
          image.setPixelRgba(x, y + dy, accent[0] ~/ 2, accent[1] ~/ 2, accent[2] ~/ 2, 220);
        }
      }
    }
  }

  File(path).writeAsBytesSync(img.encodePng(image));
}
