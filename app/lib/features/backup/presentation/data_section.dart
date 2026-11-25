import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../data/backup_service.dart';
import '../data/excel_report.dart';
import '../data/google_drive_service.dart';
import '../data/import/money_manager_import.dart';
import '../domain/backup_period.dart';
import '../../../providers.dart';
import '../../../core/widgets/common.dart';
import '../../account/presentation/account_card.dart';
import '../../account/presentation/account_screen.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_sheet.dart';

/// Isi halaman Cadangan & pemulihan: Google Drive, lalu ekspor/impor file.
class DataSection extends ConsumerStatefulWidget {
  const DataSection({super.key});

  @override
  ConsumerState<DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends ConsumerState<DataSection> {
  BackupPeriod _selectedPeriod = const BackupPeriod.all();

  static String _stamp() {
    final now = DateTime.now();
    return '${toLocalDate(now)}-${hhmm(now).replaceAll(':', '')}';
  }

  Future<void> _share(
    BuildContext context,
    List<int> bytes,
    String name,
    String mime,
  ) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(Uint8List.fromList(bytes), mimeType: mime)],
        fileNameOverrides: [name],
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: DateTimeRange(
        start: _selectedPeriod.startDate ?? DateTime(now.year, 1, 1),
        end: _selectedPeriod.endDate ?? now,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedPeriod = BackupPeriod.custom(picked.start, picked.end);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final drive = ref.watch(googleDriveProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGoogleDriveCard(context, drive),
        const SizedBox(height: AppSpace.xl),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xs,
            0,
            AppSpace.xs,
            AppSpace.sm,
          ),
          child: Text(
            l.localDataTitle.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.muted,
            ),
          ),
        ),
        _buildLocalSection(context),
      ],
    );
  }

  // ══ 1. KARTU GOOGLE DRIVE CLOUD BACKUP ══
  Widget _buildGoogleDriveCard(BuildContext context, GoogleDriveInfo drive) {
    final l = context.l10n;
    final colors = context.colors;

    return ServiceCard(
      title: 'Google Drive',
      tag: drive.isConnected
          ? l.googleDriveConnected
          : l.googleDriveNotConnected,
      tagOk: drive.isConnected,
      status: driveStatus(context, l, drive).text,
      children: drive.isConnected
          ? [
              Text(
                l.backupRangeHint,
                style: TextStyle(
                  fontSize: AppFontSize.meta,
                  color: colors.muted,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.xs,
                children: [
                  for (final (label, selected, onTap) in [
                    (
                      l.rangeAll,
                      _selectedPeriod.type == BackupPeriodType.all,
                      () => setState(
                        () => _selectedPeriod = const BackupPeriod.all(),
                      ),
                    ),
                    (
                      l.rangeThisYear,
                      _selectedPeriod.type == BackupPeriodType.thisYear,
                      () => setState(
                        () => _selectedPeriod = BackupPeriod.thisYear(),
                      ),
                    ),
                    (
                      l.rangeThisMonth,
                      _selectedPeriod.type == BackupPeriodType.thisMonth,
                      () => setState(
                        () => _selectedPeriod = BackupPeriod.thisMonth(),
                      ),
                    ),
                    (
                      _selectedPeriod.type == BackupPeriodType.custom
                          ? _selectedPeriod.label(l)
                          : l.rangeCustom,
                      _selectedPeriod.type == BackupPeriodType.custom,
                      () {
                        _pickCustomDateRange();
                      },
                    ),
                  ])
                    _periodChip(
                      label: label,
                      isSelected: selected,
                      onTap: onTap,
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              FilledButton(
                onPressed: drive.isUploading
                    ? null
                    : () => _backupToGoogleDrive(context),
                child: Text(drive.isUploading ? l.backupNowLoading : l.backupNow),
              ),
              if (drive.lastFileUrl != null) ...[
                const SizedBox(height: AppSpace.sm),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(googleDriveProvider.notifier).openInSheets(),
                  child: Text(l.openInSheets),
                ),
              ],
              const SizedBox(height: AppSpace.sm),
              OutlinedButton(
                onPressed: () => _restoreFromGoogleDrive(context),
                child: Text(l.restoreFromDrive),
              ),
            ]
          : [
              FilledButton(
                onPressed: () => connectDrive(context, ref),
                child: Text(l.connect),
              ),
            ],
    );
  }

  Widget _periodChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: AppSpace.sm),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected ? colors.primary : colors.divider,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.caption,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : colors.ink,
          ),
        ),
      ),
    );
  }

  // ══ 2. PENYIMPANAN LOKAL (2 OPSI RINGKAS) ══
  Widget _buildLocalSection(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;

    Widget localTile({
      required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap,
    }) {
      return ListTile(
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: colors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: AppFontSize.bodyLg,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: AppFontSize.caption, color: colors.muted),
        ),
        trailing: Icon(Icons.chevron_right, color: colors.muted),
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Column(
        children: [
          localTile(
            title: l.localBackup,
            subtitle: l.localBackupSub,
            icon: Icons.upload_file_outlined,
            onTap: () => _openLocalExportModal(context),
          ),
          Divider(height: 1, indent: 56, color: colors.divider),
          localTile(
            title: l.localRestore,
            subtitle: l.localRestoreSub,
            icon: Icons.file_download_outlined,
            onTap: () => _smartRestore(context),
          ),
        ],
      ),
    );
  }

  // ══ LOGIKA PENCADANGAN GOOGLE DRIVE ══
  Future<void> _backupToGoogleDrive(BuildContext context) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final money = ref.read(moneySnapshotProvider).value;
    final entries = ref.read(journalEntriesProvider).value;

    if (money == null || entries == null) return;

    try {
      // Data pemulihan selalu lengkap: Pulihkan memakai cadangan terbaru.
      // Pilihan periode hanya membatasi isi tabelnya.
      final rawJson =
          await BackupService(ref.read(databaseProvider)).exportJson();
      final bytes = buildExcelReport(
        l: l,
        money: money,
        entries: entries,
        now: DateTime.now(),
        period: _selectedPeriod,
        rawBackupJson: rawJson,
      );

      final success = await ref
          .read(googleDriveProvider.notifier)
          .backupToDrive(
            bytes: bytes,
            fileName: 'Nyawtat_Cadangan_${_stamp()}.xlsx',
          );

      if (success && mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l.backupNowSuccess)));
      }
    } catch (e) {
      debugPrint('Backup to Drive error: $e');
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l.exportFailed)));
      }
    }
  }

  Future<void> _restoreFromGoogleDrive(BuildContext context) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final driveService = ref.read(googleDriveServiceProvider);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.restoreFromDrive),
        content: Text(l.restoreFromDriveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.importAction),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final latest = await driveService.getLatestBackup();
      if (latest == null || latest.id == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Tidak ada file cadangan di Google Drive.'),
          ),
        );
        return;
      }

      final bytes = await driveService.downloadFile(latest.id!);
      if (bytes == null) {
        messenger.showSnackBar(SnackBar(content: Text(l.importInvalid)));
        return;
      }

      final rawJson = extractRawBackupJsonFromExcel(bytes);
      if (rawJson != null) {
        final result = await BackupService(ref.read(databaseProvider))
            .importJson(rawJson);
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.importDone(result.imported, result.skipped)),
          ),
        );
      } else {
        messenger.showSnackBar(SnackBar(content: Text(l.importInvalid)));
      }
    } catch (e) {
      debugPrint('Restore from Drive error: $e');
      messenger.showSnackBar(SnackBar(content: Text(l.importInvalid)));
    }
  }

  // ══ MODAL EKSPOR LOKAL (EXCEL / JSON DENGAN RENTANG) ══
  void _openLocalExportModal(BuildContext context) {
    final l = context.l10n;
    var format = 'xlsx';
    var period = _selectedPeriod;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.lg, AppSpace.xl, AppSpace.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SheetHandle(),
                    const SizedBox(height: AppSpace.lg),
                    Text(
                      l.localBackup,
                      style: const TextStyle(
                        fontSize: AppFontSize.title,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      l.localBackupSub,
                      style: TextStyle(
                        fontSize: AppFontSize.meta,
                        color: context.colors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),

                    // Format Choice Cards
                    Text(
                      '1. Pilih Format File:',
                      style: TextStyle(
                        fontSize: AppFontSize.meta,
                        fontWeight: FontWeight.w700,
                        color: context.colors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    InkWell(
                      onTap: () => setModalState(() => format = 'xlsx'),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpace.md),
                        decoration: BoxDecoration(
                          color: format == 'xlsx'
                              ? context.colors.primary.withValues(alpha: 0.08)
                              : context.colors.surface,
                          border: Border.all(
                            color: format == 'xlsx'
                                ? context.colors.primary
                                : context.colors.divider,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              format == 'xlsx'
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: format == 'xlsx'
                                  ? context.colors.primary
                                  : context.colors.muted,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpace.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.formatExcel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: AppFontSize.body,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpace.xxs),
                                  Text(
                                    l.formatExcelDesc,
                                    style: TextStyle(
                                      fontSize: AppFontSize.caption,
                                      color: context.colors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    InkWell(
                      onTap: () => setModalState(() => format = 'json'),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpace.md),
                        decoration: BoxDecoration(
                          color: format == 'json'
                              ? context.colors.primary.withValues(alpha: 0.08)
                              : context.colors.surface,
                          border: Border.all(
                            color: format == 'json'
                                ? context.colors.primary
                                : context.colors.divider,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              format == 'json'
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: format == 'json'
                                  ? context.colors.primary
                                  : context.colors.muted,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpace.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.formatJson,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: AppFontSize.body,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpace.xxs),
                                  Text(
                                    l.formatJsonDesc,
                                    style: TextStyle(
                                      fontSize: AppFontSize.caption,
                                      color: context.colors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),

                    // Periode Choice
                    Text(
                      '2. Pilih Rentang Data:',
                      style: TextStyle(
                        fontSize: AppFontSize.meta,
                        fontWeight: FontWeight.w700,
                        color: context.colors.ink,
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _periodChip(
                          label: l.rangeAll,
                          isSelected: period.type == BackupPeriodType.all,
                          onTap: () => setModalState(
                            () => period = const BackupPeriod.all(),
                          ),
                        ),
                        _periodChip(
                          label: '${l.rangeThisYear} (${DateTime.now().year})',
                          isSelected: period.type == BackupPeriodType.thisYear,
                          onTap: () => setModalState(
                            () => period = BackupPeriod.thisYear(),
                          ),
                        ),
                        _periodChip(
                          label: l.rangeThisMonth,
                          isSelected: period.type == BackupPeriodType.thisMonth,
                          onTap: () => setModalState(
                            () => period = BackupPeriod.thisMonth(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xl),

                    FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _runLocalExport(format, period);
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(l.exportAction),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _runLocalExport(String format, BackupPeriod period) async {
    final l = context.l10n;
    if (format == 'xlsx') {
      final money = ref.read(moneySnapshotProvider).value;
      final entries = ref.read(journalEntriesProvider).value;
      if (money == null || entries == null) return;
      final rawJson = await BackupService(ref.read(databaseProvider))
          .exportJson(period: period);
      final bytes = buildExcelReport(
        l: l,
        money: money,
        entries: entries,
        now: DateTime.now(),
        period: period,
        rawBackupJson: rawJson,
      );
      if (mounted) {
        await _share(
          context,
          bytes,
          'nyawtat-${_stamp()}.xlsx',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      }
    } else {
      final json = await BackupService(ref.read(databaseProvider))
          .exportJson(period: period);
      if (mounted) {
        await _share(
          context,
          utf8.encode(json),
          'nyawtat-backup-${_stamp()}.json',
          'application/json',
        );
      }
    }
  }

  // ══ PEMULIHAN PINTAR AUTO-DETECT (JSON / MONEY MANAGER) ══
  Future<void> _smartRestore(BuildContext context) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    final file = await FilePicker.pickFile(type: FileType.any);
    if (file == null || !context.mounted) return;

    final name = file.name.toLowerCase();
    final bytes = await file.readAsBytes();
    if (!context.mounted) return;

    // 1. Cek apakah ini file Excel Nyawtat yang menyimpan raw JSON
    if (name.endsWith('.xlsx')) {
      final rawJson = extractRawBackupJsonFromExcel(bytes);
      if (rawJson != null) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.importConfirm(file.name)),
            content: Text(l.importConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.importAction),
              ),
            ],
          ),
        );
        if (ok != true || !context.mounted) return;

        try {
          final result = await BackupService(ref.read(databaseProvider))
              .importJson(rawJson);
          messenger.showSnackBar(
            SnackBar(
              content: Text(l.importDone(result.imported, result.skipped)),
            ),
          );
          return;
        } catch (_) {}
      }
    }

    // 2. Cek apakah ini file JSON backup Nyawtat
    if (name.endsWith('.json')) {
      if (!context.mounted) return;
      try {
        final content = utf8.decode(bytes);
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.importConfirm(file.name)),
            content: Text(l.importConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.importAction),
              ),
            ],
          ),
        );
        if (ok != true || !context.mounted) return;

        final result = await BackupService(ref.read(databaseProvider))
            .importJson(content);
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.importDone(result.imported, result.skipped)),
          ),
        );
        return;
      } on BackupFormatException {
        messenger.showSnackBar(SnackBar(content: Text(l.importInvalid)));
        return;
      } catch (_) {}
    }

    // 3. Cek apakah ini file Money Manager (.mmbak / .sqlite / .db / .xlsx)
    if (name.endsWith('.mmbak') ||
        name.endsWith('.sqlite') ||
        name.endsWith('.db') ||
        name.endsWith('.xlsx') ||
        name.endsWith('.xls')) {
      if (!context.mounted) return;
      final navigator = Navigator.of(context);
      final importer = MoneyManagerImporter(ref.read(databaseProvider));

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          content: Row(
            children: [
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: AppSpace.lg),
              Text(l.importMmReading),
            ],
          ),
        ),
      );

      MmImportPlan? plan;
      try {
        final data = await readMoneyManagerFile(file.name, bytes);
        plan = await importer.plan(data);
      } catch (e) {
        debugPrint('Impor MM error: $e');
      } finally {
        navigator.pop();
      }

      if (plan == null) {
        messenger.showSnackBar(SnackBar(content: Text(l.importMmInvalid)));
        return;
      }
      if (plan.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(l.importMmNothing)));
        return;
      }
      if (!context.mounted) return;

      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => _MmPreviewDialog(plan: plan!),
      );
      if (ok != true) return;
      final result = await importer.apply(plan);
      messenger.showSnackBar(
        SnackBar(content: Text(l.importMmDone(result.transactions))),
      );
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(l.unsupportedFileFormat)));
  }
}

