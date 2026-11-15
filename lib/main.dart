import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'screens/main_wrapper.dart';
import 'screens/login_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/database_provider.dart';
import 'providers/current_book_provider.dart';
import 'providers/daily_goal_provider.dart';
import 'providers/widget_action_provider.dart';
import 'services/notification_service.dart';
import 'services/home_widget_sync.dart';

// Este provider gestiona si el usuario ha iniciado sesión en la sesión actual
final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    MobileAds.instance.initialize().then((status) {
       debugPrint("AdMob Inicializado: ${status.adapterStatuses}");
    });

    RequestConfiguration configuration = RequestConfiguration(
      testDeviceIds: ["D2D801BFADE21CEF306FB5FA0E21324F"],
    );
    MobileAds.instance.updateRequestConfiguration(configuration);

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

  runApp(
    const ProviderScope(
      child: BookTrackerApp(),
    ),
  );
}

class BookTrackerApp extends ConsumerStatefulWidget {
  const BookTrackerApp({super.key});

  @override
  ConsumerState<BookTrackerApp> createState() => _BookTrackerAppState();
}

class _BookTrackerAppState extends ConsumerState<BookTrackerApp> with WidgetsBindingObserver {
  StreamSubscription<Uri?>? _widgetClickSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initHomeWidget();
  }

  void _initHomeWidget() {
    HomeWidgetSync.attach(ref.read(databaseProvider));

    // Cualquier cambio que se vea en el widget dispara una actualización
    void refresh(_, __) => HomeWidgetSync.refresh();
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
      ref.read(pendingWidgetActionProvider.notifier).state = action;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver a la app: el widget pudo pausar/reanudar o cambió el día
    if (state == AppLifecycleState.resumed) HomeWidgetSync.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _widgetClickSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    final lightScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
    );

    final darkScheme = ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Book Tracker',
      themeMode: mode,
      theme: ref.watch(appThemeProvider(lightScheme)),
      darkTheme: ref.watch(appThemeProvider(darkScheme)),

      // Lógica de enrutamiento principal:
      home: isAuthenticated
        ? const MainWrapper()
        : LoginScreen(
            onLoginSuccess: () {
              // Cuando el login es exitoso, cambiamos el estado del provider
              ref.read(isAuthenticatedProvider.notifier).state = true;
            },
          ),
    );
  }
}
