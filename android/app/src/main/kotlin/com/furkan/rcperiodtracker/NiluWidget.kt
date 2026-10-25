package com.furkan.rcperiodtracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.time.LocalDate

/**
 * Uygulamanın yazdığı bir günlük içerik.
 *
 * Widget uygulamanın sözlüğüne de belleğine de erişemiyor; uygulama
 * önümüzdeki günlerin her biri için metinleri kendi dilinde hazırlayıp
 * yazıyor (Dart: `HomeWidgetEntry.toJson`, iOS: `CycleWidget.swift`). Widget
 * yalnızca bugünün girdisini çiziyor. Anahtar adları üç yerde aynı olmalı.
 */
data class WidgetDay(
    val hasData: Boolean,
    val label: String,
    val value: String,
    val caption: String,
    val detail: String,
    val spoken: String,
    val progress: Double?,
    val colorKey: String,
)

object WidgetStore {
    /** Bugünün girdisi; uygulama hiç yazmadıysa ya da günler geride kaldıysa `null`. */
    fun today(prefs: SharedPreferences): WidgetDay? {
        val json = prefs.getString("entries", null) ?: return null
        val today = LocalDate.now().toString() // yyyy-MM-dd, cihazın saat dilimi
        return try {
            val days = JSONArray(json)
            (0 until days.length())
                .map { days.getJSONObject(it) }
                .firstOrNull { it.optString("date") == today }
                ?.let {
                    WidgetDay(
                        hasData = it.optBoolean("hasData"),
                        label = it.optString("label"),
                        value = it.optString("value"),
                        caption = it.optString("caption"),
                        detail = it.optString("detail"),
                        spoken = it.optString("spoken"),
                        progress = if (it.isNull("progress")) null else it.optDouble("progress"),
                        colorKey = it.optString("colorKey", "unknown"),
                    )
                }
        } catch (e: Exception) {
            null
        }
    }

    /** Gösterilecek gün yokken: uygulamanın yazdığı metin, o da yoksa "uygulamayı aç". */
    fun message(context: Context, prefs: SharedPreferences): String {
        val stale = prefs.getString("staleText", null)
        return if (prefs.contains("entries") && !stale.isNullOrEmpty()) {
            stale
        } else {
            context.getString(R.string.widget_open_app)
        }
    }
}

/** Uygulamanın paletiyle aynı renkler; koyu temada açık tonlar (iOS: `niluColor`). */
fun niluColor(key: String, dark: Boolean): Int = when (key) {
    "menstruation" -> if (dark) 0xFFFB7185 else 0xFFE11D48 // flow
    "follicular" -> if (dark) 0xFF34D399 else 0xFF059669 // phaseFollicular
    "ovulation" -> if (dark) 0xFFA78BFA else 0xFF7C3AED // ovulation
    "luteal" -> if (dark) 0xFFFBBF24 else 0xFFD97706 // phaseLuteal
    "suppressed" -> if (dark) 0xFFA0788F else 0xFFC084AB // phaseSuppressed
    "pregnancy", "postpartum" -> if (dark) 0xFFF78E69 else 0xFFC2410C // accent
    else -> if (dark) 0xFFFFAEDE else 0xFF541942 // marka
}.toInt()

/**
 * Ana ekran widget'ı. iOS'taki gibi iki boy: küçük (2×2) ve orta (4×2);
 * Android'de her boy ayrı bir sağlayıcı.
 *
 * Gün değişince yeni girdiye geçmek için `updatePeriodMillis` saatte bir
 * yeniliyor; uygulama yeni içerik yazınca da hemen yenileniyor
 * (`WidgetDatasource`). Yalnızca ana ekranda: kilit ekranına konamıyor.
 */
abstract class NiluWidgetProvider(
    private val layout: Int,
    private val medium: Boolean,
) : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val night = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        val dark = night == Configuration.UI_MODE_NIGHT_YES
        val day = WidgetStore.today(widgetData)
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, layout)
            if (day != null && day.hasData) {
                bind(context, views, day, dark)
            } else {
                empty(views, day?.detail?.takeIf { it.isNotEmpty() } ?: WidgetStore.message(context, widgetData))
            }
            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun bind(context: Context, views: RemoteViews, day: WidgetDay, dark: Boolean) {
        val color = niluColor(day.colorKey, dark)
        views.setViewVisibility(R.id.content, View.VISIBLE)
        views.setViewVisibility(R.id.empty, View.GONE)
        views.setTextViewText(R.id.label, day.label)
        views.setTextColor(R.id.label, color)
        views.setTextViewText(R.id.value, day.value)
        text(views, R.id.caption, day.caption)
        text(views, R.id.detail, day.detail)
        if (medium) {
            views.setImageViewBitmap(R.id.ring, ring(context, day.progress, color))
        }
        // TalkBack: "24+2" sesli okununca "yirmi dört artı iki" oluyordu.
        val spoken = day.spoken.ifEmpty {
            listOf(day.label, day.value, day.caption, day.detail)
                .filter { it.isNotEmpty() }
                .joinToString(", ")
        }
        views.setContentDescription(R.id.widget_root, spoken)
    }

    private fun empty(views: RemoteViews, message: String) {
        views.setViewVisibility(R.id.content, View.GONE)
        views.setViewVisibility(R.id.empty, View.VISIBLE)
        views.setTextViewText(R.id.empty_text, message)
        views.setContentDescription(R.id.widget_root, message)
    }

    private fun text(views: RemoteViews, id: Int, value: String) {
        views.setTextViewText(id, value)
        views.setViewVisibility(id, if (value.isEmpty()) View.GONE else View.VISIBLE)
    }

    /** Döngü halkası: soluk iz ve ilerleme yayı (iOS'taki `Circle().trim`). */
    private fun ring(context: Context, progress: Double?, color: Int): Bitmap {
        val density = context.resources.displayMetrics.density
        val size = (84 * density).toInt()
        val stroke = 8 * density
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val inset = stroke / 2
        val rect = RectF(inset, inset, size - inset, size - inset)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = stroke
            strokeCap = Paint.Cap.ROUND
        }
        paint.color = (color and 0x00FFFFFF) or (0x33 shl 24)
        canvas.drawArc(rect, 0f, 360f, false, paint)
        if (progress != null) {
            paint.color = color
            val sweep = (360 * progress.coerceIn(0.0, 1.0)).toFloat()
            canvas.drawArc(rect, -90f, sweep, false, paint)
        }
        return bitmap
    }
}

/** Küçük widget (2×2). Dart: `WidgetDatasource.androidSmall`. */
class NiluWidgetSmall : NiluWidgetProvider(R.layout.nilu_widget_small, medium = false)

/** Orta widget (4×2). Dart: `WidgetDatasource.androidMedium`. */
class NiluWidgetMedium : NiluWidgetProvider(R.layout.nilu_widget_medium, medium = true)
