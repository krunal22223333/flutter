import 'package:flutter/material.dart';

/// Design palette (from provided mockups). Keep exact for brand consistency.
class AppColors {
  static const primary     = Color(0xFF2563EB); // buttons, active, links
  static const primaryDark = Color(0xFF1E3A8A); // header gradient top
  static const headerGrad1 = Color(0xFF1E3A8A);
  static const headerGrad2 = Color(0xFF2563EB);
  static const bg          = Color(0xFFF3F6FB); // page background
  static const card        = Color(0xFFFFFFFF);
  static const text        = Color(0xFF0F172A);
  static const text2       = Color(0xFF475569);
  static const text3       = Color(0xFF94A3B8);
  static const border      = Color(0xFFE5E7EB);
  static const green       = Color(0xFF16A34A);
  static const red         = Color(0xFFDC2626);
  static const orange      = Color(0xFFEA580C);
  static const amber       = Color(0xFFCA8A04);
  static const purple      = Color(0xFF7C3AED);
  static const teal        = Color(0xFF0D9488);
}

ThemeData buildTheme() {
  final base = ThemeData(useMaterial3: true, fontFamily: 'Roboto');
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: base.colorScheme.copyWith(primary: AppColors.primary),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    textTheme: base.textTheme.apply(bodyColor: AppColors.text, displayColor: AppColors.text),
  );
}

/// Small helpers used across screens.
BoxDecoration cardDecoration() => BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
      boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
    );
