import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/common.dart';
import '../../../providers.dart';
import '../domain/daily_plan.dart';

/// Popup "Buat rencana": pilih hari ini atau besok, lalu tulis satu atau
/// beberapa rencana sekaligus.
class PlanAddSheet extends ConsumerStatefulWidget {
  const PlanAddSheet({
    super.key,
    required this.today,
    required this.tomorrow,
    this.onAdded,
  });

  /// Hari ini (YYYY-MM-DD).
  final String today;

  /// Pilihan awal: besok.
  final bool tomorrow;

  /// Dipanggil tiap ada rencana yang ditambahkan, dengan hari pilihannya.
  final ValueChanged<bool>? onAdded;

  /// Hari dari rencana terakhir yang ditambahkan (true = besok); null kalau
  /// tidak ada yang ditambahkan.
  static Future<bool?> open(
    BuildContext context, {
    required String today,
    required bool tomorrow,
  }) async {
    bool? last;
    await showAppSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PlanAddSheet(
        today: today,
        tomorrow: tomorrow,
        onAdded: (t) => last = t,
      ),
    );
    return last;
  }

  @override
  ConsumerState<PlanAddSheet> createState() => _PlanAddSheetState();
}

class _PlanAddSheetState extends ConsumerState<PlanAddSheet> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _added = <({String id, String title, bool tomorrow})>[];
  late bool _tomorrow = widget.tomorrow;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _hasText => _text.text.trim().isNotEmpty;

  Future<void> _add() async {
    if (!_hasText) return;
    final title = _text.text.trim();
    final tomorrow = _tomorrow;
    _text.clear();
    // Tetap di kolom ini supaya bisa menulis beberapa rencana.
    _focus.requestFocus();
    final id = await ref
        .read(planRepositoryProvider)
        .add(
          title: title,
          date: tomorrow ? nextDay(widget.today) : widget.today,
        );
    widget.onAdded?.call(tomorrow);
    if (mounted) {
      setState(() => _added.add((id: id, title: title, tomorrow: tomorrow)));
    }
  }

  Future<void> _finish() async {
    await _add();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _undo(int i) async {
    final id = _added[i].id;
    setState(() => _added.removeAt(i));
    await ref.read(planRepositoryProvider).delete(id);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.colors;
    final labelStyle = TextStyle(fontSize: AppFontSize.meta, color: c.muted);
    final idle = !_hasText && _added.isEmpty;

    return SheetScroll(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: AppSpace.lg),
          Text(
            l.planCreate,
            style: const TextStyle(
              fontSize: AppFontSize.heading,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(l.planWhen, style: labelStyle),
          const SizedBox(height: AppSpace.sm),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: FitText(l.today)),
              ButtonSegment(value: true, label: FitText(l.planTomorrow)),
            ],
            selected: {_tomorrow},
            onSelectionChanged: (s) => setState(() => _tomorrow = s.first),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            _tomorrow ? l.planTomorrowAsk : l.planTodayAsk,
            style: labelStyle,
          ),
          const SizedBox(height: AppSpace.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('planAddText'),
                  controller: _text,
                  focusNode: _focus,
                  autofocus: true,
                  maxLength: planTitleMax,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _add,
                  style: const TextStyle(fontSize: AppFontSize.bodyLg),
                  decoration: InputDecoration(
                    hintText: l.planHint,
                    counterText: '',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              IconButton.filled(
                tooltip: l.planAddToList,
                onPressed: _hasText ? _add : null,
                style: IconButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.onPrimary,
                  disabledBackgroundColor: c.track,
                  disabledForegroundColor: c.muted,
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (_added.isNotEmpty) const SizedBox(height: AppSpace.sm),
          for (final (i, p) in _added.indexed)
            Row(
              children: [
                Icon(Icons.check_circle, size: 20, color: c.primary),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    p.title,
                    style: const TextStyle(fontSize: AppFontSize.bodyLg),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.sm,
                    vertical: AppSpace.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: c.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    p.tomorrow ? l.planTomorrow : l.today,
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: FontWeight.w600,
                      color: c.onPrimarySoft,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l.planUndo(p.title),
                  onPressed: () => _undo(i),
                  icon: Icon(Icons.close, size: 18, color: c.muted),
                ),
              ],
            ),
          const SizedBox(height: AppSpace.lg),
          FilledButton(
            onPressed: _finish,
            style: idle
                ? FilledButton.styleFrom(
                    backgroundColor: c.primarySoft,
                    foregroundColor: c.onPrimarySoft,
                  )
                : null,
            child: Text(
              _hasText
                  ? l.save
                  : _added.isNotEmpty
                  ? l.planDone
                  : l.remClose,
            ),
          ),
        ],
      ),
    );
  }
}
