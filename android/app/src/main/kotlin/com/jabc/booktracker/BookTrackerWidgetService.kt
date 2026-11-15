package com.jabc.booktracker

import android.app.Service
import android.content.Intent
import android.net.Uri
import android.os.IBinder
import android.util.Log

import androidx.work.Worker
import androidx.work.WorkerParameters
import android.content.Context

class BookTrackerWidgetService : Service() {

    companion object {
        private const val TAG = "BookTrackerWidgetService"
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Servicio iniciado con acción: ${intent?.action}")

        when (intent?.action) {
            "pause_session" -> handlePauseSession()
            "finish_session" -> handleFinishSession()
        }

        stopSelf()
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun handlePauseSession() {
        try {
            Log.d(TAG, "Pausando sesión desde widget")
            
            // Enviar broadcast a MainActivity
            val flutterIntent = Intent("com.jabc.booktracker.WIDGET_ACTION").apply {
                putExtra("action", "pause_session")
                setPackage(packageName)
            }
            sendBroadcast(flutterIntent)
            Log.d(TAG, "Broadcast de pause_session enviado")
        } catch (e: Exception) {
            Log.e(TAG, "Error pausando sesión", e)
        }
    }

    private fun handleFinishSession() {
        try {
            Log.d(TAG, "Finalizando sesión desde widget")
            
            // Enviar broadcast a MainActivity ANTES de abrir la app
            val flutterIntent = Intent("com.jabc.booktracker.WIDGET_ACTION").apply {
                putExtra("action", "finish_session")
                setPackage(packageName)
            }
            sendBroadcast(flutterIntent)
            Log.d(TAG, "Broadcast de finish_session enviado")

            // Abrir la app con deep link
            val launchIntent = Intent(this, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("booktracker://finish_session")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            startActivity(launchIntent)
            Log.d(TAG, "MainActivity abierto con deep link")
        } catch (e: Exception) {
            Log.e(TAG, "Error finalizando sesión", e)
        }
    }
}

/**
 * Worker para ejecutar tareas en background usando WorkManager
 */
class WidgetActionWorker(context: Context, params: WorkerParameters) : Worker(context, params) {

    companion object {
        private const val TAG = "WidgetActionWorker"
        const val ACTION_KEY = "action"
        const val PAUSE_SESSION_ACTION = "pause_session"
        const val FINISH_SESSION_ACTION = "finish_session"
    }

    override fun doWork(): Result {
        return try {
            val action = inputData.getString(ACTION_KEY) ?: return Result.failure()
            
            Log.d(TAG, "Ejecutando acción: $action")

            when (action) {
                PAUSE_SESSION_ACTION -> pauseSession()
                FINISH_SESSION_ACTION -> finishSession()
            }

            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Error en WidgetActionWorker", e)
            Result.retry()
        }
    }

    private fun pauseSession() {
        Log.d(TAG, "Pausando sesión desde worker")
        val intent = Intent("com.jabc.booktracker.WIDGET_ACTION").apply {
            putExtra("action", "pause_session")
            setPackage(applicationContext.packageName)
        }
        applicationContext.sendBroadcast(intent)
    }

    private fun finishSession() {
        Log.d(TAG, "Finalizando sesión desde worker")
        val intent = Intent("com.jabc.booktracker.WIDGET_ACTION").apply {
            putExtra("action", "finish_session")
            setPackage(applicationContext.packageName)
        }
        applicationContext.sendBroadcast(intent)

        // Abrir la app
        val launchIntent = Intent(applicationContext, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("booktracker://finish_session")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        applicationContext.startActivity(launchIntent)
    }
}
