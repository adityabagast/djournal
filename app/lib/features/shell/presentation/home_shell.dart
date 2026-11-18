import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../../core/platform/platform_info.dart';
import '../../../core/theme.dart';
import '../../home_widget/data/home_widget_sync.dart';
import '../../account/providers/account_controller.dart';
import '../../update/providers/update_controller.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/mascot.dart';
import '../../journal/presentation/entry_form_screen.dart';
import '../../journal/presentation/journal_screen.dart';
import '../../journal/presentation/voice/voice_record_sheet.dart';
import '../../money/presentation/money_screen.dart';
import '../../money/presentation/tx_form_screen.dart';
import '../../report/presentation/report_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../today/presentation/today_screen.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_sheet.dart';

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
      // Cek versi baru di GitHub (paling sering sekali sehari, diam kalau offline).
      ref.read(updateProvider.notifier).autoCheck();
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
    final choice = await showAppSheet<String>(
      context: context,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.md, AppSpace.xl, AppSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: AppSpace.lg),
              Text(
                l.quickAdd,
                style: Theme.of(ctx).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpace.md),
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
              const SizedBox(height: AppSpace.md),
              _QuickAction(
                icon: Icons.menu_book_outlined,
                fg: context.colors.onPrimarySoft,
                bg: context.colors.primarySoft,
                title: l.quickAddJournal,
                subtitle: l.quickAddJournalSub,
                onTap: () => Navigator.pop(ctx, 'journal'),
              ),
              const SizedBox(height: AppSpace.md),
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
            initialAudioTranscript: rec.transcript.isEmpty
                ? null
                : rec.transcript,
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final account = ref.watch(accountProvider);

    final navItems = [
      (Icons.home_outlined, l.navToday, 'Ctrl+1'),
      (Icons.menu_book_outlined, l.navJournal, 'Ctrl+2'),
      (Icons.account_balance_wallet_outlined, l.navMoney, 'Ctrl+3'),
      (Icons.bar_chart_rounded, l.navReport, 'Ctrl+4'),
    ];

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            _openQuickAdd,
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
            _openQuickAdd,
        const SingleActivator(LogicalKeyboardKey.digit1, control: true): () =>
            _goTo(0),
        const SingleActivator(LogicalKeyboardKey.digit1, meta: true): () =>
            _goTo(0),
        const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
            _goTo(1),
        const SingleActivator(LogicalKeyboardKey.digit2, meta: true): () =>
            _goTo(1),
        const SingleActivator(LogicalKeyboardKey.digit3, control: true): () =>
            _goTo(2),
        const SingleActivator(LogicalKeyboardKey.digit3, meta: true): () =>
            _goTo(2),
        const SingleActivator(LogicalKeyboardKey.digit4, control: true): () =>
            _goTo(3),
        const SingleActivator(LogicalKeyboardKey.digit4, meta: true): () =>
            _goTo(3),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            SearchScreen.open(context),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            SearchScreen.open(context),
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = PlatformInfo.isWideScreen(constraints.maxWidth);

            if (isWide) {
              return Scaffold(
                body: Row(
                  children: [
                    _DesktopSidebar(
                      selectedIndex: _index,
                      onSelect: _goTo,
                      onAdd: _openQuickAdd,
                      account: account,
                      items: navItems,
                    ),
                    Expanded(
                      child: IndexedStack(index: _index, children: _tabs),
                    ),
                  ],
                ),
              );
            }

            return Scaffold(
              body: Stack(
                children: [
                  SafeArea(
                    bottom: false,
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (i) => setState(() => _index = i),
                      children: [
                        for (final tab in _tabs) _KeepAlive(child: tab),
                      ],
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
                            for (final (icon, label, _) in navItems)
                              (icon, label),
                          ],
                          addLabel: l.add,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.onAdd,
    required this.account,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;
  final AccountState account;
  final List<(IconData, String, String)> items;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = context.l10n;
    final sidebarBg = c.isDark
        ? const Color(0xFF141A17)
        : const Color(0xFFEAEFEB);

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: c.line)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.xl, AppSpace.lg, AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9F0),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: c.line),
                ),
                child: const Center(child: Mascot(MascotPose.halo, size: 26)),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nyawtat',
                      style: TextStyle(
                        fontSize: AppFontSize.title,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    _SyncStatusBadge(account: account),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Material(
            color: c.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
            elevation: 2,
            shadowColor: c.primary.withValues(alpha: 0.3),
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Icon(Icons.add, color: c.onPrimary, size: 18),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Text(
                        l.quickAdd,
                        style: TextStyle(
                          color: c.onPrimary,
                          fontSize: AppFontSize.body,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.sm,
                        vertical: AppSpace.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        'Ctrl+N',
                        style: TextStyle(
                          color: c.onPrimary,
                          fontSize: AppFontSize.caption,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          for (var i = 0; i < items.length; i++) ...[
            _DesktopNavItem(
              icon: items[i].$1,
              label: items[i].$2,
              shortcut: items[i].$3,
              selected: selectedIndex == i,
              onTap: () => onSelect(i),
            ),
            const SizedBox(height: AppSpace.xs),
          ],
          const Spacer(),
          Divider(color: c.line, height: 1),
          const SizedBox(height: AppSpace.sm),
          _DesktopNavItem(
            icon: Icons.settings_outlined,
            label: l.settings,
            shortcut: '',
            selected: false,
            onTap: () => SettingsScreen.open(context),
          ),
        ],
      ),
    );
  }
}

class _DesktopNavItem extends StatelessWidget {
  const _DesktopNavItem({
    required this.icon,
    required this.label,
    required this.shortcut,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String shortcut;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: selected ? c.line : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: selected ? c.primary : c.muted),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? c.primary : c.muted,
                  ),
                ),
              ),
              if (shortcut.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.xs,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? c.primarySoft
                        : (c.isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05)),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    shortcut,
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: FontWeight.w500,
                      color: selected ? c.onPrimarySoft : c.faint,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncStatusBadge extends StatelessWidget {
  const _SyncStatusBadge({required this.account});

  final AccountState account;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (account.syncing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: c.primary,
            ),
          ),
          const SizedBox(width: AppSpace.xs),
          Text(
            'Menyinkronkan...',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              color: c.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    if (account.loggedIn) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c.income, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpace.xs),
          Flexible(
            child: Text(
              'Tersinkron',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                color: c.income,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: c.faint, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpace.xs),
        Flexible(
          child: Text(
            'Offline (Lokal)',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              color: c.muted,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
            decoration: BoxDecoration(
              color: c.isDark
                  ? const Color(0xFF1E2421).withValues(alpha: 0.88)
                  : Colors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(AppRadius.pill),
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
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: InkWell(
                      onTap: onAdd,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
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
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: AnimatedContainer(
          duration: AppMotion.short,
          width: 64,
          height: 54,
          decoration: BoxDecoration(
            color: selected ? context.colors.primarySoft : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: AppSpace.xxs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: AppFontSize.caption,
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: context.colors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: fg, size: 22),
              ),
              const SizedBox(width: AppSpace.lg),
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
                        fontSize: AppFontSize.body,
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
