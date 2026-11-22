import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/l10n.dart';
import '../services/app_language.dart';
import '../theme/app_colors.dart';

/// Notas de una versión publicada.
class ReleaseNotes {
  final String version;
  final List<(IconData, String, String)> items;
  const ReleaseNotes(this.version, this.items);
}

/// Novedades de la versión, para quien actualiza (los usuarios nuevos ven la
/// bienvenida en su lugar) y, en Ajustes, el historial de versiones. Al
/// publicar otra versión con novedades, añadirla al principio de [historyFor].
class WhatsNew {
  static const prefsKey = 'whats_new_seen_version';

  /// Todas las notas, de la más reciente a la más antigua, en el idioma de [l].
  static List<ReleaseNotes> historyFor(AppLocalizations l) => [
        ReleaseNotes('1.4.2', [
          (Icons.translate_rounded, l.whatsNew142EnglishTitle, l.whatsNew142EnglishText),
          (Icons.language_rounded, l.whatsNew142LanguageTitle, l.whatsNew142LanguageText),
          (Icons.spellcheck_rounded, l.whatsNew142PluralsTitle, l.whatsNew142PluralsText),
          (Icons.auto_awesome_rounded, l.whatsNew142IconTitle, l.whatsNew142IconText),
        ]),
        ReleaseNotes('1.4.1', [
          (Icons.document_scanner_outlined, l.whatsNew141CameraQuotesTitle, l.whatsNew141CameraQuotesText),
          (Icons.lock_outline_rounded, l.whatsNew141OnDeviceTitle, l.whatsNew141OnDeviceText),
          (Icons.calendar_month_rounded, l.whatsNew141CalendarTitle, l.whatsNew141CalendarText),
          (Icons.bar_chart_rounded, l.whatsNew141MonthlyChartTitle, l.whatsNew141MonthlyChartText),
        ]),
        ReleaseNotes('1.4.0', [
          (Icons.auto_awesome_rounded, l.whatsNew140RedesignTitle, l.whatsNew140RedesignText),
          (Icons.palette_outlined, l.whatsNew140PhoneColorsTitle, l.whatsNew140PhoneColorsText),
          (Icons.play_circle_outline_rounded, l.whatsNew140ContinueReadingTitle, l.whatsNew140ContinueReadingText),
          (Icons.grid_view_rounded, l.whatsNew140ListGridTitle, l.whatsNew140ListGridText),
          (Icons.swipe_rounded, l.whatsNew140SwipeTitle, l.whatsNew140SwipeText),
          (Icons.menu_book_rounded, l.whatsNew140BookDetailTitle, l.whatsNew140BookDetailText),
          (Icons.insights_rounded, l.whatsNew140StatsTilesTitle, l.whatsNew140StatsTilesText),
          (Icons.arrow_back_rounded, l.whatsNew140BackGestureTitle, l.whatsNew140BackGestureText),
          (Icons.system_update_rounded, l.whatsNew140UpdateAlertsTitle, l.whatsNew140UpdateAlertsText),
          (Icons.new_releases_outlined, l.whatsNew140ReleaseNotesTitle, l.whatsNew140ReleaseNotesText),
        ]),
        ReleaseNotes('1.3.0', [
          (Icons.bolt_rounded, l.whatsNew130FasterTitle, l.whatsNew130FasterText),
          (Icons.shield_outlined, l.whatsNew130SaferTitle, l.whatsNew130SaferText),
          (Icons.receipt_long_rounded, l.whatsNew130PurchasesTitle, l.whatsNew130PurchasesText),
        ]),
        ReleaseNotes('1.2.1', [
          (Icons.block_rounded, l.whatsNew121RemoveAdsTitle, l.whatsNew121RemoveAdsText),
        ]),
        ReleaseNotes('1.2.0', [
          (Icons.qr_code_scanner_rounded, l.whatsNew120IsbnScannerTitle, l.whatsNew120IsbnScannerText),
          (Icons.format_quote_rounded, l.whatsNew120MyQuotesTitle, l.whatsNew120MyQuotesText),
          (Icons.emoji_events_rounded, l.whatsNew120ChallengeTitle, l.whatsNew120ChallengeText),
          (Icons.flag_rounded, l.whatsNew120SessionGoalTitle, l.whatsNew120SessionGoalText),
          (Icons.rate_review_rounded, l.whatsNew120ReviewsTitle, l.whatsNew120ReviewsText),
          (Icons.local_fire_department_rounded, l.whatsNew120StreakRiskTitle, l.whatsNew120StreakRiskText),
          (Icons.widgets_rounded, l.whatsNew120WidgetTitle, l.whatsNew120WidgetText),
          (Icons.ios_share_rounded, l.whatsNew120ReadingYearTitle, l.whatsNew120ReadingYearText),
          (Icons.download_rounded, l.whatsNew120GoodreadsTitle, l.whatsNew120GoodreadsText),
        ]),
      ];

  /// Las notas en el idioma en uso (código sin pantalla y pruebas).
  static List<ReleaseNotes> get history => historyFor(AppLanguage.strings);

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
    final l = context.l10n;
    final history = WhatsNew.historyFor(l);
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
                    Text(l.whatsNewTitle, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(l.whatsNewHistorySubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                    for (final (i, release) in history.indexed) ...[
                      SizedBox(height: i == 0 ? 20 : 28),
                      _versionLabel(context, release.version, latest: i == 0),
                      const SizedBox(height: 8),
                      for (final item in release.items) _item(context, item),
                    ],
                  ] else ...[
                    _versionLabel(context, history.first.version),
                    const SizedBox(height: 6),
                    Text(l.whatsNewHeadline, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 20),
                    for (final item in history.first.items) _item(context, item),
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
                    child: Text(showHistory ? l.commonClose : l.whatsNewStart),
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
        latest ? context.l10n.whatsNewLatestLabel(version) : context.l10n.whatsNewVersionLabel(version),
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
