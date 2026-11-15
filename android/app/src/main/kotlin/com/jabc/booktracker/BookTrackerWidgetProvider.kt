package com.jabc.booktracker

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class BookTrackerWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val TAG = "BookTrackerWidget"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        Log.d(TAG, "Actualizando widget...")
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.book_tracker_widget).apply {
                // Leer datos guardados desde Flutter
                val bookTitle = widgetData.getString("bookTitle", null)
                val bookAuthor = widgetData.getString("bookAuthor", "") ?: ""
                val bookProgress = widgetData.getString("bookProgress", "0.0") ?: "0.0"
                val pagesInfo = widgetData.getString("pagesInfo", "0/0") ?: "0/0"
                val bookStatus = widgetData.getString("bookStatus", "") ?: ""
                
                val isSessionActive = widgetData.getString("isSessionActive", "false")?.toBoolean() ?: false
                val elapsedSeconds = widgetData.getString("elapsedSeconds", "0")?.toLongOrNull() ?: 0L
                val todaySessionMinutes = widgetData.getString("todaySessionMinutes", "0") ?: "0"
                val todaySessionPages = widgetData.getString("todaySessionPages", "0") ?: "0"

                Log.d(TAG, "bookTitle=$bookTitle, isSessionActive=$isSessionActive")

                if (!bookTitle.isNullOrEmpty() && bookTitle != "Sin libro") {
                    // Mostrar datos del libro
                    setTextViewText(R.id.widget_book_title, bookTitle)
                    setTextViewText(R.id.widget_book_author, if (bookAuthor.isEmpty()) "Desconocido" else bookAuthor)
                    
                    setTextViewText(R.id.widget_progress_text, "$bookProgress%")
                    setTextViewText(R.id.widget_pages_info, pagesInfo)
                    setTextViewText(R.id.widget_status, bookStatus)
                    setTextViewText(R.id.widget_today_session, "${todaySessionMinutes}min")
                    
                    // Calcular y mostrar tiempo transcurrido
                    val hours = elapsedSeconds / 3600
                    val minutes = (elapsedSeconds % 3600) / 60
                    val timeString = when {
                        hours > 0 -> "${hours}h ${minutes}m"
                        minutes > 0 -> "${minutes}m"
                        else -> "0m"
                    }
                    setTextViewText(R.id.widget_elapsed_time, timeString)
                    
                    setViewVisibility(R.id.widget_progress_section, View.VISIBLE)
                    setViewVisibility(R.id.widget_no_book_section, View.GONE)
                    
                    // Configurar UI de sesión
                    if (isSessionActive) {
                        setViewVisibility(R.id.widget_session_section, View.VISIBLE)
                        setViewVisibility(R.id.widget_no_session_section, View.GONE)
                        
                        // Intents para interactividad (Background Callback)
                        // Botón Pause
                        val pauseIntent = HomeWidgetBackgroundIntent.getBroadcast(
                            context,
                            Uri.parse("booktracker://pause_session")
                        )
                        setOnClickPendingIntent(R.id.widget_pause_button, pauseIntent)
                        
                        // Botón Finalizar (Abre la app directamente con deep link)
                        val finishIntent = HomeWidgetLaunchIntent.getActivity(
                            context,
                            MainActivity::class.java,
                            Uri.parse("booktracker://finish_session")
                        )
                        setOnClickPendingIntent(R.id.widget_finish_button, finishIntent)
                        
                    } else {
                        setViewVisibility(R.id.widget_session_section, View.GONE)
                        setViewVisibility(R.id.widget_no_session_section, View.VISIBLE)
                    }
                } else {
                    // Estado vacío - sin libro activo
                    setTextViewText(R.id.widget_book_title, "Sin libro activo")
                    setTextViewText(R.id.widget_book_author, "Selecciona un libro para comenzar")
                    setViewVisibility(R.id.widget_progress_section, View.GONE)
                    setViewVisibility(R.id.widget_session_section, View.GONE)
                    setViewVisibility(R.id.widget_no_book_section, View.VISIBLE)
                    setViewVisibility(R.id.widget_no_session_section, View.GONE)
                }

                // Tocar el widget completo abre la app principal
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("booktracker://home")
                )
                setOnClickPendingIntent(R.id.widget_main_layout, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
