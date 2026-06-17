import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand palette ──────────────────────────────────────────────────
  static const Color primaryGold    = Color(0xFFD4A017);
  static const Color deepAmber      = Color(0xFFB8860B);
  static const Color accentTeal     = Color(0xFF00BFA5);
  static const Color accentCoral    = Color(0xFFFF6B6B);
  static const Color surfaceLight   = Color(0xFFFFFBF0);
  static const Color cardLight      = Color(0xFFFFFFFF);
  static const Color textPrimary    = Color(0xFF1A1A2E);
  static const Color textSecondary  = Color(0xFF6B7280);

  static const Color darkBg         = Color(0xFF0F0F1A);
  static const Color darkSurface    = Color(0xFF1A1A2E);
  static const Color darkCard       = Color(0xFF252540);
  static const Color darkAccent     = Color(0xFFFFD700);

  // ── Text theme ─────────────────────────────────────────────────────
  // Font sizes here are the design baseline (medium phone).
  // main.dart applies MediaQuery.textScaler from AppSession.fontSizeScale
  // so individual sizes stay consistent — they're all scaled together.
  static TextTheme _textTheme(bool isDark) {
    final on  = isDark ? Colors.white    : textPrimary;
    final sub = isDark ? Colors.white60  : textSecondary;
    return TextTheme(
      displayLarge:  GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w700,  color: on,  letterSpacing: -0.5),
      displayMedium: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w700,  color: on),
      displaySmall:  GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w600,  color: on),
      headlineLarge: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600,  color: on),
      headlineMedium:GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600,  color: on),
      headlineSmall: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w600,  color: on),
      titleLarge:    GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600, color: on),
      titleMedium:   GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: on),
      titleSmall:    GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500, color: on),
      bodyLarge:     GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w400, color: on),
      bodyMedium:    GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w400, color: sub),
      bodySmall:     GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400, color: sub),
      labelLarge:    GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: on,  letterSpacing: 0.3),
      labelMedium:   GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: sub, letterSpacing: 0.3),
      labelSmall:    GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w500, color: sub, letterSpacing: 0.5),
    );
  }

  // ── Shared shape tokens ────────────────────────────────────────────
  static final _cardShape    = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  static final _pillShape    = RoundedRectangleBorder(borderRadius: BorderRadius.circular(100));
  static final _inputRadius  = BorderRadius.circular(14);

  // ── Light theme ────────────────────────────────────────────────────
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: surfaceLight,
    primaryColor: primaryGold,
    colorScheme: const ColorScheme.light(
      primary:      primaryGold,
      secondary:    accentTeal,
      tertiary:     accentCoral,
      surface:      cardLight,
      onPrimary:    Colors.white,
      onSecondary:  Colors.white,
      onSurface:    textPrimary,
    ),
    textTheme: _textTheme(false),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryGold,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 20, fontWeight: FontWeight.w700,
        color: Colors.white, letterSpacing: 0.3,
      ),
      iconTheme: const IconThemeData(color: Colors.white, size: 22),
    ),
    cardTheme: CardThemeData(
      color: cardLight,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: _cardShape,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: _pillShape,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: _pillShape,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: _inputRadius,
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: _inputRadius,
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: _inputRadius,
        borderSide: const BorderSide(color: primaryGold, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.dmSans(fontSize: 14, color: Color(0xFFABABAB)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryGold,
      unselectedItemColor: Color(0xFFB0B0B0),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade100,
      selectedColor: primaryGold.withOpacity(0.15),
      labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade200,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: GoogleFonts.dmSans(fontSize: 14),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
      contentTextStyle: GoogleFonts.dmSans(fontSize: 14, color: textSecondary),
    ),
  );

  // ── Dark theme ─────────────────────────────────────────────────────
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    primaryColor: darkAccent,
    colorScheme: const ColorScheme.dark(
      primary:     darkAccent,
      secondary:   accentTeal,
      tertiary:    accentCoral,
      surface:     darkCard,
      onPrimary:   darkBg,
      onSecondary: Colors.white,
      onSurface:   Colors.white,
    ),
    textTheme: _textTheme(true),
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 20, fontWeight: FontWeight.w700,
        color: Colors.white, letterSpacing: 0.3,
      ),
      iconTheme: const IconThemeData(color: Colors.white, size: 22),
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: _cardShape,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: _pillShape,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: _pillShape,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      border: OutlineInputBorder(
        borderRadius: _inputRadius,
        borderSide: const BorderSide(color: Color(0xFF3A3A5C)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: _inputRadius,
        borderSide: const BorderSide(color: Color(0xFF3A3A5C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: _inputRadius,
        borderSide: const BorderSide(color: darkAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.dmSans(fontSize: 14, color: Color(0xFF666680)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: darkAccent,
      unselectedItemColor: Color(0xFF6B7280),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontSize: 10),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkCard,
      selectedColor: darkAccent.withOpacity(0.2),
      labelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2A2A45),
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: GoogleFonts.dmSans(fontSize: 14),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: darkSurface,
      titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
      contentTextStyle: GoogleFonts.dmSans(fontSize: 14, color: Colors.white70),
    ),
  );
}