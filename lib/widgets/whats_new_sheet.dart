import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

/// Novedades de la versión, para quien actualiza (los usuarios nuevos ven la
/// bienvenida en su lugar). Al publicar otra versión con novedades, cambiar
/// [version] y [items].
class WhatsNew {
  static const version = '1.4.0';
  static const prefsKey = 'whats_new_seen_version';

  static const items = <(IconData, String, String)>[
    (Icons.auto_awesome_rounded, 'Diseño renovado', 'Más limpio y tranquilo, con nuevos colores, tipografía y modo oscuro.'),
    (Icons.palette_outlined, 'Colores de tu teléfono', 'En Ajustes > Colores puedes usar la paleta de tu fondo de pantalla.'),
    (Icons.play_circle_outline_rounded, 'Continuar leyendo', 'Tu libro actual arriba de la biblioteca: retoma la sesión en un toque.'),
    (Icons.grid_view_rounded, 'Lista o cuadrícula', 'Elige cómo ver tu biblioteca y filtra por estado o categoría.'),
    (Icons.swipe_rounded, 'Desliza para actuar', 'A la derecha: empezar o terminar un libro, con Deshacer. A la izquierda: borrar.'),
    (Icons.menu_book_rounded, 'Detalle del libro', 'Rediseñado, con tu ritmo, lo que falta y tus notas como citas.'),
    (Icons.insights_rounded, 'Estadísticas en mosaico', 'Racha, tu mejor racha y la semana de un vistazo.'),
    (Icons.arrow_back_rounded, 'Gesto atrás', 'Desliza para volver y mira a dónde vas; "atrás" vuelve a Libros antes de salir.'),
  ];

  /// ¿Hay que mostrarlas? Solo una vez por versión.
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(prefsKey) != version;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, version);
  }

  /// Las muestra si no se han visto en esta versión.
  static Future<void> showIfNeeded(BuildContext context) async {
    if (!await shouldShow() || !context.mounted) return;
    await markSeen();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WhatsNewSheet(),
    );
  }
}

class WhatsNewSheet extends StatelessWidget {
  const WhatsNewSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.cs.outline, borderRadius: BorderRadius.circular(10))),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                children: [
                  Text('NOVEDADES · ${WhatsNew.version}',
                      style: theme.textTheme.labelMedium?.copyWith(color: context.app.accentText, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Text('Lo nuevo en Book Tracker',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  for (final (icon, title, text) in WhatsNew.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: context.app.accentSoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(icon, size: 20, color: context.app.accentText),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.3)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: const Text('Empezar'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
