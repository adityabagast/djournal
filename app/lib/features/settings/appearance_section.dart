import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers.dart';
import '../../ui/common.dart';

/// Pengaturan › Tampilan: Sistem / Terang / Gelap, masing-masing dengan
/// gambar mini layar (desain "Mode gelap" di canvas).
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final mode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
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
      ],
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
