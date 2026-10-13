import 'package:flutter/material.dart';

/// Warna merek yang sama di mode terang dan gelap: kartu Total saldo,
/// layar kunci, dan splash. Sekaligus warna aksen bawaan ("Hijau sage").
abstract final class AppColors {
  static const hero = Color(0xFF1F5F4E);
  static const onHero = Color(0xFFFFFFFF);
  static const onHeroMuted = Color(0xFFD3E6DE);
}

/// Satu pilihan warna aksen. [id] yang disimpan di app_settings
/// ('accent_color'); [color] adalah warna dasar, warna turunannya dihitung
/// di [AppPalette.withAccent].
class AccentOption {
  const AccentOption(this.id, this.color);

  final String id;
  final Color color;
}

/// Pilihan warna aksen di Pengaturan › Tampilan.
abstract final class AccentPresets {
  static const sage = AccentOption('sage', AppColors.hero);
  static const ocean = AccentOption('ocean', Color(0xFF1D4E89));
  static const violet = AccentOption('violet', Color(0xFF5B3E9B));
  static const rose = AccentOption('rose', Color(0xFFA83B62));
  static const pink = AccentOption('pink', Color(0xFFD8467E));
  static const amber = AccentOption('amber', Color(0xFF8A5A12));
  static const teal = AccentOption('teal', Color(0xFF116B72));

  static const all = [sage, ocean, violet, rose, pink, amber, teal];

  /// Nilai 'accent_color' di app_settings → warna dasar. Belum dipilih
  /// atau tidak dikenal jatuh ke [sage]; string '#RRGGBB' dibaca sebagai
  /// warna kustom (untuk color picker nanti).
  static Color resolve(String? id) {
    if (id != null && id.startsWith('#')) {
      try {
        return hexColor(id);
      } on FormatException {
        // Nilai rusak: pakai bawaan di bawah.
      }
    }
    for (final o in all) {
      if (o.id == id) return o.color;
    }
    return sage.color;
  }
}

