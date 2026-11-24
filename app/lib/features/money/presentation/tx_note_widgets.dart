import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/note_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../domain/money_snapshot.dart';
import '../domain/tx_suggestions.dart';
import 'money_widgets.dart';
import 'tx_draft_sheet.dart';

/// Nama draft: catatan, atau jenisnya kalau catatan kosong.
String txDraftTitle(AppLocalizations l, TxDraft d) => d.note.isNotEmpty
    ? d.note
    : (d.type == 'income' ? l.income : l.expense);

String txDraftAmount(TxDraft d, {bool hide = false}) => signedRupiah(
  d.type == 'income' ? d.amount : -d.amount,
  hide: hide,
  explicitPlus: true,
);

String txDraftMeta(AppLocalizations l, MoneySnapshot snap, TxDraft d) => [
  if (snap.categoryById[d.categoryId] case final c?) categoryPath(l, snap, c),
  if (snap.walletById[d.walletId] case final w?) w.name,
].join(' · ');

/// Ubah [d] (atau tambah baru) lewat lembar, lalu simpan ke [controller].
Future<void> editTxDraft(
  BuildContext context,
  TxSuggestionController controller,
  TxDraft d, {
  bool isNew = false,
}) async {
  final result = await TxDraftSheet.show(context, draft: d, isNew: isNew);
  if (result == null) return;
  if (!result.remove) {
    controller.save(result.draft);
  } else if (d.manual) {
    controller.undo(d);
  } else {
    controller.dismiss(d.key);
  }
}

/// Bilah di atas alat catatan: menawarkan transaksi yang dikenali di cerita.
class TxSuggestionBar extends ConsumerWidget {
  const TxSuggestionBar({
    super.key,
    required this.controller,
    required this.pending,
    required this.snapshot,
    required this.onChanged,
    required this.onOpenPanel,
  });

  final TxSuggestionController controller;
  final List<TxDraft> pending;
  final MoneySnapshot snapshot;
  final VoidCallback onChanged;

  /// Lihat semua usulan (kalau lebih dari satu).
  final VoidCallback onOpenPanel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final hide = ref.watch(hideAmountsProvider).value ?? false;
    final single = pending.length == 1;
    final first = pending.first;
    final names = pending.map((d) => txDraftTitle(l, d)).join(', ');

    return NoteBar(
      background: c.primarySoft,
      foreground: c.onPrimarySoft,
      title: single ? names : '${l.noteTxCount(pending.length)} · $names',
      subtitle: single
          ? [
              txDraftAmount(first, hide: hide),
              txDraftMeta(l, snapshot, first),
            ].join(' · ')
          : pending.map((d) => txDraftAmount(d, hide: hide)).join(' · '),
      dismissLabel: l.noteTxDismiss,
      onDismiss: () {
        for (final d in pending) {
          controller.dismiss(d.key);
        }
        onChanged();
      },
      onTap: single
          ? () async {
              await editTxDraft(context, controller, first);
              onChanged();
            }
          : onOpenPanel,
      actions: [
        FilledButton(
          onPressed: () {
            for (final d in pending) {
              controller.accept(d.key);
            }
            onChanged();
          },
          child: Text(single ? l.noteTxRecord : l.noteTxRecordAll),
        ),
      ],
    );
  }
}

/// Isi panel "Uang": semua transaksi dari catatan ini + tambah manual.
class TxSuggestionPanel extends ConsumerWidget {
  const TxSuggestionPanel({
    super.key,
    required this.controller,
    required this.items,
    required this.snapshot,
    required this.onChanged,
  });

  final TxSuggestionController controller;
  final List<TxDraft> items;
  final MoneySnapshot snapshot;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.colors;
    final hide = ref.watch(hideAmountsProvider).value ?? false;
    final hint = TextStyle(
      fontSize: AppFontSize.meta,
      height: 1.6,
      color: c.muted,
    );
    if (snapshot.wallets.isEmpty) return Text(l.noteNoWallet, style: hint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.noteTxPanel,
                style: const TextStyle(
                  fontSize: AppFontSize.bodyLg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                await editTxDraft(
                  context,
                  controller,
                  emptyTxDraft(controller.newManualKey(), snapshot),
                  isNew: true,
                );
                onChanged();
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(l.add),
            ),
          ],
        ),
        if (items.isEmpty) Text(l.noteTxEmpty, style: hint),
        for (final d in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: _PanelRow(
              title: txDraftTitle(l, d),
              meta: txDraftMeta(l, snapshot, d),
              amount: txDraftAmount(d, hide: hide),
              amountColor: d.type == 'income' ? c.income : c.expense,
              onTap: d.state == TxDraftState.recorded
                  ? null
                  : () async {
                      await editTxDraft(context, controller, d);
                      onChanged();
                    },
              trailing: switch (d.state) {
                TxDraftState.recorded => Text(l.noteTxExists, style: hint),
                TxDraftState.accepted => TextButton.icon(
                  onPressed: () {
                    controller.undo(d);
                    onChanged();
                  },
                  style: TextButton.styleFrom(foregroundColor: c.income),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(l.noteTxRecorded),
                ),
                _ => FilledButton(
                  onPressed: () {
                    controller.accept(d.key);
                    onChanged();
                  },
                  child: Text(l.noteTxRecord),
                ),
              },
            ),
          ),
      ],
    );
  }
}

class _PanelRow extends StatelessWidget {
  const _PanelRow({
    required this.title,
    required this.meta,
    required this.amount,
    required this.amountColor,
    required this.trailing,
    this.onTap,
  });

  final String title;
  final String meta;
  final String amount;
  final Color amountColor;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  FitText(
                    amount,
                    style: TextStyle(
                      fontSize: AppFontSize.body,
                      fontWeight: FontWeight.w600,
                      color: amountColor,
                    ),
                  ),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppFontSize.meta,
                      color: context.colors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        trailing,
      ],
    );
  }
}