/// Ringkasan sebelum impor Money Manager: jumlah, periode, dompet, dan kategori baru.
class _MmPreviewDialog extends StatelessWidget {
  const _MmPreviewDialog({required this.plan});

  final MmImportPlan plan;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final muted = t.bodySmall?.copyWith(color: context.colors.muted);
    final date = DateFormat('d MMM y', context.localeTag);

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: AppSpace.lg, bottom: AppSpace.xs),
      child: Text(
        text,
        style: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );

    return AlertDialog(
      title: Text(l.importMm),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.importMmNew(plan.newTransactions),
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              l.importMmBreakdown(
                plan.countOf(MmKind.expense),
                plan.countOf(MmKind.income),
                plan.countOf(MmKind.transfer),
              ),
              style: muted,
            ),
            if (plan.first != null)
              Text(
                l.importMmPeriod(
                  date.format(plan.first!),
                  date.format(plan.last!),
                ),
                style: muted,
              ),
            const SizedBox(height: AppSpace.sm),
            if (plan.alreadyImported > 0)
              Text(l.importMmAlready(plan.alreadyImported), style: muted),
            if (plan.skipped > 0)
              Text(l.importMmSkipped(plan.skipped), style: muted),
            if (plan.adjustmentRows > 0)
              Text(l.importMmAdjust(plan.adjustmentRows), style: muted),
            if (plan.movedTransactions > 0)
              Text(l.importMmMoved(plan.movedTransactions), style: muted),
            heading(l.importMmWallets),
            for (final w in plan.wallets)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.xxs),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: w.sourceName),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: context.colors.muted,
                          ),
                        ),
                      ),
                      TextSpan(
                        text: w.existing ? w.name : l.importMmNewWallet,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: w.existing
                              ? context.colors.ink
                              : context.colors.primary,
                        ),
                      ),
                      if (w.archive)
                        TextSpan(
                          text: ' · ${l.importMmArchived}',
                          style: TextStyle(color: context.colors.muted),
                        ),
                    ],
                  ),
                  style: t.bodyMedium,
                ),
              ),
            if (plan.newCategories.isNotEmpty) ...[
              heading(l.importMmNewCategories(plan.newCategories.length)),
              Text(
                plan.newCategories.map((c) => c.name).join(', '),
                style: t.bodyMedium,
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            Text(
              l.importMmOverlap,
              style: muted?.copyWith(color: context.colors.warning),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.importAction),
        ),
      ],
    );
  }
}
