import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/database/app_database.dart';
import '../data/journal_repository.dart';
import '../../money/domain/money_snapshot.dart';
import '../../money/domain/tx_suggestions.dart';
import '../../money/presentation/money_widgets.dart';
import '../../money/presentation/tx_note_widgets.dart';
import '../../lock/providers/lock_controller.dart';
import '../../../providers.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/image_viewer.dart';
import '../../../core/widgets/mascot.dart';
import 'mood.dart';
import 'note/note_parts.dart';
import 'note/note_toolbar.dart';
import '../../reminders/presentation/reminder_format.dart';
import '../../reminders/presentation/reminder_suggestions.dart';
import 'voice/voice_player_card.dart';
import 'voice/voice_record_sheet.dart';
import '../../../core/tokens.dart';

/// Isi catatan, untuk mengenali perubahan yang belum disimpan.
typedef _Draft = ({
  String date,
  String? time,
  int? mood,
  String title,
  String body,
  List<String> tags,
  String? audioPath,
  int? audioDurationMs,
  String? audioTranscript,
  List<String> images,
});

bool _sameDraft(_Draft a, _Draft b) =>
    a.date == b.date &&
    a.time == b.time &&
    a.mood == b.mood &&
    a.title.trim() == b.title.trim() &&
    a.body.trim() == b.body.trim() &&
    a.audioPath == b.audioPath &&
    listEquals(a.tags, b.tags) &&
    listEquals(a.images, b.images);

/// Halaman catatan jurnal: baca dan tulis di layar yang sama. [existing] null
/// = catatan baru (langsung tulis); entri lama dibuka untuk dibaca dulu.
/// [initialDate] (YYYY-MM-DD) = tanggal awal entri baru, default hari ini.
class EntryFormScreen extends ConsumerStatefulWidget {
  const EntryFormScreen({
    super.key,
    this.existing,
    this.startEditing = false,
    this.initialDate,
    this.initialTitle,
    this.initialAudioPath,
    this.initialAudioDurationMs,
    this.initialAudioTranscript,
  });

  final JournalEntry? existing;

  /// Entri lama langsung dibuka untuk diedit dan ditutup setelah disimpan
  /// (desktop sudah punya panel baca sendiri).
  final bool startEditing;
  final String? initialDate;

  /// Judul awal entri baru (mis. dari pertanyaan permainan Kocok ide).
  final String? initialTitle;
  final String? initialAudioPath;
  final int? initialAudioDurationMs;
  final String? initialAudioTranscript;

