import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../providers.dart';

class WishlistFormSheet extends ConsumerStatefulWidget {
  const WishlistFormSheet({super.key, this.existing});

  final Wishlist? existing;

  static Future<void> open(BuildContext context, {Wishlist? existing}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => WishlistFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<WishlistFormSheet> createState() => _WishlistFormSheetState();
}

class _WishlistFormSheetState extends ConsumerState<WishlistFormSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  int _selectedMonths = 12;
  String? _selectedWalletId;
  bool _showTitleError = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleController.text = e.title;
      _amountController.text = thousands(e.targetAmount);
      _selectedMonths = e.targetMonths;
      _selectedWalletId = e.walletId;
      _notesController.text = e.notes ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _parsedAmount => parseAmount(_amountController.text);

  int get _monthlyEstimate {
    if (_selectedMonths <= 0 || _parsedAmount <= 0) return 0;
    return (_parsedAmount / _selectedMonths).round();
  }

  int get _dailyEstimate => (_monthlyEstimate / 30).round();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final wallets = ref.watch(walletsProvider).value ?? const [];
    final activeWallets = wallets.where((w) => !w.isArchived).toList();

    // Default ke dompet pertama jika belum dipilih
    if (_selectedWalletId == null && activeWallets.isNotEmpty) {
      _selectedWalletId = activeWallets.first.id;
    }

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
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  _isEdit ? 'Ubah Wishlist' : 'Tambah Wishlist Impian',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (_isEdit)
                IconButton(
                  onPressed: _delete,
                  icon: Icon(Icons.delete_outline, color: context.colors.expense),
                  tooltip: 'Hapus Wishlist',
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Nama Barang / Impian',
              hintText: 'Misal: iPhone 16 / Kamera Mirrorless',
              errorText: _showTitleError ? 'Nama wajib diisi' : null,
            ),
            onChanged: (_) {
              if (_showTitleError) setState(() => _showTitleError = false);
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Target Harga (Rp)',
              prefixText: 'Rp ',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _selectedWalletId,
            decoration: const InputDecoration(
              labelText: 'Simpan di Dompet',
            ),
            items: [
              for (final w in activeWallets)
                DropdownMenuItem(
                  value: w.id,
                  child: Text(w.name),
                ),
            ],
            onChanged: (val) => setState(() => _selectedWalletId = val),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            initialValue: _selectedMonths,
            decoration: const InputDecoration(
              labelText: 'Target Waktu Tercapai',
            ),
            items: const [
              DropdownMenuItem(value: 3, child: Text('3 Bulan ke depan')),
              DropdownMenuItem(value: 6, child: Text('6 Bulan ke depan')),
              DropdownMenuItem(value: 12, child: Text('1 Tahun (12 Bulan)')),
              DropdownMenuItem(value: 24, child: Text('2 Tahun (24 Bulan)')),
              DropdownMenuItem(value: 36, child: Text('3 Tahun (36 Bulan)')),
            ],
            onChanged: (val) => setState(() => _selectedMonths = val ?? 12),
          ),
          if (_parsedAmount > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.primarySoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 20, color: context.colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rincian Tabungan: ${rupiah(_monthlyEstimate)} / bulan '
                      '(sekitar ${rupiah(_dailyEstimate)} / hari)',
                      style: t.bodySmall?.copyWith(
                        color: context.colors.onPrimarySoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            child: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Wishlist'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _showTitleError = true);
      return;
    }
    final amount = _parsedAmount;
    if (amount <= 0) return;

    final repo = ref.read(wishlistRepositoryProvider);
    if (_isEdit) {
      await repo.updateWishlist(
        id: widget.existing!.id,
        title: title,
        targetAmount: amount,
        targetMonths: _selectedMonths,
        walletId: _selectedWalletId,
        notes: _notesController.text.trim(),
      );
    } else {
      await repo.createWishlist(
        title: title,
        targetAmount: amount,
        targetMonths: _selectedMonths,
        walletId: _selectedWalletId,
        notes: _notesController.text.trim(),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final e = widget.existing;
    if (e == null) return;
    await ref.read(wishlistRepositoryProvider).deleteWishlist(e.id);
    if (mounted) Navigator.pop(context);
  }
}
