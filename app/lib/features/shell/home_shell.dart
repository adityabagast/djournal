import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../core/platform/platform_info.dart';
import '../../core/theme.dart';
import '../../data/home_widget_sync.dart';
import '../../data/sync/account_controller.dart';
import '../../ui/common.dart';
import '../journal/entry_form_screen.dart';
import '../journal/journal_screen.dart';
import '../journal/voice/voice_record_sheet.dart';
import '../money/money_screen.dart';
import '../money/tx_form_screen.dart';
import '../report/report_screen.dart';
import '../today/today_screen.dart';

/// Kerangka utama: 4 tab yang bisa digeser + floating dock dengan tombol
/// tambah di tengah.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  final _pages = PageController();
  late final AppLifecycleListener _lifecycle;
  StreamSubscription<Uri?>? _widgetClicks;

  @override
  void initState() {
    super.initState();
    // Membaca provider sekali = menyalakan login + sync otomatis.
    ref.read(accountProvider);
    // Sync setiap app kembali dibuka dari background.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(accountProvider.notifier).sync(),
    );
    if (PlatformInfo.isAndroid) {
      ref.read(homeWidgetSyncProvider);
      HomeWidget.initiallyLaunchedFromHomeWidget().then(_openFromWidget);
      _widgetClicks = HomeWidget.widgetClicked.listen(_openFromWidget);
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _widgetClicks?.cancel();
    _pages.dispose();
    super.dispose();
  }

  /// Tombol di widget layar utama membuka app dengan URI
  /// nyawtat://tx atau nyawtat://write.
  void _openFromWidget(Uri? uri) {
    if (uri == null || !mounted) return;
    final nav = Navigator.of(context)..popUntil((r) => r.isFirst);
    switch (uri.host) {
      case 'tx':
        _goTo(2);
        TxFormScreen.open(nav.context);
      case 'write':
        _goTo(1);
        EntryFormScreen.open(nav.context);
    }
  }

  /// Tap di dock langsung lompat (tanpa animasi melewati tab lain);
  /// animasi geser hanya saat jari menggeser halaman.
  void _goTo(int i) {
    setState(() => _index = i);
    if (_pages.hasClients) {
      _pages.jumpToPage(i);
    } else {
      // Dibuka dari widget layar utama sebelum PageView sempat dibangun.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pages.hasClients) _pages.jumpToPage(i);
      });
    }
  }

  static const _tabs = [
    TodayScreen(),
    JournalScreen(),
    MoneyScreen(),
    ReportScreen(),
  ];

  Future<void> _openQuickAdd() async {
    final l = context.l10n;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.handle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.quickAdd,
                style: Theme.of(ctx).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _QuickAction(
                icon: Icons.account_balance_wallet_outlined,
                fg: context.colors.fg(const Color(0xFF9A3412)),
                bg: context.colors.isDark
                    ? context.colors.soft(const Color(0xFF9A3412))
                    : const Color(0xFFFCE9DD),
                title: l.quickAddTx,
                subtitle: l.quickAddTxSub,
                onTap: () => Navigator.pop(ctx, 'tx'),
              ),
              const SizedBox(height: 12),
              _QuickAction(
                icon: Icons.menu_book_outlined,
                fg: context.colors.onPrimarySoft,
                bg: context.colors.primarySoft,
                title: l.quickAddJournal,
                subtitle: l.quickAddJournalSub,
                onTap: () => Navigator.pop(ctx, 'journal'),
              ),
              const SizedBox(height: 12),
              _QuickAction(
                icon: Icons.mic_rounded,
                fg: context.colors.primary,
                bg: context.colors.primarySoft,
                title: l.quickAddVoice,
                subtitle: l.quickAddVoiceSub,
                onTap: () => Navigator.pop(ctx, 'voice'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'tx':
        TxFormScreen.open(context);
      case 'journal':
        EntryFormScreen.open(context);
      case 'voice':
        final rec = await VoiceRecordSheet.show(context);
        if (rec != null && mounted) {
          EntryFormScreen.open(
            context,
            initialAudioPath: rec.audioPath.isEmpty ? null : rec.audioPath,
            initialAudioDurationMs: rec.durationMs,
            initialAudioTranscript:
                rec.transcript.isEmpty ? null : rec.transcript,
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: PageView(
              controller: _pages,
              onPageChanged: (i) => setState(() => _index = i),
              children: [for (final tab in _tabs) _KeepAlive(child: tab)],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.paddingOf(context).bottom,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _Dock(
                  index: _index,
                  onSelect: _goTo,
                  onAdd: _openQuickAdd,
                  items: [
                    (Icons.home_outlined, l.navToday),
                    (Icons.menu_book_outlined, l.navJournal),
                    (Icons.account_balance_wallet_outlined, l.navMoney),
                    (Icons.bar_chart_rounded, l.navReport),
                  ],
                  addLabel: l.add,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Menjaga tab tetap hidup setelah digeser keluar layar, supaya posisi
/// scroll dan filternya tidak hilang (seperti IndexedStack dulu).
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _Dock extends StatelessWidget {
  const _Dock({
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget tab(int i) => _DockTab(
      icon: items[i].$1,
      label: items[i].$2,
      selected: index == i,
      onTap: () => onSelect(i),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
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
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: c.isDark
                  ? const Color(0xFF1E2421).withValues(alpha: 0.88)
                  : Colors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: context.colors.line.withValues(alpha: 0.9),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                tab(0),
                tab(1),
                Tooltip(
                  message: addLabel,
                  child: Material(
                    color: context.colors.primary,
                    elevation: 6,
                    shadowColor: c.isDark
                        ? Colors.black
                        : c.primary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: onAdd,
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        width: 54,
                        height: 54,
                        child: Icon(Icons.add, color: c.onPrimary, size: 28),
                      ),
                    ),
                  ),
                ),
                tab(2),
                tab(3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockTab extends StatelessWidget {
  const _DockTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? context.colors.onPrimarySoft
        : context.colors.muted;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 64,
          height: 54,
          decoration: BoxDecoration(
            color: selected ? context.colors.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.fg,
    required this.bg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color fg;
  final Color bg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.colors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: fg, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
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
    );
  }
}
