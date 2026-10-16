import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/format.dart';
import '../core/platform/platform_info.dart';
import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../data/money_snapshot.dart';
import '../l10n/app_localizations.dart';
import '../providers.dart';
import 'category_icons.dart';

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

/// Nama kategori bawaan diterjemahkan; kategori buatan user apa adanya.
String categoryLabel(AppLocalizations l, Category c) => switch (c.systemKey) {
  'food' => l.catFood,
  'transport' => l.catTransport,
  'shopping' => l.catShopping,
  'bills' => l.catBills,
  'entertainment' => l.catEntertainment,
  'other' => l.catOther,
  'salary' => l.catSalary,
  'bonus' => l.catBonus,
  'other_income' => l.catOtherIncome,
  _ => c.name,
};

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

/// Kotak inisial berwarna untuk kategori.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category, this.size = 40});

  final Category? category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = category;
    final raw = c == null ? context.colors.muted : hexColor(c.color);
    final fg = context.colors.fg(raw);
    final label = c == null ? '↔' : categoryLabel(context.l10n, c);
    // Ikon pilihan user; tanpa ikon = huruf (atau emoji) pertama nama.
    final icon = categoryIcons[c?.icon];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.soft(raw),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: icon != null
          ? Icon(icon, color: fg, size: size * 0.55)
          : Text(
              label.characters.first.toUpperCase(),
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.4,
              ),
            ),
    );
  }
}

/// Badge transfer antar dompet: panah bolak-balik biru, sebentuk dengan
/// [CategoryBadge].
class TransferBadge extends StatelessWidget {
  const TransferBadge({super.key, this.size = 40});

  final double size;

  static const _fg = Color(0xFF2F5D8A);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.isDark
            ? context.colors.soft(_fg)
            : const Color(0xFFE3EDF8),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        Icons.swap_horiz,
        color: context.colors.fg(_fg),
        size: size * 0.55,
      ),
    );
  }
}

/// Satu baris transaksi: badge, catatan, meta, nominal.
class TxRow extends ConsumerWidget {
  const TxRow({
    super.key,
    required this.tx,
    required this.snapshot,
    required this.onTap,
    this.leadingTime = false,
    this.showDivider = true,
  });

  final MoneyTx tx;
  final MoneySnapshot snapshot;
  final VoidCallback onTap;

  /// Hari Ini menampilkan jam di kiri; Keuangan menaruhnya di meta.
  final bool leadingTime;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final hide = ref.watch(hideAmountsProvider).value ?? false;
    final cat = tx.categoryId == null
        ? null
        : snapshot.categoryById[tx.categoryId];
    final wallet = snapshot.walletById[tx.walletId];
    final catName = cat == null ? '' : categoryLabel(l, cat);
    final isTransfer = tx.type == 'transfer';
    final isOut = tx.type == 'expense';
    final time = hhmm(tx.occurredAt);
    final toWallet = snapshot.walletById[tx.toWalletId];
    final metaStyle = t.bodySmall?.copyWith(color: context.colors.muted);
    // Panah transfer berupa icon: Poppins tidak punya karakter "→".
    final meta = <InlineSpan>[
      if (!leadingTime) TextSpan(text: time),
      if (catName.isNotEmpty) TextSpan(text: catName),
      if (isTransfer)
        TextSpan(
          children: [
            TextSpan(text: wallet?.name ?? '?'),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  Icons.arrow_forward,
                  size: 12,
                  color: context.colors.muted,
                  semanticLabel: l.transferTo.toLowerCase(),
                ),
              ),
            ),
            TextSpan(text: toWallet?.name ?? '?'),
          ],
        )
      else if (wallet != null)
        TextSpan(text: wallet.name),
    ];
    // Transfer hanya memindahkan uang: tanpa tanda +/−, warna netral.
    final amountText = hide
        ? maskedRupiah
        : (isTransfer
            ? rupiah(tx.amount)
            : '${isOut ? '−' : '+'}${rupiah(tx.amount)}');
    final amountColor = isTransfer
        ? context.colors.ink
        : isOut
        ? context.colors.expense
        : context.colors.income;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: context.colors.divider))
              : null,
        ),
        child: Row(
          children: [
            if (leadingTime)
              SizedBox(
                width: 46,
                child: Text(
                  time,
                  style: t.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.muted,
                  ),
                ),
              ),
            if (isTransfer)
              TransferBadge(size: leadingTime ? 36 : 40)
            else
              CategoryBadge(category: cat, size: leadingTime ? 36 : 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.note ?? (isTransfer ? l.transfer : catName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        for (var i = 0; i < meta.length; i++) ...[
                          if (i > 0) const TextSpan(text: ' · '),
                          meta[i],
                        ],
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: metaStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amountText,
              style: t.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
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
