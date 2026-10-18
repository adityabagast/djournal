import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/backup_service.dart';
import '../../data/excel_report.dart';
import '../../data/google_drive_service.dart';
import '../../data/import/money_manager_import.dart';
import '../../domain/models/backup_period.dart';
import '../../providers.dart';
import '../../ui/common.dart';
import '../money/budget_screen.dart';
import '../money/categories_screen.dart';

/// Bagian "Data" di Pengaturan yang disederhanakan:
/// 1. Cadangan Google Drive (Cloud otomatis & Excel viewable di Sheets)
/// 2. Penyimpanan Lokal (2 menu ringkas: Cadangkan Data & Pulihkan Data)
/// 3. Pengaturan Master (Budget & Kategori)
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
        const SizedBox(height: 18),
        _buildSectionHeader(
          title: l.localDataTitle.toUpperCase(),
          tag: '2 Opsi Ringkas',
        ),
        _buildLocalSection(context),
        const SizedBox(height: 18),
        _buildSectionHeader(title: 'PENGATURAN KEUANGAN'),
        _buildFinanceSection(context),
      ],
    );
  }

  Widget _buildSectionHeader({required String title, String? tag}) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: t.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.muted,
              fontSize: 12.5,
              letterSpacing: 0.5,
            ),
          ),
          if (tag != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: context.colors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ══ 1. KARTU GOOGLE DRIVE CLOUD BACKUP ══
  Widget _buildGoogleDriveCard(BuildContext context, GoogleDriveInfo drive) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final colors = context.colors;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Baris Utama
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.cloud_sync_outlined,
                    color: colors.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.googleDriveBackup,
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      l.googleDriveBackupSub,
                      style: TextStyle(fontSize: 11.5, color: colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Status Akun Google Terhubung
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.divider),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colors.primary,
                  child: Text(
                    (drive.displayName?.isNotEmpty ?? false)
                        ? drive.displayName![0].toUpperCase()
                        : (drive.email?.isNotEmpty ?? false)
                            ? drive.email![0].toUpperCase()
                            : 'G',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drive.displayName ??
                            drive.email ??
                            l.googleDriveNotConnected,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (drive.email != null && drive.displayName != null)
                        Text(
                          drive.email!,
                          style: TextStyle(fontSize: 11, color: colors.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (drive.isConnected)
                  TextButton(
                    onPressed: () =>
                        ref.read(googleDriveProvider.notifier).signOut(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      l.googleDriveDisconnect,
                      style: TextStyle(fontSize: 11, color: colors.muted),
                    ),
                  )
                else
                  FilledButton.tonal(
                    onPressed: () async {
                      try {
                        await ref.read(googleDriveProvider.notifier).signIn();
                      } catch (e) {
                        if (context.mounted) {
                          final msg = e.toString().contains('10')
                              ? 'Gagal masuk (Kode 10: DEVELOPER_ERROR). SHA-1 aplikasi belum didaftarkan di Firebase Console.'
                              : e.toString();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
                          );
                        }
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      l.googleDriveConnect,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Format Preview Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.divider),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('📊 ', style: TextStyle(fontSize: 14)),
                        Text(
                          l.googleDriveFormatInfo,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (drive.lastFileUrl != null)
                      GestureDetector(
                        onTap: () => ref
                            .read(googleDriveProvider.notifier)
                            .openInSheets(),
                        child: Text(
                          '${l.openInSheets} ›',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l.googleDriveFormatDesc,
                  style: TextStyle(fontSize: 11.5, color: colors.muted),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _sheetBadge('📑 Transaksi', colors),
                    _sheetBadge('📖 Jurnal', colors),
                    _sheetBadge('💵 Dompet', colors),
                    _sheetBadge('🎯 Budget', colors),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Pilihan Rentang Waktu Pencadangan
          Text(
            l.backupRange,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _periodChip(
                label: l.rangeAll,
                isSelected: _selectedPeriod.type == BackupPeriodType.all,
                onTap: () =>
                    setState(() => _selectedPeriod = const BackupPeriod.all()),
              ),
              _periodChip(
                label: '${l.rangeThisYear} (${DateTime.now().year})',
                isSelected: _selectedPeriod.type == BackupPeriodType.thisYear,
                onTap: () =>
                    setState(() => _selectedPeriod = BackupPeriod.thisYear()),
              ),
              _periodChip(
                label: l.rangeThisMonth,
                isSelected: _selectedPeriod.type == BackupPeriodType.thisMonth,
                onTap: () =>
                    setState(() => _selectedPeriod = BackupPeriod.thisMonth()),
              ),
              _periodChip(
                label: _selectedPeriod.type == BackupPeriodType.custom
                    ? _selectedPeriod.label(l)
                    : '${l.rangeCustom}...',
                isSelected: _selectedPeriod.type == BackupPeriodType.custom,
                onTap: _pickCustomDateRange,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sakelar Cadangkan Otomatis
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.autoBackupWifi,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    l.autoBackupWifiSub,
                    style: TextStyle(fontSize: 11, color: colors.muted),
                  ),
                ],
              ),
              Switch(
                value: drive.autoBackup,
                onChanged: (_) => ref
                    .read(googleDriveProvider.notifier)
                    .toggleAutoBackup(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tombol Cadangkan Sekarang & Pulihkan
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: drive.isUploading
                      ? null
                      : () => _backupToGoogleDrive(context),
                  icon: drive.isUploading
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: Text(
                    drive.isUploading ? l.backupNowLoading : l.backupNow,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (drive.lastFileUrl != null) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(googleDriveProvider.notifier).openInSheets(),
                  icon: const Icon(Icons.table_chart_outlined, size: 18),
                  label: Text(l.openInSheets),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: () => _restoreFromGoogleDrive(context),
              icon: const Icon(Icons.restore_outlined, size: 16),
              label: Text(
                l.restoreFromDrive,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetBadge(String title, dynamic colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF137333),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.primary : colors.divider,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
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
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: colors.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11.5, color: colors.muted),
        ),
        trailing: Icon(Icons.chevron_right, color: colors.muted),
      );
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  // ══ 3. PENGATURAN KEUANGAN MASTER ══
  Widget _buildFinanceSection(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;

    Widget tile(String title, String sub, IconData icon, VoidCallback onTap) =>
        ListTile(
          onTap: onTap,
          leading: Icon(icon, color: colors.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(
            sub,
            style: TextStyle(fontSize: 12, color: colors.muted),
          ),
          trailing: Icon(Icons.chevron_right, color: colors.muted),
        );

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          tile(
            l.budget,
            l.budgetSubtitle,
            Icons.pie_chart_outline,
            () => BudgetScreen.open(context),
          ),
          Divider(height: 1, indent: 56, color: colors.divider),
          tile(
            l.manageCategories,
            l.categoriesSub,
            Icons.category_outlined,
            () => CategoriesScreen.open(context),
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
      final rawJson = await BackupService(ref.read(databaseProvider))
          .exportJson(period: _selectedPeriod);
      final bytes = buildExcelReport(
        l: l,
        money: money,
        entries: entries,
        now: DateTime.now(),
        period: _selectedPeriod,
        rawBackupJson: rawJson,
      );

      final success =
          await ref.read(googleDriveProvider.notifier).backupToDrive(
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
          const SnackBar(content: Text('Tidak ada file cadangan di Google Drive.')),
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
          SnackBar(content: Text(l.importDone(result.imported, result.skipped))),
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.colors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l.localBackup,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.localBackupSub,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.muted,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Format Choice Cards
                    Text(
                      '1. Pilih Format File:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.colors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => setModalState(() => format = 'xlsx'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
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
                          borderRadius: BorderRadius.circular(12),
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
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.formatExcel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l.formatExcelDesc,
                                    style: TextStyle(
                                      fontSize: 11,
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
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => setModalState(() => format = 'json'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
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
                          borderRadius: BorderRadius.circular(12),
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
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.formatJson,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l.formatJsonDesc,
                                    style: TextStyle(
                                      fontSize: 11,
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
                    const SizedBox(height: 12),

                    // Periode Choice
                    Text(
                      '2. Pilih Rentang Data:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.colors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 20),

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
          SnackBar(content: Text(l.importDone(result.imported, result.skipped))),
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
              const SizedBox(width: 16),
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
      padding: const EdgeInsets.only(top: 16, bottom: 4),
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
            const SizedBox(height: 8),
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
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: w.sourceName),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
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
            const SizedBox(height: 16),
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
