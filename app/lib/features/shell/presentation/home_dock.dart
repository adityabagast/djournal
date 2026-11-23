import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../core/tokens.dart';

/// Navigasi mengapung di bawah (HP): 4 tab dengan tombol tambah di tengah.
///
/// Lebar tiap tab mengikuti panjang tulisannya dan lebar layar. Kalau tidak
/// cukup (HP kecil atau font sistem besar), semua tulisan mengecil bersama
/// supaya tidak pernah keluar dari latar aksennya.
class HomeDock extends StatelessWidget {
  const HomeDock({
    super.key,
    required this.index,
    required this.onSelect,
    required this.onAdd,
    required this.items,
    required this.addLabel,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final List<(IconData, String)> items;
  final String addLabel;

  static const height = 72.0;

  /// Jarak dock dari tepi bawah layar (di atas navigasi sistem).
  static const bottomMargin = AppSpace.lg;

  /// Jarak dock dari tepi kiri/kanan: lebih tipis di HP sempit.
  static double sideMargin(double screenWidth) =>
      screenWidth < 380 ? AppSpace.md : AppSpace.lg;

  /// Jarak tulisan ke tepi latar tab, cukup untuk lengkung sudutnya.
  static const _tabPadding = 6.0;
  static const _maxTextScale = 1.2;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: c.isDark ? 0.45 : 0.16),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: c.shadow.withValues(alpha: c.isDark ? 0.2 : 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
            decoration: BoxDecoration(
              color: c.isDark
                  ? const Color(0xFF1E2421).withValues(alpha: 0.88)
                  : Colors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: LayoutBuilder(
              builder: (context, box) => _row(context, box.maxWidth),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, double width) {
    final c = context.colors;
    final fab = width < 300 ? 50.0 : 54.0;
    final half = (width - fab - 2 * AppSpace.xs) / 2;

    // Ukur tulisan dengan ukuran font sistem, dibatasi supaya tetap muat
    // tingginya.
    final scaled = math.min(
      MediaQuery.textScalerOf(context).scale(AppFontSize.caption),
      AppFontSize.caption * _maxTextScale,
    );
    final base = DefaultTextStyle.of(context).style.merge(
      const TextStyle(fontWeight: FontWeight.w600, height: 1.3),
    );
    double measure(String label) {
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: base.copyWith(fontSize: scaled),
        ),
        textDirection: Directionality.of(context),
        maxLines: 1,
      )..layout();
      final w = painter.width;
      painter.dispose();
      return w;
    }

    final widths = [for (final (_, label) in items) measure(label)];
    // Satu faktor untuk semua tulisan supaya ukurannya tetap seragam.
    var factor = 1.0;
    for (final side in [0, 2]) {
      final need = widths[side] + widths[side + 1];
      factor = math.min(factor, (half - 4 * _tabPadding) / need);
    }

    Widget tab(int i) {
      // Sisa ruang dibagi rata antara dua tab di sisi yang sama.
      final other = i.isEven ? i + 1 : i - 1;
      final spare =
          half - (widths[i] + widths[other]) * factor - 4 * _tabPadding;
      return SizedBox(
        width: math.max(0, widths[i] * factor + 2 * _tabPadding + spare / 2),
        child: _DockTab(
          icon: items[i].$1,
          label: items[i].$2,
          labelStyle: base.copyWith(fontSize: scaled * factor),
          selected: index == i,
          onTap: () => onSelect(i),
        ),
      );
    }

    return Row(
      children: [
        tab(0),
        tab(1),
        const SizedBox(width: AppSpace.xs),
        Tooltip(
          message: addLabel,
          child: Material(
            color: c.primary,
            elevation: 6,
            shadowColor: c.isDark
                ? Colors.black
                : c.primary.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: SizedBox(
                width: fab,
                height: fab,
                child: Icon(Icons.add, color: c.onPrimary, size: 28),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpace.xs),
        tab(2),
        tab(3),
      ],
    );
  }
}

class _DockTab extends StatelessWidget {
  const _DockTab({
    required this.icon,
    required this.label,
    required this.labelStyle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final TextStyle labelStyle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.onPrimarySoft : c.muted;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: AnimatedContainer(
          duration: AppMotion.short,
          height: 56,
          padding: const EdgeInsets.symmetric(
            horizontal: HomeDock._tabPadding - 1,
          ),
          decoration: BoxDecoration(
            color: selected ? c.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: AppSpace.xxs),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: labelStyle.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
