import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'streak.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Claves de SharedPreferences compartidas con NotificationsNotifier
  static const prefsEnabledKey = 'notifications_enabled';
  static const prefsHourKey = 'notifications_hour';
  static const prefsMinuteKey = 'notifications_minute';

  static const _dailyReminderId = 0;
  static const _streakRiskId = 1;
  static const _sessionGoalId = 2;
  static const _sessionChannelId = 'session_goal';
  static const _sessionChannelName = 'Meta de la sesión';
  static const _sessionChannelDescription = 'Aviso cuando cumples la meta de tiempo de una sesión de lectura';

  static bool _initialized = false;
  static const _streakChannelId = 'streak_alerts';
  static const _streakChannelName = 'Racha en riesgo';
  static const _streakChannelDescription = 'Aviso cuando llevas racha y aún no has leído hoy';

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

  /// Inicializa una sola vez por isolate (la app o el widget en segundo plano).
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await init();
  }

  static Future<void> init() async {
    _initialized = true;
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
        settings: initializationSettings,
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

    await androidImplementation?.createNotificationChannel(const AndroidNotificationChannel(
      _sessionChannelId,
      _sessionChannelName,
      description: _sessionChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));

    await androidImplementation?.createNotificationChannel(const AndroidNotificationChannel(
      _streakChannelId,
      _streakChannelName,
      description: _streakChannelDescription,
      importance: Importance.high,
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

  /// Si no hay permiso de alarmas exactas, se usa una alarma inexacta en lugar
  /// de no programar nada (Android puede retrasarla unos minutos).
  static Future<AndroidScheduleMode> _scheduleMode({required bool requestPermission}) async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation == null) return AndroidScheduleMode.exactAllowWhileIdle;

    bool canScheduleExact = await androidImplementation.canScheduleExactNotifications() ?? true;
    if (!canScheduleExact && requestPermission) {
      canScheduleExact = await androidImplementation.requestExactAlarmsPermission() ?? false;
    }
    if (canScheduleExact) return AndroidScheduleMode.exactAllowWhileIdle;
    debugPrint("Sin permiso de alarmas exactas: se programa un aviso inexacto.");
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  static Future<void> scheduleDailyNotification(int hour, int minute, {bool requestPermission = true}) async {
    final scheduleMode = await _scheduleMode(requestPermission: requestPermission);

    await _notificationsPlugin.cancel(id: _dailyReminderId);

    try {
      await _notificationsPlugin.zonedSchedule(
        id: _dailyReminderId,
        title: '¡Hora de leer!',
        body: 'Tu racha te espera. Abre un libro y relájate un momento.',
        scheduledDate: _nextInstanceOfTime(hour, minute),
        notificationDetails: const NotificationDetails(
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
        matchDateTimeComponents: DateTimeComponents.time,
        payload: openCurrentBookPayload,
      );
    } catch (e) {
      debugPrint("Error al programar notificación: $e");
    }
  }

  /// Apaga solo el recordatorio diario (el aviso de racha va aparte).
  static Future<void> cancelDailyReminder() => _notificationsPlugin.cancel(id: _dailyReminderId);

  /// Programa el aviso "racha en riesgo" (reemplaza el anterior) o lo cancela
  /// si [alert] es null. No pide permisos: si no hay, no hace nada.
  static Future<void> scheduleStreakRisk(StreakRiskAlert? alert) async {
    try {
      await _notificationsPlugin.cancel(id: _streakRiskId);
      if (alert == null) return;
      if (!await Permission.notification.isGranted) return;

      await _notificationsPlugin.zonedSchedule(
        id: _streakRiskId,
        title: StreakRisk.title(alert.streak),
        body: StreakRisk.body,
        scheduledDate: tz.TZDateTime.from(alert.at, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _streakChannelId,
            _streakChannelName,
            channelDescription: _streakChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(StreakRisk.body),
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
        ),
        androidScheduleMode: await _scheduleMode(requestPermission: false),
        payload: openCurrentBookPayload,
      );
      debugPrint('🔥 Aviso de racha programado: $alert');
    } catch (e) {
      debugPrint('Error programando el aviso de racha: $e');
    }
  }

  /// Programa el aviso "meta de la sesión cumplida" dentro de [inSeconds].
  static Future<void> scheduleSessionGoal({required int minutes, required int inSeconds}) async {
    try {
      await _notificationsPlugin.cancel(id: _sessionGoalId);
      if (!await Permission.notification.isGranted) return;
      await _notificationsPlugin.zonedSchedule(
        id: _sessionGoalId,
        title: '🎯 ¡Meta de $minutes min cumplida!',
        body: 'Puedes seguir leyendo o terminar la sesión y guardar tu página.',
        scheduledDate: tz.TZDateTime.now(tz.local).add(Duration(seconds: inSeconds)),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _sessionChannelId,
            _sessionChannelName,
            channelDescription: _sessionChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
        androidScheduleMode: await _scheduleMode(requestPermission: false),
        payload: openCurrentBookPayload,
      );
    } catch (e) {
      debugPrint('Error programando el aviso de meta de sesión: $e');
    }
  }

  static Future<void> cancelSessionGoal() async {
    try {
      await _notificationsPlugin.cancel(id: _sessionGoalId);
    } catch (e) {
      debugPrint('Error cancelando el aviso de meta de sesión: $e');
    }
  }

  /// Muestra ya el aviso de racha (vista previa en builds de prueba).
  static Future<void> showStreakRiskPreview(int streak) => _notificationsPlugin.show(
        id: 998,
        title: StreakRisk.title(streak),
        body: StreakRisk.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _streakChannelId,
            _streakChannelName,
            channelDescription: _streakChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(StreakRisk.body),
          ),
        ),
        payload: openCurrentBookPayload,
      );

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
      id: 999, // ID único para la prueba
      title: '¡Prueba de Lectura! 📖',
      body: 'Esto es una notificación instantánea para verificar que todo funciona.',
      notificationDetails: notificationDetails,
      payload: 'test_payload',
    );
  }
}
