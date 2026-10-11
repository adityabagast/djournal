package dev.nyawtat.app

import android.app.UiModeManager
import android.content.pm.ApplicationInfo
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FragmentActivity dibutuhkan package local_auth untuk dialog biometrik.
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Build rilis: isi jurnal & keuangan tidak terlihat di daftar app
        // terbaru dan tidak bisa di-screenshot/direkam. Build debug dibiarkan
        // supaya tetap mudah dites (screenshot lewat adb).
        val debuggable = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (!debuggable) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Pengaturan › Tampilan. Android 12+ menyimpan pilihan ini per app,
        // jadi splash bawaan saat app dibuka berikutnya ikut terang/gelap.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nyawtat/theme")
            .setMethodCallHandler { call, result ->
                if (call.method != "setNightMode") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val mode = when (call.arguments as? String) {
                        "light" -> UiModeManager.MODE_NIGHT_NO
                        "dark" -> UiModeManager.MODE_NIGHT_YES
                        else -> UiModeManager.MODE_NIGHT_AUTO
                    }
                    getSystemService(UiModeManager::class.java)?.setApplicationNightMode(mode)
                }
                result.success(null)
            }
    }
}
