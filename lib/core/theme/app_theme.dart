import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Theme Colors
  static const Color primary = Color(0xFF2563EB);       // #2563EB (Blue)
  static const Color accent = Color(0xFF7C3AED);        // #7C3AED (Purple)
  static const Color background = Color(0xFF0F172A);    // #0F172A (Slate Dark)
  static const Color cardColor = Color(0xFF1E293B);      // #1E293B (Lighter Slate)
  static const Color textColor = Color(0xFFF8FAFC);      // #F8FAFC (Slate-50)
  static const Color textMutedColor = Color(0xFF94A3B8); // #94A3B8 (Slate-400)
  static const Color success = Color(0xFF22C55E);       // #22C55E (Green)
  static const Color error = Color(0xFFEF4444);         // #EF4444 (Red)
  static const Color glassBorder = Color(0xFF334155);    // #334155 (Slate-700)

  // Gradients algorithm
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient alertGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1A1E293B), // 10% Opacity Card Color
      Color(0x0D1E293B), // 5% Opacity Card Color
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark(useMaterial3: true);
    
    return baseTheme.copyWith(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: cardColor,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: cardColor,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor,
      ),
      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme).apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor.withOpacity(0.5),
        hintStyle: GoogleFonts.outfit(color: textMutedColor, fontSize: 15),
        labelStyle: GoogleFonts.outfit(color: textMutedColor, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: glassBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: glassBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error, width: 2),
        ),
      ),
      cardTheme: const CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: glassBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
