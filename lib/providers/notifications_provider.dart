import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart'; 
import '../services/notification_service.dart';

class NotificationSettings {
  final bool enabled;
  final int hour;
  final int minute;

  NotificationSettings({required this.enabled, required this.hour, required this.minute});

  String get formattedTime => 
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  NotificationSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationSettings>((ref) {
  return NotificationsNotifier();
});

class NotificationsNotifier extends StateNotifier<NotificationSettings> {
  NotificationsNotifier() : super(NotificationSettings(enabled: false, hour: 20, minute: 0)) {
    _loadSettings();
  }

  static const _notifKey = NotificationService.prefsEnabledKey;
  static const _hourKey = NotificationService.prefsHourKey;
  static const _minKey = NotificationService.prefsMinuteKey;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationSettings(
      enabled: prefs.getBool(_notifKey) ?? false,
      hour: prefs.getInt(_hourKey) ?? 20,
      minute: prefs.getInt(_minKey) ?? 0,
    );
  }

  Future<void> updateTime(int hour, int minute) async {
    state = state.copyWith(hour: hour, minute: minute);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, hour);
    await prefs.setInt(_minKey, minute);
    
    if (state.enabled) {
      await NotificationService.scheduleDailyNotification(hour, minute);
    }
  }

  Future<void> toggleNotifications(bool enabled) async {
    if (enabled) {
      // 1. Verificar y solicitar permiso de notificaciones (Android 13+)
      PermissionStatus status = await Permission.notification.request();

      if (status.isPermanentlyDenied) {
        // El usuario bloqueó las notis desde ajustes. Abrimos ajustes por él.
        await openAppSettings();
        return;
      }

      if (!status.isGranted) {
        // Si no dio permiso, forzamos el estado a false
        state = state.copyWith(enabled: false);
        return;
      }
    }

    // 2. Si llegamos aquí, o desactivó las notis o dio permiso correctamente
    state = state.copyWith(enabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifKey, enabled);

    if (enabled) {
      await NotificationService.scheduleDailyNotification(state.hour, state.minute);
    } else {
      await NotificationService.cancelAll();
    }
  }

  Future<void> showImmediateTestNotification() async {
    // Verificamos permiso antes de lanzar la prueba
    if (await Permission.notification.isGranted) {
      await NotificationService.showInstantNotification();
    } else {
      await Permission.notification.request();
    }
  }
}