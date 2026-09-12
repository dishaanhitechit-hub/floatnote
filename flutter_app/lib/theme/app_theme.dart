import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'palette.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: FNPalette.primary,
      brightness: Brightness.light,
      surface: FNPalette.canvas,
    ),
    scaffoldBackgroundColor: FNPalette.canvas,
    textTheme: GoogleFonts.quicksandTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.pacifico(
        fontSize: 22,
        color: FNPalette.textDark,
        letterSpacing: 0.5,
      ),
      iconTheme: const IconThemeData(color: FNPalette.textDark),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: FNPalette.primary,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.85),
      indicatorColor: FNPalette.primary.withValues(alpha: 0.2),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.quicksand(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: FNPalette.primary,
      brightness: Brightness.dark,
      surface: FNPalette.canvasDark,
    ),
    scaffoldBackgroundColor: FNPalette.canvasDark,
    textTheme: GoogleFonts.quicksandTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.pacifico(
        fontSize: 22,
        color: FNPalette.textLight,
        letterSpacing: 0.5,
      ),
      iconTheme: const IconThemeData(color: FNPalette.textLight),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: FNPalette.primary,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: FNPalette.surfaceDark.withValues(alpha: 0.9),
      indicatorColor: FNPalette.primary.withValues(alpha: 0.25),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.quicksand(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
  );

  // Available note fonts
  static const List<String> noteFonts = [
    'Caveat',
    'Indie Flower',
    'Dancing Script',
    'Patrick Hand',
    'Pacifico',
    'Satisfy',
    'Quicksand',
    'Nunito',
  ];

  static TextStyle noteFont(String family, {double size = 16, Color? color}) {
    final style = TextStyle(fontSize: size, color: color ?? FNPalette.textDark);
    switch (family) {
      case 'Indie Flower':    return GoogleFonts.indieFlower(textStyle: style);
      case 'Dancing Script':  return GoogleFonts.dancingScript(textStyle: style);
      case 'Patrick Hand':    return GoogleFonts.patrickHand(textStyle: style);
      case 'Pacifico':        return GoogleFonts.pacifico(textStyle: style);
      case 'Satisfy':         return GoogleFonts.satisfy(textStyle: style);
      case 'Quicksand':       return GoogleFonts.quicksand(textStyle: style);
      case 'Nunito':          return GoogleFonts.nunito(textStyle: style);
      default:                return GoogleFonts.caveat(textStyle: style);
    }
  }
}
