import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../format.dart';
import '../platform/platform_info.dart';
import '../theme.dart';
import '../../l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  String get localeTag => Localizations.localeOf(this).languageCode;
}

extension ResponsiveX on BuildContext {
  /// True jika layar lebar (desktop / tablet >= 720dp).
  bool get isWide => PlatformInfo.isWideScreen(MediaQuery.sizeOf(this).width);

  /// Padding bawah daftar: 124dp untuk memberi ruang dock mengapung di HP,
  /// atau 24dp di desktop/layar lebar karena navigasi ada di sidebar kiri.
  double get bottomDockPadding => isWide ? 24.0 : 124.0;

  /// Padding standar layar yang adaptif.
  EdgeInsets get screenPadding =>
      EdgeInsets.fromLTRB(20, 24, 20, bottomDockPadding);
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                overline,
                style: t.bodySmall?.copyWith(
                  color: context.colors.muted,
                  fontSize: 13,
                ),
              ),
              Text(
                title,
                style: t.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: context.colors.muted),
      ),
    );
  }
}
