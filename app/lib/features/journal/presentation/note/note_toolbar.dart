import 'package:flutter/material.dart';

import '../../../../core/platform/platform_info.dart';
import '../../../../core/theme.dart';
import '../../../../core/tokens.dart';
import '../../../../core/widgets/common.dart';
import '../mood.dart';

/// Panel yang tampil di bawah bilah alat (menggantikan keyboard).
enum NotePanel { when, mood, tag, money }

/// Bilah alat catatan, tepat di atas keyboard atau panel.
class NoteToolbar extends StatelessWidget {
  const NoteToolbar({
    super.key,
    required this.panel,
    required this.mood,
    required this.hasAudio,
    required this.keyboardOpen,
    required this.onPanel,
    required this.onPhoto,
    required this.onRecord,
    required this.onDictate,
    required this.onKeyboard,
  });

  final NotePanel? panel;
  final int? mood;
  final bool hasAudio;
  final bool keyboardOpen;
  final ValueChanged<NotePanel> onPanel;
  final VoidCallback onPhoto;
  final VoidCallback onRecord;
  final VoidCallback onDictate;
  final VoidCallback onKeyboard;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;

    Widget tool(
      String label,
      Widget Function(Color color) icon, {
      required VoidCallback onTap,
      bool selected = false,
    }) {
      final color = selected ? c.onPrimarySoft : c.muted;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          excludeSemantics: true,
          child: Material(
            color: selected ? c.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                height: 52,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon(color),
                    const SizedBox(height: AppSpace.xxs),
                    Flexible(
                      child: FitText(
                        label,
                        alignment: Alignment.center,
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget Function(Color) icon(IconData data) =>
        (color) => Icon(data, size: 22, color: color);

    Widget panelTool(NotePanel p, String label, Widget Function(Color) icon) =>
        tool(label, icon, selected: panel == p, onTap: () => onPanel(p));

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xs,
      ),
      child: Row(
        children: [
          panelTool(
            NotePanel.money,
            l.noteToolMoney,
            icon(Icons.account_balance_wallet_outlined),
          ),
          tool(l.noteToolPhoto, icon(Icons.image_outlined), onTap: onPhoto),
          tool(
            hasAudio ? l.noteToolRecordAgain : l.noteToolRecord,
            icon(hasAudio ? Icons.replay_rounded : Icons.mic_none_rounded),
            onTap: onRecord,
          ),
          tool(
            l.noteToolDictate,
            icon(Icons.mode_comment_outlined),
            onTap: onDictate,
          ),
          panelTool(
            NotePanel.mood,
            l.mood,
            (color) => MoodFace(
              mood: mood ?? 4,
              color: color,
              size: 22,
              strokeWidth: 1.8,
            ),
          ),
          panelTool(NotePanel.tag, l.noteToolTag, icon(Icons.tag_rounded)),
          if (!PlatformInfo.isDesktop)
            tool(
              l.noteKeyboard,
              icon(
                keyboardOpen
                    ? Icons.keyboard_hide_outlined
                    : Icons.keyboard_outlined,
              ),
              selected: keyboardOpen,
              onTap: onKeyboard,
            ),
        ],
      ),
    );
  }
}

/// Latar panel di bawah [NoteToolbar]; isinya bisa digulir.
class NotePanelFrame extends StatelessWidget {
  const NotePanelFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: child,
      ),
    );
  }
}

class MoodPanel extends StatelessWidget {
  const MoodPanel({super.key, required this.mood, required this.onChanged});

  final int? mood;

  /// Ketuk pilihan yang sama = batal (null).
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.noteMoodAsk,
          style: const TextStyle(
            fontSize: AppFontSize.bodyLg,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          children: [
            for (var v = 1; v <= 5; v++) ...[
              if (v > 1) const SizedBox(width: AppSpace.sm),
              Expanded(
                child: _MoodChoice(
                  mood: v,
                  selected: mood == v,
                  onTap: () => onChanged(mood == v ? null : v),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          l.noteMoodUndo,
          style: TextStyle(fontSize: AppFontSize.meta, color: c.muted),
        ),
      ],
    );
  }
}

class _MoodChoice extends StatelessWidget {
  const _MoodChoice({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  final int mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.colors.primary : context.colors.muted;
    final text = moodLabel(context.l10n, mood);
    return Semantics(
      selected: selected,
      button: true,
      label: text,
      excludeSemantics: true,
      child: Material(
        color: selected ? context.colors.primarySoft : context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: selected ? context.colors.primary : context.colors.line,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(
            height: 76,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MoodFace(mood: mood, color: color, size: 28),
                const SizedBox(height: AppSpace.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                  child: FitText(
                    text,
                    alignment: Alignment.center,
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
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

class TagPanel extends StatelessWidget {
  const TagPanel({
    super.key,
    required this.controller,
    required this.tags,
    required this.onAdd,
    required this.onRemove,
  });

  final TextEditingController controller;
  final List<String> tags;

  /// Tambahkan isi [controller] ke daftar tag.
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.noteTagLabel,
          style: TextStyle(
            fontSize: AppFontSize.body,
            fontWeight: FontWeight.w600,
            color: c.muted,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('noteTag'),
                controller: controller,
                textInputAction: TextInputAction.done,
                onChanged: (v) {
                  if (v.contains(',')) onAdd();
                },
                // Tetap di kolom ini supaya bisa menambah tag berikutnya.
                onEditingComplete: onAdd,
                decoration: InputDecoration(
                  hintText: l.noteTagHint,
                  fillColor: c.surface,
                ),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            OutlinedButton(onPressed: onAdd, child: Text(l.add)),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        if (tags.isEmpty)
          Text(
            l.noteTagEmpty,
            style: TextStyle(fontSize: AppFontSize.meta, color: c.muted),
          )
        else
          Wrap(
            spacing: AppSpace.sm,
            children: [
              for (final tag in tags)
                InputChip(
                  label: Text('#$tag'),
                  labelStyle: TextStyle(
                    fontSize: AppFontSize.body,
                    color: c.onPrimarySoft,
                  ),
                  backgroundColor: c.primarySoft,
                  side: BorderSide.none,
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  deleteIconColor: c.onPrimarySoft,
                  deleteButtonTooltipMessage: l.noteTagRemove(tag),
                  onDeleted: () => onRemove(tag),
                ),
            ],
          ),
      ],
    );
  }
}

class WhenPanel extends StatelessWidget {
  const WhenPanel({
    super.key,
    required this.date,
    required this.time,
    required this.onPickDate,
    required this.onPickTime,
    required this.onNow,
    required this.onClear,
  });

  final String date;
  final String? time;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onNow;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        label(l.remFieldDate),
        OutlinedButton.icon(
          onPressed: onPickDate,
          icon: const Icon(Icons.calendar_today_outlined, size: 16),
          label: FitText(dayLabel(context, date)),
        ),
        const SizedBox(height: AppSpace.lg),
        label('${l.entryTime} ${l.optional}'),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            OutlinedButton.icon(
              onPressed: onPickTime,
              icon: const Icon(Icons.schedule, size: 18),
              label: Text(time ?? l.pickTime),
            ),
            OutlinedButton(onPressed: onNow, child: Text(l.now)),
            if (time != null)
              TextButton(onPressed: onClear, child: Text(l.clearTime)),
          ],
        ),
      ],
    );
  }
}
