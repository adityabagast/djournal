import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/journal_repository.dart';
import '../../data/money_snapshot.dart';
import '../../providers.dart';
import '../../ui/common.dart';
import '../../ui/mascot.dart';
import '../../ui/mood.dart';
import '../money/tx_form_screen.dart';

/// Form tulis / edit entri jurnal. [existing] null = entri baru.
class EntryFormScreen extends ConsumerStatefulWidget {
  const EntryFormScreen({super.key, this.existing});

  final JournalEntry? existing;

  static Future<void> open(BuildContext context, {JournalEntry? existing}) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EntryFormScreen(existing: existing)),
    );
  }

  @override
  ConsumerState<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends ConsumerState<EntryFormScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _tags = TextEditingController();
  late String _date;

  /// "HH:mm" atau null.
  String? _time;
  int? _mood;
  bool _showEmptyError = false;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = e?.entryDate ?? toLocalDate(DateTime.now());
    _time = e?.entryTime;
    _mood = e?.mood;
    if (e != null) {
      _title.text = e.title ?? '';
      _body.text = e.body ?? '';
      _tags.text = entryTags(e).join(', ');
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: parseLocalDate(_date),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = toLocalDate(picked));
  }

  Future<void> _pickTime() async {
    final initial = _time == null
        ? TimeOfDay.now()
        : TimeOfDay(
            hour: int.parse(_time!.substring(0, 2)),
            minute: int.parse(_time!.substring(3, 5)),
          );
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = _formatTime(picked));
  }

  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_title.text.trim().isEmpty && _body.text.trim().isEmpty) {
      setState(() => _showEmptyError = true);
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(journalRepositoryProvider)
        .saveEntry(
          id: widget.existing?.id,
          entryDate: _date,
          entryTime: _time,
          mood: _mood,
          title: _title.text,
          body: _body.text,
          tags: parseTags(_tags.text),
        );
    if (!mounted) return;
    final l = context.l10n;
    showMascotSnackBar(
      context,
      MascotPose.senang,
      widget.existing == null ? l.toastEntrySaved : l.toastEntryUpdated,
    );
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteEntryConfirm),
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
    await ref.read(journalRepositoryProvider).deleteEntry(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final snap = ref.watch(moneySnapshotProvider).value;

    Widget label(String text, {bool optional = false}) => Text.rich(
      TextSpan(
        text: text,
        children: [
          if (optional)
            TextSpan(
              text: ' ${l.optional}',
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
        ],
      ),
      style: t.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
      ),
    );

    final outlined = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? l.editEntryTitle : l.newEntryTitle,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: l.delete,
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              child: Text(l.save),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          // Tanggal entri; bisa diganti untuk mencatat hari yang lalu.
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _pickDate,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.muted,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
              ),
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text(dayLabel(context, _date)),
            ),
          ),
          const SizedBox(height: 8),
          label(l.entryTime, optional: true),
          const SizedBox(height: 6),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickTime,
                style: outlined.copyWith(
                  foregroundColor: WidgetStatePropertyAll(
                    _time == null ? AppColors.muted : AppColors.ink,
                  ),
                ),
                icon: const Icon(Icons.schedule, size: 18),
                label: Text(
                  _time ?? l.pickTime,
                  style: TextStyle(
                    fontSize: _time == null ? 13 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () =>
                    setState(() => _time = _formatTime(TimeOfDay.now())),
                style: outlined,
                child: Text(l.now),
              ),
              if (_time != null)
                TextButton(
                  onPressed: () => setState(() => _time = null),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.muted,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  child: Text(l.clearTime),
                ),
            ],
          ),
          const SizedBox(height: 16),
          label(l.mood, optional: true),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var v = 1; v <= 5; v++) ...[
                if (v > 1) const SizedBox(width: 6),
                Expanded(
                  child: _MoodChoice(
                    mood: v,
                    selected: _mood == v,
                    // Tap lagi untuk membatalkan pilihan.
                    onTap: () => setState(() => _mood = _mood == v ? null : v),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          label(l.entryTitle),
          const SizedBox(height: 6),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_showEmptyError) setState(() => _showEmptyError = false);
            },
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            decoration: InputDecoration(hintText: l.entryTitleHint),
          ),
          const SizedBox(height: 16),
          label(l.story),
          const SizedBox(height: 6),
          TextField(
            controller: _body,
            minLines: 6,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_showEmptyError) setState(() => _showEmptyError = false);
            },
            style: t.bodyLarge?.copyWith(height: 1.55),
            decoration: InputDecoration(
              hintText: l.storyHint,
              errorText: _showEmptyError ? l.entryEmptyError : null,
            ),
          ),
          const SizedBox(height: 16),
          label(l.tags, optional: true),
          const SizedBox(height: 6),
          TextField(
            controller: _tags,
            decoration: InputDecoration(hintText: l.tagsHint),
          ),
          const SizedBox(height: 16),
          if (snap != null) _DayTransactions(date: _date, snapshot: snap),
        ],
      ),
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
    final color = selected ? AppColors.primary : AppColors.muted;
    final text = moodLabel(context.l10n, mood);
    return Semantics(
      selected: selected,
      button: true,
      label: text,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.line,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MoodFace(mood: mood, color: color, size: 26),
                const SizedBox(height: 2),
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
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

/// Transaksi di tanggal yang sama, terhubung lewat local_date (tanpa FK).
class _DayTransactions extends StatelessWidget {
  const _DayTransactions({required this.date, required this.snapshot});

  final String date;
  final MoneySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final txs = snapshot.onDate(date).toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final out = MoneySnapshot.sumOf(txs, 'expense');

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.dayTransactions,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (out > 0)
                Text(
                  '−${rupiah(out)}',
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
            ],
          ),
          Text(
            l.linkedByDate,
            style: t.bodySmall?.copyWith(color: AppColors.muted),
          ),
          if (txs.isEmpty) EmptyNote(l.noTransactions),
          for (var i = 0; i < txs.length; i++)
            TxRow(
              tx: txs[i],
              snapshot: snapshot,
              leadingTime: true,
              showDivider: i < txs.length - 1,
              onTap: () => TxFormScreen.open(context, existing: txs[i]),
            ),
        ],
      ),
    );
  }
}
