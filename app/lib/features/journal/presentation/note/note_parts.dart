import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/format.dart';
import '../../../../core/theme.dart';
import '../../../../core/tokens.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/image_viewer.dart';
import '../../../../providers.dart';
import '../../../money/domain/money_snapshot.dart';
import '../../../money/domain/tx_suggestions.dart';
import '../../../money/presentation/money_widgets.dart';
import '../../../money/presentation/tx_form_screen.dart';
import '../../../money/presentation/tx_note_widgets.dart';

/// Foto di dalam catatan; [onRemove] null = mode baca.
class NotePhotos extends StatelessWidget {
  const NotePhotos({super.key, required this.paths, this.onRemove});

  final List<String> paths;
  final ValueChanged<int>? onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final single = paths.length == 1;
        final width = single
            ? box.maxWidth
            : (box.maxWidth - AppSpace.sm) / 2;
        return Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (var i = 0; i < paths.length; i++)
              SizedBox(
                width: width,
                height: single ? width * 10 / 16 : width,
                child: _photo(context, i),
              ),
          ],
        );
      },
    );
  }

  Widget _photo(BuildContext context, int i) {
    final l = context.l10n;
    final c = context.colors;
    final file = File(paths[i]);
    final broken = ColoredBox(
      color: c.subtle,
      child: Center(child: Icon(Icons.broken_image_rounded, color: c.muted)),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        Semantics(
          button: true,
          label: l.notePhotoLabel(i + 1),
          child: GestureDetector(
            onTap: () => openImageViewer(
              context,
              paths: paths,
              initialIndex: i,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: file.existsSync()
                  ? Image.file(
                      file,
                      fit: BoxFit.cover,
                      cacheWidth: 600,
                      errorBuilder: (_, _, _) => broken,
                    )
                  : broken,
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              tooltip: l.notePhotoRemove,
              onPressed: () => onRemove!(i),
              icon: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close_rounded, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

/// Transaksi di tanggal catatan (terhubung lewat local_date, tanpa FK), bisa
/// dilipat. [accepted] = yang akan dicatat saat catatan disimpan.
class NoteDayTransactions extends ConsumerWidget {
  const NoteDayTransactions({
    super.key,
    required this.date,
    required this.snapshot,
    required this.open,
    required this.onToggle,
    this.accepted = const [],
    this.onEditDraft,
  });

  final String date;
  final MoneySnapshot snapshot;
  final bool open;
  final VoidCallback onToggle;
  final List<TxDraft> accepted;
  final ValueChanged<TxDraft>? onEditDraft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final hide = ref.watch(hideAmountsProvider).value ?? false;
    final txs = snapshot.onDate(date).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final out =
        MoneySnapshot.sumOf(txs, 'expense') +
        accepted
            .where((d) => d.type == 'expense')
            .fold<int>(0, (sum, d) => sum + d.amount);
    final empty = txs.isEmpty && accepted.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: c.line),
        Semantics(
          button: true,
          expanded: open && !empty,
          child: InkWell(
            onTap: empty ? null : onToggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.dayTransactions,
                      style: TextStyle(
                        fontSize: AppFontSize.body,
                        fontWeight: FontWeight.w500,
                        color: c.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.45,
                    ),
                    child: FitText(
                      empty
                          ? l.noteTxNone
                          : out > 0
                          ? signedRupiah(-out, hide: hide)
                          : l.noteTxCount(txs.length + accepted.length),
                      alignment: Alignment.centerRight,
                      style: TextStyle(
                        fontSize: AppFontSize.body,
                        fontWeight: FontWeight.w600,
                        color: empty ? c.muted : c.ink,
                      ),
                    ),
                  ),
                  if (!empty)
                    Icon(
                      open
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 20,
                      color: c.muted,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (open && !empty) ...[
          for (final d in accepted)
            InkWell(
              onTap: onEditDraft == null ? null : () => onEditDraft!(d),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                child: Row(
                  children: [
                    CategoryBadge(
                      category: snapshot.categoryById[d.categoryId],
                      size: 36,
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            txDraftTitle(l, d),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: AppFontSize.bodyLg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${l.noteTxNew} · ${l.noteTxWithSave}',
                            style: TextStyle(
                              fontSize: AppFontSize.meta,
                              color: c.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.4,
                      ),
                      child: FitText(
                        txDraftAmount(d, hide: hide),
                        alignment: Alignment.centerRight,
                        style: TextStyle(
                          fontSize: AppFontSize.bodyLg,
                          fontWeight: FontWeight.w600,
                          color: d.type == 'income' ? c.income : c.expense,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          for (var i = 0; i < txs.length; i++)
            TxRow(
              tx: txs[i],
              snapshot: snapshot,
              leadingTime: true,
              showDivider: i < txs.length - 1,
              onTap: () => TxFormScreen.open(context, existing: txs[i]),
            ),
        ],
      ],
    );
  }
}

enum NoteLeave { save, stay, discard }

/// Lembar "Simpan catatan ini?" saat keluar dengan tulisan belum disimpan.
class NoteLeaveSheet extends StatelessWidget {
  const NoteLeaveSheet({super.key});

  static Future<NoteLeave?> show(BuildContext context) =>
      showAppSheet<NoteLeave>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const NoteLeaveSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    return SheetScroll(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpace.lg),
          Text(
            l.noteDiscardTitle,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            l.noteDiscardBody,
            style: t.bodySmall?.copyWith(color: c.muted),
          ),
          const SizedBox(height: AppSpace.lg),
          FilledButton(
            onPressed: () => Navigator.pop(context, NoteLeave.save),
            child: Text(l.save),
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, NoteLeave.stay),
                  child: FitText(l.noteKeepWriting),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, NoteLeave.discard),
                  style: OutlinedButton.styleFrom(foregroundColor: c.expense),
                  child: FitText(l.noteDiscard),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
