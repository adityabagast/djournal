import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/money_snapshot.dart';
import '../../providers.dart';
import '../../ui/common.dart';
import '../../ui/mascot.dart';
import 'categories_screen.dart';
import 'wallet_form_sheet.dart';

/// Form catat / edit transaksi (pengeluaran, pemasukan, atau transfer antar
/// dompet). [existing] null = transaksi baru.
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

  /// Dompet transaksi; untuk transfer = dompet asal.
  String? _walletId;

  /// Dompet tujuan, hanya untuk transfer.
  String? _toWalletId;
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
    _toWalletId = e?.toWalletId;
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
    final isTransfer = _type == 'transfer';
    final categoryId = isTransfer ? null : (_categoryId ?? cats.first.id);
    final overBudget = categoryId != null && _exceedsBudget(categoryId, amount);
    await ref
        .read(moneyRepositoryProvider)
        .saveTransaction(
          id: widget.existing?.id,
          type: _type,
          amount: amount,
          walletId: _walletId ?? wallets.first.id,
          toWalletId: isTransfer ? _toWalletId : null,
          categoryId: categoryId,
          note: _note.text,
          occurredAt: _occurredAt,
        );
    if (!mounted) return;
    final l = context.l10n;
    if (overBudget) {
      final cat = cats.firstWhere((c) => c.id == categoryId);
      showMascotSnackBar(
        context,
        MascotPose.sedih,
        l.toastBudgetOver(categoryLabel(l, cat)),
      );
    } else {
      showMascotSnackBar(
        context,
        MascotPose.senang,
        isTransfer ? l.toastTransferSaved : l.toastTxSaved,
      );
    }
    Navigator.of(context).pop();
  }

  /// Apakah pengeluaran ini membuat kategorinya lewat budget bulan itu.
  bool _exceedsBudget(String categoryId, int amount) {
    final snap = ref.read(moneySnapshotProvider).value;
    if (_type != 'expense' || snap == null) return false;
    final month = toMonthKey(_occurredAt);
    final budget = snap.budgetFor(categoryId, month);
    if (budget <= 0) return false;
    // Saat edit, nominal lama sudah termasuk di spentIn: jangan dihitung dua kali.
    final old = widget.existing;
    final oldAmount =
        old != null &&
            old.type == 'expense' &&
            old.categoryId == categoryId &&
            old.localDate.startsWith(month)
        ? old.amount
        : 0;
    return snap.spentIn(categoryId, month) - oldAmount + amount > budget;
  }

  /// Saldo [walletId] tanpa pengaruh transaksi yang sedang diedit, supaya
  /// peringatan saldo kurang tidak menghitung nominal lamanya dua kali.
  int _balanceExcludingThis(MoneySnapshot snap, String walletId) {
    var balance = snap.balanceOf(walletId);
    final e = widget.existing;
    if (e == null) return balance;
    if (e.walletId == walletId) {
      balance += e.type == 'income' ? -e.amount : e.amount;
    }
    if (e.type == 'transfer' && e.toWalletId == walletId) balance -= e.amount;
    return balance;
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
            style: TextButton.styleFrom(
              foregroundColor: context.colors.expense,
            ),
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

    final hideAmounts = ref.watch(hideAmountsProvider).value ?? false;
    // Kategori aktif, plus kategori tersembunyi yang dipakai transaksi yang
    // sedang diedit supaya tetap terpilih.
    final current = snap.categoryById[widget.existing?.categoryId];
    final cats = [
      ...snap.categories.where((c) => c.kind == _type),
      if (current != null && current.isArchived && current.kind == _type)
        current,
    ];
    // Kategori terpilih harus sesuai jenis (pengeluaran/pemasukan).
    if (_categoryId == null || !cats.any((c) => c.id == _categoryId)) {
      _categoryId = cats.isEmpty ? null : cats.first.id;
    }
    // Dompet aktif, plus dompet arsip yang dipakai transaksi yang sedang
    // diedit supaya pilihannya tetap terlihat.
    final e = widget.existing;
    final wallets = [
      ...snap.wallets,
      for (final id in {e?.walletId, e?.toWalletId})
        if (snap.walletById[id]?.isArchived ?? false) snap.walletById[id]!,
    ];
    _walletId ??= wallets.isEmpty ? null : wallets.first.id;
    final isTransfer = _type == 'transfer';
    // Tujuan transfer harus dompet lain yang masih ada.
    if (isTransfer &&
        (_toWalletId == _walletId ||
            !wallets.any((w) => w.id == _toWalletId))) {
      _toWalletId = wallets.where((w) => w.id != _walletId).firstOrNull?.id;
    }
    final canSave = !isTransfer || _toWalletId != null;

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
        color: context.colors.muted,
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
              color: context.colors.track,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                for (final (type, text) in [
                  ('expense', l.expense),
                  ('income', l.income),
                  ('transfer', l.transfer),
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
                  color: context.colors.muted,
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
                  // Rebuild tiap ketikan: peringatan saldo transfer ikut nominal.
                  onChanged: (_) => setState(() => _showAmountError = false),
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
                            ? context.colors.expense
                            : context.colors.primary,
                        width: 2,
                      ),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: _showAmountError
                            ? context.colors.expense
                            : context.colors.line,
                        width: 2,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: _showAmountError
                            ? context.colors.expense
                            : context.colors.primary,
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
                style: t.bodySmall?.copyWith(color: context.colors.expense),
              ),
            ),
          const SizedBox(height: 20),
          if (isTransfer)
            _TransferWallets(
              wallets: wallets,
              fromId: _walletId,
              toId: _toWalletId,
              balanceOf: (id) => _balanceExcludingThis(snap, id),
              amount: parseAmount(_amount.text),
              label: label,
              hideAmounts: hideAmounts,
              onFrom: (id) => setState(() {
                if (id == _toWalletId) _toWalletId = _walletId;
                _walletId = id;
              }),
              onTo: (id) => setState(() => _toWalletId = id),
              onSwap: () => setState(() {
                final from = _walletId;
                _walletId = _toWalletId;
                _toWalletId = from;
              }),
            )
          else ...[
            Row(
              children: [
                Expanded(child: label(l.category)),
                TextButton(
                  onPressed: () => CategoriesScreen.open(context, kind: _type),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(l.manage),
                ),
              ],
            ),
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
            _WalletChips(
              wallets: wallets,
              selectedId: _walletId,
              onSelect: (id) => setState(() => _walletId = id),
            ),
          ],
          const SizedBox(height: 20),
          Material(
            color: context.colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: context.colors.line),
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
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: context.colors.muted,
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
            decoration: InputDecoration(
              hintText: isTransfer ? l.transferNoteHint : l.noteHint,
            ),
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
        decoration: BoxDecoration(
          color: context.colors.background,
          border: Border(top: BorderSide(color: context.colors.line)),
        ),
        child: FilledButton(
          onPressed: _saving || !canSave ? null : () => _save(cats, wallets),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            isTransfer ? l.saveTransfer : l.saveTx,
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
            color: selected ? context.colors.raised : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: context.colors.shadow.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? context.colors.ink : context.colors.muted,
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
      color: selected ? context.colors.primarySoft : context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? context.colors.primary : context.colors.line,
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

/// Pilihan dompet berbentuk chip. [disabledId] tidak bisa dipilih (dompet
/// asal di baris tujuan transfer).
class _WalletChips extends StatelessWidget {
  const _WalletChips({
    required this.wallets,
    required this.selectedId,
    required this.onSelect,
    this.disabledId,
  });

  final List<Wallet> wallets;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final String? disabledId;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final w in wallets)
          ChoiceChip(
            label: Text(w.name),
            selected: w.id == selectedId,
            showCheckmark: false,
            onSelected: w.id == disabledId ? null : (_) => onSelect(w.id),
            selectedColor: context.colors.primary,
            backgroundColor: context.colors.surface,
            disabledColor: context.colors.track,
            side: BorderSide(
              color: w.id == selectedId
                  ? context.colors.primary
                  : context.colors.line,
            ),
            shape: const StadiumBorder(),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: w.id == disabledId
                  ? context.colors.muted
                  : w.id == selectedId
                  ? context.colors.onPrimary
                  : context.colors.ink,
              decoration: w.id == disabledId
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
      ],
    );
  }
}

