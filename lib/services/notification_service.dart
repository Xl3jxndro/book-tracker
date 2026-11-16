import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Claves de SharedPreferences compartidas con NotificationsNotifier
  static const prefsEnabledKey = 'notifications_enabled';
  static const prefsHourKey = 'notifications_hour';
  static const prefsMinuteKey = 'notifications_minute';

  static const _dailyReminderId = 0;

  /// Contenido del recordatorio diario: al tocarlo se abre el libro actual.
  static const openCurrentBookPayload = 'open_current_book';

  static final _taps = StreamController<String?>.broadcast();

  /// Notificaciones tocadas con la app ya abierta (o en segundo plano).
  static Stream<String?> get taps => _taps.stream;

  /// ¿Esta notificación debe abrir el libro actual? Los recordatorios
  /// programados antes de esta versión no llevan contenido (`null`).
  static bool opensCurrentBook(String? payload) =>
      payload == null || payload == openCurrentBookPayload;

  /// Si la app se abrió en frío tocando una notificación, devuelve su
  /// contenido (el recordatorio sin contenido se trata como "abrir libro").
  /// Devuelve `null` si la app no se abrió desde una notificación.
  static Future<String?> launchPayload() async {
    try {
      final details = await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp != true) return null;
      return details!.notificationResponse?.payload ?? openCurrentBookPayload;
    } catch (e) {
      debugPrint('No se pudo leer el lanzamiento desde notificación: $e');
      return null;
    }
  }

  static Future<void> init() async {
    tz.initializeTimeZones();
    await _configureLocalTimeZone();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      ),
    );

    await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _taps.add(response.payload);
        },
    );

    // --- CONFIGURACIÓN PARA PRIMER PLANO (FOREGROUND) ---
    // Creamos el canal de alta importancia. Si el canal ya existe con baja importancia,
    // Android NO lo actualizará automáticamente, por lo que deberás desinstalar y reinstalar la app.
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(const AndroidNotificationChannel(
      'reading_reminders', // Debe coincidir con el ID usado en AndroidNotificationDetails
      'Recordatorios de Lectura',
      description: 'Notificaciones diarias para fomentar la lectura',
      importance: Importance.max, // Permite que la notificación "flote" (heads-up)
      playSound: true,
      showBadge: true,
      enableVibration: true,
    ));
  }

  /// Ajusta `tz.local` a la zona horaria real del dispositivo.
  /// Sin esto, `tz.local` es UTC y el recordatorio sale a una hora equivocada
  /// (ej. en Colombia, UTC-5, un recordatorio de las 20:00 saldría a las 15:00).
  static Future<void> _configureLocalTimeZone() async {
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
      debugPrint('🕒 Zona horaria local: ${timezoneInfo.identifier}');
    } catch (e) {
      debugPrint('⚠️ No se pudo obtener la zona horaria, se usará UTC: $e');
    }
  }

  /// Reprograma el recordatorio diario si el usuario lo tiene activado.
  /// Se llama al arrancar la app para corregir recordatorios programados con
  /// una zona horaria incorrecta y para mantenerlos tras actualizaciones.
  /// No solicita permisos (no debe interrumpir el arranque con diálogos).
  static Future<void> rescheduleIfEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(prefsEnabledKey) ?? false)) return;

      await scheduleDailyNotification(
        prefs.getInt(prefsHourKey) ?? 20,
        prefs.getInt(prefsMinuteKey) ?? 0,
        requestPermission: false,
      );
    } catch (e) {
      debugPrint('Error reprogramando recordatorio: $e');
    }
  }

  static Future<void> scheduleDailyNotification(int hour, int minute, {bool requestPermission = true}) async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // Si no hay permiso de alarmas exactas, usamos una alarma inexacta en lugar
    // de no programar nada (Android puede retrasarla unos minutos).
    var scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    if (androidImplementation != null) {
      bool canScheduleExact = await androidImplementation.canScheduleExactNotifications() ?? true;
      if (!canScheduleExact && requestPermission) {
        canScheduleExact = await androidImplementation.requestExactAlarmsPermission() ?? false;
      }
      if (!canScheduleExact) {
        debugPrint("Sin permiso de alarmas exactas: se programa recordatorio inexacto.");
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      }
    }

    await _notificationsPlugin.cancel(_dailyReminderId);

    try {
      await _notificationsPlugin.zonedSchedule(
        _dailyReminderId,
        '¡Hora de leer!',
        'Tu racha te espera. Abre un libro y relájate un momento.',
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reading_reminders',
            'Recordatorios de Lectura',
            channelDescription: 'Notificaciones diarias para fomentar la lectura',
            importance: Importance.max, // Máxima importancia
            priority: Priority.high,    // Máxima prioridad
            ticker: 'ticker',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,  // Presentar alerta con app abierta en iOS
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: openCurrentBookPayload,
      );
    } catch (e) {
      debugPrint("Error al programar notificación: $e");
    }
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> showInstantNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reading_reminders', // Mismo ID de canal para que use la configuración de alta importancia
      'Recordatorios de Lectura',
      channelDescription: 'Notificaciones de prueba inmediata',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true, // Esto ayuda a que "salte" en pantalla
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notificationsPlugin.show(
      999, // ID único para la prueba
      '¡Prueba de Lectura! 📖',
      'Esto es una notificación instantánea para verificar que todo funciona.',
      notificationDetails,
      payload: 'test_payload',
    );
  }
}
