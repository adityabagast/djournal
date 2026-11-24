import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/common.dart';
import '../../../providers.dart';
import '../domain/money_snapshot.dart';
import '../domain/tx_suggestions.dart';
import 'tx_form_screen.dart';

/// Hasil [TxDraftSheet]: draft yang dicatat, atau [remove] = batal dicatat.
typedef TxDraftResult = ({TxDraft draft, bool remove});

/// Lembar kecil untuk memeriksa transaksi dari jurnal atau menambah manual.
/// Tanggal dan jam ikut jurnalnya; transfer dan struk lewat form lengkap.
class TxDraftSheet extends ConsumerStatefulWidget {
  const TxDraftSheet({super.key, required this.draft, required this.isNew});

  final TxDraft draft;

  /// Tambah manual yang belum ada di daftar.
  final bool isNew;

  static Future<TxDraftResult?> show(
    BuildContext context, {
    required TxDraft draft,
    bool isNew = false,
  }) => showAppSheet<TxDraftResult>(
    context: context,
    isScrollControlled: true,
    builder: (_) => TxDraftSheet(draft: draft, isNew: isNew),
  );

  @override
  ConsumerState<TxDraftSheet> createState() => _TxDraftSheetState();
}

class _TxDraftSheetState extends ConsumerState<TxDraftSheet> {
  late final _amount = TextEditingController(
    text: widget.draft.amount == 0 ? '' : thousands(widget.draft.amount),
  );
  late final _note = TextEditingController(text: widget.draft.note);
  late String _type = widget.draft.type;
  late String? _categoryId = widget.draft.categoryId;
  late String _walletId = widget.draft.walletId;
  bool _showError = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = parseAmount(_amount.text);
    if (amount <= 0) {
      setState(() => _showError = true);
      return;
    }
    // Dibuat baru (bukan copyWith) supaya kategori boleh kosong.
    final d = TxDraft(
      key: widget.draft.key,
      note: _note.text.trim(),
      amount: amount,
      type: _type,
      categoryId: _categoryId,
      walletId: _walletId,
      manual: widget.draft.manual,
    );
    Navigator.pop(context, (draft: d, remove: false));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final snap = ref.watch(moneySnapshotProvider).value;
    if (snap == null) return const SizedBox.shrink();

    final roots = snap.categories.where((x) => x.kind == _type).toList();
    if (snap.categoryById[_categoryId]?.kind != _type) {
      _categoryId = roots.isEmpty ? null : roots.first.id;
    }
    final rootId = _categoryId == null ? null : snap.rootIdOf(_categoryId!);
    final root = snap.categoryById[rootId];
    final subs = root == null ? const [] : snap.childrenOf(root.id);
    final canRemove =
        !widget.isNew && widget.draft.state != TxDraftState.dismissed;

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppFontSize.body,
          fontWeight: FontWeight.w600,
          color: c.muted,
        ),
      ),
    );

    return SheetScroll(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpace.lg),
          Text(
            widget.isNew ? l.noteTxAdd : l.noteTxEdit,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(l.noteTxWhen, style: t.bodySmall?.copyWith(color: c.muted)),
          const SizedBox(height: AppSpace.lg),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 'expense', label: FitText(l.expense)),
              ButtonSegment(value: 'income', label: FitText(l.income)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: AppSpace.lg),
          label(l.amount),
          TextField(
            key: const Key('txDraftAmount'),
            controller: _amount,
            autofocus: widget.isNew,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsInputFormatter()],
            onChanged: (_) {
              if (_showError) setState(() => _showError = false);
            },
            style: const TextStyle(
              fontSize: AppFontSize.display,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              prefixText: 'Rp ',
              hintText: '0',
              errorText: _showError ? l.amountRequired : null,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          label(l.note),
          TextField(
            key: const Key('txDraftNote'),
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l.noteHint),
          ),
          const SizedBox(height: AppSpace.lg),
          label(l.category),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final x in roots)
                TxCategoryPill(
                  category: x,
                  selected: x.id == rootId,
                  onTap: () => setState(() => _categoryId = x.id),
                ),
            ],
          ),
          if (root != null && subs.isNotEmpty)
            TxSubcategoryRow(
              root: root,
              subs: [...snap.childrenOf(root.id)],
              selectedId: _categoryId,
              onSelect: (id) => setState(() => _categoryId = id),
            ),
          const SizedBox(height: AppSpace.lg),
          label(l.wallet),
          TxWalletChips(
            wallets: snap.wallets,
            selectedId: _walletId,
            onSelect: (id) => setState(() => _walletId = id),
          ),
          const SizedBox(height: AppSpace.xxl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    canRemove ? (draft: widget.draft, remove: true) : null,
                  ),
                  child: FitText(canRemove ? l.noteTxDismiss : l.cancel),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: FilledButton(
                  onPressed: _submit,
                  child: FitText(l.noteTxRecord),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Draft kosong untuk tambah manual.
TxDraft emptyTxDraft(String key, MoneySnapshot snap) => TxDraft(
  key: key,
  note: '',
  amount: 0,
  type: 'expense',
  categoryId: null,
  walletId: snap.wallets.first.id,
  manual: true,
);