/// Kartu "Dari → Ke" untuk transfer: pilih dompet asal dan tujuan, tukar
/// keduanya, dan peringatan kalau saldo asal kurang. Tetap boleh disimpan,
/// karena saldo di app belum tentu sama persis dengan saldo sungguhan.
class _TransferWallets extends StatelessWidget {
  const _TransferWallets({
    required this.wallets,
    required this.fromId,
    required this.toId,
    required this.balanceOf,
    required this.amount,
    required this.label,
    required this.onFrom,
    required this.onTo,
    required this.onSwap,
    required this.hideAmounts,
  });

  final List<Wallet> wallets;
  final String? fromId;
  final String? toId;
  final int Function(String walletId) balanceOf;
  final int amount;
  final Widget Function(String text) label;
  final ValueChanged<String> onFrom;
  final ValueChanged<String> onTo;
  final VoidCallback onSwap;
  final bool hideAmounts;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final small = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.colors.muted);
    final from = wallets.where((w) => w.id == fromId).firstOrNull;
    final hasTo = toId != null;

    Widget header(String title, String? walletId) => Row(
      children: [
        label(title),
        const Spacer(),
        if (walletId != null)
          Text(
            l.walletBalance(
              '${balanceOf(walletId) < 0 ? '−' : ''}'
              '${rupiah(balanceOf(walletId), hide: hideAmounts)}',
            ),
            style: small,
          ),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header(l.transferFrom, fromId),
          const SizedBox(height: 8),
          _WalletChips(wallets: wallets, selectedId: fromId, onSelect: onFrom),
          if (from != null && hasTo && amount > balanceOf(from.id))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l.transferOverdraw(from.name),
                style: small?.copyWith(color: context.colors.warning),
              ),
            ),
          SizedBox(
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Divider(height: 1, color: context.colors.divider),
                Material(
                  color: context.colors.primarySoft,
                  shape: CircleBorder(
                    side: BorderSide(color: context.colors.line),
                  ),
                  child: IconButton(
                    tooltip: l.swapWallets,
                    onPressed: hasTo ? onSwap : null,
                    icon: const Icon(Icons.swap_vert),
                    color: context.colors.primary,
                  ),
                ),
              ],
            ),
          ),
          header(l.transferTo, toId),
          const SizedBox(height: 8),
          if (wallets.length >= 2)
            _WalletChips(
              wallets: wallets,
              selectedId: toId,
              onSelect: onTo,
              disabledId: fromId,
            )
          else
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
              decoration: BoxDecoration(
                color: context.colors.warnSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.transferNeedsTwoWallets,
                      style: small?.copyWith(color: context.colors.onWarnSoft),
                    ),
                  ),
                  TextButton(
                    onPressed: () => WalletFormSheet.open(context),
                    child: Text(l.addWallet),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
