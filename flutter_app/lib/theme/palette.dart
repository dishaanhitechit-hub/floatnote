import 'package:flutter/material.dart';

class FNPalette {
  // Canvas background
  static const canvas      = Color(0xFFF5F0E8);
  static const canvasDark  = Color(0xFF1A1A2E);

  // Note pastels (12)
  static const List<Color> noteColors = [
    Color(0xFFFFF9C4), // lemon
    Color(0xFFFFCDD2), // blush
    Color(0xFFC8E6C9), // mint
    Color(0xFFBBDEFB), // sky
    Color(0xFFE1BEE7), // lilac
    Color(0xFFFFE0B2), // peach
    Color(0xFFB2EBF2), // aqua
    Color(0xFFF8BBD0), // rose
    Color(0xFFDCEDC8), // sage
    Color(0xFFFFF3E0), // cream
    Color(0xFFE8EAF6), // periwinkle
    Color(0xFFFCE4EC), // petal
  ];

  // Neon notes (6)
  static const List<Color> neonColors = [
    Color(0xFFFFFF00), // neon yellow
    Color(0xFFFF6EC7), // neon pink
    Color(0xFF39FF14), // neon green
    Color(0xFF00FFFF), // neon cyan
    Color(0xFFFF4500), // neon orange
    Color(0xFFBF00FF), // neon purple
  ];

  // Event label colors (6)
  static const List<Color> eventColors = [
    Color(0xFFEF9A9A),
    Color(0xFF90CAF9),
    Color(0xFFA5D6A7),
    Color(0xFFFFE082),
    Color(0xFFCE93D8),
    Color(0xFF80DEEA),
  ];

  // UI accents
  static const primary     = Color(0xFFFF7AA2);
  static const secondary   = Color(0xFF7EC8E3);
  static const accent      = Color(0xFFFFD166);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF16213E);
  static const textDark    = Color(0xFF212121);
  static const textLight   = Color(0xFFFAFAFA);
  static const shadow      = Color(0x22000000);
}
