import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../providers.dart';
import '../../ui/common.dart';

/// Form catat / edit transaksi. [existing] null = transaksi baru.
class TxFormScreen extends ConsumerStatefulWidget {
  const TxFormScreen({super.key, this.existing});

  final MoneyTx? existing;

  static Future<void> open(BuildContext context, {MoneyTx? existing}) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => TxFormScreen(existing: existing)));
  }

  @override
  ConsumerState<TxFormScreen> createState() => _TxFormScreenState();
}

class _TxFormScreenState extends ConsumerState<TxFormScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late String _type;
  String? _categoryId;
  String? _walletId;
  late DateTime _occurredAt;
  bool _showAmountError = false;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? 'expense';
    _categoryId = e?.categoryId;
    _walletId = e?.walletId;
    _occurredAt = e?.occurredAt.toLocal() ?? DateTime.now();
    if (e != null) {
      _amount.text = thousands(e.amount);
      _note.text = e.note ?? '';
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (!mounted) return;
    final t = time ?? TimeOfDay.fromDateTime(_occurredAt);
    setState(() {
      _occurredAt = DateTime(date.year, date.month, date.day, t.hour, t.minute);
    });
  }

  Future<void> _save(List<Category> cats, List<Wallet> wallets) async {
    final amount = parseAmount(_amount.text);
    if (amount <= 0) {
      setState(() => _showAmountError = true);
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(moneyRepositoryProvider)
        .saveTransaction(
          id: widget.existing?.id,
          type: _type,
          amount: amount,
          walletId: _walletId ?? wallets.first.id,
          categoryId: _categoryId ?? cats.first.id,
          note: _note.text,
          occurredAt: _occurredAt,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteTxConfirm),
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
    await ref
        .read(moneyRepositoryProvider)
        .deleteTransaction(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final snap = ref.watch(moneySnapshotProvider).value;

    if (snap == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final cats = snap.categories.where((c) => c.kind == _type).toList();
    // Kategori terpilih harus sesuai jenis (pengeluaran/pemasukan).
    if (_categoryId == null || !cats.any((c) => c.id == _categoryId)) {
      _categoryId = cats.isEmpty ? null : cats.first.id;
    }
    _walletId ??= snap.wallets.isEmpty ? null : snap.wallets.first.id;

    final now = DateTime.now();
    final sameDay = toLocalDate(_occurredAt) == toLocalDate(now);
    final whenLabel = sameDay
        ? '${l.today} · ${hhmm(_occurredAt)}'
        : '${DateFormat('EEE, d MMM y', context.localeTag).format(_occurredAt)} · ${hhmm(_occurredAt)}';

    Widget label(String text) => Text(
      text,
      style: t.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? l.editTxTitle : l.addTxTitle,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: l.delete,
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          // Jenis transaksi: segmented control seperti desain.
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.track,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                for (final (type, text) in [
                  ('expense', l.expense),
                  ('income', l.income),
                ])
                  Expanded(
                    child: _Segment(
                      label: text,
                      selected: _type == type,
                      onTap: () => setState(() => _type = type),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          label(l.amount),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Rp',
                style: t.headlineSmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amount,
                  autofocus: !_isEdit,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsInputFormatter()],
                  onChanged: (_) {
                    if (_showAmountError) {
                      setState(() => _showAmountError = false);
                    }
                  },
                  style: t.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 34,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    filled: false,
                    contentPadding: const EdgeInsets.only(bottom: 6),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: _showAmountError
                            ? AppColors.expense
                            : AppColors.primary,
                        width: 2,
                      ),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: _showAmountError
                            ? AppColors.expense
                            : AppColors.line,
                        width: 2,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: _showAmountError
                            ? AppColors.expense
                            : AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showAmountError)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l.amountRequired,
                style: t.bodySmall?.copyWith(color: AppColors.expense),
              ),
            ),
          const SizedBox(height: 20),
          label(l.category),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.45,
            children: [
              for (final c in cats)
                _CategoryChoice(
                  category: c,
                  selected: c.id == _categoryId,
                  onTap: () => setState(() => _categoryId = c.id),
                ),
            ],
          ),
          const SizedBox(height: 20),
          label(l.wallet),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in snap.wallets)
                ChoiceChip(
                  label: Text(w.name),
                  selected: w.id == _walletId,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _walletId = w.id),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: w.id == _walletId
                        ? AppColors.primary
                        : AppColors.line,
                  ),
                  shape: const StadiumBorder(),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: w.id == _walletId ? Colors.white : AppColors.ink,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.line),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDateTime,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    label(l.time),
                    const Spacer(),
                    Text(
                      whenLabel,
                      style: t.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          label(l.note),
          const SizedBox(height: 6),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l.noteHint),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          12 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: FilledButton(
          onPressed: _saving ? null : () => _save(cats, snap.wallets),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            l.saveTx,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x1F1B1F1D),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.ink : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChoice extends StatelessWidget {
  const _CategoryChoice({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.line,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CategoryBadge(category: category, size: 32),
            const SizedBox(height: 6),
            Text(
              categoryLabel(context.l10n, category),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
