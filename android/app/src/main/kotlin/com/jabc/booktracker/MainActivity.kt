package com.jabc.booktracker

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val APP_CHANNEL = "com.jabc.booktracker/app"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Registramos la fábrica de anuncios nativos
        val factory = ListTileNativeAdFactory(this)
        GoogleMobileAdsPlugin.registerNativeAdFactory(flutterEngine, "listTile", factory)

        // "Atrás" en la pantalla de bloqueo: minimiza la app (como el sistema
        // en la pantalla principal) sin cerrarla ni perder dónde estaba.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "moveToBackground" -> result.success(moveTaskToBack(true))
                    else -> result.notImplemented()
                }
            }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)

        // Limpiamos la fábrica para evitar fugas de memoria
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTile")
    }
}
