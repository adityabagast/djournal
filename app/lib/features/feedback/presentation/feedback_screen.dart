import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config.dart';
import '../../../core/theme.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/mascot.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../domain/feedback_mail.dart';

/// Pengaturan › Tentang › Kirim masukan: lapor bug atau usul fitur lewat
/// aplikasi email milik user.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const FeedbackScreen()));

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  FeedbackKind _kind = FeedbackKind.bug;
  FeedbackArea _area = FeedbackArea.other;
  FeedbackSeverity _severity = FeedbackSeverity.medium;
  bool _withDevice = true;
  bool _tried = false;
  bool _done = false;
  bool _busy = false;

  bool get _isBug => _kind == FeedbackKind.bug;
  bool get _dirty =>
      _title.text.trim().isNotEmpty || _body.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _title.addListener(_changed);
    _body.addListener(_changed);
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  String _areaLabel(AppLocalizations l, FeedbackArea a) => switch (a) {
    FeedbackArea.journal => l.navJournal,
    FeedbackArea.money => l.navMoney,
    FeedbackArea.report => l.navReport,
    FeedbackArea.reminders => l.fbAreaReminders,
    FeedbackArea.backup => l.fbAreaBackup,
    FeedbackArea.other => l.fbAreaOther,
  };

  String _severityLabel(AppLocalizations l, FeedbackSeverity s) => switch (s) {
    FeedbackSeverity.low => l.fbSevLow,
    FeedbackSeverity.medium => l.fbSevMedium,
    FeedbackSeverity.high => l.fbSevHigh,
  };

  Future<FeedbackMail> _compose() async {
    final l = context.l10n;
    final device = <String>[];
    if (_isBug && _withDevice) {
      try {
        final app = await ref.read(appVersionProvider.future);
        device.add('Nyawtat ${app.version} (${app.buildNumber})');
      } on Exception {
        // Versi tidak terbaca: laporan tetap bisa dikirim tanpa versi.
      }
      final info = await ref.read(feedbackServiceProvider).deviceInfo();
      if (info != null) device.add(info);
    }
    return FeedbackMail.compose(
      kindLabel: _isBug ? l.fbBug : l.fbFeature,
      title: _title.text.trim().isEmpty ? l.fbNoTitle : _title.text,
      areaLine: l.fbMailArea(_areaLabel(l, _area)),
      severityLine: _isBug
          ? l.fbMailSeverity(_severityLabel(l, _severity))
          : null,
      body: _body.text.trim().isEmpty ? l.fbNoBody : _body.text,
      deviceLines: device,
    );
  }

  Future<void> _openMail() async {
    if (_busy) return;
    if (!validFeedbackTitle(_title.text) || !validFeedbackBody(_body.text)) {
      setState(() => _tried = true);
      return;
    }
    _busy = true;
    try {
      final mail = await _compose();
      final opened = await ref
          .read(feedbackServiceProvider)
          .open(mail.uri(supportEmail));
      if (!mounted) return;
      if (opened) {
        setState(() => _done = true);
      } else {
        await showAppSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => _NoMailSheet(mail: mail),
        );
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _preview() async {
    final mail = await _compose();
    if (!mounted) return;
    await showAppSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PreviewSheet(mail: mail),
    );
  }

  Future<void> _confirmDiscard() async {
    final discard = await showAppSheet<bool>(
      context: context,
      builder: (_) => const _DiscardSheet(),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_done) {
          setState(() => _done = false);
        } else {
          _confirmDiscard();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l.fbTitle,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        body: _done ? _doneView(l) : _form(l),
      ),
    );
  }

  Widget _form(AppLocalizations l) {
    final c = context.colors;
    final labelStyle = TextStyle(fontSize: AppFontSize.meta, color: c.muted);
    const gap = SizedBox(height: AppSpace.lg);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xl,
        AppSpace.sm,
        AppSpace.xl,
        AppSpace.xxxl,
      ),
      children: [
        SegmentedButton<FeedbackKind>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: FeedbackKind.bug, label: Text(l.fbBug)),
            ButtonSegment(
              value: FeedbackKind.feature,
              label: Text(l.fbFeature),
            ),
          ],
          selected: {_kind},
          onSelectionChanged: (s) => setState(() {
            _kind = s.first;
            _tried = false;
          }),
        ),
        gap,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.fbArea, style: labelStyle),
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.xs,
                children: [
                  for (final a in FeedbackArea.values)
                    ChoiceChip(
                      label: Text(_areaLabel(l, a)),
                      selected: a == _area,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _area = a),
                      selectedColor: c.primary,
                      backgroundColor: c.surface,
                      side: BorderSide(color: a == _area ? c.primary : c.line),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: a == _area ? c.onPrimary : c.ink,
                      ),
                    ),
                ],
              ),
              gap,
              Text(_isBug ? l.fbBugTitle : l.fbFeatureTitle, style: labelStyle),
              const SizedBox(height: AppSpace.sm),
              TextField(
                key: const Key('fbTitle'),
                controller: _title,
                maxLength: feedbackTitleMax,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: _isBug ? l.fbBugTitleHint : l.fbFeatureTitleHint,
                  hintStyle: TextStyle(
                    fontSize: AppFontSize.bodyLg,
                    color: c.muted,
                  ),
                  counterText: '',
                  errorText: _tried && !validFeedbackTitle(_title.text)
                      ? l.fbTitleError
                      : null,
                ),
              ),
              gap,
              Text(_isBug ? l.fbBugBody : l.fbFeatureBody, style: labelStyle),
              const SizedBox(height: AppSpace.sm),
              TextField(
                key: const Key('fbBody'),
                controller: _body,
                maxLength: feedbackBodyMax,
                minLines: 4,
                maxLines: 10,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: _isBug ? l.fbBugBodyHint : l.fbFeatureBodyHint,
                  hintStyle: TextStyle(
                    fontSize: AppFontSize.bodyLg,
                    color: c.muted,
                  ),
                  hintMaxLines: 3,
                  errorText: _tried && !validFeedbackBody(_body.text)
                      ? l.fbBodyError
                      : null,
                ),
              ),
              if (_isBug) ...[
                const SizedBox(height: AppSpace.sm),
                Text(l.fbSeverity, style: labelStyle),
                const SizedBox(height: AppSpace.sm),
                SegmentedButton<FeedbackSeverity>(
                  showSelectedIcon: false,
                  segments: [
                    for (final s in FeedbackSeverity.values)
                      ButtonSegment(
                        value: s,
                        label: FitText(_severityLabel(l, s)),
                      ),
                  ],
                  selected: {_severity},
                  onSelectionChanged: (s) =>
                      setState(() => _severity = s.first),
                ),
                const SizedBox(height: AppSpace.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _withDevice,
                  onChanged: (v) => setState(() => _withDevice = v),
                  title: Text(
                    l.fbDevice,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(l.fbDeviceSub, style: labelStyle),
                  activeThumbColor: c.onPrimary,
                  activeTrackColor: c.primary,
                ),
              ],
            ],
          ),
        ),
        gap,
        Container(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: c.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 18, color: c.onPrimarySoft),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  l.fbPrivacy,
                  style: TextStyle(
                    fontSize: AppFontSize.meta,
                    height: 1.5,
                    color: c.onPrimarySoft,
                  ),
                ),
              ),
            ],
          ),
        ),
        gap,
        FilledButton(onPressed: _openMail, child: Text(l.fbOpenMail)),
        TextButton(onPressed: _preview, child: Text(l.fbPreview)),
      ],
    );
  }

  Widget _doneView(AppLocalizations l) {
    final c = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xxxl,
        AppSpace.xxxl * 2,
        AppSpace.xxxl,
        AppSpace.xxxl,
      ),
      children: [
        const Center(child: Mascot(MascotPose.senang)),
        const SizedBox(height: AppSpace.lg),
        Text(
          l.fbDoneTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: AppFontSize.heading,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          l.fbDoneBody,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppFontSize.bodyLg,
            height: 1.6,
            color: c.muted,
          ),
        ),
        const SizedBox(height: AppSpace.xxl),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.fbDoneSent),
        ),
        const SizedBox(height: AppSpace.sm),
        OutlinedButton(onPressed: _openMail, child: Text(l.fbDoneAgain)),
        TextButton(
          onPressed: () => setState(() => _done = false),
          child: Text(l.fbDoneEdit),
        ),
      ],
    );
  }
}

