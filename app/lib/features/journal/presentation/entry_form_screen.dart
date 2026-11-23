import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/database/app_database.dart';
import '../data/journal_repository.dart';
import '../../money/domain/money_snapshot.dart';
import '../../lock/providers/lock_controller.dart';
import '../../../providers.dart';
import '../../../core/widgets/common.dart';
import '../../money/presentation/money_widgets.dart';
import '../../../core/widgets/image_viewer.dart';
import '../../../core/widgets/mascot.dart';
import 'mood.dart';
import '../../money/presentation/tx_form_screen.dart';
import '../../reminders/presentation/reminder_format.dart';
import '../../reminders/presentation/reminder_suggestions.dart';
import 'voice/voice_player_card.dart';
import 'voice/voice_record_sheet.dart';
import '../../../core/tokens.dart';

/// Form tulis / edit entri jurnal. [existing] null = entri baru;
/// [initialDate] (YYYY-MM-DD) = tanggal awal entri baru, default hari ini.
class EntryFormScreen extends ConsumerStatefulWidget {
  const EntryFormScreen({
    super.key,
    this.existing,
    this.initialDate,
    this.initialTitle,
    this.initialAudioPath,
    this.initialAudioDurationMs,
    this.initialAudioTranscript,
  });

  final JournalEntry? existing;
  final String? initialDate;

  /// Judul awal entri baru (mis. dari pertanyaan permainan Kocok ide).
  final String? initialTitle;
  final String? initialAudioPath;
  final int? initialAudioDurationMs;
  final String? initialAudioTranscript;

