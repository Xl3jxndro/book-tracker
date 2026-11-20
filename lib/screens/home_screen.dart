import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/database_provider.dart';
import '../providers/ui_provider.dart';
import '../providers/tutorial_provider.dart';
import '../providers/current_book_provider.dart';
import '../providers/continue_reading_provider.dart';
import '../widgets/continue_reading_card.dart';
import '../widgets/book_card.dart';
import '../widgets/add_book_button.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/skeleton_loader.dart';
import '../services/ad_helper.dart';
import '../services/ads_gate.dart';
import '../services/library_ad_layout.dart';
import '../services/quick_status.dart';
import 'book_details_screen.dart';
import 'quotes_screen.dart';
import '../database/database.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

// --- PROVIDERS DE FILTRADO Y ORDENAMIENTO ---
enum BookSortOption { recentlyAdded, mostProgress, longest, alphabetical }

final searchQueryProvider = NotifierProvider<SimpleState<String>, String>(() => SimpleState(''));
final isSearchingProvider = NotifierProvider<SimpleState<bool>, bool>(() => SimpleState(false));
final selectedFilterProvider = NotifierProvider<SimpleState<String?>, String?>(() => SimpleState(null));
final sortOptionProvider = NotifierProvider<SimpleState<BookSortOption>, BookSortOption>(() => SimpleState(BookSortOption.recentlyAdded));

/// Vista de la biblioteca: lista (false) o cuadrícula (true). Se recuerda.
final libraryGridViewProvider = NotifierProvider<LibraryViewNotifier, bool>(LibraryViewNotifier.new);

