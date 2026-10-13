import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/security/lock_controller.dart';
import 'lock_screen.dart';

/// Membungkus seluruh app (lewat MaterialApp.builder). Selama terkunci,
/// isi app disembunyikan dan layar kunci tampil di atasnya.
class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    final lock = ref.read(lockProvider.notifier);
    _lifecycle = AppLifecycleListener(
      onHide: lock.onBackground,
      onShow: lock.onForeground,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(lockProvider);
    // Saat status kunci belum terbaca, jangan tampilkan isi app sekejap.
    final hide = lock.loading || lock.locked;

    return Stack(
      children: [
        // Tetap di tree supaya posisi layar tidak hilang, tapi tidak
        // digambar dan tidak terbaca pembaca layar selama terkunci.
        Offstage(offstage: hide, child: widget.child),
        if (lock.loading) ColoredBox(color: context.colors.hero),
        if (!lock.loading && lock.locked)
          // Navigator sendiri supaya dialog (mis. "Lupa PIN") bisa tampil.
          // HeroController milik MaterialApp hanya boleh dipakai satu
          // Navigator; kalau ikut dipakai di sini, navigasi app macet
          // (layar hitam saat membuka halaman baru).
          HeroControllerScope.none(
            child: Navigator(
              onGenerateRoute: (_) =>
                  MaterialPageRoute(builder: (_) => const LockScreen()),
            ),
          ),
      ],
    );
  }
}