  static Future<void> open(
    BuildContext context, {
    JournalEntry? existing,
    bool startEditing = false,
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
          startEditing: startEditing,
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
  static const _maxImages = 10;

  final _title = TextEditingController();
  final _body = TextEditingController();
  final _tagInput = TextEditingController();
  final _titleFocus = FocusNode();
  final _bodyFocus = FocusNode();
  final _scroll = ScrollController();

  late String _date;

  /// "HH:mm" atau null.
  String? _time;
  int? _mood;
  List<String> _tags = [];
  String? _audioPath;
  int? _audioDurationMs;
  String? _audioTranscript;
  List<String> _imagePaths = [];

  /// Selesai setelah foto lama dibaca; sebelum itu daftar fotonya belum
  /// lengkap dan tidak boleh dipakai untuk menyimpan.
  Future<bool> _imagesLoading = Future.value(true);

  /// Id entri yang tersimpan; null = catatan baru.
  String? _entryId;

  /// Isi terakhir yang tersimpan.
  late _Draft _saved;
  late bool _editing;
  NotePanel? _panel;
  bool _txOpen = false;
  bool _showEmptyError = false;
  bool _saving = false;

  /// Pilihan pengingat dan transaksi dari cerita selama mode tulis.
  var _reminders = ReminderSuggestionController();
  var _txs = TxSuggestionController();

  /// Pengingat yang sudah dibuat dari entri ini.
  List<Reminder> _existingReminders = const [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _entryId = e?.id;
    _editing = e == null || widget.startEditing;
    _date = e?.entryDate ?? widget.initialDate ?? toLocalDate(DateTime.now());
    if (e != null) {
      _time = e.entryTime;
      _mood = e.mood;
      _title.text = e.title ?? '';
      _body.text = e.body ?? '';
      _tags = entryTags(e);
      _audioPath = e.audioPath;
      _audioDurationMs = e.audioDurationMs;
      _audioTranscript = e.audioTranscript;
      _loadReminders(e.id);
      _imagesLoading = _loadImages(e.id);
    } else {
      _title.text = widget.initialTitle ?? '';
    }
    _saved = _draft();
    if (e == null) {
      // Rekaman dari Tambah cepat belum tersimpan sampai user menekan Simpan.
      _audioPath = widget.initialAudioPath;
      _audioDurationMs = widget.initialAudioDurationMs;
      _audioTranscript = widget.initialAudioTranscript;
      _body.text = widget.initialAudioTranscript ?? '';
    }
    // Saran dan tanda "belum disimpan" dibaca dari isi catatan.
    for (final c in [_title, _body]) {
      c.addListener(_onText);
    }
    for (final f in [_titleFocus, _bodyFocus]) {
      f.addListener(() {
        if (f.hasFocus && _panel != null) setState(() => _panel = null);
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _tagInput.dispose();
    _titleFocus.dispose();
    _bodyFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onText() => setState(() => _showEmptyError = false);

  /// true kalau foto lama berhasil dibaca (atau memang belum ada).
  Future<bool> _loadImages(String entryId) async {
    try {
      final atts = await ref
          .read(attachmentRepositoryProvider)
          .getAttachmentsForEntry(entryId);
      if (!mounted) return false;
      final paths = atts.map((a) => a.localPath).whereType<String>().toList();
      setState(() {
        _imagePaths = [...paths, ..._imagePaths];
        _saved = _withImages(_saved, paths);
      });
      return true;
    } catch (e) {
      debugPrint('Foto jurnal gagal dibaca: ${e.runtimeType}');
      return false;
    }
  }

  Future<void> _loadReminders(String entryId) async {
    final rows = await ref.read(reminderRepositoryProvider).forEntry(entryId);
    if (mounted) setState(() => _existingReminders = rows);
  }

  _Draft _draft() => (
    date: _date,
    time: _time,
    mood: _mood,
    title: _title.text,
    body: _body.text,
    tags: [..._tags],
    audioPath: _audioPath,
    audioDurationMs: _audioDurationMs,
    audioTranscript: _audioTranscript,
    images: [..._imagePaths],
  );

  static _Draft _withImages(_Draft d, List<String> images) => (
    date: d.date,
    time: d.time,
    mood: d.mood,
    title: d.title,
    body: d.body,
    tags: d.tags,
    audioPath: d.audioPath,
    audioDurationMs: d.audioDurationMs,
    audioTranscript: d.audioTranscript,
    images: [...images],
  );

  bool get _dirty =>
      _editing &&
      (!_sameDraft(_draft(), _saved) ||
          _txs.hasAccepted ||
          parseTags(_tagInput.text).isNotEmpty ||
          _reminders
              .acceptedDrafts(
                _body.text,
                DateTime.now(),
                existing: _existingReminders,
              )
              .isNotEmpty);

  bool get _empty =>
      _title.text.trim().isEmpty &&
      _body.text.trim().isEmpty &&
      (_audioPath?.trim().isEmpty ?? true) &&
      _imagePaths.isEmpty;

  // ---------------------------------------------------------------- mode

  void _startEdit() {
    setState(() {
      _editing = true;
      _panel = null;
    });
    _bodyFocus.requestFocus();
  }

  void _toRead() {
    _unfocus();
    setState(() {
      _editing = false;
      _panel = null;
      _showEmptyError = false;
      _tagInput.clear();
      _reminders = ReminderSuggestionController();
      _txs = TxSuggestionController();
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _restore(_Draft d) {
    _date = d.date;
    _time = d.time;
    _mood = d.mood;
    _title.text = d.title;
    _body.text = d.body;
    _tags = [...d.tags];
    _audioPath = d.audioPath;
    _audioDurationMs = d.audioDurationMs;
    _audioTranscript = d.audioTranscript;
    _imagePaths = [...d.images];
  }

  /// Kembali dari mode tulis: tutup panel, konfirmasi kalau ada yang belum
  /// disimpan, lalu ke mode baca atau keluar.
  Future<void> _onBack() async {
    if (_panel != null) {
      setState(() => _panel = null);
      return;
    }
    final navigator = Navigator.of(context);
    if (_dirty) {
      final answer = await NoteLeaveSheet.show(context);
      if (!mounted) return;
      switch (answer) {
        case NoteLeave.save:
          await _save();
          return;
        case NoteLeave.discard:
          _restore(_saved);
        case NoteLeave.stay || null:
          return;
      }
    }
    if (_entryId != null && !widget.startEditing) {
      _toRead();
    } else {
      navigator.pop();
    }
  }

  /// Lepas fokus dari kolomnya sendiri; lewat FocusScope, fokus (dan
  /// keyboard) kembali ke kolom itu setelah sheet ditutup.
  void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  void _togglePanel(NotePanel p) {
    if (_panel == p) {
      setState(() => _panel = null);
      _bodyFocus.requestFocus();
      return;
    }
    _unfocus();
    setState(() => _panel = p);
  }

  void _toggleKeyboard(bool open) {
    if (open) {
      _unfocus();
      return;
    }
    setState(() => _panel = null);
    _bodyFocus.requestFocus();
    // Fokus bisa sudah di sini walau keyboard-nya ditutup.
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  // --------------------------------------------------------------- isian

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

  void _addTags() {
    final added = parseTags(_tagInput.text);
    setState(() {
      _tags = {..._tags, ...added}.toList();
      _tagInput.clear();
    });
  }

  Future<void> _recordVoice() async {
    _unfocus();
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
        if (_body.text.trim().isEmpty) _body.text = result.transcript;
      }
      _showEmptyError = false;
    });
  }

  Future<void> _dictateStory() async {
    _unfocus();
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
        _body.text = _body.text.trim().isEmpty
            ? result.transcript
            : '${_body.text} ${result.transcript}';
      }
      _showEmptyError = false;
    });
  }

  Future<void> _pickImage() async {
    if (_imagePaths.length >= _maxImages) {
      showMascotSnackBar(
        context,
        MascotPose.sedih,
        context.l10n.notePhotoMax,
        aboveDock: false,
      );
      return;
    }
    _unfocus();
    final source = await showImageSourcePicker(context);
    if (source == null || !mounted) return;
    final path = await ref
        .read(attachmentRepositoryProvider)
        .pickAndStoreImage(source: source);
    if (path != null && mounted) {
      setState(() {
        _imagePaths = [..._imagePaths, path];
        _showEmptyError = false;
      });
    }
  }

  // -------------------------------------------------------------- simpan

  /// Transaksi dari jurnal memakai tanggal catatan; jamnya jam kejadian,
  /// atau sekarang (hari ini), atau tengah hari (hari lalu).
  DateTime _occurredAt() {
    final day = parseLocalDate(_date);
    final now = DateTime.now();
    if (_time case final t?) {
      return DateTime(
        day.year,
        day.month,
        day.day,
        int.parse(t.substring(0, 2)),
        int.parse(t.substring(3, 5)),
      );
    }
    return _date == toLocalDate(now)
        ? now
        : DateTime(day.year, day.month, day.day, 12);
  }

  Future<void> _save() async {
    _addTags();
    if (_empty) {
      setState(() => _showEmptyError = true);
      if (_scroll.hasClients) _scroll.jumpTo(0);
      return;
    }
    setState(() => _saving = true);
    final isNew = _entryId == null;
    final entryId = await ref
        .read(journalRepositoryProvider)
        .saveEntry(
          id: _entryId,
          entryDate: _date,
          entryTime: _time,
          mood: _mood,
          title: _title.text,
          body: _body.text,
          tags: _tags,
          audioPath: _audioPath,
          audioDurationMs: _audioDurationMs,
          audioTranscript: _audioTranscript,
        );
    // Foto yang gagal dibaca jangan sampai dianggap dihapus.
    if (await _imagesLoading) {
      await ref
          .read(attachmentRepositoryProvider)
          .syncEntryAttachments(entryId, _imagePaths);
    }

    if (!mounted) return;
    final l = context.l10n;
    final reminderCount = await _saveReminders(entryId);
    if (!mounted) return;
    final (txCount, overBudget) = await _saveTransactions();
    if (!mounted) return;

    showMascotSnackBar(
      context,
      overBudget == null ? MascotPose.senang : MascotPose.sedih,
      [
        isNew ? l.toastEntrySaved : l.toastEntryUpdated,
        if (txCount > 0) l.noteTxSaved(txCount),
        if (reminderCount > 0) l.remCreated(reminderCount),
        if (overBudget != null) l.toastBudgetOver(categoryLabel(l, overBudget)),
      ].join(' · '),
      aboveDock: widget.startEditing,
    );
    if (widget.startEditing) {
      Navigator.of(context).pop();
      return;
    }
    _entryId = entryId;
    _title.text = _title.text.trim();
    _body.text = _body.text.trim();
    _saved = _draft();
    _saving = false;
    if (txCount > 0) _txOpen = true;
    _toRead();
    await _loadReminders(entryId);
  }

  Future<int> _saveReminders(String entryId) async {
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
    return jobs.length;
  }

  /// Catat transaksi yang diterima. Hasil: jumlahnya, dan kategori yang
  /// budget bulannya jadi terlewati (kalau ada).
  Future<(int, Category?)> _saveTransactions() async {
    final snap = ref.read(moneySnapshotProvider).value;
    if (snap == null) return (0, null);
    final drafts = _txs.accepted(_body.text, _date, snap);
    final at = _occurredAt();
    final repo = ref.read(moneyRepositoryProvider);
    final attachments = ref.read(attachmentRepositoryProvider);
    for (final d in drafts) {
      final txId = await repo.saveTransaction(
        type: d.type,
        amount: d.amount,
        walletId: d.walletId,
        categoryId: d.categoryId,
        note: d.note,
        occurredAt: at,
      );
      if (d.receiptPath case final path?) {
        // Foto catatan disalin agar nota tetap ada kalau fotonya dihapus
        // dari catatan.
        final own = _imagePaths.contains(path)
            ? await attachments.copyStoredImage(path)
            : path;
        await attachments.syncTxAttachment(txId, own);
      }
    }
    final month = toMonthKey(at);
    final spent = <String, int>{};
    for (final d in drafts) {
      if (d.type != 'expense' || d.categoryId == null) continue;
      spent.update(
        snap.rootIdOf(d.categoryId!),
        (n) => n + d.amount,
        ifAbsent: () => d.amount,
      );
    }
    for (final MapEntry(key: root, value: amount) in spent.entries) {
      final budget = snap.budgetFor(root, month);
      if (budget > 0 && snap.spentIn(root, month) + amount > budget) {
        return (drafts.length, snap.categoryById[root]);
      }
    }
    return (drafts.length, null);
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
    await ref.read(journalRepositoryProvider).deleteEntry(_entryId!);
    await ref.read(reminderServiceProvider).deleteForEntry(_entryId!);
    if (mounted) Navigator.of(context).pop();
  }

  // ------------------------------------------------------------ tampilan

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final snap = ref.watch(moneySnapshotProvider).value;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    _txs.photos = _imagePaths;
    final items = _editing && snap != null
        ? _txs.items(_body.text, _date, snap)
        : const <TxDraft>[];
    final leavesApp = _entryId == null || widget.startEditing;

    return PopScope(
      canPop: !_editing || (_panel == null && !_dirty && leavesApp),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: c.surface,
        appBar: AppBar(
          backgroundColor: c.surface,
          scrolledUnderElevation: 0,
          actions: [
            if (_entryId != null)
              IconButton(
                tooltip: l.delete,
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
              ),
            if (_editing)
              Padding(
                padding: const EdgeInsets.only(right: AppSpace.md),
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(l.save),
                ),
              )
            else
              IconButton(
                tooltip: l.noteEditAction,
                onPressed: _startEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, box) => Column(
              children: [
                Expanded(child: _page(snap, items)),
                if (_editing) ...[
                  // Di layar sangat pendek tulisan didahulukan.
                  if (_panel == null && box.maxHeight > 200)
                    _suggestionBar(snap, items),
                  NoteToolbar(
                    panel: _panel,
                    mood: _mood,
                    hasAudio: _audioPath != null,
                    keyboardOpen: keyboardOpen,
                    onPanel: _togglePanel,
                    onPhoto: _pickImage,
                    onRecord: _recordVoice,
                    onDictate: _dictateStory,
                    onKeyboard: () => _toggleKeyboard(keyboardOpen),
                  ),
                  if (_panel != null)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: math.max(0, box.maxHeight * 0.48),
                      ),
                      child: NotePanelFrame(child: _panelBody(snap, items)),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _suggestionBar(MoneySnapshot? snap, List<TxDraft> items) {
    final pending = items
        .where((d) => d.state == TxDraftState.pending)
        .toList();
    if (snap != null && pending.isNotEmpty) {
      return TxSuggestionBar(
        controller: _txs,
        pending: pending,
        snapshot: snap,
        onChanged: () => setState(() {}),
        onOpenPanel: () => _togglePanel(NotePanel.money),
      );
    }
    return ReminderBar(
      controller: _reminders,
      text: _body.text,
      existing: _existingReminders,
      onChanged: () => setState(() {}),
    );
  }

  Widget _panelBody(MoneySnapshot? snap, List<TxDraft> items) =>
      switch (_panel!) {
        NotePanel.when => WhenPanel(
          date: _date,
          time: _time,
          onPickDate: _pickDate,
          onPickTime: _pickTime,
          onNow: () => setState(() => _time = _formatTime(TimeOfDay.now())),
          onClear: () => setState(() => _time = null),
        ),
        NotePanel.mood => MoodPanel(
          mood: _mood,
          onChanged: (v) => setState(() => _mood = v),
        ),
        NotePanel.tag => TagPanel(
          controller: _tagInput,
          tags: _tags,
          onAdd: _addTags,
          onRemove: (tag) =>
              setState(() => _tags = _tags.where((t) => t != tag).toList()),
        ),
        NotePanel.money =>
          snap == null
              ? const Center(child: CircularProgressIndicator())
              : TxSuggestionPanel(
                  controller: _txs,
                  items: items,
                  snapshot: snap,
                  onChanged: () => setState(() {}),
                ),
      };

  Widget _page(MoneySnapshot? snap, List<TxDraft> items) {
    final c = context.colors;
    final accepted = items
        .where((d) => d.state == TxDraftState.accepted)
        .toList();
    const gap = SizedBox(height: AppSpace.lg);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xl,
            0,
            AppSpace.xl,
            AppSpace.xxxl,
          ),
          children: [
            if (_editing) ..._writeText() else ..._readText(),
            if (_imagePaths.isNotEmpty) ...[
              gap,
              NotePhotos(
                paths: _imagePaths,
                onRemove: _editing
                    ? (i) => setState(
                        () => _imagePaths = [..._imagePaths]..removeAt(i),
                      )
                    : null,
              ),
            ],
            if (_audioPath != null) ...[gap, _player()],
            if (_tags.isNotEmpty) ...[
              gap,
              Wrap(
                spacing: AppSpace.md,
                runSpacing: AppSpace.xs,
                children: [
                  for (final tag in _tags)
                    Text(
                      '#$tag',
                      style: TextStyle(
                        fontSize: AppFontSize.body,
                        fontWeight: FontWeight.w500,
                        color: c.primary,
                      ),
                    ),
                ],
              ),
            ],
            NoteReminders(
              controller: _reminders,
              text: _editing ? _body.text : '',
              existing: _existingReminders,
              onChanged: () => setState(() {}),
            ),
            if (snap != null) ...[
              gap,
              NoteDayTransactions(
                date: _date,
                snapshot: snap,
                open: _txOpen,
                onToggle: () => setState(() => _txOpen = !_txOpen),
                accepted: accepted,
                notePhotos: _imagePaths,
                onEditDraft: (d) async {
                  await editTxDraft(context, _txs, d);
                  if (mounted) setState(() {});
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _player() {
    final key = ValueKey(_audioPath);
    if (!_editing) {
      return VoicePlayerCard(
        key: key,
        audioPath: _audioPath!,
        durationMs: _audioDurationMs,
        transcript: _audioTranscript,
      );
    }
    return VoicePlayerCard(
      key: key,
      audioPath: _audioPath!,
      durationMs: _audioDurationMs,
      transcript: _audioTranscript,
      onDelete: () => setState(() {
        _audioPath = null;
        _audioDurationMs = null;
        _audioTranscript = null;
      }),
      onCopyToNotes: (text) {
        _body.text = _body.text.trim().isEmpty
            ? text
            : '${_body.text}\n\n$text';
        showMascotSnackBar(
          context,
          MascotPose.senang,
          context.l10n.copiedToStory,
        );
      },
    );
  }

  TextStyle get _titleStyle => TextStyle(
    fontSize: AppFontSize.display,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: context.colors.ink,
  );

  TextStyle get _bodyStyle => TextStyle(
    fontSize: AppFontSize.title,
    height: 1.7,
    color: context.colors.ink,
  );

  List<Widget> _writeText() {
    final l = context.l10n;
    final c = context.colors;
    ButtonStyle meta(bool active) => TextButton.styleFrom(
      foregroundColor: active ? c.muted : c.primary,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
      minimumSize: const Size(0, 44),
      textStyle: buttonTextStyle(
        context,
        const TextStyle(
          fontSize: AppFontSize.body,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    InputDecoration plain(String hint, TextStyle style) => InputDecoration(
      hintText: hint,
      hintStyle: style.copyWith(color: c.muted),
      filled: false,
      isDense: true,
      contentPadding: EdgeInsets.zero,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
    );

    return [
      Transform.translate(
        // Teks tombol sejajar dengan judul di bawahnya.
        offset: const Offset(-AppSpace.sm, 0),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () => _togglePanel(NotePanel.when),
              style: meta(true),
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text(
                DateFormat(
                  'EEE, d MMM',
                  context.localeTag,
                ).format(parseLocalDate(_date)),
              ),
            ),
            TextButton(
              onPressed: () => _togglePanel(NotePanel.when),
              style: meta(_time != null),
              child: Text(_time ?? l.noteAddTime),
            ),
            TextButton.icon(
              onPressed: () => _togglePanel(NotePanel.mood),
              style: meta(_mood != null),
              icon: _mood == null
                  ? const Icon(Icons.add_reaction_outlined, size: 18)
                  : MoodFace(mood: _mood!, color: c.primary, size: 18),
              label: Text(_mood == null ? l.mood : moodLabel(l, _mood!)),
            ),
          ],
        ),
      ),
      TextField(
        key: const Key('noteTitle'),
        controller: _title,
        focusNode: _titleFocus,
        maxLines: null,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.deny('\n')],
        onSubmitted: (_) => _bodyFocus.requestFocus(),
        textCapitalization: TextCapitalization.sentences,
        style: _titleStyle,
        decoration: plain(l.entryTitle, _titleStyle),
      ),
      if (_showEmptyError)
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.xs),
          child: Text(
            l.entryEmptyError,
            style: TextStyle(fontSize: AppFontSize.body, color: c.expense),
          ),
        ),
      const SizedBox(height: AppSpace.md),
      TextField(
        key: const Key('noteBody'),
        controller: _body,
        focusNode: _bodyFocus,
        autofocus: _entryId == null && widget.initialAudioPath == null,
        minLines: 8,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        style: _bodyStyle,
        decoration: plain(l.storyHint, _bodyStyle),
      ),
    ];
  }

  List<Widget> _readText() {
    final l = context.l10n;
    final c = context.colors;
    final meta = TextStyle(fontSize: AppFontSize.body, color: c.muted);
    final date = DateFormat(
      'EEEE, d MMMM y',
      context.localeTag,
    ).format(parseLocalDate(_date));
    return [
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Wrap(
          spacing: AppSpace.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text([date, ?_time].join(' · '), style: meta),
            if (_mood != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MoodFace(mood: _mood!, color: c.primary, size: 18),
                  const SizedBox(width: AppSpace.xs),
                  Text(moodLabel(l, _mood!), style: meta),
                ],
              ),
          ],
        ),
      ),
      if (!(_title.text.isEmpty && _body.text.isEmpty))
        Semantics(
          button: true,
          onTapHint: l.noteEditAction,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _startEdit,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_title.text.isNotEmpty) ...[
                  Text(_title.text, style: _titleStyle),
                  const SizedBox(height: AppSpace.md),
                ],
                if (_body.text.isNotEmpty) Text(_body.text, style: _bodyStyle),
              ],
            ),
          ),
        ),
    ];
  }
}
