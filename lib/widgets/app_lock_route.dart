import 'package:material_ui/material_ui.dart';

import '../services/app_navigation.dart';

/// Muestra la pantalla de bloqueo como una pantalla más de la navegación
/// principal, por encima de donde estaba el usuario, cuando la app se vuelve
/// a bloquear al regresar.
///
/// Al ser una ruta del mismo Navigator (y no una capa aparte):
/// - "Atrás" (gesto o botón de Android) llega primero a ella: no deja
///   retroceder y minimiza la app, sin cerrar las pantallas de detrás.
/// - Al desbloquear se quita y se sigue exactamente donde se estaba.
class AppLockRouteController {
  Route<void>? _route;

  bool get isShowing => _route != null;

  /// Pone o quita la pantalla de bloqueo según [locked]. Se puede llamar en
  /// cada cambio: solo actúa si el estado cambió.
  void sync({
    required NavigatorState? navigator,
    required bool locked,
    required WidgetBuilder lockScreenBuilder,
  }) {
    if (navigator == null) return;

    if (locked && _route == null) {
      final route = _buildRoute(lockScreenBuilder);
      _route = route;
      navigator.push(route);
    } else if (!locked && _route != null) {
      final route = _route!;
      _route = null;
      if (route.isActive) navigator.removeRoute(route);
    }
  }

  static Route<void> _buildRoute(WidgetBuilder lockScreenBuilder) {
    return PageRouteBuilder<void>(
      opaque: true,
      // Aparece al instante: la app no debe asomarse al volver
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      settings: const RouteSettings(name: '/bloqueo'),
      pageBuilder: (context, _, _) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) AppNavigation.moveToBackground();
        },
        child: lockScreenBuilder(context),
      ),
    );
  }
}
