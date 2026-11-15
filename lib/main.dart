import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:google_mobile_ads/google_mobile_ads.dart'; 

import 'screens/main_wrapper.dart';
import 'screens/login_screen.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'services/widget_service.dart';
import 'services/widget_update_service.dart';
import 'services/widget_action_receiver.dart';
import 'services/deep_link_service.dart'; 

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
    await WidgetService.initialize();
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

class _BookTrackerAppState extends ConsumerState<BookTrackerApp> {
  final _deepLinkService = DeepLinkService();
  final _widgetActionReceiver = WidgetActionReceiver();
  final _widgetUpdateService = WidgetUpdateService();
  String? _pendingRoute;

  @override
  void initState() {
    super.initState();
    _initializeDeepLinks();
    _initializeWidgetActions();
    _initializeWidgetUpdates();
  }

  Future<void> _initializeDeepLinks() async {
    await _deepLinkService.initialize((route) async {
      debugPrint('🔗 Navegando a: $route');
      
      // Guardar la ruta pendiente para navegar cuando sea apropiado
      setState(() {
        _pendingRoute = route;
      });
      
      // Manejar diferentes rutas
      if (route.contains('finish_session')) {
        // Marcar que se debe mostrar la pantalla de resumen
        // Esto será manejado por el MainWrapper
      }
    });
  }

  Future<void> _initializeWidgetActions() async {
    await _widgetActionReceiver.initialize((action) async {
      debugPrint('📱 Widget action recibida en main: $action');
      
      if (action == 'pause_session') {
        debugPrint('⏸ Pausando sesión desde widget');
        // TODO: Pausar la sesión actual
      } else if (action == 'finish_session') {
        debugPrint('✓ Finalizando sesión desde widget');
        // La navegación será manejada por el deep link
      }
    });
  }

  void _initializeWidgetUpdates() {
    debugPrint('⏱️ Inicializando actualización periódica del widget');
    _widgetUpdateService.startPeriodicUpdate();
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    _widgetActionReceiver.dispose();
    _widgetUpdateService.dispose();
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
        ? MainWrapper(pendingRoute: _pendingRoute)
        : LoginScreen(
            onLoginSuccess: () {
              // Cuando el login es exitoso, cambiamos el estado del provider
              ref.read(isAuthenticatedProvider.notifier).state = true;
            },
          ),
    );
  }
}