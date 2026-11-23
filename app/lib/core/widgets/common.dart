import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../format.dart';
import '../platform/platform_info.dart';
import '../theme.dart';
import '../../l10n/app_localizations.dart';
import '../tokens.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get localeTag => Localizations.localeOf(this).languageCode;
}

extension ResponsiveX on BuildContext {
  /// True jika layar lebar (desktop / tablet >= 720dp).
  bool get isWide => PlatformInfo.isWideScreen(MediaQuery.sizeOf(this).width);

  /// Padding bawah daftar: ruang untuk dock mengapung (tinggi 72 + jarak 16 +
  /// napas 20) ditambah navigasi sistem HP, atau 24dp di desktop/layar lebar
  /// karena navigasi ada di sidebar kiri.
  double get bottomDockPadding => isWide
      ? 24.0
      : 108.0 + MediaQuery.paddingOf(this).bottom;

  /// Padding standar layar yang adaptif.
  EdgeInsets get screenPadding =>
      EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.xxl, AppSpace.xl, bottomDockPadding);
}

/// "Hari ini · Kamis, 8 Okt"
String dayLabel(BuildContext context, String localDate) {
  final l = context.l10n;
  final date = parseLocalDate(localDate);
  final base = DateFormat('EEEE, d MMM', context.localeTag).format(date);
  final now = DateTime.now();
  if (localDate == toLocalDate(now)) return '${l.today} · $base';
  if (localDate == toLocalDate(now.subtract(const Duration(days: 1)))) {
    return '${l.yesterday} · $base';
  }
  return base;
}

/// Teks pendek satu baris (label, nominal) yang mengecil kalau tempatnya
/// sempit, supaya tidak patah di tengah kata atau terpotong "…".
class FitText extends StatelessWidget {
  const FitText(
    this.text, {
    super.key,
    this.style,
    this.alignment = Alignment.centerLeft,
  });

  final String text;
  final TextStyle? style;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: alignment,
    child: Text(text, maxLines: 1, softWrap: false, style: style),
  );
}

/// Judul besar di atas layar tab: tanggal/bulan kecil + judul.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.overline,
    required this.title,
    this.trailing,
  });

  final String overline;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tanggal memakai lebar penuh, jadi tidak patah di HP sempit.
        FitText(
          overline,
          style: t.bodySmall?.copyWith(
            color: context.colors.muted,
            fontSize: AppFontSize.body,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: FitText(
                title,
                style: t.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            // Tinggi sama di semua tab, dengan atau tanpa tombol.
            const SizedBox(width: AppSpace.sm, height: 48),
            ?trailing,
          ],
        ),
      ],
    );
  }
}

/// Teks muted sederhana untuk state kosong.
class EmptyNote extends StatelessWidget {
  const EmptyNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: context.colors.muted),
      ),
    );
  }
}
