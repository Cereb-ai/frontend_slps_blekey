import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _brand = Color(0xFF176B87);
  static const _accent = Color(0xFF00D9FF);
  static const _bg = Color(0xFF05070B);
  static const _surface = Color(0xFF0B1220);
  static const _surfaceAlt = Color(0xFF111C2D);
  static const _outline = Color(0xFF1E2E40);
  static const _text = Color(0xFFE6EEF7);
  static const _textMuted = Color(0xFF90A4B8);

  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: _brand,
      onPrimary: Colors.white,
      secondary: _accent,
      onSecondary: Color(0xFF02131A),
      error: Color(0xFFFF6B6B),
      onError: Colors.white,
      surface: _surface,
      onSurface: _text,
      outline: _outline,
      outlineVariant: _outline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _bg,
      dividerColor: _outline,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: _bg,
        foregroundColor: _text,
        titleTextStyle: TextStyle(
          color: _text,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(size: 28),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surface,
        indicatorColor: _brand.withValues(alpha: 0.28),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? _text : _textMuted,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? _accent : _textMuted,
            size: 26,
          );
        }),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceAlt,
        hintStyle: const TextStyle(color: _textMuted),
        labelStyle: const TextStyle(color: _textMuted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _brand),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        isDense: true,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: _text, fontSize: 18),
        bodyMedium: TextStyle(color: _text, fontSize: 16),
        bodySmall: TextStyle(color: _textMuted, fontSize: 14),
        titleLarge: TextStyle(
          color: _text,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: _text,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(color: _text, fontSize: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _brand,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _text,
          side: const BorderSide(color: _outline),
          minimumSize: const Size(48, 56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _accent,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF101A2A),
        contentTextStyle: const TextStyle(color: _text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
