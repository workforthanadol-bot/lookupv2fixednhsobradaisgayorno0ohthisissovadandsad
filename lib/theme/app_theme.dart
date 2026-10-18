import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors - government navy blue palette
  static const Color primaryColor = Color(0xFF1F3A5F);
  static const Color primaryDark = Color(0xFF152A47);
  static const Color primaryLight = Color(0xFF2C4F7C);
  static const Color accentColor = Color(0xFFD4AF37); // gold accent
  static const Color scaffoldBg = Color(0xFFF4F6F9);
  static const Color cardBg = Colors.white;
  static const Color dividerColor = Color(0xFFDDE3EE);
  static const Color textPrimary = Color(0xFF1A2332);
  static const Color textSecondary = Color(0xFF5A6578);
  static const Color textHint = Color(0xFF9AA3B0);
  static const Color successColor = Color(0xFF2E7D32);
  static const Color errorColor = Color(0xFFC62828);
  static const Color warningColor = Color(0xFFF57F17);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: accentColor,
        surface: cardBg,
        background: scaffoldBg,
        error: errorColor,
      ),
      
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: cardBg,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCDD5E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCDD5E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF9AA3B0),
          
          fontSize: 15,
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          
          fontSize: 15,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF9AA3B0),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          
          fontSize: 12,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEEF2F7),
        selectedColor: primaryColor,
        labelStyle: const TextStyle( fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle( fontWeight: FontWeight.w700),
        displayMedium: TextStyle( fontWeight: FontWeight.w700),
        displaySmall: TextStyle( fontWeight: FontWeight.w700),
        headlineLarge: TextStyle( fontWeight: FontWeight.w700),
        headlineMedium: TextStyle( fontWeight: FontWeight.w600),
        headlineSmall: TextStyle( fontWeight: FontWeight.w600),
        titleLarge: TextStyle( fontWeight: FontWeight.w700),
        titleMedium: TextStyle( fontWeight: FontWeight.w600),
        titleSmall: TextStyle( fontWeight: FontWeight.w600),
        bodyLarge: TextStyle( fontSize: 16),
        bodyMedium: TextStyle( fontSize: 15),
        bodySmall: TextStyle( fontSize: 13),
        labelLarge: TextStyle( fontWeight: FontWeight.w700),
        labelMedium: TextStyle(),
        labelSmall: TextStyle( fontSize: 11),
      ),
    );
  }
}