/// Token warna yang ikut tema (canvas: baris "Mode gelap").
/// Ambil lewat `context.colors`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.isDark,
    required this.hero,
    required this.onHero,
    required this.onHeroMuted,
    required this.background,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.line,
    required this.divider,
    required this.track,
    required this.handle,
    required this.subtle,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.onPrimarySoft,
    required this.expense,
    required this.income,
    required this.warning,
    required this.warnSoft,
    required this.onWarnSoft,
    required this.highlight,
    required this.shadow,
  });

  final bool isDark;

  /// Warna merek: kartu Total saldo, layar kunci, splash. Bisa diganti di
  /// Pengaturan › Tampilan › Warna aksen, sama di mode terang dan gelap.
  final Color hero;
  final Color onHero;
  final Color onHeroMuted;
  final Color background;
  final Color surface;
  final Color ink;
  final Color muted;

  /// Abu-abu paling pucat: ikon seret, panah kecil.
  final Color faint;
  final Color line;
  final Color divider;
  final Color track;

  /// Pegangan bottom sheet dan garis putus-putus.
  final Color handle;

  /// Latar kotak info yang sedikit beda dari halaman.
  final Color subtle;

  /// Aksen: tombol utama, ikon aktif, bar progres.
  final Color primary;
  final Color onPrimary;
  final Color primarySoft;
  final Color onPrimarySoft;
  final Color expense;
  final Color income;
  final Color warning;
  final Color warnSoft;
  final Color onWarnSoft;

  /// Sorotan kata yang cocok di pencarian.
  final Color highlight;
  final Color shadow;

  static const light = AppPalette(
    isDark: false,
    hero: AppColors.hero,
    onHero: AppColors.onHero,
    onHeroMuted: AppColors.onHeroMuted,
    background: Color(0xFFF6F5F1),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF1B1F1D),
    muted: Color(0xFF5C625F),
    faint: Color(0xFFA6AAA7),
    line: Color(0xFFE4E1D9),
    divider: Color(0xFFEFEDE7),
    track: Color(0xFFECEAE4),
    handle: Color(0xFFD9D6CD),
    subtle: Color(0xFFFAF9F6),
    primary: Color(0xFF1F5F4E),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFDCEBE4),
    onPrimarySoft: Color(0xFF1F5F4E),
    expense: Color(0xFFA3401C),
    income: Color(0xFF17624A),
    warning: Color(0xFF9A5B12),
    warnSoft: Color(0xFFFBF3D6),
    onWarnSoft: Color(0xFF5B4A12),
    highlight: Color(0xFFFDE9A8),
    shadow: Color(0xFF1B1F1D),
  );

  static const dark = AppPalette(
    isDark: true,
    hero: AppColors.hero,
    onHero: AppColors.onHero,
    onHeroMuted: AppColors.onHeroMuted,
    background: Color(0xFF111513),
    surface: Color(0xFF1A1F1D),
    ink: Color(0xFFE6EBE8),
    muted: Color(0xFFA0A8A4),
    faint: Color(0xFF6C7470),
    line: Color(0xFF2C3330),
    divider: Color(0xFF252B28),
    track: Color(0xFF2B322F),
    handle: Color(0xFF3A423E),
    subtle: Color(0xFF161A18),
    primary: Color(0xFF7CC7A8),
    onPrimary: Color(0xFF0D2A20),
    primarySoft: Color(0xFF1F3A31),
    onPrimarySoft: Color(0xFFA6DBC4),
    expense: Color(0xFFF2A285),
    income: Color(0xFF7DD3AE),
    warning: Color(0xFFE8B46A),
    warnSoft: Color(0xFF3A3019),
    onWarnSoft: Color(0xFFE8D29A),
    highlight: Color(0xFF5A4A16),
    shadow: Color(0xFF000000),
  );

  /// Warna teks/ikon kategori. Di mode gelap dinaikkan terangnya supaya
  /// terbaca di atas latar gelap.
  Color fg(Color c) {
    if (!isDark) return c;
    final hsl = HSLColor.fromColor(c);
    return hsl.lightness >= 0.72 ? c : hsl.withLightness(0.74).toColor();
  }

  /// Latar lembut untuk chip kategori, diturunkan dari warna utamanya.
  Color soft(Color c) => isDark
      ? Color.lerp(c, surface, 0.78)!
      : Color.lerp(c, Colors.white, 0.86)!;

  /// Lingkaran pastel di belakang maskot; di mode gelap jadi versi redupnya.
  Color tint(Color pastel) {
    if (!isDark) return pastel;
    final hsl = HSLColor.fromColor(pastel);
    return hsl
        .withSaturation(hsl.saturation.clamp(0, 0.24))
        .withLightness(0.17)
        .toColor();
  }

  /// Segmen terpilih di atas track: putih di mode terang, sedikit lebih
  /// terang dari track di mode gelap.
  Color get raised => isDark ? handle : surface;

  /// Hanya token aksen (hero + primary) yang bisa ditimpa; sisanya ikut
  /// palet dasar. Dipakai [withAccent].
  @override
  AppPalette copyWith({
    Color? hero,
    Color? onHero,
    Color? onHeroMuted,
    Color? primary,
    Color? onPrimary,
    Color? primarySoft,
    Color? onPrimarySoft,
  }) => AppPalette(
        isDark: isDark,
        hero: hero ?? this.hero,
        onHero: onHero ?? this.onHero,
        onHeroMuted: onHeroMuted ?? this.onHeroMuted,
        background: background,
        surface: surface,
        ink: ink,
        muted: muted,
        faint: faint,
        line: line,
        divider: divider,
        track: track,
        handle: handle,
        subtle: subtle,
        primary: primary ?? this.primary,
        onPrimary: onPrimary ?? this.onPrimary,
        primarySoft: primarySoft ?? this.primarySoft,
        onPrimarySoft: onPrimarySoft ?? this.onPrimarySoft,
        expense: expense,
        income: income,
        warning: warning,
        warnSoft: warnSoft,
        onWarnSoft: onWarnSoft,
        highlight: highlight,
        shadow: shadow,
      );

  /// Palet dengan warna aksen [seed] menggantikan hijau bawaan: token hero
  /// dan primary berubah, warna semantic (expense/income/warning) dan
  /// netral tetap. Warna turunan dihitung dari hue [seed] supaya mode
  /// terang dan gelap tetap satu keluarga warna.
  AppPalette withAccent(Color seed) {
    if (seed == AppColors.hero) return this;
    final hsl = HSLColor.fromColor(seed);
    final onHero = readableOn(seed);
    final onHeroMuted = Color.lerp(onHero, seed, 0.2)!;
    if (!isDark) {
      // Terang: primary gelap sedikit supaya teks putih tetap terbaca.
      final primary =
          hsl.withLightness(hsl.lightness.clamp(0.22, 0.52).toDouble()).toColor();
      return copyWith(
        hero: seed,
        onHero: onHero,
        onHeroMuted: onHeroMuted,
        primary: primary,
        onPrimary: readableOn(primary),
        primarySoft: Color.lerp(primary, Colors.white, 0.86)!,
        onPrimarySoft: seed,
      );
    }
    // Gelap: primary dinaikkan terangnya dan dijenuhkan sedang, seperti
    // pasangan hijau tua ↔ hijau muda di palet bawaan.
    final saturation = hsl.saturation.clamp(0.30, 0.52).toDouble();
    final primary = hsl.withLightness(0.64).withSaturation(saturation);
    return copyWith(
      hero: seed,
      onHero: onHero,
      onHeroMuted: onHeroMuted,
      primary: primary.toColor(),
      onPrimary: hsl.withLightness(0.13).toColor(),
      primarySoft: Color.lerp(primary.toColor(), surface, 0.78)!,
      onPrimarySoft: primary.withLightness(0.76).toColor(),
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

extension AppPaletteContext on BuildContext {
  /// Tanpa [buildTheme] (mis. MaterialApp polos di tes) jatuh ke palet
  /// sesuai kecerahan tema.
  AppPalette get colors {
    final theme = Theme.of(this);
    return theme.extension<AppPalette>() ??
        (theme.brightness == Brightness.dark
            ? AppPalette.dark
            : AppPalette.light);
  }
}

Color hexColor(String hex) =>
    Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));