class LibraryViewNotifier extends Notifier<bool> {
  static const prefsKey = 'library_grid_view';

  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(prefsKey);
    if (saved != null && ref.mounted) state = saved;
  }

  Future<void> set(bool grid) async {
    state = grid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, grid);
  }
}

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
  final GlobalKey _quotesButtonKey = GlobalKey();
  final GlobalKey _sortButtonKey = GlobalKey();
  final GlobalKey _searchButtonKey = GlobalKey();

  /// Anuncios nativos ya cargados: uno por hueco de la lista (un mismo
  /// anuncio no puede mostrarse en dos sitios a la vez).
  final List<NativeAd> _ads = [];
  bool _loadingAd = false;
  int _adsNeeded = 0;
  bool _isTutorialShowing = false;

  @override
  void initState() {
    super.initState();
    AdsGate.showAds.addListener(_onAdsGateChanged);
  }

  @override
  void dispose() {
    AdsGate.showAds.removeListener(_onAdsGateChanged);
    for (final ad in _ads) {
      ad.dispose();
    }
    super.dispose();
  }

  /// Carga de uno en uno los anuncios que pide la lista (según cuántos libros
  /// hay), solo si hay consentimiento o no hace falta.
  /// Llegó el consentimiento o se compró "Quitar anuncios".
  void _onAdsGateChanged() {
    if (!mounted) return;
    setState(() {});
    _loadAdsIfNeeded();
  }

  void _loadAdsIfNeeded() {
    if (!mounted || _loadingAd || _ads.length >= _adsNeeded || !AdsGate.showAds.value) return;
    _loadingAd = true;
    NativeAd(
      adUnitId: AdHelper.nativeAdUnitId,
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _loadingAd = false;
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _ads.add(ad as NativeAd));
          _loadAdsIfNeeded();
        },
        onAdFailedToLoad: (ad, error) {
          _loadingAd = false;
          ad.dispose();
          debugPrint('Anuncio nativo no disponible: ${error.message}');
        },
      ),
    ).load();
  }

  // Lógica de tutorial mejorada
  void _execTutorialFlow() {
    if (_isTutorialShowing || !mounted) return;

    // Los botones que señalan los tooltips deben estar a la vista: la barra
    // y el botón + se ocultan al hacer scroll, y el buscador tapa los demás.
    // Si no, el tooltip se calcula sobre un botón fuera de pantalla y se corta.
    ref.read(navBarVisibleProvider.notifier).set(true);
    if (ref.read(isSearchingProvider)) {
      ref.read(isSearchingProvider.notifier).set(false);
      ref.read(searchQueryProvider.notifier).set('');
    }
    
    // Un pequeño delay para que el árbol de widgets esté listo
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || addBookButtonKey.currentContext == null) return;
      
      _isTutorialShowing = true;
      TutorialCoachMark(
        targets: _createTargets(),
        colorShadow: Theme.of(context).colorScheme.primary,
        hideSkip: true,
        //textSkip: "Saltar",
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
      case 'status_0': case 0: return context.app.statusPending;
      case 'status_1': case 1: return context.app.statusReading;
      case 'status_2': case 2: return context.app.statusFinished;
      case 'status_3': case 3: return context.app.statusAbandoned;
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
                ref.read(navBarVisibleProvider.notifier).set(false);
              } else if (notification.direction == ScrollDirection.forward && !isNavVisible) {
                ref.read(navBarVisibleProvider.notifier).set(true);
              }
              return false;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                _buildHeader(context, ref, isSearching, theme),
                // "Continuar leyendo": solo en la vista normal (sin buscar ni filtrar)
                if (!isSearching && selectedFilter == null) _buildContinueReading(ref),
                if (allBooks.isNotEmpty && !isSearching)
                  SliverToBoxAdapter(child: _buildFilterSection(ref, selectedFilter, tags, theme, counts)),
                if (allBooks.isNotEmpty && filteredBooks.isNotEmpty)
                  SliverToBoxAdapter(child: _buildCountRow(ref, filteredBooks.length, theme)),
                _buildMainContent(context, ref, allBooks, filteredBooks, theme),
              ],
            ),
          );
        },
        loading: () => _buildLoadingSkeleton(context),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  // --- WIDGETS DE SOPORTE (SECCIONES) ---

  /// Cabecera: fecha y "Mi biblioteca" con sus acciones, o el buscador.
  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isSearching, ThemeData theme) {
    final today = DateFormat("EEEE, d 'de' MMMM", 'es').format(DateTime.now());
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(AppSpace.screen + 4, MediaQuery.of(context).padding.top + AppSpace.md, AppSpace.screen, AppSpace.xs),
        child: AnimatedSwitcher(
          duration: AppMotion.fast,
          child: isSearching
              ? Row(
                  key: const ValueKey('search'),
                  children: [
                    Expanded(child: _buildSearchField(ref, theme)),
                    const SizedBox(width: AppSpace.xs),
                    _buildSearchButton(ref, isSearching),
                  ],
                )
              : Row(
                  key: const ValueKey('title'),
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            today[0].toUpperCase() + today.substring(1),
                            style: theme.textTheme.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 2),
                          Text('Mi biblioteca', style: theme.textTheme.headlineLarge),
                        ],
                      ),
                    ),
                    _buildQuotesButton(context),
                    const SizedBox(width: AppSpace.xs),
                    _buildSortButton(context, ref, theme),
                    const SizedBox(width: AppSpace.xs),
                    _buildSearchButton(ref, isSearching),
                  ],
                ),
        ),
      ),
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
          actionLabel: 'Añadir mi primer libro',
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
          actionLabel: 'Ver todos los libros',
          onAction: () {
            ref.read(selectedFilterProvider.notifier).set(null);
            ref.read(searchQueryProvider.notifier).set('');
          },
        ),
      );
    }

    // Cuántos anuncios pide esta lista y cuáles caben con los ya cargados
    final needed = libraryLayout(books: filteredBooks.length, adsReady: 99).whereType<AdEntry>().length;
    if (needed != _adsNeeded) {
      _adsNeeded = needed;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAdsIfNeeded());
    }
    final entries = libraryLayout(books: filteredBooks.length, adsReady: AdsGate.showAds.value ? _ads.length : 0);
    final query = ref.watch(searchQueryProvider);
    final padding = EdgeInsets.fromLTRB(AppSpace.screen - AppSpace.xs, AppSpace.xs, AppSpace.screen - AppSpace.xs, 180 + MediaQuery.of(context).padding.bottom);

    if (ref.watch(libraryGridViewProvider)) {
      final rows = gridRows(entries);
      return SliverPadding(
        padding: padding.copyWith(left: AppSpace.screen, right: AppSpace.screen),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, r) {
              final row = rows[r];
              if (row.first case AdEntry(:final slot)) return _buildAdWrapper(theme, _ads[slot], slot);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var c = 0; c < 3; c++) ...[
                      if (c > 0) const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: c < row.length
                            ? BookGridTile(
                                key: ValueKey('grid_${filteredBooks[(row[c] as BookEntry).index].id}'),
                                book: filteredBooks[(row[c] as BookEntry).index],
                                searchQuery: query,
                                onTap: () => _openBook(filteredBooks[(row[c] as BookEntry).index]),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              );
            },
            childCount: rows.length,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: padding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => switch (entries[index]) {
            AdEntry(:final slot) => _buildAdWrapper(theme, _ads[slot], slot),
            BookEntry(index: final i) => _buildDismissibleCard(context, ref, filteredBooks[i], query),
          },
          childCount: entries.length,
        ),
      ),
    );
  }

  Widget _buildAdWrapper(ThemeData theme, NativeAd ad, int slot) {
    return Container(
      key: ValueKey('library_ad_$slot'),
      margin: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      height: 90,
      decoration: BoxDecoration(color: context.cs.surfaceContainerLow, borderRadius: AppRadius.lgAll),
      child: ClipRRect(borderRadius: AppRadius.lgAll, child: AdWidget(ad: ad)),
    );
  }

  Widget _buildSearchField(WidgetRef ref, ThemeData theme) {
    return TextField(
      key: const ValueKey('search_field'),
      autofocus: true,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Título o autor…',
        prefixIcon: const Icon(Icons.search_rounded),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)), borderSide: BorderSide.none),
        enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
          borderSide: BorderSide(color: context.cs.primary, width: 1.5),
        ),
      ),
      onChanged: (value) => ref.read(searchQueryProvider.notifier).set(value),
    );
  }

  /// Botón redondo de la cabecera.
  Widget _headerButton({Key? key, required IconData icon, required String tooltip, required VoidCallback onPressed}) {
    return IconButton(
      key: key,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      style: IconButton.styleFrom(
        fixedSize: const Size(44, 44),
        backgroundColor: context.cs.surfaceContainerHigh,
        foregroundColor: context.cs.onSurface,
      ),
    );
  }

  Widget _buildSearchButton(WidgetRef ref, bool isSearching) {
    return _headerButton(
      key: _searchButtonKey,
      icon: isSearching ? Icons.close_rounded : Icons.search_rounded,
      tooltip: isSearching ? 'Cerrar búsqueda' : 'Buscar',
      onPressed: () {
        HapticFeedback.selectionClick();
        ref.read(isSearchingProvider.notifier).set(!isSearching);
        if (isSearching) ref.read(searchQueryProvider.notifier).set('');
      },
    );
  }

  Widget _buildQuotesButton(BuildContext context) {
    return _headerButton(
      key: _quotesButtonKey,
      icon: Icons.format_quote_rounded,
      tooltip: 'Mis citas',
      onPressed: () {
        HapticFeedback.selectionClick();
        Navigator.push(context, MaterialPageRoute(builder: (_) => const QuotesScreen()));
      },
    );
  }

  Widget _buildSortButton(BuildContext context, WidgetRef ref, ThemeData theme) {
    return _headerButton(
      key: _sortButtonKey,
      icon: Icons.sort_rounded,
      tooltip: 'Ordenar',
      onPressed: () => _showSortSheet(context, ref, theme),
    );
  }

  static const _sortLabels = {
    BookSortOption.recentlyAdded: 'Recientes',
    BookSortOption.mostProgress: 'Mayor progreso',
    BookSortOption.longest: 'Más largos',
    BookSortOption.alphabetical: 'A–Z',
  };

  void _showSortSheet(BuildContext context, WidgetRef ref, ThemeData theme) {
    final currentSort = ref.read(sortOptionProvider);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.lg, AppSpace.md, AppSpace.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: context.cs.outline, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: AppSpace.lg),
              Text('Ordenar libros', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpace.md),
              _sortTile(ref, context, 'Añadido recientemente', BookSortOption.recentlyAdded, Icons.history_rounded, currentSort),
              _sortTile(ref, context, 'Mayor progreso', BookSortOption.mostProgress, Icons.auto_graph_rounded, currentSort),
              _sortTile(ref, context, 'Libros más largos', BookSortOption.longest, Icons.format_list_numbered_rounded, currentSort),
              _sortTile(ref, context, 'Orden alfabético', BookSortOption.alphabetical, Icons.sort_by_alpha_rounded, currentSort),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sortTile(WidgetRef ref, BuildContext context, String title, BookSortOption option, IconData icon, BookSortOption current) {
    final isSelected = current == option;
    return ListTile(
      leading: Icon(icon, color: isSelected ? context.app.accentText : context.cs.onSurfaceVariant),
      title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
      trailing: isSelected ? Icon(Icons.check_circle_rounded, color: context.app.accent) : null,
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(sortOptionProvider.notifier).set(option);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildFilterSection(WidgetRef ref, String? selectedFilter, List<String> tags, ThemeData theme, Map<String?, int> counts) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chipRow(ref, ['Todos', 'Pendientes', 'Leyendo', 'Terminados', 'Abandonados'],
              [null, 'status_0', 'status_1', 'status_2', 'status_3'], selectedFilter, theme, counts),
          // Categorías: solo si hay más de una (con una sola no filtran nada)
          if (tags.length > 1) ...[
            const SizedBox(height: AppSpace.xs),
            _chipRow(ref, tags, tags, selectedFilter, theme, counts, small: true),
          ],
        ],
      ),
    );
  }

  /// Fila de filtros: el seleccionado en tono invertido; los estados llevan
  /// un punto con su color.
  Widget _chipRow(WidgetRef ref, List<String> labels, List<String?> values, String? selected, ThemeData theme,
      Map<String?, int> counts, {bool small = false}) {
    final cs = context.cs;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
      child: Row(
        children: List.generate(labels.length, (i) {
          final val = values[i];
          final isSelected = selected == val;
          final count = counts[val] ?? 0;
          final isStatus = val != null && val.startsWith('status_');
          final fg = isSelected ? cs.onInverseSurface : cs.onSurface;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpace.xs),
            child: Material(
              color: isSelected ? cs.inverseSurface : (small ? Colors.transparent : cs.surfaceContainerHigh),
              shape: StadiumBorder(side: small && !isSelected ? BorderSide(color: cs.outlineVariant) : BorderSide.none),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(selectedFilterProvider.notifier).set(isSelected ? null : val);
                },
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  height: small ? 34 : 40,
                  padding: EdgeInsets.symmetric(horizontal: small ? 12 : 14),
                  child: Row(
                    children: [
                      if (isStatus) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: _getStatusColor(val, theme), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(labels[i], style: theme.textTheme.labelLarge?.copyWith(color: fg, fontSize: small ? 13 : 14)),
                      const SizedBox(width: 6),
                      Text('$count', style: theme.textTheme.labelMedium?.copyWith(color: fg.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// "N libros · orden" y el cambio entre lista y cuadrícula.
  Widget _buildCountRow(WidgetRef ref, int count, ThemeData theme) {
    final grid = ref.watch(libraryGridViewProvider);
    final cs = context.cs;
    Widget toggle(bool forGrid, IconData icon, String tooltip) {
      final selected = grid == forGrid;
      return IconButton(
        tooltip: tooltip,
        isSelected: selected,
        onPressed: () {
          HapticFeedback.selectionClick();
          ref.read(libraryGridViewProvider.notifier).set(forGrid);
        },
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          fixedSize: const Size(40, 40),
          backgroundColor: selected ? cs.surfaceContainerHighest : Colors.transparent,
          foregroundColor: selected ? cs.onSurface : cs.onSurfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen + 4, AppSpace.sm, AppSpace.screen - 4, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count ${count == 1 ? 'libro' : 'libros'} · ${_sortLabels[ref.watch(sortOptionProvider)]}',
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          toggle(false, Icons.view_agenda_outlined, 'Vista de lista'),
          const SizedBox(width: 4),
          toggle(true, Icons.grid_view_rounded, 'Vista de cuadrícula'),
        ],
      ),
    );
  }

  Widget _buildContinueReading(WidgetRef ref) {
    final item = ref.watch(continueReadingProvider).value;
    if (item == null) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, 0),
      sliver: SliverToBoxAdapter(
        child: ContinueReadingCard(
          item: item,
          onOpen: () => _openBook(item.book, heroTag: 'continue_cover_${item.book.id}'),
          onStart: () => _openBook(item.book, startTimer: true, heroTag: 'continue_cover_${item.book.id}'),
        ),
      ),
    );
  }

  void _openBook(Book book, {bool startTimer = false, String? heroTag}) {
    HapticFeedback.mediumImpact();
    // Establecer como libro actual (el widget se actualiza solo)
    ref.read(currentBookProvider.notifier).setCurrentBook(book.id);
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) => BookDetailsScreen(book: book, autoStartTimer: startTimer, heroTag: heroTag ?? 'cover_${book.id}'),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
      ),
    ).then((_) {
      // Al volver: la sesión pudo empezar o terminar
      if (mounted) ref.invalidate(continueReadingProvider);
    });
  }

  /// Libro de la lista con gestos: a la derecha, la acción rápida de su
  /// estado (con "Deshacer"); a la izquierda, borrar (con confirmación).
  Widget _buildDismissibleCard(BuildContext context, WidgetRef ref, Book book, String query) {
    final quick = quickStatusAction(book);
    final cs = context.cs;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Dismissible(
        key: Key('dismiss_${book.id}'),
        direction: quick == null ? DismissDirection.endToStart : DismissDirection.horizontal,
        dismissThresholds: const {DismissDirection.startToEnd: 0.3, DismissDirection.endToStart: 0.4},
        background: quick == null
            ? const SizedBox.shrink()
            : _swipeBackground(context, quick.icon, quick.label, context.app.accent, context.app.onAccent, Alignment.centerLeft),
        secondaryBackground: _swipeBackground(context, Icons.delete_sweep_rounded, 'Eliminar', cs.error, cs.onError, Alignment.centerRight),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            await _applyQuickStatus(ref, book, quick!);
            return false; // la tarjeta vuelve a su sitio; la lista se actualiza sola
          }
          HapticFeedback.heavyImpact();
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('¿Eliminar libro?'),
              content: Text('Esta acción borrará "${book.title}" permanentemente.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: context.cs.error, foregroundColor: context.cs.onError),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Eliminar'),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) => ref.read(databaseProvider).deleteBookComplete(book),
        child: BookCard(book: book, searchQuery: query, onTap: () => _openBook(book)),
      ),
    );
  }

  Widget _swipeBackground(BuildContext context, IconData icon, String label, Color bg, Color fg, Alignment align) {
    final left = align == Alignment.centerLeft;
    return Container(
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.lgAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!left) Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg)),
          if (!left) const SizedBox(width: AppSpace.xs),
          Icon(icon, color: fg, size: 26),
          if (left) const SizedBox(width: AppSpace.xs),
          if (left) Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg)),
        ],
      ),
    );
  }

  Future<void> _applyQuickStatus(WidgetRef ref, Book book, QuickStatusAction action) async {
    final updated = applyQuickStatus(book, DateTime.now());
    if (updated == null) return;
    HapticFeedback.mediumImpact();
    final db = ref.read(databaseProvider);
    await db.updateBook(updated);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text('${action.done} "${book.title}"'),
      duration: const Duration(seconds: 5),
      // Por encima de la barra de navegación flotante
      margin: EdgeInsets.fromLTRB(16, 0, 16, 64 + 24 + 12 + MediaQuery.of(context).padding.bottom),
      action: SnackBarAction(label: 'Deshacer', onPressed: () => db.updateBook(book)),
    ));
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: 120),
      child: LibrarySkeleton(),
    );
  }

  void _showAddBook(BuildContext context) => showAddBookSheet(context);

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
        keyTarget: addBookButtonKey, 
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