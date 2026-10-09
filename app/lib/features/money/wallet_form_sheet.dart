import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../providers.dart';
import '../../ui/common.dart';

/// Bottom sheet untuk menambah dompet baru, atau mengubah/menghapus
/// dompet [existing].
class WalletFormSheet extends ConsumerStatefulWidget {
  const WalletFormSheet({super.key, this.existing});

  final Wallet? existing;

  static Future<void> open(BuildContext context, {Wallet? existing}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => WalletFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends ConsumerState<WalletFormSheet> {
  final _name = TextEditingController();
  final _opening = TextEditingController();
  String _type = 'bank';
  bool _showNameError = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text = e.name;
      _type = e.type;
      if (e.openingBalance != 0) _opening.text = thousands(e.openingBalance);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _showNameError = true);
      return;
    }
    final repo = ref.read(moneyRepositoryProvider);
    if (_isEdit) {
      await repo.updateWallet(
        id: widget.existing!.id,
        name: _name.text,
        type: _type,
        openingBalance: parseAmount(_opening.text),
      );
    } else {
      await repo.addWallet(
        name: _name.text,
        type: _type,
        openingBalance: parseAmount(_opening.text),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete(int txCount) async {
    final l = context.l10n;
    final w = widget.existing!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteWalletConfirm(w.name)),
        content: txCount > 0 ? Text(l.deleteWalletTxWarning(txCount)) : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(moneyRepositoryProvider).deleteWallet(w.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final snap = ref.watch(moneySnapshotProvider).value;
    // Minimal satu dompet harus ada supaya transaksi baru punya tempat.
    final canDelete = _isEdit && (snap?.wallets.length ?? 0) > 1;
    final txCount = !_isEdit || snap == null
        ? 0
        : snap.transactions
              .where(
                (tx) =>
                    tx.walletId == widget.existing!.id ||
                    tx.toWalletId == widget.existing!.id,
              )
              .length;
    final types = [
      ('cash', l.walletTypeCash),
      ('bank', l.walletTypeBank),
      ('ewallet', l.walletTypeEwallet),
      ('other', l.walletTypeOther),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D6CD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isEdit ? l.editWallet : l.addWallet,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: !_isEdit,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) {
              if (_showNameError) setState(() => _showNameError = false);
            },
            decoration: InputDecoration(
              labelText: l.walletName,
              hintText: l.walletNameHint,
              errorText: _showNameError ? l.walletNameRequired : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l.walletType,
            style: t.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final (key, text) in types)
                ChoiceChip(
                  label: Text(text),
                  selected: _type == key,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _type = key),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _opening,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsInputFormatter()],
            decoration: InputDecoration(
              labelText: l.openingBalance,
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(l.save),
          ),
          if (canDelete) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _delete(txCount),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.expense,
                minimumSize: const Size.fromHeight(44),
              ),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: Text(l.deleteWallet),
            ),
          ] else if (_isEdit) ...[
            const SizedBox(height: 12),
            Text(
              l.lastWalletCantDelete,
              textAlign: TextAlign.center,
              style: t.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
