import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../providers/database_provider.dart';
import '../providers/ui_provider.dart';
import '../providers/tutorial_provider.dart';
import '../providers/current_book_provider.dart';
import '../widgets/book_card.dart';
import '../widgets/add_book_sheet.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/skeleton_loader.dart';
import '../services/ad_helper.dart';
import 'book_details_screen.dart';
import 'quotes_screen.dart';
import '../database/database.dart';

// --- PROVIDERS DE FILTRADO Y ORDENAMIENTO ---
enum BookSortOption { recentlyAdded, mostProgress, longest, alphabetical }

final searchQueryProvider = StateProvider<String>((ref) => '');
final isSearchingProvider = StateProvider<bool>((ref) => false);
final selectedFilterProvider = StateProvider<String?>((ref) => null);
final sortOptionProvider = StateProvider<BookSortOption>((ref) => BookSortOption.recentlyAdded);

/// ¿El libro es de la categoría [tag]? Sin distinguir mayúsculas ni espacios
/// en los bordes (los chips muestran la categoría normalizada).
bool _categoryMatches(Book book, String tag) =>
    (book.category ?? 'General').trim().toLowerCase() == tag.trim().toLowerCase();

final filteredBooksProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final booksAsync = ref.watch(booksStreamProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final filter = ref.watch(selectedFilterProvider);
  final sort = ref.watch(sortOptionProvider);

  return booksAsync.whenData((allBooks) {
    List<Book> filtered = allBooks.where((book) {
      final matchesSearch = book.title.toLowerCase().contains(query) || 
                            book.author.toLowerCase().contains(query);
      if (!matchesSearch) return false;
      if (filter == null) return true;
      if (filter == 'status_0') return book.status == 0;
      if (filter == 'status_1') return book.status == 1;
      if (filter == 'status_2') return book.status == 2;
      if (filter == 'status_3') return book.status == 3;
      return _categoryMatches(book, filter);
    }).toList();

    switch (sort) {
      case BookSortOption.recentlyAdded:
        filtered.sort((a, b) => b.id.compareTo(a.id));
        break;
      case BookSortOption.mostProgress:
        filtered.sort((a, b) {
          double progA = a.totalPages > 0 ? a.readPages / a.totalPages : 0;
          double progB = b.totalPages > 0 ? b.readPages / b.totalPages : 0;
          return progB.compareTo(progA);
        });
        break;
      case BookSortOption.longest:
        filtered.sort((a, b) => b.totalPages.compareTo(a.totalPages));
        break;
      case BookSortOption.alphabetical:
        filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
    return filtered;
  });
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey _addBookKey = GlobalKey();
  final GlobalKey _quotesButtonKey = GlobalKey();
  final GlobalKey _sortButtonKey = GlobalKey();
  final GlobalKey _searchButtonKey = GlobalKey();

  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _isTutorialShowing = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: AdHelper.nativeAdUnitId,
      factoryId: 'listTile', 
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) { ad.dispose(); return; }
          setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    )..load();
  }

  // Lógica de tutorial mejorada
  void _execTutorialFlow() {
    if (_isTutorialShowing || !mounted) return;

    // Los botones que señalan los tooltips deben estar a la vista: la barra
    // y el botón + se ocultan al hacer scroll, y el buscador tapa los demás.
    // Si no, el tooltip se calcula sobre un botón fuera de pantalla y se corta.
    ref.read(navBarVisibleProvider.notifier).state = true;
    if (ref.read(isSearchingProvider)) {
      ref.read(isSearchingProvider.notifier).state = false;
      ref.read(searchQueryProvider.notifier).state = '';
    }
    
    // Un pequeño delay para que el árbol de widgets esté listo
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || _addBookKey.currentContext == null) return;
      
      _isTutorialShowing = true;
      TutorialCoachMark(
        targets: _createTargets(),
        colorShadow: Theme.of(context).colorScheme.primary,
        hideSkip: true,
        //textSkip: "SALTAR",
        paddingFocus: 10,
        opacityShadow: 0.8,
        onFinish: () {
          ref.read(tutorialProvider.notifier).completeHome();
          _isTutorialShowing = false;
        },
        
        onSkip: () {
          ref.read(tutorialProvider.notifier).completeHome();
          _isTutorialShowing = false;
          return true;
        },
        
      ).show(context: context);
    });
  }

  Color _getStatusColor(dynamic statusValue, ThemeData theme) {
    switch (statusValue) {
      case 'status_0': case 0: return Colors.blue.shade600;
      case 'status_1': case 1: return Colors.orange.shade600;
      case 'status_2': case 2: return Colors.green.shade600;
      case 'status_3': case 3: return Colors.red.shade600;
      default: return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBooksAsync = ref.watch(filteredBooksProvider);
    final allBooksAsync = ref.watch(booksStreamProvider); 
    final isSearching = ref.watch(isSearchingProvider);
    final selectedFilter = ref.watch(selectedFilterProvider);
    final isNavVisible = ref.watch(navBarVisibleProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ESCUCHA DEL TUTORIAL: Se dispara cuando el estado cambia a 'home' y no se ha visto.
    ref.listen(tutorialProvider, (prev, next) {
      if (next.stage == TutorialStage.home && !next.hasSeenHome) {
        _execTutorialFlow();
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false, 
      body: filteredBooksAsync.when(
        data: (filteredBooks) {
          final allBooks = allBooksAsync.value ?? [];
          
          final tags = allBooks
              .map((b) => (b.category ?? 'General').trim())
              .where((t) => t.isNotEmpty)
              .map((t) => t[0].toUpperCase() + t.substring(1).toLowerCase())
              .toSet().toList()..sort();

          final counts = <String?, int>{
            null: allBooks.length,
            'status_0': allBooks.where((b) => b.status == 0).length,
            'status_1': allBooks.where((b) => b.status == 1).length,
            'status_2': allBooks.where((b) => b.status == 2).length,
            'status_3': allBooks.where((b) => b.status == 3).length,
            // Categorías: mismo criterio que el filtro (sin distinguir mayúsculas)
            for (final tag in tags)
              tag: allBooks.where((b) => _categoryMatches(b, tag)).length,
          };

          return NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.reverse && isNavVisible) {
                ref.read(navBarVisibleProvider.notifier).state = false;
              } else if (notification.direction == ScrollDirection.forward && !isNavVisible) {
                ref.read(navBarVisibleProvider.notifier).state = true;
              }
              return false; 
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                _buildSliverAppBar(context, ref, isSearching, isDark, theme),
                if (allBooks.isNotEmpty && !isSearching)
                  SliverToBoxAdapter(
                    child: _buildFilterSection(ref, selectedFilter, tags, theme, counts),
                  ),
                _buildMainContent(context, ref, allBooks, filteredBooks, theme),
              ],
            ),
          );
        },
        loading: () => _buildLoadingSkeleton(context),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: _buildModernFab(context, theme, isNavVisible, isSearching),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // --- WIDGETS DE SOPORTE (SECCIONES) ---

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref, bool isSearching, bool isDark, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: true,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: FlexibleSpaceBar(
            titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 14),
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: !isSearching 
                ? Text('Mi Biblioteca', 
                    key: const ValueKey('title'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 20, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.5,
                    ))
                : _buildSearchField(ref, theme),
            ),
          ),
        ),
      ),
      actions: [
        if (!isSearching) _buildQuotesButton(context),
        if (!isSearching) _buildSortButton(context, ref, theme),
        _buildSearchButton(ref, isSearching),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref, List<Book> allBooks, List<Book> filteredBooks, ThemeData theme) {
    if (allBooks.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyStateWidget(
          icon: Icons.auto_stories_rounded,
          title: 'Tu biblioteca está vacía',
          description: 'Parece un buen momento para empezar una nueva aventura.',
          //actionLabel: 'AÑADIR LIBRO',
          onAction: () => _showAddBook(context),
        ),
      );
    }
    
    if (filteredBooks.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyStateWidget(
          icon: Icons.search_off_rounded,
          title: 'Sin coincidencias',
          description: 'No encontramos nada que coincida con tus filtros.',
        ),
      );
    }

    const int adInterval = 4;
    int totalItems = filteredBooks.length;
    if (_isAdLoaded) {
      totalItems += (filteredBooks.length / adInterval).floor();
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 180 + MediaQuery.of(context).padding.bottom), 
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (_isAdLoaded && index > 0 && (index + 1) % (adInterval + 1) == 0) {
              return _buildAdWrapper(theme);
            }

            final int adCount = _isAdLoaded ? (index / (adInterval + 1)).floor() : 0;
            final int bookIndex = index - adCount;

            if (bookIndex >= filteredBooks.length) return null;

            final book = filteredBooks[bookIndex];
            return _buildDismissibleCard(context, ref, book, theme);
          },
          childCount: totalItems,
        ),
      ),
    );
  }

  Widget _buildAdWrapper(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
      height: 90, 
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }

  Widget _buildSearchField(WidgetRef ref, ThemeData theme) {
    return Container(
      key: const ValueKey('search_field'),
      height: 40,
      margin: const EdgeInsets.only(right: 60),
      alignment: Alignment.centerLeft,
      child: TextField(
        autofocus: true,
        cursorColor: theme.colorScheme.primary,
        style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Título o autor...',
          hintStyle: TextStyle(
            color: theme.brightness == Brightness.dark ? Colors.white38 : Colors.black38, 
            fontSize: 18,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
      ),
    );
  }

  Widget _buildSearchButton(WidgetRef ref, bool isSearching) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 4), 
      child: IconButton.filledTonal(
        key: _searchButtonKey,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(isSearching ? Icons.close_rounded : Icons.search_rounded, size: 22),
        onPressed: () {
          HapticFeedback.selectionClick();
          ref.read(isSearchingProvider.notifier).state = !isSearching;
          if (isSearching) ref.read(searchQueryProvider.notifier).state = '';
        },
      ),
    );
  }

  Widget _buildQuotesButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: IconButton(
        key: _quotesButtonKey,
        tooltip: 'Mis citas',
        icon: const Icon(Icons.format_quote_rounded),
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const QuotesScreen()));
        },
      ),
    );
  }

  Widget _buildSortButton(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 4),
      child: IconButton(
        key: _sortButtonKey, 
        icon: const Icon(Icons.sort_rounded),
        onPressed: () => _showSortSheet(context, ref, theme),
      ),
    );
  }

  void _showSortSheet(BuildContext context, WidgetRef ref, ThemeData theme) {
    final currentSort = ref.read(sortOptionProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text("Ordenar libros", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _sortTile(ref, context, "Añadido recientemente", BookSortOption.recentlyAdded, Icons.history_rounded, currentSort),
            _sortTile(ref, context, "Mayor progreso", BookSortOption.mostProgress, Icons.auto_graph_rounded, currentSort),
            _sortTile(ref, context, "Libros más largos", BookSortOption.longest, Icons.format_list_numbered_rounded, currentSort),
            _sortTile(ref, context, "Orden alfabético", BookSortOption.alphabetical, Icons.sort_by_alpha_rounded, currentSort),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sortTile(WidgetRef ref, BuildContext context, String title, BookSortOption option, IconData icon, BookSortOption current) {
    final theme = Theme.of(context);
    final isSelected = current == option;
    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : theme.iconTheme.color?.withValues(alpha: 0.6)),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary) : null,
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(sortOptionProvider.notifier).state = option;
        Navigator.pop(context);
      },
    );
  }

  Widget _buildFilterSection(WidgetRef ref, String? selectedFilter, List<String> tags, ThemeData theme, Map<String?, int> counts) {
    return Column(
      children: [
        _modernChipRow(ref, 'ESTADOS', ['Todos', 'Pendientes', 'Leyendo', 'Terminados', 'Abandonados'], [null, 'status_0', 'status_1', 'status_2', 'status_3'], selectedFilter, theme, counts),
        if (tags.isNotEmpty) _modernChipRow(ref, 'CATEGORÍAS', tags, tags, selectedFilter, theme, counts),
      ],
    );
  }

  Widget _modernChipRow(WidgetRef ref, String title, List<String> labels, List<String?> values, String? selected, ThemeData theme, Map<String?, int> counts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
          child: Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: theme.colorScheme.primary.withValues(alpha: 0.5))),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: List.generate(labels.length, (i) {
              final val = values[i];
              final isSelected = selected == val;
              final count = counts[val] ?? 0;
              final activeColor = _getStatusColor(val, theme);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(selectedFilterProvider.notifier).state = isSelected ? null : val;
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor : activeColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Text(labels[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : activeColor)),
                        const SizedBox(width: 6),
                        Text('$count', style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : activeColor.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDismissibleCard(BuildContext context, WidgetRef ref, Book book, ThemeData theme) {
    final statusColor = _getStatusColor(book.status, theme);
    final query = ref.watch(searchQueryProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key('dismiss_${book.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 30),
        ),
        confirmDismiss: (direction) async {
          HapticFeedback.heavyImpact();
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: const Text('¿Eliminar libro?'),
              content: Text('Esta acción borrará "${book.title}" permanentemente.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(context, true), 
                  child: const Text('ELIMINAR')
                ),
              ],
            ),
          );
        },
        onDismissed: (_) => ref.read(databaseProvider).deleteBookComplete(book),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withValues(alpha: 0.15))),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 6, color: statusColor)),
                BookCard(book: book, searchQuery: query, onTap: () {
                  HapticFeedback.mediumImpact();
                  
                  // Establecer como libro actual (el widget se actualiza solo)
                  ref.read(currentBookProvider.notifier).setCurrentBook(book.id);
                  
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 450),
                      pageBuilder: (context, animation, secondaryAnimation) => BookDetailsScreen(book: book),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20), itemCount: 6,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: SkeletonLoader(height: 110, width: double.infinity, borderRadius: 20),
      ),
    );
  }

  void _showAddBook(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const AddBookSheet());
  }

  Widget _buildModernFab(BuildContext context, ThemeData theme, bool isVisible, bool isSearching) {
    final bool shouldShow = isVisible && !isSearching;
    
    // 1. Detectamos dimensiones y área segura
    final double screenHeight = MediaQuery.of(context).size.height;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // Definimos si la pantalla es "pequeña" (menos de 710px suele ser el límite de iPhones SE o Redmis antiguos)
    final bool isCompact = screenHeight < 710;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutQuart,
      // Si no debe mostrarse, se desliza hacia abajo
      offset: shouldShow ? Offset.zero : const Offset(0, 2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: shouldShow ? 1.0 : 0.0,
        child: Padding(
          // 2. Ajuste dinámico del Bottom Padding:
          // 80 es el alto aproximado de tu NavBar. Sumamos el bottomPadding del sistema (Safe Area).
          padding: EdgeInsets.only(bottom: 20 + bottomPadding), 
          child: GestureDetector(
            key: _addBookKey, 
            onTap: shouldShow ? () => _showAddBook(context) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 56,
              // Si es compacto, el ancho es igual al alto (círculo/cuadrado), si no, es ancho variable
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                  // 3. Lógica Dinámica de Texto:
                  // Solo mostramos el texto y el espacio si NO es una pantalla compacta
                  if (!isCompact) ...[
                    const SizedBox(width: 10),
                    const Text(
                      'Nuevo Libro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- DEFINICIÓN DE TARGETS PARA TUTORIAL ---
  List<TargetFocus> _createTargets() {
    final theme = Theme.of(context);
    return [
      TargetFocus(
        identify: "search_button", 
        keyTarget: _searchButtonKey, 
        paddingFocus: 5,
        contents: [
          TargetContent(
            align: ContentAlign.bottom, 
            builder: (context, controller) => _buildTutorialBalloon(
              theme: theme, 
              title: "🔍 Encuentra tus libros", 
              description: "Busca rápidamente cualquier título o autor en tu colección."
            )
          ),
        ]
      ),
      TargetFocus(
        identify: "quotes_button",
        keyTarget: _quotesButtonKey,
        paddingFocus: 5,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialBalloon(
              theme: theme,
              title: "❝ Mis citas",
              description: "Todas las frases y notas de tus libros en un solo lugar: búscalas, marca favoritas y compártelas."
            )
          ),
        ]
      ),
      TargetFocus(
        identify: "sort_button", 
        keyTarget: _sortButtonKey, 
        paddingFocus: 5,
        contents: [
          TargetContent(
            align: ContentAlign.bottom, 
            builder: (context, controller) => _buildTutorialBalloon(
              theme: theme, 
              title: "↕️ Organiza tu biblioteca", 
              description: "Ordena tus libros por progreso, tamaño o fecha de añadido."
            )
          ),
        ]
      ),
      TargetFocus(
        identify: "add_button", 
        keyTarget: _addBookKey, 
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top, 
            builder: (context, controller) => _buildTutorialBalloon(
              theme: theme, 
              title: "📚 Nueva aventura", 
              description: "Toca aquí para registrar un nuevo libro y empezar a leer."
            )
          ),
        ]
      ),
    ];
  }

  Widget _buildTutorialBalloon({required String title, required String description, required ThemeData theme}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor, 
        borderRadius: BorderRadius.circular(24), 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20)]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(fontSize: 14, height: 1.4, color: theme.textTheme.bodyMedium?.color)),
        ],
      ),
    );
  }
}