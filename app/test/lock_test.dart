import 'package:djournal/data/security/lock_controller.dart';
import 'package:djournal/data/security/pin_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  /// Container baru = app baru dibuka. Tunggu status kunci terbaca.
  Future<ProviderContainer> openApp() async {
    final container = ProviderContainer();
    container.read(lockProvider);
    for (var i = 0; i < 50 && container.read(lockProvider).loading; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return container;
  }

  test('PIN disimpan sebagai hash, bukan angka aslinya', () async {
    final store = PinStore();
    await store.setPin('1234');
    final raw = await const FlutterSecureStorage().readAll();
    expect(raw.values.join(), isNot(contains('1234')));
    expect(await store.verify('1234'), isTrue);
    expect(await store.verify('4321'), isFalse);
    expect(() => store.setPin('12a4'), throwsArgumentError);
  });

  test('tanpa PIN app tidak terkunci', () async {
    final app = await openApp();
    expect(app.read(lockProvider).locked, isFalse);
    app.read(lockProvider.notifier).lockNow();
    expect(app.read(lockProvider).locked, isFalse);
    app.dispose();
  });

  test('aktifkan PIN, kunci, buka dengan PIN benar', () async {
    final app = await openApp();
    final lock = app.read(lockProvider.notifier);
    await lock.enablePin('2580');
    expect(app.read(lockProvider).locked, isFalse);

    lock.lockNow();
    expect(app.read(lockProvider).locked, isTrue);
    expect(await lock.unlockWithPin('0000'), UnlockResult.wrong);
    expect(app.read(lockProvider).locked, isTrue);
    expect(await lock.unlockWithPin('2580'), UnlockResult.ok);
    expect(app.read(lockProvider).locked, isFalse);
    app.dispose();

    // Buka app lagi: langsung terkunci.
    final reopened = await openApp();
    expect(reopened.read(lockProvider).pinEnabled, isTrue);
    expect(reopened.read(lockProvider).locked, isTrue);
    reopened.dispose();
  });

  test('terlalu banyak PIN salah: harus menunggu', () async {
    final app = await openApp();
    final lock = app.read(lockProvider.notifier);
    await lock.enablePin('2580');
    lock.lockNow();

    for (var i = 0; i < LockController.freeAttempts - 1; i++) {
      expect(await lock.unlockWithPin('1111'), UnlockResult.wrong);
    }
    expect(await lock.unlockWithPin('1111'), UnlockResult.lockedOut);
    // Selama masa tunggu, PIN benar pun ditolak.
    expect(await lock.unlockWithPin('2580'), UnlockResult.lockedOut);
    expect(lock.lockoutRemaining, isNotNull);
    expect(app.read(lockProvider).locked, isTrue);
    app.dispose();
  });

  test('matikan PIN menghapus PIN dan biometrik', () async {
    final app = await openApp();
    final lock = app.read(lockProvider.notifier);
    await lock.enablePin('2580');
    await lock.setBiometric(true);
    await lock.disablePin();
    expect(app.read(lockProvider).pinEnabled, isFalse);
    expect(app.read(lockProvider).biometricEnabled, isFalse);
    expect(await PinStore().hasPin(), isFalse);
    app.dispose();
  });

  test('kembali dari background sebentar tidak mengunci', () async {
    final app = await openApp();
    final lock = app.read(lockProvider.notifier);
    await lock.enablePin('2580');
    lock.onBackground();
    lock.onForeground();
    expect(app.read(lockProvider).locked, isFalse);
    app.dispose();
  });
}
