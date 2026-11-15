import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/ui_provider.dart'; 
import '../providers/tutorial_provider.dart';
import '../providers/database_provider.dart';
import '../providers/current_book_provider.dart';
import '../services/widget_service.dart';
import '../database/database.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import 'session_summary_screen.dart';
import 'package:flutter/services.dart';

class MainWrapper extends ConsumerStatefulWidget {
  final String? pendingRoute;

  const MainWrapper({super.key, this.pendingRoute});

  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper> {
  int _currentIndex = 0;
  bool _isTutorialProcessing = false; 
  
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
    
    // Manejar deep link de finish_session
    if (widget.pendingRoute?.contains('finish_session') ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleFinishSessionDeepLink();
      });
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final tutorialState = ref.read(tutorialProvider);
        _checkAndTriggerTutorial(tutorialState.stage);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Escuchar cambios en el libro actual y actualizar el widget
    ref.listen<AsyncValue<({Book book, ReadingSession? session})?>>(
      currentBookWithSessionProvider,
      (previous, next) {
        next.whenData((data) {
          if (data != null) {
            debugPrint('📱 Actualizando widget con libro: ${data.book.title}');
            WidgetService.updateWidget(
              currentBook: data.book,
              todaySession: data.session,
              isSessionActive: false,
            );
          }
        });
      },
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
      if (next.stage == TutorialStage.navigation) {
        _checkAndTriggerTutorial(next.stage);
      }
    });

    final tutorialData = ref.watch(tutorialProvider);
    final bool isNavTutorialPhase = tutorialData.stage == TutorialStage.navigation;
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
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
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
                  ? const Color(0xFF121212).withOpacity(0.85) 
                  : Colors.white.withOpacity(0.9),
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
          color: isSelected ? selectedColor.withOpacity(0.12) : Colors.transparent,
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

  Future<void> _handleFinishSessionDeepLink() async {
    try {
      debugPrint('📱 Manejando deep link: finish_session');
      
      // Obtener el book_id de SharedPreferences si fue guardado desde el widget
      final prefs = await SharedPreferences.getInstance();
      final bookId = prefs.getInt('session_summary_book_id');
      
      if (bookId != null) {
        // Verificar que el libro existe
        final db = ref.read(databaseProvider);
        final book = await (db.select(db.books)
          ..where((t) => t.id.equals(bookId)))
          .getSingleOrNull();
        
        if (book != null && mounted) {
          // Navegar a la pantalla de resumen de sesión
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SessionSummaryScreen(
                bookId: bookId,
                fromWidget: true,
              ),
            ),
          );
          
          // Limpiar el flag
          await prefs.remove('show_session_summary');
          await prefs.remove('session_summary_book_id');
        }
      }
    } catch (e) {
      debugPrint('Error manejando deep link: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar sesión: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
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