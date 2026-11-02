import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../providers.dart';

class BillFormSheet extends ConsumerStatefulWidget {
  const BillFormSheet({super.key, this.existing});

  final Bill? existing;

  static Future<void> open(BuildContext context, {Bill? existing}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BillFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<BillFormSheet> createState() => _BillFormSheetState();
}

class _BillFormSheetState extends ConsumerState<BillFormSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 3));
  String? _selectedWalletId;
  String _repeatInterval = 'monthly';
  bool _showTitleError = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleController.text = e.title;
      _amountController.text = thousands(e.amount);
      _selectedDate = DateTime.tryParse(e.dueDate) ?? _selectedDate;
      _selectedWalletId = e.walletId;
      _repeatInterval = e.repeatInterval ?? 'monthly';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final wallets = ref.watch(walletsProvider).value ?? const [];
    final activeWallets = wallets.where((w) => !w.isArchived).toList();

    // Dompet lama bisa sudah diarsip/dihapus; dropdown akan crash kalau
    // nilainya tidak ada di daftar pilihan.
    if (_selectedWalletId != null &&
        !activeWallets.any((w) => w.id == _selectedWalletId)) {
      _selectedWalletId = null;
    }
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
                  _isEdit ? 'Ubah Tagihan' : 'Jadwalkan Tagihan Baru',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (_isEdit)
                IconButton(
                  onPressed: _delete,
                  icon: Icon(Icons.delete_outline, color: context.colors.expense),
                  tooltip: 'Hapus Tagihan',
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Nama Tagihan',
              hintText: 'Misal: Wi-Fi IndiHome / Listrik PLN',
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
              labelText: 'Nominal Tagihan (Rp)',
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _selectedWalletId,
            decoration: const InputDecoration(
              labelText: 'Rencana Bayar Dari Dompet',
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
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Tanggal Jatuh Tempo',
                suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
              ),
              child: Text(
                DateFormat('EEEE, d MMMM yyyy', 'id').format(_selectedDate),
                style: t.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _repeatInterval,
            decoration: const InputDecoration(
              labelText: 'Pengulangan',
            ),
            items: const [
              DropdownMenuItem(value: 'monthly', child: Text('Bulanan (Tiap Bulan)')),
              DropdownMenuItem(value: 'once', child: Text('Satu Kali Saja')),
              DropdownMenuItem(value: 'yearly', child: Text('Tahunan')),
            ],
            onChanged: (val) => setState(() => _repeatInterval = val ?? 'monthly'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            child: Text(_isEdit ? 'Simpan Perubahan' : 'Jadwalkan Tagihan'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    // Tagihan yang sudah lama lewat tempo bisa lebih tua dari batas 30 hari;
    // showDatePicker menolak initialDate sebelum firstDate.
    final minDate = DateTime.now().subtract(const Duration(days: 30));
    final maxDate = DateTime.now().add(const Duration(days: 365 * 2));
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: _selectedDate.isBefore(minDate) ? _selectedDate : minDate,
      lastDate: _selectedDate.isAfter(maxDate) ? _selectedDate : maxDate,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _showTitleError = true);
      return;
    }
    final amount = parseAmount(_amountController.text);
    if (amount <= 0) return;

    final dueDateStr = toLocalDate(_selectedDate);
    final repo = ref.read(billRepositoryProvider);

    if (_isEdit) {
      await repo.updateBill(
        id: widget.existing!.id,
        title: title,
        amount: amount,
        dueDate: dueDateStr,
        repeatInterval: _repeatInterval,
        walletId: _selectedWalletId,
      );
    } else {
      await repo.createBill(
        title: title,
        amount: amount,
        dueDate: dueDateStr,
        repeatInterval: _repeatInterval,
        walletId: _selectedWalletId,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final e = widget.existing;
    if (e == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tagihan?'),
        content: Text(
          '${e.title} (${rupiah(e.amount)}) akan dihapus dari daftar. '
          'Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(billRepositoryProvider).deleteBill(e.id);
    if (mounted) Navigator.pop(context);
  }
}
