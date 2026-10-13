import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/money_snapshot.dart';
import '../../providers.dart';
import '../../ui/common.dart';
import '../../ui/mascot.dart';
import 'wallet_form_sheet.dart';

/// Halaman "Kelola dompet": daftar dompet aktif dan arsip, tambah dompet,
/// dan pintu ke lembar ubah/arsip/hapus. Dibuka dari Keuangan.
class WalletsScreen extends ConsumerStatefulWidget {
  const WalletsScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const WalletsScreen()));

  @override
  ConsumerState<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends ConsumerState<WalletsScreen> {
  bool _archiveOpen = true;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final snap = ref.watch(moneySnapshotProvider).value;
    final hideAmounts = ref.watch(hideAmountsProvider).value ?? false;

    Widget sectionTitle(String text) => Text(
      text.toUpperCase(),
      style: t.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: context.colors.muted,
        fontSize: 13,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.manageWallets,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => WalletFormSheet.open(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l.add),
            ),
          ),
        ],
      ),
      body: snap == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.walletsTotal(snap.wallets.length),
                        style: t.bodySmall?.copyWith(
                          color: context.colors.muted,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        signedRupiah(snap.totalBalance, hide: hideAmounts),
                        style: t.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: sectionTitle(l.activeWallets),
                ),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (final (i, w) in snap.wallets.indexed)
                        _WalletRow(
                          wallet: w,
                          snapshot: snap,
                          showDivider: i < snap.wallets.length - 1,
                        ),
                    ],
                  ),
                ),
                if (snap.archivedWallets.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => setState(() => _archiveOpen = !_archiveOpen),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: sectionTitle(
                              l.archivedWalletsCard(
                                snap.archivedWallets.length,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _archiveOpen ? 0.5 : 0,
                            duration: const Duration(milliseconds: 150),
                            child: Icon(
                              Icons.expand_more,
                              color: context.colors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_archiveOpen) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                      child: Text(
                        l.archiveWalletHint,
                        style: t.bodySmall?.copyWith(
                          color: context.colors.muted,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: context.colors.subtle,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: context.colors.handle),
                      ),
                      child: Column(
                        children: [
                          for (final (i, w) in snap.archivedWallets.indexed)
                            _ArchivedRow(
                              wallet: w,
                              snapshot: snap,
                              showDivider: i < snap.archivedWallets.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
    );
  }
}

int _txCount(MoneySnapshot snap, String walletId) => snap.transactions
    .where((t) => t.walletId == walletId || t.toWalletId == walletId)
    .length;

class _WalletRow extends ConsumerWidget {
  const _WalletRow({
    required this.wallet,
    required this.snapshot,
    required this.showDivider,
  });

  final Wallet wallet;
  final MoneySnapshot snapshot;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final hideAmounts = ref.watch(hideAmountsProvider).value ?? false;
    final balance = snapshot.balanceOf(wallet.id);
    final (icon, raw) = switch (wallet.type) {
      'cash' => (Icons.payments_outlined, context.colors.hero),
      'ewallet' => (Icons.phone_iphone, const Color(0xFF6B2C7A)),
      'bank' => (Icons.account_balance_outlined, const Color(0xFF1E4E79)),
      _ => (Icons.account_balance_wallet_outlined, const Color(0xFF4A4E4C)),
    };
    final fg = context.colors.fg(raw);
    final typeLabel = switch (wallet.type) {
      'cash' => l.walletTypeCash,
      'bank' => l.walletTypeBank,
      'ewallet' => l.walletTypeEwallet,
      _ => l.walletTypeOther,
    };

    return InkWell(
      onTap: () => WalletFormSheet.open(context, existing: wallet),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: context.colors.divider))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.colors.soft(raw),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: fg, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$typeLabel · ${l.walletTxCount(_txCount(snapshot, wallet.id))}',
                    style: t.bodySmall?.copyWith(color: context.colors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              signedRupiah(balance, hide: hideAmounts),
              style: t.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: balance < 0
                    ? context.colors.expense
                    : context.colors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchivedRow extends ConsumerWidget {
  const _ArchivedRow({
    required this.wallet,
    required this.snapshot,
    required this.showDivider,
  });

  final Wallet wallet;
  final MoneySnapshot snapshot;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final hideAmounts = ref.watch(hideAmountsProvider).value ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: context.colors.divider))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => WalletFormSheet.open(context, existing: wallet),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.muted,
                      ),
                    ),
                    Text(
                      l.archivedWalletLine(
                        _txCount(snapshot, wallet.id),
                        signedRupiah(snapshot.balanceOf(wallet.id), hide: hideAmounts),
                      ),
                      style: t.bodySmall?.copyWith(color: context.colors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () async {
              await ref
                  .read(moneyRepositoryProvider)
                  .setWalletArchived(wallet.id, false);
              if (context.mounted) {
                showMascotSnackBar(
                  context,
                  MascotPose.senang,
                  l.toastWalletUnarchived,
                );
              }
            },
            child: Text(l.unarchiveShort),
          ),
        ],
      ),
    );
  }
}
