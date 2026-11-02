package dev.nyawtat.app

import android.app.UiModeManager
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import androidx.core.content.FileProvider
import java.io.File
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

        // Cek update di dalam app: ABI untuk memilih APK, lalu buka installer.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nyawtat/update")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "abi" -> result.success(Build.SUPPORTED_ABIS.firstOrNull())
                    "installApk" -> result.success(installApk(call.argument<String>("path")))
                    else -> result.notImplemented()
                }
            }
    }

    /// Hasil "permission" = user perlu mengizinkan "Instal aplikasi tak
    /// dikenal" dulu (layar izinnya dibuka); "started" = installer dibuka.
    private fun installApk(path: String?): String {
        val file = File(path ?: return "missing")
        // Hanya file di folder unduhan update milik app ini.
        val updatesDir = File(cacheDir, "updates").canonicalPath
        if (!file.canonicalPath.startsWith(updatesDir + File.separator) || !file.exists()) {
            return "missing"
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()
        ) {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:$packageName"),
                ),
            )
            return "permission"
        }
        val uri = FileProvider.getUriForFile(this, "$packageName.updates", file)
        startActivity(
            Intent(Intent.ACTION_VIEW)
                .setDataAndType(uri, "application/vnd.android.package-archive")
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION),
        )
        return "started"
    }
}
