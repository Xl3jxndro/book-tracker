import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../providers/ui_provider.dart';
import '../providers/auth_provider.dart';
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
import '../widgets/add_book_button.dart';
import '../widgets/goodreads_import_actions.dart';
import '../widgets/whats_new_sheet.dart';
import '../widgets/streak_save_sheet.dart';
import '../providers/streak_save_provider.dart';
import '../services/ads_consent.dart';
import '../services/ads_gate.dart';
import '../services/streak_save.dart';
import '../services/app_update.dart';
import '../widgets/app_update_actions.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../l10n/l10n.dart';

/// Qué hace "atrás" (gesto o botón de Android) en la pantalla principal.
enum MainBackAction { closeSearch, goToLibrary, leaveApp }

MainBackAction mainBackAction({required int tabIndex, required bool isSearching}) {
  if (isSearching) return MainBackAction.closeSearch;
  if (tabIndex != 0) return MainBackAction.goToLibrary;
  return MainBackAction.leaveApp;
}

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

    // Si llegó una acción con la app bloqueada (al volver), se atiende al desbloquear
    ref.listenManual<bool>(
      authProvider.select((s) => s.canEnterApp),
      (wasAllowed, allowed) {
        final pending = ref.read(pendingWidgetActionProvider);
        if (allowed && wasAllowed == false && pending != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _handleWidgetAction(pending));
        }
      },
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
          // Y por último: ¿hay una versión nueva en Google Play?
          await _maybeOfferUpdate();
        });
      }
    }, fireImmediately: true);
  }

  /// Avisa (una vez por versión) si hay una versión nueva en Google Play, o
  /// si ya se descargó y falta reiniciar.
  Future<void> _maybeOfferUpdate() async {
    final status = await AppUpdate.check();
    if (!mounted) return;
    if (status == UpdateStatus.downloaded) {
      offerInstall(context);
    } else if (await AppUpdate.shouldPrompt() && mounted) {
      await AppUpdate.markPrompted();
      if (mounted) await showUpdatePrompt(context);
    }
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

  /// Abre el libro pedido desde el widget o la notificación; con
  /// `finishSession` muestra además el diálogo para terminar la sesión.
  Future<void> _handleWidgetAction(WidgetAction action) async {
    if (!mounted) return;
    // Con la app bloqueada no se navega: cerraría también la pantalla de
    // bloqueo. La acción queda pendiente hasta desbloquear.
    if (!ref.read(authProvider).canEnterApp) return;
    ref.read(pendingWidgetActionProvider.notifier).set(null);

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
    final double totalNavHeight = isVisible ? (64 + 24 + systemBottomPadding) : 0;

    // "Atrás" de Android: primero cierra el buscador, luego vuelve a Libros
    // y, solo desde ahí, sale de la app.
    final backAction = mainBackAction(tabIndex: _currentIndex, isSearching: ref.watch(isSearchingProvider));

    return PopScope(
      canPop: backAction == MainBackAction.leaveApp,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        switch (backAction) {
          case MainBackAction.closeSearch:
            ref.read(isSearchingProvider.notifier).set(false);
            ref.read(searchQueryProvider.notifier).set('');
          case MainBackAction.goToLibrary:
            setState(() => _currentIndex = 0);
          case MainBackAction.leaveApp:
            break;
        }
        ref.read(navBarVisibleProvider.notifier).set(true);
      },
      child: Scaffold(
      // Mantenemos extendBody para el efecto Blur detrás de la barra
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is UserScrollNotification && !isNavTutorialPhase) {
            if (notification.direction == ScrollDirection.reverse) {
              if (isVisible) ref.read(navBarVisibleProvider.notifier).set(false);
            } else if (notification.direction == ScrollDirection.forward) {
              if (!isVisible) ref.read(navBarVisibleProvider.notifier).set(true);
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
      ),
    );
  }

  /// Barra inferior: navegación flotante en cápsula y, en la biblioteca, el
  /// botón "+" a su derecha.
  Widget _buildModernNav(bool isDark, ThemeData theme, double systemPadding) {
    final showAdd = _currentIndex == 0 && !ref.watch(isSearchingProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + systemPadding),
      child: Row(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: context.cs.surfaceContainer,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10), blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNavItem(0, Icons.auto_stories_outlined, Icons.auto_stories, context.l10n.navBooks, null),
                _buildNavItem(1, Icons.insights_outlined, Icons.insights, context.l10n.navStats, _statsKey),
                _buildNavItem(2, Icons.tune_outlined, Icons.tune, context.l10n.navSettings, _settingsKey),
              ],
            ),
          ),
          const Spacer(),
          AnimatedScale(
            scale: showAdd ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: IgnorePointer(ignoring: !showAdd, child: const AddBookButton()),
          ),
        ],
      ),
    );
  }

  /// Elemento de la barra: el elegido es una cápsula con icono y nombre; los
  /// demás, solo el icono.
  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label, GlobalKey? key) {
    final isSelected = _currentIndex == index;
    final app = context.app;
    return Semantics(
      key: key,
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            if (_currentIndex != index) {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = index);
            }
            ref.read(navBarVisibleProvider.notifier).set(true);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 12),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: isSelected ? app.accentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isSelected ? selectedIcon : icon, size: 24, color: isSelected ? app.accentText : context.cs.onSurfaceVariant),
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  child: isSelected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: app.accentText)),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
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
                title: context.l10n.navTutorialStatsTitle,
                description: context.l10n.navTutorialStatsDescription,
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
                title: context.l10n.navTutorialSettingsTitle,
                description: context.l10n.navTutorialSettingsDescription,
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