/// Teks/ikon yang paling terbaca di atas [bg]: putih atau tinta gelap,
/// dipilih berdasarkan rasio kontras WCAG (minimal ~4:1).
Color readableOn(Color bg) {
  const ink = Color(0xFF1B1F1D);
  const white = Color(0xFFFFFFFF);
  final lum = bg.computeLuminance();
  double contrast(Color c) {
    final cl = c.computeLuminance();
    final hi = cl > lum ? cl : lum;
    final lo = cl > lum ? lum : cl;
    return (hi + 0.05) / (lo + 0.05);
  }

  return contrast(white) >= contrast(ink) ? white : ink;
}

/// Gaya teks tombol berbasis tema. `textStyle` di ButtonStyle MENGGANTIKAN
/// gaya tema (tidak digabung), jadi tanpa ini label tombol kehilangan Poppins.
TextStyle buttonTextStyle(BuildContext context, TextStyle overrides) =>
    Theme.of(context).textTheme.labelLarge!.merge(overrides);

/// Membangun tema untuk [brightness] dengan warna aksen [accent]
/// (bawaan: hijau sage [AppColors.hero]).
ThemeData buildTheme(Brightness brightness, {Color accent = AppColors.hero}) {
  final c = (brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light)
      .withAccent(accent);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: c.hero,
        brightness: brightness,
      ).copyWith(
        primary: c.primary,
        onPrimary: c.onPrimary,
        primaryContainer: c.primarySoft,
        onPrimaryContainer: c.onPrimarySoft,
        secondaryContainer: c.primarySoft,
        onSecondaryContainer: c.onPrimarySoft,
        surface: c.background,
        onSurface: c.ink,
        onSurfaceVariant: c.muted,
        surfaceContainerLowest: c.surface,
        surfaceContainerLow: c.surface,
        surfaceContainer: c.surface,
        surfaceContainerHigh: c.surface,
        surfaceContainerHighest: c.track,
        outline: c.line,
        outlineVariant: c.divider,
        error: c.expense,
      );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    // Didaftarkan di pubspec.yaml (flutter > fonts) dengan 4 ketebalan.
    fontFamily: 'Poppins',
    colorScheme: scheme,
    scaffoldBackgroundColor: c.background,
    extensions: [c],
  );
  final text = base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink);
  final inputBorder = OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: c.line),
  );
  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: c.ink,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(color: c.divider),
    dialogTheme: DialogThemeData(backgroundColor: c.surface),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: c.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.onPrimary : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.primary : null,
      ),
    ),
  );
}

/// Kartu bergaris tipis, dipakai di hampir semua layar.
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
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}
