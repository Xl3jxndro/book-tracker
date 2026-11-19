import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../providers/ui_provider.dart';
import '../providers/tutorial_provider.dart';
import '../providers/database_provider.dart';
import '../providers/current_book_provider.dart';
import '../providers/widget_action_provider.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'book_details_screen.dart';
import 'onboarding_screen.dart';
import '../widgets/add_book_sheet.dart';
import '../widgets/goodreads_import_actions.dart';
import '../widgets/whats_new_sheet.dart';
import '../widgets/streak_save_sheet.dart';
import '../providers/streak_save_provider.dart';
import '../services/ads_consent.dart';
import '../services/ads_gate.dart';
import '../services/streak_save.dart';
import 'package:flutter/services.dart';

class MainWrapper extends ConsumerStatefulWidget {
  const MainWrapper({super.key});

  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper> {
  int _currentIndex = 0;
  bool _isTutorialProcessing = false; 

  /// La bienvenida ya se cerró (mientras corre la acción elegida al final).
  bool _onboardingHidden = false;
  bool _whatsNewChecked = false;
  
  final GlobalKey _statsKey = GlobalKey(debugLabel: 'stats_nav_item');
  final GlobalKey _settingsKey = GlobalKey(debugLabel: 'settings_nav_item');

  final List<Widget> _pages = [
    const HomeScreen(),
    const StatsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // Acciones del widget de pantalla de inicio (incluida la que llegó antes del login)
    ref.listenManual<WidgetAction?>(
      pendingWidgetActionProvider,
      (_, action) {
        if (action == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) => _handleWidgetAction(action));
      },
      fireImmediately: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final tutorialState = ref.read(tutorialProvider);
        _checkAndTriggerTutorial(tutorialState.stage);
      }
    });

    // Novedades de la versión para quien actualiza (ya vio los tooltips de la
    // biblioteca y la barra); los usuarios nuevos ven la bienvenida
    ref.listenManual<TutorialState>(tutorialProvider, (_, state) {
      if (_whatsNewChecked) return;
      if (state.stage == TutorialStage.bookDetails || state.stage == TutorialStage.completed) {
        _whatsNewChecked = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await WhatsNew.showIfNeeded(context);
          // Después de las novedades (para no encimarse): ¿salvar la racha?
          await _maybeOfferStreakSave();
        });
      }
    }, fireImmediately: true);
  }

  /// Si ayer se rompió una racha, ofrece recuperarla con un anuncio recompensado.
  Future<void> _maybeOfferStreakSave() async {
    try {
      final sessions = await ref.read(sessionsStreamProvider.future);
      await ref.read(streakSaveProvider.notifier).ready;
      // Al abrir en frío, el permiso de anuncios tarda un momento en confirmarse
      // (con "Quitar anuncios" no hace falta: se salva sin anuncio)
      for (var i = 0; i < 16 && !AdsConsent.canRequestAds.value && !AdsGate.adsRemoved; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      if (!mounted || (!AdsConsent.canRequestAds.value && !AdsGate.adsRemoved)) return;
      final saves = ref.read(streakSaveProvider);
      final offer = StreakSave.offer(
        readingDates: sessions.map((s) => s.date),
        savedDays: saves.savedDays,
        now: DateTime.now(),
        lastSaveAt: saves.lastSaveAt,
        dismissedOn: saves.dismissedOn,
      );
      if (offer != null && mounted) await showStreakSaveSheet(context, offer);
    } catch (e) {
      debugPrint('Oferta de salvar racha: $e');
    }
  }

  /// Fin de la bienvenida: hace lo elegido y después siguen los tooltips.
  Future<void> _onOnboardingFinish(OnboardingChoice choice) async {
    // A la biblioteca: ahí empiezan los tooltips
    setState(() {
      _onboardingHidden = true;
      _currentIndex = 0;
    });
    _whatsNewChecked = true;
    await WhatsNew.markSeen(); // las novedades ya las contó la bienvenida

    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    switch (choice) {
      case OnboardingChoice.addBook:
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AddBookSheet(),
        );
      case OnboardingChoice.importGoodreads:
        await importFromGoodreads(context, ref);
      case OnboardingChoice.explore:
        break;
    }
    await ref.read(tutorialProvider.notifier).completeOnboarding();
  }

  /// Abre el libro pedido desde el widget; con `finishSession` muestra además
  /// el diálogo para terminar la sesión y guardar las páginas.
  Future<void> _handleWidgetAction(WidgetAction action) async {
    if (!mounted) return;
    ref.read(pendingWidgetActionProvider.notifier).state = null;

    final db = ref.read(databaseProvider);
    final book = await (db.select(db.books)..where((t) => t.id.equals(action.bookId))).getSingleOrNull();
    if (book == null || !mounted) return;

    ref.read(currentBookProvider.notifier).setCurrentBook(book.id);
    setState(() => _currentIndex = 0);

    // Cerramos lo que hubiera abierto (otro libro, diálogos) para no tener
    // dos cronómetros del mismo libro a la vez.
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    navigator.push(
      MaterialPageRoute(
        builder: (_) => BookDetailsScreen(book: book, autoFinishSession: action.finishSession),
      ),
    );
  }

  void _checkAndTriggerTutorial(TutorialStage stage) {
    if (stage != TutorialStage.navigation || _isTutorialProcessing) return;

    _isTutorialProcessing = true;
    
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;

      final statsContext = _statsKey.currentContext;
      final settingsContext = _settingsKey.currentContext;

      if (statsContext == null || settingsContext == null) {
        _isTutorialProcessing = false;
        return;
      }

      _showNavTutorial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // 1. OBTENEMOS EL ESPACIO DE LA BARRA DEL SISTEMA (Botones o Gestos)
    final double systemBottomPadding = MediaQuery.of(context).padding.bottom;

    ref.listen<TutorialState>(tutorialProvider, (previous, next) {
      // "Ver la bienvenida de nuevo" (Ajustes): se vuelve a mostrar
      if (next.stage == TutorialStage.onboarding && previous?.stage != TutorialStage.onboarding) {
        setState(() => _onboardingHidden = false);
      }
      if (next.stage == TutorialStage.navigation) {
        _checkAndTriggerTutorial(next.stage);
      }
    });

    final tutorialData = ref.watch(tutorialProvider);
    if (tutorialData.stage == TutorialStage.onboarding && !_onboardingHidden) {
      return OnboardingScreen(onFinish: _onOnboardingFinish);
    }
    // Durante los tooltips de la biblioteca y de la barra, la barra se ve siempre
    final bool isNavTutorialPhase =
        tutorialData.stage == TutorialStage.navigation || tutorialData.stage == TutorialStage.home;
    final isVisible = ref.watch(navBarVisibleProvider) || isNavTutorialPhase;

    // 2. ALTURA DINÁMICA: 68 (nav) + 25 (margen) + espacio del sistema
    final double totalNavHeight = isVisible ? (68 + 25 + systemBottomPadding) : 0;

    return Scaffold(
      // Mantenemos extendBody para el efecto Blur detrás de la barra
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is UserScrollNotification && !isNavTutorialPhase) {
            if (notification.direction == ScrollDirection.reverse) {
              if (isVisible) ref.read(navBarVisibleProvider.notifier).state = false;
            } else if (notification.direction == ScrollDirection.forward) {
              if (!isVisible) ref.read(navBarVisibleProvider.notifier).state = true;
            }
          }
          return false; 
        },
        child: IndexedStack(
          index: _currentIndex, 
          children: _pages,
        ),
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        height: totalNavHeight, 
        // Usamos SingleChildScrollView para evitar que los iconos "choquen" al cerrarse la barra
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isVisible ? 1.0 : 0.0,
            child: _buildModernNav(isDark, theme, systemBottomPadding),
          ),
        ),
      ),
    );
  }

  Widget _buildModernNav(bool isDark, ThemeData theme, double systemPadding) {
    return Container(
      height: 68, 
      // Aplicamos el margen inferior sumando el padding del sistema
      margin: EdgeInsets.fromLTRB(24, 0, 24, 25 + systemPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF121212).withValues(alpha: 0.85) 
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark ? Colors.black45 : Colors.black12,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.auto_stories_outlined, Icons.auto_stories, 'Libros', null),
                _buildNavItem(1, Icons.insights_outlined, Icons.insights, 'Stats', _statsKey),
                _buildNavItem(2, Icons.tune_outlined, Icons.tune, 'Ajustes', _settingsKey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label, GlobalKey? key) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = isDark ? Colors.indigoAccent : Colors.indigo;

    return GestureDetector(
      key: key, 
      onTap: () {
        if (_currentIndex != index) {
          // AÑADIDO: Feedback táctil al cambiar de pestaña
          HapticFeedback.selectionClick(); 
          setState(() => _currentIndex = index);
        }
        ref.read(navBarVisibleProvider.notifier).state = true;
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Efecto visual: el icono crece un poco cuando se selecciona
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 200),
              builder: (context, value, child) {
                return Icon(
                  isSelected ? selectedIcon : icon, 
                  color: isSelected ? selectedColor : (isDark ? Colors.white38 : Colors.black38), 
                  size: 24 + (value * 2), // Crece ligeramente de 24 a 26
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedColor : (isDark ? Colors.white38 : Colors.black38),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNavTutorial() {
    final theme = Theme.of(context);

    TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: "stats_nav",
          keyTarget: _statsKey,
          shape: ShapeLightFocus.RRect,
          radius: 12,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) => _buildTutorialBalloon(
                theme: theme,
                title: "📊​ Analiza tu progreso",
                description: "Mira estadísticas detalladas sobre tus lecturas.",
              ),
            ),
          ],
        ),
        TargetFocus(
          identify: "settings_nav",
          keyTarget: _settingsKey,
          shape: ShapeLightFocus.RRect,
          radius: 12,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) => _buildTutorialBalloon(
                theme: theme,
                title: "⚙️​ Configuración",
                description: "Personaliza el tema y gestiona tus datos.",
              ),
            ),
          ],
        ),
      ],
      colorShadow: theme.colorScheme.primary,
      hideSkip: true, 
      onFinish: () {
        ref.read(tutorialProvider.notifier).completeNavigation();
        setState(() => _isTutorialProcessing = false);
      },
    ).show(context: context);
  }

  Widget _buildTutorialBalloon({required String title, required String description, required ThemeData theme}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}