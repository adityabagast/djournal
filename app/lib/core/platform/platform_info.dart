import 'package:flutter/foundation.dart';

/// Informasi platform terpusat untuk memisahkan logika khusus Android/iOS/Desktop/Web.
class PlatformInfo {
  const PlatformInfo._();

  /// True jika berjalan di desktop (Windows, macOS, Linux).
  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// True jika berjalan di mobile (Android, iOS).
  static bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// True jika berjalan di Android.
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// True jika berjalan di Windows.
  static bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// True jika berjalan di Web.
  static bool get isWeb => kIsWeb;

  /// True jika perangkat memiliki layar lebar (desktop / tablet / landscape).
  static bool isWideScreen(double width) => width >= 720;
}

