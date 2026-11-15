package com.jabc.booktracker

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import android.content.IntentFilter
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val CHANNEL = "com.jabc.booktracker/widget"
        private const val TAG = "MainActivity"
    }

    private var methodChannel: MethodChannel? = null
    private var widgetActionReceiver: WidgetBroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Registramos la fábrica de anuncios nativos
        val factory = ListTileNativeAdFactory(this)
        GoogleMobileAdsPlugin.registerNativeAdFactory(flutterEngine, "listTile", factory)

        // Configurar el MethodChannel para comunicación con Flutter
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // Registrar BroadcastReceiver para las acciones del widget
        widgetActionReceiver = WidgetBroadcastReceiver(methodChannel!!)
        val filter = IntentFilter("com.jabc.booktracker.WIDGET_ACTION")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(widgetActionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(widgetActionReceiver, filter)
        }

        Log.d(TAG, "Flutter Engine configurado con MethodChannel")
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)

        // Limpiamos la fábrica para evitar fugas de memoria
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTile")

        // Desregistrar BroadcastReceiver
        if (widgetActionReceiver != null) {
            try {
                unregisterReceiver(widgetActionReceiver)
                Log.d(TAG, "BroadcastReceiver desregistrado")
            } catch (e: Exception) {
                Log.e(TAG, "Error desregistrando BroadcastReceiver", e)
            }
        }

        methodChannel = null
    }
}

/**
 * BroadcastReceiver para manejar acciones del widget en tiempo real
 */
class WidgetBroadcastReceiver(private val methodChannel: MethodChannel) : BroadcastReceiver() {

    companion object {
        private const val TAG = "WidgetBroadcastReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == "com.jabc.booktracker.WIDGET_ACTION") {
            val action = intent.getStringExtra("action")
            Log.d(TAG, "Broadcast recibido con acción: $action")

            if (action != null) {
                // Enviar la acción a Flutter a través del MethodChannel
                methodChannel.invokeMethod("onWidgetAction", action)
            }
        }
    }
}