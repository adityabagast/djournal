import 'package:flutter/material.dart';

import '../tokens.dart';

/// Bilah tawaran di atas alat catatan (pengingat, transaksi): judul yang bisa
/// diketuk, tombol aksi, dan tombol abaikan.
class NoteBar extends StatelessWidget {
  const NoteBar({
    super.key,
    required this.background,
    required this.foreground,
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.dismissLabel,
    required this.onDismiss,
    this.note,
    this.onTap,
  });

  final Color background;
  final Color foreground;
  final String title;
  final String subtitle;

  /// Keterangan tambahan di bawah [subtitle].
  final String? note;
  final List<Widget> actions;
  final String dismissLabel;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final meta = TextStyle(
      fontSize: AppFontSize.meta,
      height: 1.4,
      color: foreground,
    );
    final info = InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: meta.copyWith(
                fontSize: AppFontSize.body,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: meta,
            ),
            if (note != null) Text(note!, style: meta),
          ],
        ),
      ),
    );
    final close = IconButton(
      tooltip: dismissLabel,
      onPressed: onDismiss,
      icon: const Icon(Icons.close_rounded, size: 20),
      color: foreground,
    );
    // Tombol pindah ke baris sendiri kalau lebih dari satu atau font besar.
    final stacked =
        actions.length > 1 || MediaQuery.textScalerOf(context).scale(10) > 12;

    return Material(
      color: background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.sm,
          AppSpace.xs,
          AppSpace.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: info),
                if (!stacked) ...[
                  const SizedBox(width: AppSpace.sm),
                  ...actions,
                ],
                close,
              ],
            ),
            if (stacked)
              Padding(
                padding: const EdgeInsets.only(right: AppSpace.md),
                child: Wrap(spacing: AppSpace.sm, children: actions),
              ),
          ],
        ),
      ),
    );
  }
}
