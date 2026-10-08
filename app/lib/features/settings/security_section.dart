import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/security/lock_controller.dart';
import '../../ui/common.dart';
import '../lock/pin_setup_screen.dart';

/// Bagian "Keamanan" di Pengaturan: PIN, biometrik, kunci sekarang.
class SecuritySection extends ConsumerWidget {
  const SecuritySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lock = ref.watch(lockProvider);
    final controller = ref.read(lockProvider.notifier);
    const divider = Divider(height: 1, color: AppColors.divider);
    const titleStyle = TextStyle(fontWeight: FontWeight.w500);
    const subStyle = TextStyle(fontSize: 12, color: AppColors.muted);

    Future<void> togglePin(bool on) async {
      if (on) {
        await PinSetupScreen.open(context);
      } else if (await PinVerifyScreen.open(context) == true) {
        await controller.disablePin();
      }
    }

    Future<void> toggleBiometric(bool on) async {
      // Pastikan sensor benar-benar bisa dipakai sebelum diaktifkan.
      if (on && !await controller.authenticateBiometric(l.biometricReason)) {
        return;
      }
      await controller.setBiometric(on);
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        children: [
          SwitchListTile(
            value: lock.pinEnabled,
            onChanged: lock.loading ? null : togglePin,
            title: Text(l.lockWithPin, style: titleStyle),
            subtitle: Text(l.lockWithPinSub, style: subStyle),
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
          ),
          divider,
          SwitchListTile(
            value: lock.biometricEnabled,
            onChanged: lock.pinEnabled && lock.biometricAvailable
                ? toggleBiometric
                : null,
            title: Text(l.unlockWithBiometric, style: titleStyle),
            subtitle: Text(
              lock.biometricAvailable
                  ? l.unlockWithBiometricSub
                  : l.biometricUnavailable,
              style: subStyle,
            ),
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
          ),
          if (lock.pinEnabled) ...[
            divider,
            ListTile(
              onTap: controller.lockNow,
              leading: const Icon(Icons.lock_outline, color: AppColors.primary),
              title: Text(
                l.lockNow,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
