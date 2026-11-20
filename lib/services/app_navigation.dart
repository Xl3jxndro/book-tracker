import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Acciones de navegación del sistema Android.
class AppNavigation {
  AppNavigation._();

  static const _channel = MethodChannel('com.jabc.booktracker/app');

  /// Minimiza la app (como "atrás" en la pantalla principal de Android),
  /// sin cerrarla ni perder el estado.
  static Future<void> moveToBackground() async {
    try {
      await _channel.invokeMethod<bool>('moveToBackground');
    } catch (e) {
      debugPrint('No se pudo minimizar la app: $e');
    }
  }
}
