import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/platform/platform_info.dart';

/// Membuka aplikasi email dan membaca info perangkat untuk laporan bug.
class FeedbackService {
  static const _channel = MethodChannel('nyawtat/device');

  /// false kalau tidak ada aplikasi email yang bisa membuka [uri].
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }

  /// Mis. "Android 16 · Merek Tipe". null kalau tidak diketahui.
  Future<String?> deviceInfo() async {
    if (PlatformInfo.isWeb) return null;
    if (!PlatformInfo.isAndroid) return Platform.operatingSystemVersion;
    try {
      return await _channel.invokeMethod<String>('info');
    } on Exception {
      return null;
    }
  }
}
