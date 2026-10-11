import 'package:flutter/material.dart';

/// Token warna Stripe dari Design.md.
/// Ungu primary hanya untuk aksi interaktif, tidak untuk wash latar.
class StripeColors {
  StripeColors._();

  static const Color primary = Color(0xFF533AFD);
  static const Color primaryDeep = Color(0xFF2E2B8C);
  static const Color ink = Color(0xFF061B31);
  static const Color background = Colors.white;
  static const Color canvas = Color(0xFFF8FAFC);
  static const Color bone = Color(0xFFF1F5F9);
  static const Color hairline = Color(0xFFE5EDF5);
  static const Color hairlineStrong = Color(0xFFB9B9F9);
  static const Color body = Color(0xFF64748D);
  static const Color stone = Color(0xFFA0AEC0);
  static const Color danger = Color(0xFFEA2261);
  static const Color dangerText = Color(0xFFC71B50);
  static const Color dangerWash = Color(0x1AEA2261);
  static const Color success = Color(0xFF15BE53);
  static const Color successText = Color(0xFF108C3D);
  static const Color successWash = Color(0x3315BE53);
  static const Color focusRing = Color(0x80533AFD);
  static const Color overlay = Color(0x66061B31);
}

/// Radius Stripe: tombol dan input 4px, kartu 6px.
/// Override satu baris: NeedMCP craft floor menyarankan kartu 12-16px,
/// tetapi token Stripe menetapkan kartu 6px sehingga token Stripe menang.
class StripeRadius {
  StripeRadius._();

  static const double control = 4;
  static const double card = 6;
  static const double dialog = 8;
}

ThemeData stripeTheme() {
  const scheme = ColorScheme.light(
    primary: StripeColors.primary,
    onPrimary: Colors.white,
    secondary: StripeColors.ink,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: StripeColors.ink,
    error: StripeColors.danger,
    onError: Colors.white,
  );

  final textTheme = const TextTheme(
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.4,
      color: StripeColors.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: StripeColors.ink,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: StripeColors.ink,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: StripeColors.ink,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: StripeColors.body,
    ),
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.0,
      color: Colors.white,
    ),
  );

  final outline = OutlineInputBorder(
    borderRadius: BorderRadius.circular(StripeRadius.control),
    borderSide: const BorderSide(color: StripeColors.hairline),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: StripeColors.background,
    canvasColor: StripeColors.canvas,
    textTheme: textTheme,
    focusColor: StripeColors.focusRing,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: StripeColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StripeRadius.control),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ).copyWith(
        overlayColor: WidgetStateProperty.all(
          Colors.white.withValues(alpha: 0.12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: StripeColors.primary,
        minimumSize: const Size(double.infinity, 48),
        side: const BorderSide(color: StripeColors.hairlineStrong),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StripeRadius.control),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: StripeColors.primary,
        minimumSize: const Size(44, 44),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      constraints: const BoxConstraints(minHeight: 48),
      hintStyle: const TextStyle(color: StripeColors.body, fontSize: 16),
      border: outline,
      enabledBorder: outline,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StripeRadius.control),
        borderSide: const BorderSide(color: StripeColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StripeRadius.control),
        borderSide: const BorderSide(color: StripeColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StripeRadius.control),
        borderSide: const BorderSide(color: StripeColors.danger, width: 1.5),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StripeRadius.card),
        side: const BorderSide(color: StripeColors.hairline),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StripeRadius.control),
      ),
      side: const BorderSide(color: StripeColors.hairlineStrong, width: 1.5),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? StripeColors.primary
            : StripeColors.body,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: StripeColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: StripeColors.ink,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: StripeColors.ink,
      contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
