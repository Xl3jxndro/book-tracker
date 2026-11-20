import 'package:material_ui/material_ui.dart';

/// Muestra la pantalla de bloqueo por encima de toda la app sin desmontarla,
/// para que al desbloquear se siga en la misma pantalla.
class AppLockOverlay extends StatelessWidget {
  final bool isLocked;
  final Widget child;
  final WidgetBuilder lockScreenBuilder;

  const AppLockOverlay({
    super.key,
    required this.isLocked,
    required this.child,
    required this.lockScreenBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLocked)
          Positioned.fill(
            // El login necesita su propio Navigator (para sus diálogos), pero
            // NO debe quedarse con el HeroController de la app: solo puede
            // pertenecer a un Navigator y, al quitarse el bloqueo, el principal
            // se quedaba sin él (no abrían diálogos ni se podía volver atrás).
            child: HeroControllerScope.none(
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute(builder: lockScreenBuilder),
              ),
            ),
          ),
      ],
    );
  }
}
