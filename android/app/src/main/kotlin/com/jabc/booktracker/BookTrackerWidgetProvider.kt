package com.jabc.booktracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Widget de pantalla de inicio. Solo dibuja: los datos los escribe Flutter
 * (lib/services/home_widget_sync.dart) y las claves deben coincidir.
 */
class BookTrackerWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.book_tracker_widget)
            bind(context, views, widgetData)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun bind(context: Context, views: RemoteViews, data: SharedPreferences) {
        val bookId = data.getString("bookId", null)
        val bookTitle = data.getString("bookTitle", null)

        if (bookId.isNullOrEmpty() || bookTitle.isNullOrEmpty()) {
            // Sin libros: mensaje vacío y tocar abre la app
            views.setViewVisibility(R.id.widget_no_book_section, View.VISIBLE)
            views.setViewVisibility(R.id.widget_content_section, View.GONE)
            views.setOnClickPendingIntent(R.id.widget_main_layout, launch(context, "home", null))
            return
        }

        views.setViewVisibility(R.id.widget_no_book_section, View.GONE)
        views.setViewVisibility(R.id.widget_content_section, View.VISIBLE)

        // --- Libro y progreso ---
        val progress = data.getString("bookProgress", "0")?.toIntOrNull()?.coerceIn(0, 100) ?: 0
        views.setTextViewText(R.id.widget_book_title, bookTitle)
        views.setTextViewText(R.id.widget_book_author, data.getString("bookAuthor", "") ?: "")
        views.setProgressBar(R.id.widget_progress_bar, 100, progress, false)
        views.setTextViewText(R.id.widget_progress_text, "$progress%")
        views.setTextViewText(R.id.widget_pages_info, data.getString("pagesInfo", "") ?: "")
        views.setTextViewText(R.id.widget_status, data.getString("bookStatus", "") ?: "")

        // Minutos de hoy: si los datos son de otro día, hoy aún no se ha leído
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val todayMinutes = if (data.getString("todayDate", null) == today) {
            data.getString("todayMinutes", "0") ?: "0"
        } else "0"
        val goal = data.getString("dailyGoalMinutes", null)
        views.setTextViewText(
            R.id.widget_today_session,
            if (goal.isNullOrEmpty()) "$todayMinutes min" else "$todayMinutes / $goal min"
        )

        // --- Sesión (cronómetro) ---
        val sessionState = data.getString("sessionState", "none") ?: "none"
        val sessionBookId = data.getString("sessionBookId", null)
        val hasSession = sessionState != "none" && sessionBookId == bookId

        if (hasSession) {
            val isRunning = sessionState == "running"
            val accumulatedMs = data.getString("sessionAccumulatedMs", "0")?.toLongOrNull() ?: 0L
            val runningSinceMs = data.getString("sessionRunningSinceMs", "0")?.toLongOrNull() ?: 0L
            val runningMs = if (isRunning && runningSinceMs > 0) {
                (System.currentTimeMillis() - runningSinceMs).coerceAtLeast(0L)
            } else 0L
            val base = SystemClock.elapsedRealtime() - (accumulatedMs + runningMs)

            views.setViewVisibility(R.id.widget_session_section, View.VISIBLE)
            views.setViewVisibility(R.id.widget_no_session_section, View.GONE)
            views.setChronometer(R.id.widget_chronometer, base, null, isRunning)
            views.setTextViewText(R.id.widget_session_label, if (isRunning) "LEYENDO…" else "EN PAUSA")
            views.setTextViewText(R.id.widget_pause_button, if (isRunning) "⏸ PAUSAR" else "▶ REANUDAR")

            // Pausar/reanudar sin abrir la app (callback de Dart en segundo plano)
            views.setOnClickPendingIntent(
                R.id.widget_pause_button,
                HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("booktracker://toggle_pause"))
            )
            // Finalizar: abre la app en el libro con el diálogo de páginas
            views.setOnClickPendingIntent(
                R.id.widget_finish_button,
                launch(context, "finish_session", bookId)
            )
        } else {
            views.setViewVisibility(R.id.widget_session_section, View.GONE)
            views.setViewVisibility(R.id.widget_no_session_section, View.VISIBLE)
        }

        // Tocar el widget abre el libro
        views.setOnClickPendingIntent(R.id.widget_main_layout, launch(context, "open_book", bookId))
    }

    private fun launch(context: Context, host: String, bookId: String?) =
        HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse(if (bookId == null) "booktracker://$host" else "booktracker://$host?bookId=$bookId")
        )
}
