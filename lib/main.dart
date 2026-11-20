import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/main_wrapper.dart';
import 'screens/login_screen.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/database_provider.dart';
import 'providers/current_book_provider.dart';
import 'providers/daily_goal_provider.dart';
import 'providers/widget_action_provider.dart';
import 'providers/streak_risk_provider.dart';
import 'providers/streak_save_provider.dart';
import 'providers/today_provider.dart';
import 'services/notification_service.dart';
import 'services/ads_consent.dart';
import 'services/ads_gate.dart';
import 'services/remove_ads.dart';
import 'services/home_widget_sync.dart';
import 'services/session_goal_alarm.dart';
import 'widgets/app_lock_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationService.init();
    // Corrige recordatorios ya programados (antes se programaban en UTC)
    await NotificationService.rescheduleIfEnabled();
    // Botón PAUSAR/REANUDAR del widget (se ejecuta sin abrir la app)
    await HomeWidget.registerInteractivityCallback(homeWidgetBackgroundCallback);
    await initializeDateFormatting('es_ES', null);
    await initializeDateFormatting('es', null);
  } catch (e) {
    debugPrint("Error durante el arranque: $e");
  }

  // Anuncios visibles = consentimiento y sin la compra "Quitar anuncios"
  AdsGate.init();

  runApp(
    ProviderScope(
      // Sin reintentos automáticos (Riverpod 3): los errores ya se manejan en cada provider
      retry: (_, _) => null,
      child: const BookTrackerApp(),
    ),
  );

  // Consentimiento de anuncios (formulario de Google solo donde se exige) y,
  // después, AdMob. No retrasa el arranque.
  unawaited(AdsConsent.initialize());
  // Compra "Quitar anuncios": estado guardado y restauración silenciosa
  unawaited(RemoveAds.instance.initialize());
}

class BookTrackerApp extends ConsumerStatefulWidget {
  const BookTrackerApp({super.key});

  @override
  ConsumerState<BookTrackerApp> createState() => _BookTrackerAppState();
}

class _BookTrackerAppState extends ConsumerState<BookTrackerApp> with WidgetsBindingObserver {
  StreamSubscription<Uri?>? _widgetClickSubscription;
  StreamSubscription<String?>? _notificationTapSubscription;

  /// Ya se entró a la app en esta ejecución. A partir de entonces, si se
  /// vuelve a bloquear (por estar fuera), el login se muestra encima sin
  /// desmontar la app: al desbloquear se sigue en la misma pantalla.
  bool _hasEnteredApp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initHomeWidget();
    _initNotificationTaps();
    _initStreakRisk();
  }

  /// Aviso "racha en riesgo": se reprograma al leer, al cambiar el ajuste o
  /// el día, y al volver a la app.
  void _initStreakRisk() {
    void sync(_, _) => StreakRiskSync.sync(ref.read);
    ref.listenManual(sessionsStreamProvider, sync);
    ref.listenManual(streakRiskProvider, sync);
    ref.listenManual(streakSaveProvider, sync); // al salvar una racha
    ref.listenManual(todayProvider, sync);
  }

  /// Tocar el recordatorio diario abre el libro actual (en frío o con la app
  /// abierta). Usa la misma acción pendiente que el widget, que espera al login.
  void _initNotificationTaps() {
    NotificationService.launchPayload().then((payload) {
      if (payload != null) _handleNotificationPayload(payload);
    });
    _notificationTapSubscription = NotificationService.taps.listen(_handleNotificationPayload);
  }

  Future<void> _handleNotificationPayload(String? payload) async {
    if (!NotificationService.opensCurrentBook(payload)) return;
    final book = await HomeWidgetSync.currentBook(ref.read(databaseProvider));
    if (book == null || !mounted) return; // sin libros: solo se abre la app
    ref.read(pendingWidgetActionProvider.notifier).set(
        WidgetAction(bookId: book.id, finishSession: false));
  }

  void _initHomeWidget() {
    HomeWidgetSync.attach(ref.read(databaseProvider));

    // Cualquier cambio que se vea en el widget dispara una actualización
    void refresh(_, _) => HomeWidgetSync.refresh();
    ref.listenManual(booksStreamProvider, refresh);
    ref.listenManual(sessionsStreamProvider, refresh);
    ref.listenManual(currentBookProvider, refresh);
    ref.listenManual(dailyGoalProvider, refresh);
    HomeWidgetSync.refresh();

    // Toques en el widget que abren la app (en frío o ya abierta)
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetUri).catchError((e) {
      debugPrint('Error leyendo lanzamiento desde el widget: $e');
    });
    _widgetClickSubscription = HomeWidget.widgetClicked.listen(
      _handleWidgetUri,
      onError: (e) => debugPrint('Error en clics del widget: $e'),
    );
  }

  void _handleWidgetUri(Uri? uri) {
    final action = WidgetAction.fromUri(uri);
    if (action != null && mounted) {
      ref.read(pendingWidgetActionProvider.notifier).set(action);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final auth = ref.read(authProvider.notifier);
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        auth.appBackgrounded();
        // Fuera de la app, la meta de la sesión se avisa con una notificación
        SessionGoalAlarm.sync();
      case AppLifecycleState.resumed:
        // "Bloquear al salir" y, además, el widget pudo pausar o cambió el día
        auth.appResumed();
        HomeWidgetSync.refresh();
        // Con la app abierta avisa la pantalla del cronómetro
        NotificationService.cancelSessionGoal();
        ref.invalidate(notificationPermissionProvider);
        StreakRiskSync.sync(ref.read);
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _widgetClickSubscription?.cancel();
    _notificationTapSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeProvider);
    final auth = ref.watch(authProvider);
    if (auth.canEnterApp) _hasEnteredApp = true;
    final isRelocked = _hasEnteredApp && !auth.isLoading && !auth.canEnterApp;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Book Tracker',
      themeMode: mode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,

      // Lógica de enrutamiento principal:
      home: auth.isLoading
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : ((auth.canEnterApp || _hasEnteredApp) ? const MainWrapper() : const LoginScreen()),

      // Bloqueo al volver a la app: login por encima de todo (incluidas las
      // pantallas abiertas), sin desmontar la app.
      builder: (context, child) =>
          // Puente temporal de material_ui: librerías que aún usan
          // package:flutter/material.dart (tooltips del tutorial, tarjeta de
          // "Mi año lector") reciben el tema de la app. Quitar cuando migren.
          // ignore: deprecated_member_use
          MaterialUiCompatibilityBridge(
        child: AppLockOverlay(
          isLocked: isRelocked,
          lockScreenBuilder: (_) => const LoginScreen(),
          child: child!,
        ),
      ),
    );
  }
}
