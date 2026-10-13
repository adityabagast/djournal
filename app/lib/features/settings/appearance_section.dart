import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/common.dart';

/// Pengaturan › Tampilan: Sistem / Terang / Gelap (dengan gambar mini layar)
/// dan pilihan warna aksen.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final accentId =
        ref.watch(accentIdProvider).value ?? AccentPresets.sage.id;
    final hint = switch (mode) {
      ThemeMode.system => l.themeSystemHint,
      ThemeMode.light => l.themeLightHint,
      ThemeMode.dark => l.themeDarkHint,
    };

    void pick(ThemeMode m) =>
        ref.read(settingsRepositoryProvider).set('theme_mode', m.name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              for (final (m, label) in [
                (ThemeMode.system, l.themeSystem),
                (ThemeMode.light, l.themeLight),
                (ThemeMode.dark, l.themeDark),
              ]) ...[
                if (m != ThemeMode.system) const SizedBox(width: 10),
                Expanded(
                  child: _ModeOption(
                    mode: m,
                    label: label,
                    selected: mode == m,
                    onTap: () => pick(m),
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(
            hint,
            style: TextStyle(fontSize: 13, color: context.colors.muted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Text(
            l.accentTitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colors.muted,
            ),
          ),
        ),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 8,
            runSpacing: 12,
            children: [
              for (final o in AccentPresets.all)
                SizedBox(
                  width: 88,
                  child: _AccentOption(
                    label: _accentName(l, o.id),
                    color: o.color,
                    selected: accentId == o.id,
                    onTap: () => ref
                        .read(settingsRepositoryProvider)
                        .set('accent_color', o.id),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Text(
            l.accentHint,
            style: TextStyle(fontSize: 13, color: context.colors.muted),
          ),
        ),
      ],
    );
  }
}

String _accentName(AppLocalizations l, String id) => switch (id) {
  'sage' => l.accentSage,
  'ocean' => l.accentOcean,
  'violet' => l.accentViolet,
  'rose' => l.accentRose,
  'pink' => l.accentPink,
  'amber' => l.accentAmber,
  'teal' => l.accentTeal,
  _ => id,
};

/// Satu warna aksen: lingkaran warna dengan centang saat terpilih, plus
/// namanya. Mirip _ModeOption, tapi tanpa gambar mini.
class _AccentOption extends StatelessWidget {
  const _AccentOption({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? c.primary : c.line,
                    width: 2,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                  child: selected
                      ? Icon(Icons.check, size: 18, color: readableOn(color))
                      : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? c.primarySoft : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? c.primary : c.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
            child: Column(
              children: [
                _MiniScreen(mode: mode),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? c.primary : c.muted,
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gambar mini layar: terang, gelap, atau separuh-separuh untuk "Sistem".
class _MiniScreen extends StatelessWidget {
  const _MiniScreen({required this.mode});

  final ThemeMode mode;

  Widget _half(AppPalette p, {required bool left, required bool split}) {
    return Expanded(
      child: ColoredBox(
        color: p.background,
        child: Padding(
          padding: EdgeInsets.only(left: left ? 7 : 0, top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 5,
                child: left
                    ? Container(
                        width: 22,
                        decoration: BoxDecoration(
                          color: p.ink,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 5),
              for (final h in [16.0, 24.0]) ...[
                Container(
                  height: h,
                  margin: EdgeInsets.only(right: split && left ? 0 : 7),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: split
                        ? (left
                              ? const BorderRadius.horizontal(
                                  left: Radius.circular(5),
                                )
                              : const BorderRadius.horizontal(
                                  right: Radius.circular(5),
                                ))
                        : BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final split = mode == ThemeMode.system;
    final first = mode == ThemeMode.dark ? AppPalette.dark : AppPalette.light;
    return Container(
      width: 64,
      height: 92,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.line),
      ),
      child: Row(
        children: [
          _half(first, left: true, split: split),
          if (split) _half(AppPalette.dark, left: false, split: true),
        ],
      ),
    );
  }
}