  static Future<void> open(
    BuildContext context, {
    JournalEntry? existing,
    String? initialDate,
    String? initialTitle,
    String? initialAudioPath,
    int? initialAudioDurationMs,
    String? initialAudioTranscript,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntryFormScreen(
          existing: existing,
          initialDate: initialDate,
          initialTitle: initialTitle,
          initialAudioPath: initialAudioPath,
          initialAudioDurationMs: initialAudioDurationMs,
          initialAudioTranscript: initialAudioTranscript,
        ),
      ),
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
  String? _audioPath;
  int? _audioDurationMs;
  String? _audioTranscript;
  List<String> _imagePaths = [];
  bool _showEmptyError = false;
  bool _saving = false;

  /// Pilihan pengingat dari cerita selama form terbuka.
  final _reminders = ReminderSuggestionController();

  /// Pengingat yang sudah dibuat dari entri ini (saat mengedit).
  List<Reminder> _existingReminders = const [];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = e?.entryDate ?? widget.initialDate ?? toLocalDate(DateTime.now());
    _time = e?.entryTime;
    _mood = e?.mood;
    _audioPath = e?.audioPath ?? widget.initialAudioPath;
    _audioDurationMs = e?.audioDurationMs ?? widget.initialAudioDurationMs;
    _audioTranscript = e?.audioTranscript ?? widget.initialAudioTranscript;
    if (e == null) _title.text = widget.initialTitle ?? '';
    if (e != null) {
      _title.text = e.title ?? '';
      _body.text = e.body ?? '';
      _tags.text = entryTags(e).join(', ');
      ref.read(reminderRepositoryProvider).forEntry(e.id).then((rows) {
        if (mounted) setState(() => _existingReminders = rows);
      });
      ref.read(attachmentRepositoryProvider).getAttachmentsForEntry(e.id).then((atts) {
        if (mounted) {
          setState(() {
            _imagePaths = atts
                .map((a) => a.localPath)
                .whereType<String>()
                .toList();
          });
        }
      });
    } else if (_audioTranscript != null && _audioTranscript!.isNotEmpty) {
      _body.text = _audioTranscript!;
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

  Future<void> _recordVoice() async {
    final result = await VoiceRecordSheet.show(
      context,
      initialMode: VoiceRecordMode.voiceOnly,
    );
    if (!mounted || result == null) return;
    setState(() {
      if (result.audioPath.isNotEmpty) {
        _audioPath = result.audioPath;
        _audioDurationMs = result.durationMs;
      }
      if (result.transcript.isNotEmpty) {
        _audioTranscript = result.transcript;
        if (_body.text.trim().isEmpty) {
          _body.text = result.transcript;
        }
      }
      if (_showEmptyError) _showEmptyError = false;
    });
  }

  Future<void> _dictateStory() async {
    final result = await VoiceRecordSheet.show(
      context,
      initialMode: VoiceRecordMode.textOnly,
    );
    if (!mounted || result == null) return;
    setState(() {
      if (result.audioPath.isNotEmpty) {
        _audioPath = result.audioPath;
        _audioDurationMs = result.durationMs;
      }
      if (result.transcript.isNotEmpty) {
        if (_body.text.trim().isEmpty) {
          _body.text = result.transcript;
        } else {
          _body.text += ' ${result.transcript}';
        }
      }
      if (_showEmptyError) _showEmptyError = false;
    });
  }

  Future<void> _pickImage() async {
    final source = await showImageSourcePicker(context);
    if (source == null || !mounted) return;
    final path = await ref
        .read(attachmentRepositoryProvider)
        .pickAndStoreImage(source: source);
    if (path != null && mounted) {
      setState(() {
        _imagePaths.add(path);
        if (_showEmptyError) _showEmptyError = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  Future<void> _save() async {
    final hasAudio = _audioPath != null && _audioPath!.trim().isNotEmpty;
    final hasImages = _imagePaths.isNotEmpty;
    if (_title.text.trim().isEmpty &&
        _body.text.trim().isEmpty &&
        !hasAudio &&
        !hasImages) {
      setState(() => _showEmptyError = true);
      return;
    }
    setState(() => _saving = true);
    final entryId = await ref
        .read(journalRepositoryProvider)
        .saveEntry(
          id: widget.existing?.id,
          entryDate: _date,
          entryTime: _time,
          mood: _mood,
          title: _title.text,
          body: _body.text,
          tags: parseTags(_tags.text),
          audioPath: _audioPath,
          audioDurationMs: _audioDurationMs,
          audioTranscript: _audioTranscript,
        );
    await ref
        .read(attachmentRepositoryProvider)
        .syncEntryAttachments(entryId, _imagePaths);

    if (!mounted) return;
    final l = context.l10n;
    final drafts = _reminders.acceptedDrafts(
      _body.text,
      DateTime.now(),
      existing: _existingReminders,
    );
    final service = ref.read(reminderServiceProvider);
    final private = ref.read(lockProvider).pinEnabled;
    // Teks notifikasi disiapkan dulu selagi context masih aktif.
    final jobs = [
      for (final d in drafts)
        (
          d,
          d.title.isEmpty ? l.remDefaultTitle : d.title,
          reminderNotifTexts(
            context,
            title: d.title.isEmpty ? l.remDefaultTitle : d.title,
            date: d.date,
            time: d.time,
            lead: d.lead,
          ),
        ),
    ];
    for (final (d, title, texts) in jobs) {
      await service.add(
        entryId: entryId,
        title: title,
        date: d.date,
        time: d.time,
        lead: d.lead,
        notifTitle: texts.$1,
        notifBody: texts.$2,
        private: private,
      );
    }

    if (!mounted) return;
    final saved = widget.existing == null
        ? l.toastEntrySaved
        : l.toastEntryUpdated;
    showMascotSnackBar(
      context,
      MascotPose.senang,
      jobs.isEmpty ? saved : '$saved · ${l.remCreated(jobs.length)}',
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
            style: TextButton.styleFrom(
              foregroundColor: context.colors.expense,
            ),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(journalRepositoryProvider).deleteEntry(widget.existing!.id);
    await ref.read(reminderServiceProvider).deleteForEntry(widget.existing!.id);
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
        fontSize: AppFontSize.body,
        fontWeight: FontWeight.w600,
        color: context.colors.muted,
      ),
    );

    final outlined = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      backgroundColor: context.colors.surface,
      foregroundColor: context.colors.primary,
      side: BorderSide(color: context.colors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      textStyle: buttonTextStyle(
        context,
        const TextStyle(fontSize: AppFontSize.body, fontWeight: FontWeight.w600),
      ),
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
            padding: const EdgeInsets.only(right: AppSpace.md),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              child: Text(l.save),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.sm, AppSpace.xl, AppSpace.xxxl),
        children: [
          // Tanggal entri; bisa diganti untuk mencatat hari yang lalu.
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _pickDate,
              style: TextButton.styleFrom(
                foregroundColor: context.colors.muted,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
              ),
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text(dayLabel(context, _date)),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          label(l.entryTime, optional: true),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _pickTime,
                style: outlined.copyWith(
                  foregroundColor: WidgetStatePropertyAll(
                    _time == null ? context.colors.muted : context.colors.ink,
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
                    foregroundColor: context.colors.muted,
                    textStyle: buttonTextStyle(
                      context,
                      const TextStyle(
                        fontSize: AppFontSize.body,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  child: Text(l.clearTime),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          label(l.mood, optional: true),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              for (var v = 1; v <= 5; v++) ...[
                if (v > 1) const SizedBox(width: AppSpace.sm),
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
          const SizedBox(height: AppSpace.lg),
          label(l.entryTitle),
          const SizedBox(height: AppSpace.sm),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_showEmptyError) setState(() => _showEmptyError = false);
            },
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            decoration: InputDecoration(hintText: l.entryTitleHint),
          ),
          const SizedBox(height: AppSpace.lg),
          label('Lampiran Gambar', optional: true),
          const SizedBox(height: AppSpace.sm),
          JournalImageGrid(
            imagePaths: _imagePaths,
            onAddImage: _pickImage,
            onRemoveImage: _removeImage,
          ),
          const SizedBox(height: AppSpace.lg),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              label(l.story),
              Wrap(
                spacing: AppSpace.xs,
                children: [
                  TextButton.icon(
                    onPressed: _dictateStory,
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.sm, vertical: AppSpace.xs),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.mode_comment_outlined, size: 14),
                    label: const Text(
                      'Dikte',
                      style: TextStyle(
                        fontSize: AppFontSize.meta,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _recordVoice,
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.sm, vertical: AppSpace.xs),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      _audioPath != null
                          ? Icons.replay_rounded
                          : Icons.mic_rounded,
                      size: 15,
                    ),
                    label: Text(
                      _audioPath != null ? l.recordAgain : l.recordVoice,
                      style: const TextStyle(
                        fontSize: AppFontSize.meta,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          if (_audioPath != null) ...[
            VoicePlayerCard(
              audioPath: _audioPath!,
              durationMs: _audioDurationMs,
              transcript: _audioTranscript,
              onDelete: () => setState(() {
                _audioPath = null;
                _audioDurationMs = null;
                _audioTranscript = null;
              }),
              onCopyToNotes: (text) {
                if (_body.text.trim().isEmpty) {
                  _body.text = text;
                } else {
                  _body.text += '\n\n$text';
                }
                showMascotSnackBar(
                  context,
                  MascotPose.senang,
                  l.copiedToStory,
                );
              },
            ),
            const SizedBox(height: AppSpace.md),
          ],
          TextField(
            controller: _body,
            minLines: 6,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            // Selalu rebuild: saran pengingat dibaca dari isi cerita.
            onChanged: (_) => setState(() => _showEmptyError = false),
            style: t.bodyLarge?.copyWith(height: 1.55),
            decoration: InputDecoration(
              hintText: l.storyHint,
              errorText: _showEmptyError ? l.entryEmptyError : null,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          ReminderSuggestions(
            controller: _reminders,
            text: _body.text,
            existing: _existingReminders,
          ),
          const SizedBox(height: AppSpace.lg),
          label(l.tags, optional: true),
          const SizedBox(height: AppSpace.sm),
          TextField(
            controller: _tags,
            decoration: InputDecoration(hintText: l.tagsHint),
          ),
          const SizedBox(height: AppSpace.lg),
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
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MoodFace(mood: mood, color: color, size: 26),
                const SizedBox(height: AppSpace.xxs),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
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

/// Transaksi di tanggal yang sama, terhubung lewat local_date (tanpa FK).
class _DayTransactions extends ConsumerWidget {
  const _DayTransactions({required this.date, required this.snapshot});

  final String date;
  final MoneySnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final hideAmounts = ref.watch(hideAmountsProvider).value ?? false;
    final txs = snapshot.onDate(date).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final out = MoneySnapshot.sumOf(txs, 'expense');

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.sm),
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
                  signedRupiah(-out, hide: hideAmounts),
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
            ],
          ),
          Text(
            l.linkedByDate,
            style: t.bodySmall?.copyWith(color: context.colors.muted),
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
