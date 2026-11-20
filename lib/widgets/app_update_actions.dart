import 'package:material_ui/material_ui.dart';

import '../services/app_update.dart';
import '../theme/app_colors.dart';

/// Aviso flotante por encima de la barra de navegación.
void _snack(BuildContext context, String text, {SnackBarAction? action, Duration duration = const Duration(seconds: 4)}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text),
      action: action,
      duration: duration,
      margin: EdgeInsets.fromLTRB(16, 0, 16, 64 + 24 + 12 + MediaQuery.of(context).padding.bottom),
    ));
}

/// "Hay una versión nueva": se muestra una vez por versión al abrir la app.
Future<void> showUpdatePrompt(BuildContext context) async {
  final update = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const UpdatePromptSheet(),
  );
  if (update == true && context.mounted) await startAppUpdate(context);
}

/// Descarga la versión nueva mientras se sigue usando la app y, al terminar,
/// ofrece reiniciar para instalarla.
Future<void> startAppUpdate(BuildContext context) async {
  await AppUpdate.start();
  if (context.mounted && AppUpdate.status.value == UpdateStatus.downloaded) offerInstall(context);
}

/// La versión nueva ya está descargada: reiniciar para instalarla.
void offerInstall(BuildContext context) {
  _snack(
    context,
    'Actualización descargada',
    duration: const Duration(days: 1),
    action: SnackBarAction(label: 'Reiniciar', onPressed: AppUpdate.install),
  );
}

/// "Buscar actualizaciones" desde Ajustes.
Future<void> checkForUpdatesManually(BuildContext context) async {
  switch (AppUpdate.status.value) {
    case UpdateStatus.available:
      return showUpdatePrompt(context);
    case UpdateStatus.downloaded:
      return offerInstall(context);
    case UpdateStatus.downloading:
      return _snack(context, 'Descargando la versión nueva…');
    default:
      break;
  }
  final status = await AppUpdate.check();
  if (!context.mounted) return;
  switch (status) {
    case UpdateStatus.available:
      await showUpdatePrompt(context);
    case UpdateStatus.downloaded:
      offerInstall(context);
    case UpdateStatus.upToDate:
      _snack(context, 'Tienes la última versión');
    default:
      _snack(context, 'No se pudo comprobar. Las actualizaciones llegan desde Google Play.');
  }
}

class UpdatePromptSheet extends StatelessWidget {
  const UpdatePromptSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.app;
    return Container(
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: context.cs.outline, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: app.accentSoft, borderRadius: BorderRadius.circular(18)),
                child: Icon(Icons.system_update_rounded, color: app.accentText, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Hay una versión nueva', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Actualiza para tener las últimas mejoras. Se descarga mientras sigues usando la app.',
                style: theme.textTheme.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant, height: 1.35),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: const Text('Actualizar'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: const Text('Ahora no'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
