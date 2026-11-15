package com.jabc.booktracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.appwidget.AppWidgetManager
import android.net.Uri
import android.util.Log

class BookTrackerWidgetReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BookTrackerWidgetReceiver"
        const val ACTION_PAUSE = "booktracker://pause_session"
        const val ACTION_FINISH = "booktracker://finish_session"
        const val ACTION_UPDATE_WIDGET = "com.jabc.booktracker.UPDATE_WIDGET"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Acción recibida: ${intent.data}")

        when (intent.data?.toString()) {
            ACTION_PAUSE -> {
                Log.d(TAG, "Pausando sesión desde widget")
                // Notificar a Flutter que pausa la sesión
                sendBroadcastToFlutter(context, "pause_session")
                
                // Actualizar el widget
                updateWidget(context)
            }
            ACTION_FINISH -> {
                Log.d(TAG, "Finalizando sesión desde widget")
                // Notificar a Flutter que finalice la sesión
                sendBroadcastToFlutter(context, "finish_session")
                
                // Abrir la app con deep link para mostrar la pantalla de resumen
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    data = Uri.parse("booktracker://finish_session")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                }
                context.startActivity(launchIntent)
                
                // Actualizar el widget
                updateWidget(context)
            }
            ACTION_UPDATE_WIDGET -> {
                Log.d(TAG, "Actualizando widget")
                updateWidget(context)
            }
        }
    }

    private fun sendBroadcastToFlutter(context: Context, action: String) {
        try {
            val flutterIntent = Intent("com.jabc.booktracker.WIDGET_ACTION").apply {
                putExtra("action", action)
                setPackage(context.packageName)
            }
            context.sendBroadcast(flutterIntent)
            Log.d(TAG, "Broadcast enviado a Flutter: $action")
        } catch (e: Exception) {
            Log.e(TAG, "Error enviando broadcast a Flutter", e)
        }
    }

    private fun updateWidget(context: Context) {
        try {
            val intent = Intent(context, BookTrackerWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            }
            context.sendBroadcast(intent)
            Log.d(TAG, "Broadcast de actualización enviado")
        } catch (e: Exception) {
            Log.e(TAG, "Error actualizando widget", e)
        }
    }
}
