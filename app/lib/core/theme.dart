import 'package:flutter/material.dart';

/// Token warna dari canvas desain.
abstract final class AppColors {
  static const primary = Color(0xFF1F5F4E);
  static const primarySoft = Color(0xFFDCEBE4);
  static const primaryOnDark = Color(0xFFD3E6DE);
  static const background = Color(0xFFF6F5F1);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1B1F1D);
  static const muted = Color(0xFF5C625F);
  static const line = Color(0xFFE4E1D9);
  static const divider = Color(0xFFEFEDE7);
  static const track = Color(0xFFECEAE4);
  static const expense = Color(0xFFA3401C);
  static const income = Color(0xFF17624A);
}

Color hexColor(String hex) =>
    Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

/// Latar lembut untuk chip kategori, diturunkan dari warna utamanya.
Color softOf(Color c) => Color.lerp(c, Colors.white, 0.86)!;

/// Gaya teks tombol berbasis tema. `textStyle` di ButtonStyle MENGGANTIKAN
/// gaya tema (tidak digabung), jadi tanpa ini label tombol kehilangan Poppins.
TextStyle buttonTextStyle(BuildContext context, TextStyle overrides) =>
    Theme.of(context).textTheme.labelLarge!.merge(overrides);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    // Didaftarkan di pubspec.yaml (flutter > fonts) dengan 4 ketebalan.
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.background,
      onSurface: AppColors.ink,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );
  final text = base.textTheme.apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  );
  const inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: AppColors.line),
  );
  return base.copyWith(
    textTheme: text,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
  );
}

/// Kartu putih bergaris tipis, dipakai di hampir semua layar.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}
