import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/journal_repository.dart';
import '../../ui/common.dart';
import '../../ui/mood.dart';
import 'voice/voice_player_card.dart';

String _titleOf(BuildContext context, JournalEntry e) =>
    e.title ?? context.l10n.untitled;

/// Baris entri di timeline Hari Ini: jam, ikon buku, judul, mood · cerita.
class EntryTimelineRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final hasAudio = entry.audioPath != null && entry.audioPath!.isNotEmpty;
    final sub = [
      if (entry.mood != null) moodLabel(context.l10n, entry.mood!),
      if (hasAudio) '🎙️ ${context.l10n.voiceNote}',
      ?entry.body,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: context.colors.divider))
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 46,
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
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                hasAudio ? Icons.mic_rounded : Icons.menu_book_outlined,
                size: 18,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleOf(context, entry),
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

/// Baris entri di daftar Jurnal: jam, judul, 2 baris cerita, mood dan tag.
class EntryListRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tags = entryTags(entry);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: context.colors.divider))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 46,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
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
                    _titleOf(context, entry),
                    style: t.titleSmall?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (entry.body != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.body!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium?.copyWith(
                        color: context.colors.muted,
                      ),
                    ),
                  ],
                  if (entry.audioPath != null &&
                      entry.audioPath!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    VoicePlayerCard(
                      audioPath: entry.audioPath!,
                      durationMs: entry.audioDurationMs,
                      compact: true,
                    ),
                  ],
                  if (entry.audioPath != null ||
                      entry.mood != null ||
                      tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (entry.audioPath != null &&
                            entry.audioPath!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.primarySoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.mic_rounded,
                                  size: 12,
                                  color: context.colors.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  context.l10n.voiceNote,
                                  style: TextStyle(
                                    fontSize: 11,
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
                              const SizedBox(width: 4),
                              Text(
                                moodLabel(context.l10n, entry.mood!),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.primary,
                                ),
                              ),
                            ],
                          ),
                        for (final tag in tags)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.isDark
                                  ? context.colors.primarySoft
                                  : const Color(0xFFEEF5F1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 12,
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
