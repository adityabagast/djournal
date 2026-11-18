import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/database/app_database.dart';
import '../../../providers.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_sheet.dart';

class WishlistDepositSheet extends ConsumerStatefulWidget {
  const WishlistDepositSheet({super.key, required this.wishlist});

  final Wishlist wishlist;

  static Future<void> open(BuildContext context, {required Wishlist wishlist}) {
    return showAppSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => WishlistDepositSheet(wishlist: wishlist),
    );
  }

  @override
  ConsumerState<WishlistDepositSheet> createState() => _WishlistDepositSheetState();
}

class _WishlistDepositSheetState extends ConsumerState<WishlistDepositSheet> {
  final _amountController = TextEditingController();
  String? _sourceWalletId;

  @override
  void initState() {
    super.initState();
    final remaining = widget.wishlist.targetAmount - widget.wishlist.savedAmount;
    final monthly = widget.wishlist.targetMonths > 0
        ? (widget.wishlist.targetAmount / widget.wishlist.targetMonths).round()
        : 100000;
    final defaultAmount = remaining < monthly ? remaining : monthly;
    _amountController.text = thousands(defaultAmount > 0 ? defaultAmount : 50000);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final snap = ref.watch(moneySnapshotProvider).value;
    final activeWallets = snap?.wallets ?? const [];

    if (_sourceWalletId == null && activeWallets.isNotEmpty) {
      _sourceWalletId = activeWallets.first.id;
    }

    final targetWallet = widget.wishlist.walletId != null
        ? snap?.walletById[widget.wishlist.walletId!]
        : null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpace.lg),
          Text(
            'Setor Tabungan Wishlist',
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            widget.wishlist.title,
            style: t.bodyMedium?.copyWith(
              color: context.colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (targetWallet != null)
            Text(
              'Disimpan di: ${targetWallet.name}',
              style: t.bodySmall?.copyWith(color: context.colors.muted),
            ),
          const SizedBox(height: AppSpace.lg),
          DropdownButtonFormField<String>(
            initialValue: _sourceWalletId,
            decoration: const InputDecoration(
              labelText: 'Ambil dari Dompet Sumber',
            ),
            items: [
              for (final w in activeWallets)
                DropdownMenuItem(
                  value: w.id,
                  child: Text('${w.name} (${rupiah(snap?.balanceOf(w.id) ?? 0)})'),
                ),
            ],
            onChanged: (val) => setState(() => _sourceWalletId = val),
          ),
          const SizedBox(height: AppSpace.lg),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Nominal Setor (Rp)',
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          FilledButton(
            onPressed: _submit,
            child: const Text('Konfirmasi Setor'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final amount = parseAmount(_amountController.text);
    if (amount <= 0) return;

    await ref.read(wishlistRepositoryProvider).deposit(
      wishlistId: widget.wishlist.id,
      amount: amount,
      sourceWalletId: _sourceWalletId,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil menyisihkan ${rupiah(amount)} untuk ${widget.wishlist.title}!'),
        ),
      );
    }
  }
}
