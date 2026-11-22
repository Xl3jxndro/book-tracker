import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

/// Notas de una versión publicada.
class ReleaseNotes {
  final String version;
  final List<(IconData, String, String)> items;
  const ReleaseNotes(this.version, this.items);
}

/// Novedades de la versión, para quien actualiza (los usuarios nuevos ven la
/// bienvenida en su lugar) y, en Ajustes, el historial de versiones. Al
/// publicar otra versión con novedades, añadirla al principio de [history].
class WhatsNew {
  static const prefsKey = 'whats_new_seen_version';

  static const history = <ReleaseNotes>[
    ReleaseNotes('1.4.1', [
      (Icons.document_scanner_outlined, 'Citas con la cámara', 'Fotografía una página y subraya con el dedo la frase que quieres guardar. Con zoom y lupa para más precisión.'),
      (Icons.lock_outline_rounded, 'Todo en tu teléfono', 'El texto se reconoce en tu dispositivo: la foto no se envía a ningún sitio.'),
      (Icons.calendar_month_rounded, 'Calendario de lectura', 'Cada día coloreado según cuánto leíste. Toca un día para ver qué libros leíste.'),
      (Icons.bar_chart_rounded, 'Gráfico mensual más claro', 'Escala redonda y barras que nacen en el cero.'),
    ]),
    ReleaseNotes('1.4.0', [
      (Icons.auto_awesome_rounded, 'Diseño renovado', 'Más limpio y tranquilo, con nuevos colores, tipografía y modo oscuro.'),
      (Icons.palette_outlined, 'Colores de tu teléfono', 'En Ajustes > Colores puedes usar la paleta de tu fondo de pantalla.'),
      (Icons.play_circle_outline_rounded, 'Continuar leyendo', 'Tu libro actual arriba de la biblioteca: retoma la sesión en un toque.'),
      (Icons.grid_view_rounded, 'Lista o cuadrícula', 'Elige cómo ver tu biblioteca y filtra por estado o categoría.'),
      (Icons.swipe_rounded, 'Desliza para actuar', 'A la derecha: empezar o terminar un libro, con Deshacer. A la izquierda: borrar.'),
      (Icons.menu_book_rounded, 'Detalle del libro', 'Rediseñado, con tu ritmo, lo que falta y tus notas como citas.'),
      (Icons.insights_rounded, 'Estadísticas en mosaico', 'Racha, tu mejor racha y la semana de un vistazo.'),
      (Icons.arrow_back_rounded, 'Gesto atrás', 'Desliza para volver y mira a dónde vas; "atrás" vuelve a Libros antes de salir.'),
      (Icons.system_update_rounded, 'Avisos de actualización', 'Te avisamos cuando haya una versión nueva y la instalas sin salir de la app.'),
      (Icons.new_releases_outlined, 'Notas de la versión', 'Consulta las novedades cuando quieras en Ajustes > Novedades.'),
    ]),
    ReleaseNotes('1.3.0', [
      (Icons.bolt_rounded, 'Más rápida y ligera', 'La app ocupa menos y abre antes.'),
      (Icons.shield_outlined, 'Más segura', 'Tu palabra secreta se guarda con el almacenamiento seguro más reciente.'),
      (Icons.receipt_long_rounded, 'Compras más fiables', '"Quitar anuncios" reconoce mejor las compras pendientes y los reembolsos.'),
    ]),
    ReleaseNotes('1.2.1', [
      (Icons.block_rounded, 'Quitar anuncios', 'Un único pago para usar la app sin anuncios, para siempre.'),
    ]),
    ReleaseNotes('1.2.0', [
      (Icons.qr_code_scanner_rounded, 'Escáner de ISBN', 'Añade un libro escaneando su código de barras o escribiendo el ISBN.'),
      (Icons.format_quote_rounded, 'Mis citas', 'Todas tus notas en un lugar: búscalas, marca favoritas y compártelas.'),
      (Icons.emoji_events_rounded, 'Reto anual y fechas', 'Fechas de inicio y fin de cada libro y tu meta de libros del año.'),
      (Icons.flag_rounded, 'Meta por sesión', 'Elige 15–60 min o una página y te aviso al cumplirla.'),
      (Icons.rate_review_rounded, 'Reseñas', 'Califica y reseña al terminar un libro (o cuando quieras).'),
      (Icons.local_fire_department_rounded, 'Racha en riesgo', 'Un aviso por la noche si aún no has leído y llevas racha.'),
      (Icons.widgets_rounded, 'Widget renovado', 'Con la portada de tu libro y pausa en un toque.'),
      (Icons.ios_share_rounded, 'Mi año lector', 'Comparte una tarjeta con tus estadísticas del año.'),
      (Icons.download_rounded, 'Goodreads y respaldos', 'Importa tu biblioteca de Goodreads y guarda una copia completa con portadas.'),
    ]),
  ];

  static String get version => history.first.version;
  static List<(IconData, String, String)> get items => history.first.items;

  /// Todas las notas, de la más reciente a la más antigua (desde Ajustes).
  static Future<void> showHistory(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const WhatsNewSheet(showHistory: true),
      );

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
  /// Todas las versiones (Ajustes) en vez de solo la última.
  final bool showHistory;
  const WhatsNewSheet({super.key, this.showHistory = false});

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
                  if (showHistory) ...[
                    Text('Notas de la versión', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text('Lo que ha cambiado en cada versión de Book Tracker.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                    for (final (i, release) in WhatsNew.history.indexed) ...[
                      SizedBox(height: i == 0 ? 20 : 28),
                      _versionLabel(context, release.version, latest: i == 0),
                      const SizedBox(height: 8),
                      for (final item in release.items) _item(context, item),
                    ],
                  ] else ...[
                    _versionLabel(context, WhatsNew.version),
                    const SizedBox(height: 6),
                    Text('Lo nuevo en Book Tracker', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 20),
                    for (final item in WhatsNew.items) _item(context, item),
                  ],
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
                    child: Text(showHistory ? 'Cerrar' : 'Empezar'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _versionLabel(BuildContext context, String version, {bool latest = true}) => Text(
        latest ? 'NOVEDADES · $version' : 'VERSIÓN $version',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: latest ? context.app.accentText : context.cs.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
      );

  Widget _item(BuildContext context, (IconData, String, String) item) {
    final (icon, title, text) = item;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: context.app.accentSoft, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, size: 20, color: context.app.accentText),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