/// Kerangka sheet: pegangan, judul, keterangan, lalu isi.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.title, required this.sub, required this.children});

  final String title;
  final String sub;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xl,
          AppSpace.md,
          AppSpace.xl,
          AppSpace.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: AppSpace.lg),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppFontSize.heading,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              sub,
              style: TextStyle(
                fontSize: AppFontSize.body,
                color: context.colors.muted,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _MailText extends StatelessWidget {
  const _MailText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: context.colors.subtle,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: SelectableText(
        text,
        key: const Key('fbPreview'),
        style: const TextStyle(fontSize: AppFontSize.body, height: 1.6),
      ),
    );
  }
}

class _PreviewSheet extends StatelessWidget {
  const _PreviewSheet({required this.mail});

  final FeedbackMail mail;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: context.colors.muted)),
          const SizedBox(width: AppSpace.md),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
    return _Sheet(
      title: l.fbPreviewTitle,
      sub: l.fbPreviewSub,
      children: [
        row(l.fbTo, supportEmail),
        row(l.fbSubject, mail.subject),
        _MailText(mail.body),
        const SizedBox(height: AppSpace.lg),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.fbClose),
        ),
      ],
    );
  }
}

class _NoMailSheet extends StatefulWidget {
  const _NoMailSheet({required this.mail});

  final FeedbackMail mail;

  @override
  State<_NoMailSheet> createState() => _NoMailSheetState();
}

class _NoMailSheetState extends State<_NoMailSheet> {
  String? _copied;

  Future<void> _copy(String what, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) setState(() => _copied = what);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final mail = widget.mail;
    return _Sheet(
      title: l.fbNoMail,
      sub: l.fbNoMailSub,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                supportEmail,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => _copy('to', supportEmail),
              child: Text(_copied == 'to' ? l.fbCopied : l.fbCopyAddress),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        _MailText(mail.body),
        const SizedBox(height: AppSpace.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.fbClose),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: FilledButton(
                onPressed: () =>
                    _copy('text', '${mail.subject}\n\n${mail.body}'),
                child: Text(_copied == 'text' ? l.fbCopied : l.fbCopyText),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DiscardSheet extends StatelessWidget {
  const _DiscardSheet();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _Sheet(
      title: l.fbDiscardTitle,
      sub: l.fbDiscardBody,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.expense,
                ),
                child: Text(l.fbDiscard),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l.fbKeep),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
