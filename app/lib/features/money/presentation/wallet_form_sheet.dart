import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/database/app_database.dart';
import '../../../providers.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/mascot.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_sheet.dart';

/// Bottom sheet untuk menambah dompet baru, atau mengubah, mengarsipkan,
/// atau menghapus dompet [existing].
class WalletFormSheet extends ConsumerStatefulWidget {
  const WalletFormSheet({super.key, this.existing});

  final Wallet? existing;

  static Future<void> open(BuildContext context, {Wallet? existing}) {
    return showAppSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => WalletFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends ConsumerState<WalletFormSheet> {
  final _name = TextEditingController();

  /// Dompet baru: saldo awal. Dompet lama: saldo sekarang, karena itu yang
  /// user lihat dan cocokkan dengan rekening; saldo awal dihitung mundur.
  final _balance = TextEditingController();
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
      final snap = ref.read(moneySnapshotProvider).value;
      final balance = snap?.balanceOf(e.id) ?? e.openingBalance;
      if (balance != 0) _balance.text = thousands(balance);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _showNameError = true);
      return;
    }
    final repo = ref.read(moneyRepositoryProvider);
    final typed = parseAmount(_balance.text);
    final adjustmentNote = context.l10n.balanceAdjustmentNote;
    if (_isEdit) {
      final w = widget.existing!;
      final current =
          ref.read(moneySnapshotProvider).value?.balanceOf(w.id) ??
          w.openingBalance;
      await repo.updateWallet(
        id: w.id,
        name: _name.text,
        type: _type,
        openingBalance: w.openingBalance,
      );
      // Saldo diubah langsung: selisihnya jadi transaksi Lainnya.
      await repo.adjustWalletBalance(
        walletId: w.id,
        currentBalance: current,
        targetBalance: typed,
        note: adjustmentNote,
      );
    } else {
      await repo.addWallet(
        name: _name.text,
        type: _type,
        openingBalance: typed,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _setArchived(bool archived) async {
    final l = context.l10n;
    await ref
        .read(moneyRepositoryProvider)
        .setWalletArchived(widget.existing!.id, archived);
    if (!mounted) return;
    Navigator.of(context).pop();
    showMascotSnackBar(
      context,
      MascotPose.senang,
      archived ? l.toastWalletArchived : l.toastWalletUnarchived,
    );
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
            style: TextButton.styleFrom(
              foregroundColor: context.colors.expense,
            ),
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
    final archived = widget.existing?.isArchived ?? false;
    // Minimal satu dompet aktif harus ada supaya transaksi baru punya tempat.
    final lastActive = !archived && (snap?.wallets.length ?? 0) <= 1;
    final canDelete = _isEdit && !lastActive;
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: AppSpace.lg),
              Text(
                _isEdit ? l.editWallet : l.addWallet,
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpace.lg),
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
              const SizedBox(height: AppSpace.md),
              Text(
                l.walletType,
                style: t.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.muted,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
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
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: _balance,
                keyboardType: const TextInputType.numberWithOptions(signed: true),
                inputFormatters: [ThousandsInputFormatter(allowNegative: true)],
                decoration: InputDecoration(
                  labelText: _isEdit ? l.currentBalance : l.openingBalance,
                  helperText: _isEdit ? l.currentBalanceHint : null,
                  helperMaxLines: 2,
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(l.save),
              ),
              if (_isEdit && !lastActive) ...[
                const SizedBox(height: AppSpace.sm),
                OutlinedButton.icon(
                  onPressed: () => _setArchived(!archived),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: Icon(
                    archived ? Icons.unarchive_outlined : Icons.archive_outlined,
                    size: 20,
                  ),
                  label: Text(archived ? l.unarchiveWallet : l.archiveWallet),
                ),
                if (!archived)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.xs),
                    child: Text(
                      l.archiveWalletHint,
                      textAlign: TextAlign.center,
                      style: t.bodySmall?.copyWith(color: context.colors.muted),
                    ),
                  ),
              ],
              if (canDelete) ...[
                const SizedBox(height: AppSpace.sm),
                TextButton.icon(
                  onPressed: () => _delete(txCount),
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.expense,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: Text(l.deleteWallet),
                ),
              ] else if (_isEdit) ...[
                const SizedBox(height: AppSpace.md),
                Text(
                  l.lastWalletCantDelete,
                  textAlign: TextAlign.center,
                  style: t.bodySmall?.copyWith(color: context.colors.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
