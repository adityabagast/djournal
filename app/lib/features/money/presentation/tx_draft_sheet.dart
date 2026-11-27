import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/format.dart';
import '../../../core/platform/platform_info.dart';
import '../../../core/theme.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/image_viewer.dart';
import '../../../providers.dart';
import '../domain/money_snapshot.dart';
import '../domain/tx_suggestions.dart';
import 'tx_form_screen.dart';
import 'tx_note_widgets.dart';

/// Hasil [TxDraftSheet]: draft yang dicatat, atau [remove] = batal dicatat.
typedef TxDraftResult = ({TxDraft draft, bool remove});

/// Lembar kecil untuk memeriksa transaksi dari jurnal atau menambah manual.
/// Tanggal dan jam ikut jurnalnya; transfer dan struk lewat form lengkap.
class TxDraftSheet extends ConsumerStatefulWidget {
  const TxDraftSheet({
    super.key,
    required this.draft,
    required this.isNew,
    this.controller,
  });

  final TxDraft draft;

  /// Tambah manual yang belum ada di daftar.
  final bool isNew;

  /// Sumber foto catatan & pemakaiannya oleh transaksi lain.
  final TxSuggestionController? controller;

  static Future<TxDraftResult?> show(
    BuildContext context, {
    required TxDraft draft,
    bool isNew = false,
    TxSuggestionController? controller,
  }) => showAppSheet<TxDraftResult>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        TxDraftSheet(draft: draft, isNew: isNew, controller: controller),
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
  late String? _receiptPath = widget.draft.receiptPath;
  bool _showError = false;

  Future<void> _pickReceipt(ImageSource source) async {
    final path = await ref
        .read(attachmentRepositoryProvider)
        .pickAndStoreImage(source: source);
    if (path != null && mounted) setState(() => _receiptPath = path);
  }

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
      receiptPath: _receiptPath,
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
          const SizedBox(height: AppSpace.lg),
          label(l.noteTxReceipt),
          _receipt(context),
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

  /// Nota terpilih, atau pilihan: foto catatan, kamera, galeri.
  Widget _receipt(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final photos = widget.controller?.photos ?? const <String>[];
    final meta = TextStyle(fontSize: AppFontSize.meta, color: c.muted);

    if (_receiptPath case final path?) {
      final i = photos.indexOf(path);
      return Row(
        children: [
          Semantics(
            button: true,
            label: l.noteTxReceiptView,
            child: InkWell(
              onTap: () => openImageViewer(context, paths: [path]),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: ReceiptThumb(path: path, width: 64, height: 64),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              i < 0 ? l.noteTxReceiptOwn : l.noteTxReceiptFromPhoto(i + 1),
              style: meta,
            ),
          ),
          IconButton(
            key: const Key('txDraftReceiptRemove'),
            tooltip: l.noteTxReceiptRemove,
            onPressed: () => setState(() => _receiptPath = null),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (photos.isNotEmpty) ...[
          Text(l.noteTxReceiptFromNote, style: meta),
          const SizedBox(height: AppSpace.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < photos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.md),
                    child: _notePhoto(context, photos[i], i),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
        ],
        Row(
          children: [
            // Kamera hanya di HP; desktop memilih file lewat Galeri.
            if (PlatformInfo.isMobile) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickReceipt(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: FitText(l.noteTxCamera),
                ),
              ),
              const SizedBox(width: AppSpace.md),
            ],
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickReceipt(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: FitText(l.noteTxGallery),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _notePhoto(BuildContext context, String path, int i) {
    final l = context.l10n;
    final c = context.colors;
    final user = widget.controller?.receiptUser(
      path,
      exceptKey: widget.draft.key,
    );
    final userName = user == null ? null : txDraftTitle(l, user);
    return SizedBox(
      width: 92,
      child: Semantics(
        button: true,
        label: [
          l.noteTxPhotoPick(i + 1),
          if (userName != null) l.noteTxPhotoUsed(userName),
        ].join(', '),
        child: InkWell(
          onTap: () => setState(() => _receiptPath = path),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReceiptThumb(path: path, width: 92, height: 64),
                const SizedBox(height: AppSpace.xs),
                Text(
                  l.noteTxPhotoN(i + 1),
                  style: TextStyle(
                    fontSize: AppFontSize.meta,
                    fontWeight: FontWeight.w700,
                    color: c.ink,
                  ),
                ),
                Text(
                  userName == null
                      ? l.noteTxPhotoFree
                      : l.noteTxPhotoUsed(userName),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    height: 1.3,
                    fontWeight: userName == null
                        ? FontWeight.w400
                        : FontWeight.w600,
                    color: userName == null ? c.muted : c.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
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
