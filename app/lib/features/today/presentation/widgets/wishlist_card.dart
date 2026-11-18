import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../../../../core/theme.dart';
import '../../../../core/database/app_database.dart';
import '../../../../providers.dart';
import '../../../money/presentation/wishlist_deposit_sheet.dart';
import '../../../money/presentation/wishlist_form_sheet.dart';
import '../../../../core/tokens.dart';

class WishlistCard extends ConsumerWidget {
  const WishlistCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final wishlists = ref.watch(wishlistsProvider).value ?? const [];
    final activeWishlists = wishlists.where((w) => !w.isFulfilled).toList();
    final snap = ref.watch(moneySnapshotProvider).value;
    final hide = ref.watch(hideAmountsProvider).value ?? false;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text('✨ ', style: TextStyle(fontSize: AppFontSize.title)),
                    Flexible(
                      child: Text(
                        'Wishlist & Target Impian',
                        style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => WishlistFormSheet.open(context),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xxs),
                  child: Text(
                    '+ Tambah',
                    style: t.bodySmall?.copyWith(
                      color: context.colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          if (activeWishlists.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
              child: Text(
                'Belum ada impian yang ditambahkan. Tambahkan wishlist pertamamu!',
                style: t.bodySmall?.copyWith(color: context.colors.muted),
              ),
            )
          else
            for (var i = 0; i < activeWishlists.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpace.md),
              _buildWishlistItem(context, ref, activeWishlists[i], snap, hide),
            ],
        ],
      ),
    );
  }

  Widget _buildWishlistItem(
    BuildContext context,
    WidgetRef ref,
    Wishlist w,
    dynamic snap,
    bool hide,
  ) {
    final t = Theme.of(context).textTheme;
    final pct = w.targetAmount > 0
        ? ((w.savedAmount / w.targetAmount) * 100).round()
        : 0;
    final progress = w.targetAmount > 0
        ? (w.savedAmount / w.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    final targetWallet = w.walletId != null ? snap?.walletById[w.walletId!] : null;
    final monthly = w.targetMonths > 0 ? (w.targetAmount / w.targetMonths).round() : 0;
    final daily = (monthly / 30).round();
    // Setoran bisa melebihi target; jangan tampilkan kekurangan negatif.
    final shortfall = w.targetAmount > w.savedAmount
        ? w.targetAmount - w.savedAmount
        : 0;

    return InkWell(
      onTap: () => WishlistFormSheet.open(context, existing: w),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: context.colors.subtle,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.colors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    w.title,
                    style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  rupiah(w.targetAmount, hide: hide),
                  style: t.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            if (targetWallet != null)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpace.sm),
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xxs),
                decoration: BoxDecoration(
                  color: context.colors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '🏦 Disimpan di: ${targetWallet.name}',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  ),
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: context.colors.track,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Terkumpul: ${rupiah(w.savedAmount, hide: hide)} ($pct%)',
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall?.copyWith(fontSize: AppFontSize.caption, color: context.colors.muted),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Flexible(
                  child: Text(
                    'Kurang: ${rupiah(shortfall, hide: hide)}',
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: t.bodySmall?.copyWith(fontSize: AppFontSize.caption, color: context.colors.muted),
                  ),
                ),
              ],
            ),
            if (monthly > 0) ...[
              const SizedBox(height: AppSpace.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.sm),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Rincian: ${rupiah(monthly, hide: hide)} / bln (sekitar ${rupiah(daily, hide: hide)} / hr)',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          color: context.colors.ink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    SizedBox(
                      height: 32,
                      child: FilledButton(
                        onPressed: () => WishlistDepositSheet.open(context, wishlist: w),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                          textStyle: const TextStyle(fontSize: AppFontSize.caption, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('+ Nabung'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
