import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers.dart';
import '../../../core/widgets/common.dart';
import 'custom_accent_sheet.dart';
import '../../../core/tokens.dart';

/// Pengaturan › Tampilan: Sistem / Terang / Gelap (dengan gambar mini layar)
/// dan pilihan warna aksen.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final accentId = ref.watch(accentIdProvider).value ?? AccentPresets.sage.id;
    final recent = ref.watch(accentRecentProvider).value ?? const <String>[];
    final customSelected = AccentPresets.isHex(accentId);
    // Warna tombol Kustom: yang sedang dipakai, atau kustom terakhir.
    final customHex = customSelected
        ? AccentPresets.normalizeHex(accentId)
        : (recent.isEmpty ? null : recent.first);
    final hint = switch (mode) {
      ThemeMode.system => l.themeSystemHint,
      ThemeMode.light => l.themeLightHint,
      ThemeMode.dark => l.themeDarkHint,
    };

    void pick(ThemeMode m) =>
        ref.read(settingsRepositoryProvider).set('theme_mode', m.name);

    Future<void> pickCustom() async {
      final settings = ref.read(settingsRepositoryProvider);
      final hex = await CustomAccentSheet.open(
        context,
        initial: AccentPresets.resolve(customHex ?? accentId),
        recent: recent,
      );
      if (hex == null) return;
      await settings.set('accent_color', hex);
      await settings.set(
        'accent_recent',
        AccentPresets.addRecent(recent, hex).join(','),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Row(
            children: [
              for (final (m, label) in [
                (ThemeMode.system, l.themeSystem),
                (ThemeMode.light, l.themeLight),
                (ThemeMode.dark, l.themeDark),
              ]) ...[
                if (m != ThemeMode.system) const SizedBox(width: AppSpace.md),
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
          padding: const EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.sm, AppSpace.xs, 0),
          child: Text(
            hint,
            style: TextStyle(fontSize: AppFontSize.body, color: context.colors.muted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.xl, AppSpace.xs, AppSpace.sm),
          child: Text(
            l.accentTitle,
            style: TextStyle(
              fontSize: AppFontSize.body,
              fontWeight: FontWeight.w600,
              color: context.colors.muted,
            ),
          ),
        ),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.lg),
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
              SizedBox(
                width: 88,
                child: _AccentOption(
                  label: l.accentCustom,
                  semanticLabel: l.accentCustomA11y,
                  color: customHex == null ? null : hexColor(customHex),
                  icon: customHex == null
                      ? Icons.add
                      : (customSelected ? null : Icons.edit_outlined),
                  selected: customSelected,
                  onTap: pickCustom,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.sm, AppSpace.xs, 0),
          child: Text(
            customSelected ? l.accentCustomHint(customHex!) : l.accentHint,
            style: TextStyle(fontSize: AppFontSize.body, color: context.colors.muted),
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

/// Gradasi pelangi tombol Kustom sebelum ada warna kustom.
const _rainbow = SweepGradient(
  colors: [
    Color(0xFFE5484D),
    Color(0xFFF5A524),
    Color(0xFF46A758),
    Color(0xFF0EA5E9),
    Color(0xFF6E56CF),
    Color(0xFFE5484D),
  ],
);

/// Satu warna aksen: lingkaran warna dengan centang saat terpilih, plus
/// namanya. Mirip _ModeOption, tapi tanpa gambar mini. [color] null =
/// lingkaran pelangi (tombol Kustom yang belum punya warna); [icon]
/// tampil saat tidak terpilih.
class _AccentOption extends StatelessWidget {
  const _AccentOption({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.icon,
    this.semanticLabel,
  });

  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = this.color;
    final fg = color == null ? Colors.white : readableOn(color);
    final mark = selected ? Icons.check : icon;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xxs),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(AppSpace.xxs),
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
                    gradient: color == null ? _rainbow : null,
                  ),
                  child: mark == null ? null : Icon(mark, size: 18, color: fg),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              FitText(
                label,
                alignment: Alignment.center,
                style: TextStyle(
                  fontSize: AppFontSize.meta,
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
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: selected ? c.primary : c.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.md, AppSpace.sm, AppSpace.sm),
            child: Column(
              children: [
                _MiniScreen(mode: mode),
                const SizedBox(height: AppSpace.sm),
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
                    const SizedBox(width: AppSpace.xs),
                    Flexible(
                      child: FitText(
                        label,
                        style: const TextStyle(
                          fontSize: AppFontSize.body,
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
          padding: EdgeInsets.only(left: left ? AppSpace.sm : 0, top: AppSpace.sm),
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
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: AppSpace.xs),
              for (final h in [16.0, 24.0]) ...[
                Container(
                  height: h,
                  margin: EdgeInsets.only(right: split && left ? 0 : AppSpace.sm),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: split
                        ? (left
                              ? const BorderRadius.horizontal(
                                  left: Radius.circular(AppRadius.xs),
                                )
                              : const BorderRadius.horizontal(
                                  right: Radius.circular(AppRadius.xs),
                                ))
                        : BorderRadius.circular(AppRadius.xs),
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
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
        borderRadius: BorderRadius.circular(AppRadius.md),
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
