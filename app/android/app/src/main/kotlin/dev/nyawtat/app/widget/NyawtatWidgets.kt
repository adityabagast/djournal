package dev.nyawtat.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import dev.nyawtat.app.MainActivity
import dev.nyawtat.app.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

// Widget layar utama. Isinya ditulis Flutter (lib/data/home_widget_sync.dart)
// sebagai string yang sudah jadi; di sini hanya ditampilkan, plus menangani
// hari/bulan yang sudah berganti sejak app terakhir dibuka.

private const val MASK = "Rp •••••"

private fun launch(context: Context, path: String): PendingIntent =
    HomeWidgetLaunchIntent.getActivity(
        context,
        MainActivity::class.java,
        Uri.parse("nyawtat://$path"),
    )

private class WidgetData(private val prefs: SharedPreferences) {
    private val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

    fun text(key: String, fallback: String): String = prefs.getString(key, null) ?: fallback

    private val hasData get() = prefs.contains("nw_date")
    private val hidden get() = text("nw_hide", "0") == "1"
    private val isToday get() = text("nw_date", "") == today
    private val isThisMonth get() = text("nw_month", "") == today.substring(0, 7)

    val balance get() = text("nw_balance", "—")

    /**
     * Layout sesuai Pengaturan › Tampilan. "system" memakai alias di
     * res/values(-night)/widget_layouts.xml, jadi launcher memilih sendiri
     * sesuai mode gelap HP, termasuk saat mode HP berganti.
     */
    fun layout(system: Int, light: Int, dark: Int): Int = when (text("nw_theme", "system")) {
        "light" -> light
        "dark" -> dark
        else -> system
    }

    /** Data dari kemarin = belum ada transaksi hari ini. */
    val todayOut
        get() = when {
            !hasData -> "—"
            isToday -> text("nw_today_out", "—")
            hidden -> MASK
            else -> "Rp 0"
        }

    /** Data dari kemarin = belum ada entri hari ini. */
    val journalCount get() = if (isToday) text("nw_j_count", "0").toIntOrNull() ?: 0 else 0

    val hasBudget get() = isThisMonth && text("nw_has_budget", "0") == "1"
    val budgetOver get() = text("nw_budget_over", "0") == "1"
    val budgetPct get() = text("nw_budget_pct", "0").toIntOrNull() ?: 0
    val budgetLine get() = text("nw_budget_line", "")

    /** "Kamis, 9 Okt" dalam bahasa yang dipilih di app. */
    val dateLabel: String
        get() {
            val locale = Locale.forLanguageTag(text("nw_locale", "id"))
            return SimpleDateFormat("EEEE, d MMM", locale).format(Date())
        }
}

class RingkasWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val d = WidgetData(widgetData)
        for (id in appWidgetIds) {
            val views = RemoteViews(
                context.packageName,
                d.layout(R.layout.widget_ringkas, R.layout.widget_ringkas_light, R.layout.widget_ringkas_dark),
            ).apply {
                setTextViewText(R.id.label_balance, d.text("nw_l_balance", "Saldo"))
                setTextViewText(R.id.balance, d.balance)
                setTextViewText(R.id.label_today_out, d.text("nw_l_today_out", "Keluar hari ini"))
                setTextViewText(R.id.today_out, d.todayOut)
                setTextViewText(R.id.label_record, d.text("nw_l_record", "Catat"))
                setOnClickPendingIntent(R.id.widget_root, launch(context, "open"))
                setOnClickPendingIntent(R.id.btn_record, launch(context, "tx"))
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

class HariIniWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val d = WidgetData(widgetData)
        val over = d.hasBudget && d.budgetOver
        for (id in appWidgetIds) {
            val views = RemoteViews(
                context.packageName,
                d.layout(R.layout.widget_hari_ini, R.layout.widget_hari_ini_light, R.layout.widget_hari_ini_dark),
            ).apply {
                setTextViewText(
                    R.id.header,
                    d.dateLabel + " · " + d.text("nw_l_today_suffix", "keluar hari ini"),
                )
                setTextViewText(R.id.today_out, d.todayOut)
                setImageViewResource(
                    R.id.mascot,
                    if (over) R.drawable.widget_kucing_sedih else R.drawable.widget_kucing_koin,
                )
                setViewVisibility(R.id.budget_group, if (d.hasBudget) View.VISIBLE else View.GONE)
                setViewVisibility(R.id.progress_normal, if (over) View.GONE else View.VISIBLE)
                setViewVisibility(R.id.progress_over, if (over) View.VISIBLE else View.GONE)
                setProgressBar(R.id.progress_normal, 100, d.budgetPct, false)
                setTextViewText(R.id.budget_line, d.budgetLine)
                setTextViewText(R.id.label_record, d.text("nw_l_record", "Catat"))
                setTextViewText(R.id.label_write, d.text("nw_l_write", "Tulis"))
                setOnClickPendingIntent(R.id.widget_root, launch(context, "open"))
                setOnClickPendingIntent(R.id.btn_record, launch(context, "tx"))
                setOnClickPendingIntent(R.id.btn_write, launch(context, "write"))
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

/** Widget C: jurnal cepat. Hanya jumlah entri dan jam, tidak pernah isi entri. */
class CepatWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val d = WidgetData(widgetData)
        val written = d.journalCount > 0
        for (id in appWidgetIds) {
            val views = RemoteViews(
                context.packageName,
                d.layout(R.layout.widget_cepat, R.layout.widget_cepat_light, R.layout.widget_cepat_dark),
            ).apply {
                setImageViewResource(
                    R.id.mascot,
                    if (written) R.drawable.widget_kucing_senang else R.drawable.widget_kucing_menulis,
                )
                setTextViewText(
                    R.id.title,
                    if (written) d.text("nw_l_j_title", "Jurnal hari ini")
                    else d.text("nw_l_j_empty_title", "Gimana harimu?"),
                )
                setTextViewText(
                    R.id.sub,
                    if (written) d.text("nw_j_sub", "")
                    else d.text("nw_l_j_empty_sub", "Belum ada cerita hari ini"),
                )
                setTextViewText(R.id.label_write, d.text("nw_l_write", "Tulis"))
                setOnClickPendingIntent(R.id.widget_root, launch(context, "write"))
                setOnClickPendingIntent(R.id.btn_write, launch(context, "write"))
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
