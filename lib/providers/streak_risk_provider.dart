import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../services/streak.dart';
import 'database_provider.dart';

class StreakRiskSettings {
  final bool enabled;
  final int hour;
  final int minute;

  /// Ya se leyeron las preferencias guardadas (antes no se programa nada).
  final bool loaded;

  const StreakRiskSettings({required this.enabled, required this.hour, required this.minute, this.loaded = true});

  String get formattedTime => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  StreakRiskSettings copyWith({bool? enabled, int? hour, int? minute}) =>
      StreakRiskSettings(enabled: enabled ?? this.enabled, hour: hour ?? this.hour, minute: minute ?? this.minute);
}

/// ¿La app puede mostrar notificaciones? Se vuelve a consultar al volver a
/// la app (el usuario pudo cambiarlo en los ajustes de Android).
final notificationPermissionProvider = FutureProvider.autoDispose<bool>((ref) => Permission.notification.isGranted);

final streakRiskProvider = StateNotifierProvider<StreakRiskNotifier, StreakRiskSettings>((ref) => StreakRiskNotifier());

/// Aviso "racha en riesgo": activado por defecto a las 21:00. Solo suena si
/// la app tiene permiso de notificaciones (no lo pide al arrancar).
class StreakRiskNotifier extends StateNotifier<StreakRiskSettings> {
  StreakRiskNotifier() : super(const StreakRiskSettings(enabled: true, hour: defaultHour, minute: 0, loaded: false)) {
    _load();
  }

  static const enabledKey = 'streak_risk_enabled';
  static const hourKey = 'streak_risk_hour';
  static const minuteKey = 'streak_risk_minute';
  static const defaultHour = 21;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    state = StreakRiskSettings(
      enabled: prefs.getBool(enabledKey) ?? true,
      hour: prefs.getInt(hourKey) ?? defaultHour,
      minute: prefs.getInt(minuteKey) ?? 0,
    );
  }

  /// Al activarlo pide el permiso de notificaciones si hace falta.
  /// Devuelve el estado final (false si no se concedió el permiso).
  Future<bool> setEnabled(bool enabled) async {
    if (enabled) {
      final status = await Permission.notification.request();
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }
      if (!status.isGranted) return false;
    }
    state = state.copyWith(enabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, enabled);
    return enabled;
  }

  Future<void> updateTime(int hour, int minute) async {
    state = state.copyWith(hour: hour, minute: minute);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(hourKey, hour);
    await prefs.setInt(minuteKey, minute);
  }
}

/// Mantiene programado el aviso según las sesiones y la configuración.
/// Se llama cuando cambian las sesiones, la configuración o el día, y al
/// volver a la app.
class StreakRiskSync {
  /// [read] es `ref.read` (de un WidgetRef o de un Ref).
  static Future<void> sync(ProviderReader read) async {
    final settings = read(streakRiskProvider);
    if (!settings.loaded) return;
    final sessions = read(sessionsStreamProvider).valueOrNull;
    if (sessions == null) return; // aún cargando: no borrar el aviso existente

    final alert = settings.enabled
        ? StreakRisk.next(
            readingDates: sessions.map((s) => s.date),
            now: DateTime.now(),
            hour: settings.hour,
            minute: settings.minute,
          )
        : null;

    await NotificationService.scheduleStreakRisk(alert);
  }
}

typedef ProviderReader = T Function<T>(ProviderListenable<T> provider);
