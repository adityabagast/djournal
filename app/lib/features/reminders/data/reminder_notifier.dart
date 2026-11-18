import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Penjadwal notifikasi pengingat. Dipisah supaya platform tanpa notifikasi
/// (web, desktop) dan tes memakai [NoopReminderNotifier].
abstract class ReminderNotifier {
  /// False = platform ini tidak punya notifikasi terjadwal.
  bool get supported;

  Future<bool> isAllowed();

  /// Menampilkan dialog izin sistem; true kalau diizinkan.
  Future<bool> requestPermission();

  /// [private] menyembunyikan isi notifikasi di layar kunci.
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required bool private,
  });

  Future<void> cancel(int id);
}

class NoopReminderNotifier implements ReminderNotifier {
  const NoopReminderNotifier();

  @override
  bool get supported => false;

  @override
  Future<bool> isAllowed() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required bool private,
  }) async {}

  @override
  Future<void> cancel(int id) async {}
}

/// Notifikasi lokal Android. Semua dijadwalkan di perangkat, tanpa jaringan.
class AndroidReminderNotifier implements ReminderNotifier {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  Future<void> _init() => _ready ??= _plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_reminder'),
    ),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  bool get supported => true;

  @override
  Future<bool> isAllowed() async {
    await _init();
    return await _android?.areNotificationsEnabled() ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    await _init();
    return await _android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    required bool private,
  }) async {
    if (!at.isAfter(DateTime.now())) return;
    await _init();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      // Waktu absolut; zona UTC cukup, jadi tidak perlu database zona waktu.
      scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'Pengingat',
          channelDescription: 'Pengingat acara dari jurnal',
          importance: Importance.high,
          priority: Priority.high,
          visibility: private
              ? NotificationVisibility.private
              : NotificationVisibility.public,
        ),
      ),
      // Tidak butuh izin alarm presisi; bisa meleset beberapa menit.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _init();
    await _plugin.cancel(id: id);
  }
}
