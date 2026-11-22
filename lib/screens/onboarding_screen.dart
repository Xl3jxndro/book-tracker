import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';

/// Qué eligió el usuario al terminar la bienvenida.
enum OnboardingChoice { addBook, importGoodreads, explore }

class _OnboardingPage {
  final IconData icon;
  final List<IconData> satellites;
  final String title;
  final String subtitle;
  final List<(IconData, String)> points;
  const _OnboardingPage({
    required this.icon,
    required this.satellites,
    required this.title,
    required this.subtitle,
    required this.points,
  });
}

/// Número de pantallas de la bienvenida.
const _pageCount = 4;

/// Pantallas de la bienvenida, con los textos en el idioma en uso.
List<_OnboardingPage> _buildPages(AppLocalizations l10n) => [
      _OnboardingPage(
        icon: Icons.auto_stories_rounded,
        satellites: const [Icons.qr_code_scanner_rounded, Icons.download_rounded],
        title: l10n.onboardingPage1Title,
        subtitle: l10n.onboardingPage1Subtitle,
        points: [
          (Icons.qr_code_scanner_rounded, l10n.onboardingPage1Point1),
          (Icons.search_rounded, l10n.onboardingPage1Point2),
          (Icons.download_rounded, l10n.onboardingPage1Point3),
        ],
      ),
      _OnboardingPage(
        icon: Icons.timer_rounded,
        satellites: const [Icons.flag_rounded, Icons.widgets_rounded],
        title: l10n.onboardingPage2Title,
        subtitle: l10n.onboardingPage2Subtitle,
        points: [
          (Icons.timer_outlined, l10n.onboardingPage2Point1),
          (Icons.flag_outlined, l10n.onboardingPage2Point2),
          (Icons.widgets_outlined, l10n.onboardingPage2Point3),
        ],
      ),
      _OnboardingPage(
        icon: Icons.format_quote_rounded,
        satellites: const [Icons.mic_rounded, Icons.star_rounded],
        title: l10n.onboardingPage3Title,
        subtitle: l10n.onboardingPage3Subtitle,
        points: [
          (Icons.edit_note_rounded, l10n.onboardingPage3Point1),
          (Icons.format_quote_rounded, l10n.onboardingPage3Point2),
          (Icons.rate_review_outlined, l10n.onboardingPage3Point3),
        ],
      ),
      _OnboardingPage(
        icon: Icons.local_fire_department_rounded,
        satellites: const [Icons.emoji_events_rounded, Icons.insights_rounded],
        title: l10n.onboardingPage4Title,
        subtitle: l10n.onboardingPage4Subtitle,
        points: [
          (Icons.local_fire_department_outlined, l10n.onboardingPage4Point1),
          (Icons.emoji_events_outlined, l10n.onboardingPage4Point2),
          (Icons.ios_share_rounded, l10n.onboardingPage4Point3),
        ],
      ),
    ];

/// Bienvenida para usuarios nuevos: 4 pantallas y, al final, por dónde empezar.
class OnboardingScreen extends StatefulWidget {
  final ValueChanged<OnboardingChoice> onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == _pageCount - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    _controller.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  void _finish(OnboardingChoice choice) {
    HapticFeedback.mediumImpact();
    widget.onFinish(choice);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pages = _buildPages(context.l10n);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Saltar (no en la última página, que ya tiene las opciones)
            SizedBox(
              height: 52,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: _isLast ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: _isLast ? null : () => _finish(OnboardingChoice.explore),
                    child: Text(context.l10n.onboardingSkip),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => _PageContent(page: pages[i]),
              ),
            ),
            // Indicador de página
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _page ? scheme.primary : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isLast
                    ? Column(
                        key: const ValueKey('cta'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _finish(OnboardingChoice.addBook),
                              icon: const Icon(Icons.add_rounded),
                              label: Text(context.l10n.homeAddFirstBook),
                              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _finish(OnboardingChoice.importGoodreads),
                              icon: const Icon(Icons.download_rounded),
                              label: Text(context.l10n.onboardingImportGoodreads),
                              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _finish(OnboardingChoice.explore),
                            child: Text(context.l10n.onboardingExploreFirst),
                          ),
                        ],
                      )
                    : SizedBox(
                        key: const ValueKey('next'),
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _next,
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                          child: Text(context.l10n.onboardingNext),
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

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;
  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(builder: (context, constraints) {
      // En pantallas bajas la ilustración se reduce
      final art = (constraints.maxHeight * 0.32).clamp(120.0, 200.0);
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Illustration(page: page, size: art),
              SizedBox(height: art * 0.22),
              Text(page.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text(page.subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              for (final (icon, text) in page.points)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, size: 18, color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}

/// Tarjeta con degradado, icono principal y dos iconos "flotando" alrededor.
class _Illustration extends StatelessWidget {
  final _OnboardingPage page;
  final double size;
  const _Illustration({required this.page, required this.size});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bubble = size * 0.3;

    Widget satellite(IconData icon) => Container(
          width: bubble,
          height: bubble,
          decoration: BoxDecoration(
            color: scheme.surface,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: Icon(icon, color: scheme.primary, size: bubble * 0.48),
        );

    return SizedBox(
      width: size * 1.35,
      height: size * 1.1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [scheme.primary, scheme.tertiary],
              ),
              boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.35), blurRadius: 32, offset: const Offset(0, 14))],
            ),
            child: Icon(page.icon, color: scheme.onPrimary, size: size * 0.46),
          ),
          Positioned(top: 0, right: 0, child: satellite(page.satellites[0])),
          Positioned(bottom: 0, left: 0, child: satellite(page.satellites[1])),
        ],
      ),
    );
  }
}
