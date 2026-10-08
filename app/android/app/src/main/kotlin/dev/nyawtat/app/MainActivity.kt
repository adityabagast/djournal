package dev.nyawtat.app

import android.content.pm.ApplicationInfo
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

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
}
