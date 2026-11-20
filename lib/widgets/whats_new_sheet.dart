import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

/// Novedades de la versión, para quien actualiza (los usuarios nuevos ven la
/// bienvenida en su lugar). Al publicar otra versión con novedades, cambiar
/// [version] y [items].
class WhatsNew {
  static const version = '1.2.0';
  static const prefsKey = 'whats_new_seen_version';

  static const items = <(IconData, String, String)>[
    (Icons.qr_code_scanner_rounded, 'Escáner de ISBN', 'Añade un libro escaneando su código de barras o escribiendo el ISBN.'),
    (Icons.format_quote_rounded, 'Mis citas', 'Todas tus notas en un lugar: búscalas, marca favoritas y compártelas.'),
    (Icons.emoji_events_rounded, 'Reto anual y fechas', 'Fechas de inicio y fin de cada libro y tu meta de libros del año.'),
    (Icons.flag_rounded, 'Meta por sesión', 'Elige 15–60 min o una página y te aviso al cumplirla.'),
    (Icons.rate_review_rounded, 'Reseñas', 'Califica y reseña al terminar un libro (o cuando quieras).'),
    (Icons.local_fire_department_rounded, 'Racha en riesgo', 'Un aviso por la noche si aún no has leído y llevas racha.'),
    (Icons.widgets_rounded, 'Widget renovado', 'Con la portada de tu libro y pausa en un toque.'),
    (Icons.ios_share_rounded, 'Mi año lector', 'Comparte una tarjeta con tus estadísticas del año.'),
    (Icons.download_rounded, 'Goodreads y respaldos', 'Importa tu biblioteca de Goodreads y guarda una copia completa con portadas.'),
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
                      style: theme.textTheme.labelMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  const SizedBox(height: 6),
                  Text('Lo nuevo en Book Tracker',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
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
                              color: scheme.primaryContainer.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(icon, size: 20, color: scheme.onPrimaryContainer),
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
                    child: const Text('¡Genial!'),
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
