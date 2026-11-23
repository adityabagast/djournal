import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../core/database/app_database.dart';
import '../data/journal_repository.dart';
import '../../../providers.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/image_viewer.dart';
import 'mood.dart';
import 'voice/voice_player_card.dart';
import '../../../core/tokens.dart';
import '../domain/entry_headline.dart';

/// Judul + cuplikan tampilan entri (judul kosong → kalimat pertama isi).
EntryHeadline headlineOf(JournalEntry e) =>
    entryHeadline(title: e.title, body: e.body);

/// Judul yang tampil: judul/isi, atau "Catatan suara" / "Tanpa judul".
String headlineTitle(BuildContext context, JournalEntry e, EntryHeadline h) =>
    h.title ??
    (e.audioPath?.isNotEmpty == true
        ? context.l10n.voiceNote
        : context.l10n.untitled);

/// Baris entri di timeline Hari Ini: jam, ikon buku, judul, mood · cerita.
class EntryTimelineRow extends ConsumerWidget {
  const EntryTimelineRow({
    super.key,
    required this.entry,
    required this.onTap,
    this.showDivider = true,
  });

  final JournalEntry entry;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final hasAudio = entry.audioPath != null && entry.audioPath!.isNotEmpty;
    final attachments =
        ref.watch(entryAttachmentsMapProvider)[entry.id] ?? const [];
    final headline = headlineOf(entry);
    final sub = [
      if (entry.mood != null) moodLabel(context.l10n, entry.mood!),
      // Judul sudah "Catatan suara" kalau entri hanya berisi rekaman.
      if (hasAudio && headline.title != null) '🎙️ ${context.l10n.voiceNote}',
      if (attachments.isNotEmpty) '📷 ${attachments.length} foto',
      ?headline.preview,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: context.colors.divider))
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: MediaQuery.textScalerOf(context).scale(40),
              // Label jam hanya tampil kalau user mengisinya.
              child: Text(
                entry.entryTime ?? '',
                style: t.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.muted,
                ),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                hasAudio ? Icons.mic_rounded : Icons.menu_book_outlined,
                size: 18,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headlineTitle(context, entry, headline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (sub.isNotEmpty)
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(color: context.colors.muted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Baris entri di daftar Jurnal: jam, judul, 2 baris cerita, mood, tag, dan foto.
class EntryListRow extends ConsumerWidget {
  const EntryListRow({
    super.key,
    required this.entry,
    required this.onTap,
    this.showDivider = true,
  });

  final JournalEntry entry;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final tags = entryTags(entry);
    final headline = headlineOf(entry);
    final attachments =
        ref.watch(entryAttachmentsMapProvider)[entry.id] ?? const [];
    final imagePaths = attachments
        .map((a) => a.localPath)
        .whereType<String>()
        .toList();

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: context.colors.divider))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: MediaQuery.textScalerOf(context).scale(40),
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpace.xxs),
                child: Text(
                  entry.entryTime ?? '',
                  style: t.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.muted,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headlineTitle(context, entry, headline),
                    style: t.titleSmall?.copyWith(
                      fontSize: AppFontSize.title,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (headline.preview != null) ...[
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      headline.preview!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium?.copyWith(
                        color: context.colors.muted,
                      ),
                    ),
                  ],
                  if (imagePaths.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.sm),
                    SizedBox(
                      height: 58,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: imagePaths.length,
                        separatorBuilder: (_, index) => const SizedBox(width: AppSpace.sm),
                        itemBuilder: (context, i) {
                          final f = File(imagePaths[i]);
                          return GestureDetector(
                            onTap: () => openImageViewer(
                              context,
                              paths: imagePaths,
                              initialIndex: i,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: SizedBox(
                                width: 58,
                                height: 58,
                                child: f.existsSync()
                                    ? Image.file(
                                        f,
                                        fit: BoxFit.cover,
                                        cacheWidth: 150,
                                        errorBuilder: (_, err, stack) =>
                                            Container(
                                          color: context.colors.subtle,
                                          child: Icon(
                                            Icons.broken_image_rounded,
                                            size: 20,
                                            color: context.colors.muted,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: context.colors.subtle,
                                        child: Icon(
                                          Icons.broken_image_rounded,
                                          size: 20,
                                          color: context.colors.muted,
                                        ),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (entry.audioPath != null &&
                      entry.audioPath!.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.sm),
                    VoicePlayerCard(
                      audioPath: entry.audioPath!,
                      durationMs: entry.audioDurationMs,
                      compact: true,
                    ),
                  ],
                  if (entry.audioPath != null ||
                      entry.mood != null ||
                      tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (entry.audioPath != null &&
                            entry.audioPath!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.sm,
                              vertical: AppSpace.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.primarySoft,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.mic_rounded,
                                  size: 12,
                                  color: context.colors.primary,
                                ),
                                const SizedBox(width: AppSpace.xxs),
                                Text(
                                  context.l10n.voiceNote,
                                  style: TextStyle(
                                    fontSize: AppFontSize.caption,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (entry.mood != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MoodFace(
                                mood: entry.mood!,
                                color: context.colors.primary,
                                size: 16,
                                strokeWidth: 1.8,
                              ),
                              const SizedBox(width: AppSpace.xs),
                              Text(
                                moodLabel(context.l10n, entry.mood!),
                                style: TextStyle(
                                  fontSize: AppFontSize.meta,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.primary,
                                ),
                              ),
                            ],
                          ),
                        for (final tag in tags)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.sm,
                              vertical: AppSpace.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.isDark
                                  ? context.colors.primarySoft
                                  : const Color(0xFFEEF5F1),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: AppFontSize.meta,
                                fontWeight: FontWeight.w600,
                                color: context.colors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
