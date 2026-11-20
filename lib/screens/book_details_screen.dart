import 'dart:math';
import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:drift/drift.dart' show Value;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/timer_widget.dart';
import '../widgets/add_note_sheet.dart';
import '../widgets/quote_share.dart';
import '../widgets/finish_review_sheet.dart';
import '../widgets/empty_state_widget.dart';
import '../providers/tutorial_provider.dart';
import '../providers/daily_goal_provider.dart';
import '../services/voice_service.dart';
import '../theme/app_colors.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/add_book_sheet.dart';
import '../widgets/book_card.dart';
import '../theme/app_tokens.dart';

enum NoteFilter { recent, page, length, favorites }

class BookDetailsScreen extends ConsumerStatefulWidget {
  final Book book;

  /// Abierto desde el botón FINALIZAR del widget: muestra el diálogo de fin de sesión.
  final bool autoFinishSession;

  /// Abierto desde "Continuar leyendo": arranca (o reanuda) el cronómetro.
  final bool autoStartTimer;

  /// Etiqueta de la transición de la portada (la de la tarjeta que se tocó).
  final String? heroTag;

  const BookDetailsScreen({super.key, required this.book, this.autoFinishSession = false, this.autoStartTimer = false, this.heroTag});

  @override
  ConsumerState<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends ConsumerState<BookDetailsScreen> {
  bool _isTutorialShowing = false;
  final ScrollController _scrollController = ScrollController();
  late ConfettiController _confettiController;
  final VoiceService _voiceService = VoiceService();
  final String appName = "Book Tracker";

  NoteFilter _selectedFilter = NoteFilter.recent;

  final GlobalKey _progressKey = GlobalKey();
  final GlobalKey _goalKey = GlobalKey();
  final GlobalKey _timerKey = GlobalKey();
  final GlobalKey _notesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _voiceService.initVoice();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDetailsTutorial());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE COMPARTIR AVANZADA ---
  
  void _shareBook(Book book) async {
    String text = "📖 *Estoy leyendo:* ${book.title}\n✍️ *Autor:* ${book.author}\n";
    text += "📊 *Progreso:* ${book.readPages}/${book.totalPages} pág.\n\n";
    text += "✨ Compartido desde $appName";
    
    SharePlus.instance.share(ShareParams(text: text));
  }

  // --- LÓGICA DE FILTRADO Y TIEMPO ---
  List<Note> _getSortedNotes(List<Note> notes) {
    List<Note> sorted = List.from(notes);
    switch (_selectedFilter) {
      case NoteFilter.recent: sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt)); break;
      case NoteFilter.page: sorted.sort((a, b) => (a.pageNumber ?? 0).compareTo(b.pageNumber ?? 0)); break;
      case NoteFilter.length: sorted.sort((a, b) => b.content.length.compareTo(a.content.length)); break;
      case NoteFilter.favorites:
        sorted = sorted.where((n) => n.isFavorite).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return sorted;
  }

  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return now.day == date.day ? 'Hoy' : 'Ayer';
    return '${date.day}/${date.month}/${date.year % 100}';
  }

  void _showFeedback(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        behavior: SnackBarBehavior.floating,
        width: 180,
        duration: const Duration(milliseconds: 1500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Al pasar a "Terminado" (desde el progreso o el cronómetro): confeti y
  /// la hoja para calificar y reseñar.
  void _onBooksChanged(AsyncValue<List<Book>>? previous, AsyncValue<List<Book>> next) {
    Book? find(AsyncValue<List<Book>>? value) {
      for (final b in value?.value ?? const <Book>[]) {
        if (b.id == widget.book.id) return b;
      }
      return null;
    }

    final before = find(previous), after = find(next);
    if (before == null || after == null) return;
    if (before.status != 2 && after.status == 2) _celebrateFinish(after);
  }

  Future<void> _celebrateFinish(Book book) async {
    _confettiController.play();
    // Esperar a que se cierre el diálogo que guardó el progreso: si la hoja se
    // abriera antes, ese cierre la cerraría a ella.
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent ?? false) break;
    }
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    await Future<void>.delayed(const Duration(milliseconds: 600)); // dejar ver el confeti
    if (!mounted) return;
    final latest = ref.read(booksStreamProvider).value?.where((b) => b.id == book.id).firstOrNull ?? book;
    await showFinishReviewSheet(context, latest);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Book>>>(booksStreamProvider, _onBooksChanged);
    final booksAsync = ref.watch(booksStreamProvider);
    final theme = Theme.of(context);

    return booksAsync.when(
      data: (allBooks) {
        final currentBook = allBooks.firstWhere((b) => b.id == widget.book.id, orElse: () => widget.book);
        final double progress = currentBook.totalPages > 0 ? (currentBook.readPages / currentBook.totalPages).clamp(0.0, 1.0) : 0;
        final bool isFinished = progress >= 1.0 || currentBook.status == 2;
        final colorSchemeAsync = ref.watch(bookColorSchemeProvider(currentBook.coverUrl));

        return colorSchemeAsync.when(
          data: (dynamicScheme) {
            return Theme(
              data: theme.copyWith(colorScheme: dynamicScheme, primaryColor: dynamicScheme.primary),
              child: Builder(builder: (context) {
                final tint = Color.lerp(
                  dynamicScheme.surface,
                  dynamicScheme.primary,
                  theme.brightness == Brightness.dark ? 0.16 : 0.20,
                )!;
                return Scaffold(
                  body: Stack(
                    children: [
                      CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(child: _buildHeader(context, currentBook, tint, theme)),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.xl, AppSpace.screen, 0),
                            sliver: SliverToBoxAdapter(
                              child: _buildMainContent(context, ref, currentBook, progress, isFinished, dynamicScheme, theme),
                            ),
                          ),
                        ],
                      ),
                      _buildTopBar(context, ref, currentBook),
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConfettiWidget(
                          confettiController: _confettiController,
                          blastDirectionality: BlastDirectionality.explosive,
                          createParticlePath: _drawStar,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            );
          },
          loading: () => _buildElegantLoading(theme),
          error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
        );
      },
      loading: () => _buildElegantLoading(theme),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  // --- CARGA ELEGANTE ---
  Widget _buildElegantLoading(ThemeData theme) {
    // Mientras se sacan los colores de la portada: la portada y el título
    // (ya conocidos) y una silueta del resto
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 72, 24, 24),
        child: Column(
          children: [
            _buildFloatingCover(widget.book.coverUrl, widget.book.id),
            const SizedBox(height: 24),
            Text(widget.book.title, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(widget.book.author, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 40),
            const BookDetailsSkeleton(),
          ],
        ),
      ),
    );
  }

  /// Botones fijos arriba: volver, compartir y más opciones (editar, eliminar).
  Widget _buildTopBar(BuildContext context, WidgetRef ref, Book book) {
    final cs = context.cs;
    final style = IconButton.styleFrom(
      fixedSize: const Size(44, 44),
      backgroundColor: cs.surface.withValues(alpha: 0.72),
      foregroundColor: cs.onSurface,
    );
    return Positioned(
      top: MediaQuery.of(context).padding.top + AppSpace.xs,
      left: AppSpace.screen - 4,
      right: AppSpace.screen - 4,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver',
            style: style,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Compartir',
            style: style,
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            onPressed: () => _shareBook(book),
          ),
          const SizedBox(width: AppSpace.xs),
          MenuAnchor(
            alignmentOffset: const Offset(-120, 4),
            builder: (context, controller, _) => IconButton(
              tooltip: 'Más opciones',
              style: style,
              icon: const Icon(Icons.more_horiz_rounded),
              onPressed: () => controller.isOpen ? controller.close() : controller.open(),
            ),
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(Icons.edit_outlined),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddBookSheet(bookToEdit: book),
                ),
                child: const Text('Editar libro'),
              ),
              MenuItemButton(
                leadingIcon: Icon(Icons.delete_outline_rounded, color: cs.error),
                onPressed: () => _confirmDelete(context, ref.read(databaseProvider), book),
                child: Text('Eliminar', style: TextStyle(color: cs.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Cabecera con el tono de la portada: portada, título, autor y categoría.
  Widget _buildHeader(BuildContext context, Book book, Color tint, ThemeData theme) {
    final cs = context.cs;
    return Container(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      padding: EdgeInsets.fromLTRB(AppSpace.xl, MediaQuery.of(context).padding.top + 64, AppSpace.xl, AppSpace.xl),
      child: Column(
        children: [
          _buildFloatingCover(book.coverUrl, book.id),
          const SizedBox(height: AppSpace.lg),
          Text(book.title, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(book.author, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: AppSpace.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: cs.surface.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(AppRadius.pill)),
            child: Text(book.category ?? 'General', style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurface)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(WidgetRef ref, Book currentBook, ColorScheme scheme, ThemeData theme) {
    return StreamBuilder<List<Note>>(
      stream: ref.read(databaseProvider).watchNotesForBook(currentBook.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
            child: EmptyStateWidget(
              icon: Icons.edit_note_rounded, title: 'Sin notas aún', description: 'Guarda aquí tus citas y pensamientos.',
              actionLabel: 'Nueva nota', onAction: () => _showAddNote(context, currentBook.id),
            ),
          );
        }

        final sortedNotes = _getSortedNotes(snapshot.data!);
        return Column(
          children: [
            _buildFilterChips(scheme),
            const SizedBox(height: AppSpace.sm),
            if (sortedNotes.isEmpty && _selectedFilter == NoteFilter.favorites)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Toca la ☆ de una nota para guardarla en tus citas favoritas.',
                    textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              ),
            ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedNotes.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
              itemBuilder: (context, index) {
                final note = sortedNotes[index];
                return _NoteEntranceAnimation(
                  key: ValueKey(note.id),
                  glowColor: scheme.primary,
                  child: Dismissible(
                    key: Key('note_${note.id}'),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _deleteNoteWithUndo(note),
                    background: Container(
                      alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(color: context.cs.error, borderRadius: AppRadius.xlAll),
                      child: Icon(Icons.delete_forever, color: context.cs.onError),
                    ),
                    child: Material(
                      color: scheme.surfaceContainerLow,
                      borderRadius: AppRadius.xlAll,
                      child: InkWell(
                        // Tocar la nota la abre para editarla
                        borderRadius: AppRadius.xlAll,
                        onTap: () => _showAddNote(context, currentBook.id, noteToEdit: note),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 8, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('“', style: theme.textTheme.displaySmall?.copyWith(color: context.app.accent, height: 1)),
                                  const Spacer(),
                                  _buildActionIcon(
                                    icon: Icons.image_outlined,
                                    tooltip: 'Compartir como imagen',
                                    color: scheme.onSurfaceVariant,
                                    onTap: () => shareQuoteAsImage(context, currentBook, note),
                                  ),
                                  _buildActionIcon(
                                    icon: note.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                                    tooltip: note.isFavorite ? 'Quitar de favoritas' : 'Guardar en favoritas',
                                    color: note.isFavorite ? context.app.rating : scheme.onSurfaceVariant,
                                    onTap: () => _toggleFavorite(note),
                                  ),
                                  _buildActionIcon(
                                    icon: Icons.copy_rounded,
                                    tooltip: 'Copiar',
                                    color: scheme.onSurfaceVariant,
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: note.content));
                                      _showFeedback('Copiado', scheme.primary);
                                    },
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(note.content, style: GoogleFonts.lora(textStyle: theme.textTheme.bodyLarge, height: 1.5)),
                              ),
                              const SizedBox(height: AppSpace.sm),
                              Text(
                                [
                                  if (note.pageNumber != null) 'Página ${note.pageNumber}',
                                  _getRelativeTime(note.createdAt),
                                ].join(' · '),
                                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // --- COMPONENTES UI AUXILIARES ---

  Widget _buildActionIcon({required IconData icon, required String tooltip, required Color color, required VoidCallback onTap}) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 20, color: color),
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref, Book currentBook, double progress, bool isFinished, ColorScheme scheme, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressSection(context, ref, currentBook, progress, isFinished, scheme, theme),
        const SizedBox(height: AppSpace.lg),
        if (isFinished) ...[
          _buildFinishedBadge(currentBook, scheme, theme),
        ] else ...[
          if (currentBook.status == 3) ...[
            _buildAbandonedCard(currentBook, scheme, theme),
            const SizedBox(height: AppSpace.md),
          ],
          _buildReadingStats(currentBook, scheme, theme),
          _buildDailyGoalSection(scheme, theme),
          const SizedBox(height: AppSpace.xl),
          _buildSectionTitle('Sesión de lectura', theme),
          const SizedBox(height: AppSpace.sm),
          TimerWidget(key: _timerKey, book: currentBook, autoFinish: widget.autoFinishSession, autoStart: widget.autoStartTimer),
        ],
        const SizedBox(height: AppSpace.xxl),
        _buildNotesHeader(currentBook, theme, scheme),
        const SizedBox(height: AppSpace.sm),
        _buildNotesList(ref, currentBook, scheme, theme),
        SizedBox(height: 48 + MediaQuery.of(context).padding.bottom),
      ],
    );
  }

  Widget _buildNotesHeader(Book currentBook, ThemeData theme, ColorScheme scheme) {
    return StreamBuilder<List<Note>>(
      stream: ref.read(databaseProvider).watchNotesForBook(currentBook.id),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSectionTitle('Notas y citas', theme),
            if (count > 0) ...[
              const SizedBox(width: AppSpace.xs),
              Text('$count', style: theme.textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant)),
            ],
            const Spacer(),
            FilledButton.tonalIcon(
              key: _notesKey,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 14)),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Añadir'),
              onPressed: () => _showAddNote(context, currentBook.id),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChips(ColorScheme scheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('Recientes', NoteFilter.recent, scheme),
          const SizedBox(width: 8),
          _filterChip('Página', NoteFilter.page, scheme),
          const SizedBox(width: 8),
          _filterChip('Longitud', NoteFilter.length, scheme),
          const SizedBox(width: 8),
          _filterChip('★ Favoritas', NoteFilter.favorites, scheme),
        ],
      ),
    );
  }

  Widget _filterChip(String label, NoteFilter filter, ColorScheme scheme) {
    final isSelected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? scheme.onInverseSurface : scheme.onSurface)),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (val) { if (val) setState(() => _selectedFilter = filter); },
      selectedColor: scheme.inverseSurface,
      shape: const StadiumBorder(),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) => Text(title, style: theme.textTheme.headlineSmall);

  /// Portada grande; al abrir el libro viaja desde la biblioteca (Hero).
  Widget _buildFloatingCover(String? url, int bookId) {
    return Hero(
      tag: widget.heroTag ?? 'cover_$bookId',
      child: BookCover(path: url, width: 150, height: 225, radius: 14),
    );
  }

  Widget _buildProgressSection(BuildContext context, WidgetRef ref, Book book, double progress, bool isFinished, ColorScheme scheme, ThemeData theme) {
    final cs = context.cs;
    final barColor = isFinished ? context.app.statusFinished : context.app.accent;
    return Column(
      key: _progressKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tu progreso', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: 10,
                    children: [
                      Text('${(progress * 100).toInt()}%',
                          style: theme.textTheme.displaySmall?.copyWith(fontFamily: theme.textTheme.titleMedium?.fontFamily, fontWeight: FontWeight.w700, color: cs.onSurface)),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('${book.readPages} de ${book.totalPages} páginas',
                            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isFinished)
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 14)),
                onPressed: () => _showResetConfirmation(context, ref, book),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Releer'),
              )
            else
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 14)),
                onPressed: () => _showUpdateDialog(context, ref, book),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Actualizar'),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress, minHeight: 8, color: barColor, backgroundColor: cs.surfaceContainerHighest),
        ),
        _buildReadingDates(book, scheme, theme),
      ],
    );
  }

  /// "Empezado el… · Terminado el… (N días)". Tocar una fecha la corrige
  /// (útil para libros terminados antes de que existiera esta función).
  Widget _buildReadingDates(Book book, ColorScheme scheme, ThemeData theme) {
    final isFinished = book.status == 2;
    if (book.startedAt == null && !isFinished && book.status == 0) return const SizedBox.shrink();

    final fmt = DateFormat("d MMM y", 'es');
    Widget chip({required IconData icon, required String label, required VoidCallback onTap}) => ActionChip(
          avatar: Icon(icon, size: 16, color: context.cs.onSurfaceVariant),
          label: Text(label, style: theme.textTheme.labelMedium),
          onPressed: onTap,
          backgroundColor: context.cs.surfaceContainerLow,
          shape: const StadiumBorder(),
        );

    String? duration;
    if (isFinished && book.startedAt != null && book.finishedAt != null) {
      final days = DateUtils.dateOnly(book.finishedAt!).difference(DateUtils.dateOnly(book.startedAt!)).inDays + 1;
      duration = days == 1 ? '1 día' : '$days días';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          chip(
            icon: Icons.play_arrow_rounded,
            label: book.startedAt == null ? 'Inicio: añadir fecha' : 'Empezado el ${fmt.format(book.startedAt!)}',
            onTap: () => _editReadingDate(book, isStart: true),
          ),
          if (isFinished)
            chip(
              icon: Icons.flag_rounded,
              label: book.finishedAt == null
                  ? 'Fin: añadir fecha'
                  : 'Terminado el ${fmt.format(book.finishedAt!)}${duration == null ? '' : ' · $duration'}',
              onTap: () => _editReadingDate(book, isStart: false),
            ),
        ],
      ),
    );
  }

  Future<void> _editReadingDate(Book book, {required bool isStart}) async {
    final today = DateUtils.dateOnly(DateTime.now());
    // El inicio no puede ser posterior al fin, ni el fin anterior al inicio
    final first = isStart ? DateTime(1950) : (book.startedAt != null ? DateUtils.dateOnly(book.startedAt!) : DateTime(1950));
    final last = isStart && book.finishedAt != null && book.status == 2 ? DateUtils.dateOnly(book.finishedAt!) : today;
    final current = (isStart ? book.startedAt : book.finishedAt) ?? last;

    final picked = await showDatePicker(
      context: context,
      initialDate: current.isBefore(first) ? first : (current.isAfter(last) ? last : current),
      firstDate: first,
      lastDate: last,
      helpText: isStart ? '¿Cuándo lo empezaste?' : '¿Cuándo lo terminaste?',
    );
    if (picked == null || !mounted) return;

    await ref.read(databaseProvider).updateBook(isStart
        ? book.copyWith(startedAt: Value(picked))
        : book.copyWith(finishedAt: Value(picked)));
    HapticFeedback.selectionClick();
  }

  /// Datos de la lectura en mosaico: ritmo, lo que falta y el tiempo leído.
  Widget _buildReadingStats(Book book, ColorScheme scheme, ThemeData theme) {
    if (book.totalReadTime <= 0 || book.readPages <= 0) return const SizedBox.shrink();
    final double ppm = book.readPages / (book.totalReadTime / 60);
    final int left = book.totalPages - book.readPages;
    String duration(int minutes) => minutes >= 60 ? '${minutes ~/ 60} h ${minutes % 60} min' : '$minutes min';
    final pace = ppm >= 1 ? '${ppm.toStringAsFixed(1)} pág/min' : '${(ppm * 60).round()} pág/h';

    Widget tile(String label, String value) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: AppRadius.lgAll),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(children: [
        tile('Ritmo', pace),
        const SizedBox(width: AppSpace.xs),
        tile('Faltan', duration((left / ppm).round())),
        const SizedBox(width: AppSpace.xs),
        tile('Leído', duration((book.totalReadTime / 60).round())),
      ]),
    );
  }

  Widget _buildDailyGoalSection(ColorScheme scheme, ThemeData theme) {
    final timeAsync = ref.watch(totalTimeTodayProvider);
    final goalMinutes = ref.watch(dailyGoalProvider);
    return timeAsync.when(
      data: (sec) {
        final progress = (sec / 60 / goalMinutes).clamp(0.0, 1.0);
        return Container(
          key: _goalKey,
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
          decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: AppRadius.xxlAll),
          child: Row(children: [
            SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 7,
                strokeCap: StrokeCap.round,
                color: progress >= 1 ? context.app.statusFinished : context.app.accent,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Meta diaria', style: theme.textTheme.titleMedium),
                Text('${(sec / 60).toInt()} de $goalMinutes min hoy', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              ]),
            ),
            IconButton(tooltip: 'Cambiar meta diaria', icon: const Icon(Icons.tune_rounded), onPressed: () => _showSetGoalDialog(scheme)),
          ]),
        );
      },
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
    );
  }

  Widget _buildFinishedBadge(Book book, ColorScheme scheme, ThemeData theme) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: AppRadius.xxlAll),
      child: Column(children: [
        Icon(Icons.auto_awesome_rounded, color: context.app.rating, size: 40),
        const SizedBox(height: AppSpace.sm),
        Text('¡Lectura completada!', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpace.xs),
        _ratingRow(book, 34),
        const SizedBox(height: AppSpace.xs),
        _buildReviewSection(book, scheme, theme),
      ]),
    );
  }

  Widget _ratingRow(Book book, double size) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) => IconButton(
          tooltip: '${i + 1} de 5',
          icon: Icon(i < (book.rating ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded, color: context.app.rating, size: size),
          onPressed: () => ref.read(databaseProvider).updateBook(book.copyWith(rating: Value(i + 1))),
        )),
      );

  /// Recuadro de un libro abandonado: estrellas y reseña ("¿por qué lo dejaste?").
  Widget _buildAbandonedCard(Book book, ColorScheme scheme, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.app.statusAbandoned.withValues(alpha: 0.08),
        borderRadius: AppRadius.xxlAll,
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.bookmark_remove_rounded, color: context.app.statusAbandoned),
          const SizedBox(width: 8),
          Text('Abandonado', style: theme.textTheme.titleMedium?.copyWith(color: context.app.statusAbandoned)),
        ]),
        _ratingRow(book, 28),
        _buildReviewSection(book, scheme, theme),
      ]),
    );
  }

  /// La reseña del libro (si tiene) y el botón para escribirla o editarla.
  Widget _buildReviewSection(Book book, ColorScheme scheme, ThemeData theme) {
    return StreamBuilder<Note?>(
      stream: ref.read(databaseProvider).watchReview(book.id),
      builder: (context, snapshot) {
        final review = snapshot.data;
        return Column(children: [
          if (review != null) ...[
            Text(
              '"${AppDatabase.reviewText(review)}"',
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, height: 1.4),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: () => showFinishReviewSheet(context, book, celebrate: false),
            icon: Icon(review == null ? Icons.rate_review_outlined : Icons.edit_note_rounded),
            label: Text(review == null ? 'Escribir reseña' : 'Editar reseña'),
          ),
        ]);
      },
    );
  }

  void _showAddNote(BuildContext context, int bookId, {Note? noteToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddNoteSheet(bookId: bookId, voiceService: _voiceService, noteToEdit: noteToEdit),
    );
  }

  void _toggleFavorite(Note note) {
    ref.read(databaseProvider).setNoteFavorite(note.id, !note.isFavorite);
    _showFeedback(note.isFavorite ? 'Quitada de favoritas' : 'Guardada en favoritas ★', context.app.rating);
  }

  /// Borra la nota y ofrece deshacerlo durante unos segundos.
  void _deleteNoteWithUndo(Note note) {
    final db = ref.read(databaseProvider);
    db.deleteNote(note);
    HapticFeedback.mediumImpact();

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Nota eliminada'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'DESHACER',
          onPressed: () => db.restoreNote(note),
        ),
      ),
    );
  }

  void _showUpdateDialog(BuildContext context, WidgetRef ref, Book book) {
    final controller = TextEditingController(text: book.readPages.toString());
    showDialog(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        final int? val = int.tryParse(controller.text);
        final String? error = val == null
            ? 'Escribe un número de página'
            : (val > book.totalPages ? 'No puede superar ${book.totalPages}' : null);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('Actualizar Progreso'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setDialogState(() {}),
            decoration: InputDecoration(
              labelText: '¿En qué página vas?',
              suffixText: '/ ${book.totalPages}',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: error != null ? null : () async {
                final navigator = Navigator.of(dialogContext);
                // Si con esto se termina el libro, _onBooksChanged lanza el confeti y la reseña
                await ref.read(databaseProvider).logProgress(book.id, val!);
                navigator.pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    ));
  }

  void _confirmDelete(BuildContext context, AppDatabase db, Book book) {
    showDialog(context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('¿Eliminar libro?'),
      content: const Text('Se perderán todas tus notas.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: context.cs.error, foregroundColor: context.cs.onError), onPressed: () async {
          await db.deleteBookComplete(book);
          if (context.mounted) { Navigator.pop(context); Navigator.pop(context); }
        }, child: const Text('Eliminar')),
      ],
    ));
  }

  void _showSetGoalDialog(ColorScheme scheme) {
    showDialog(context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text("Meta Diaria"),
      content: Wrap(spacing: 10, children: DailyGoalNotifier.options.map((m) => ChoiceChip(
        label: Text("$m min"),
        selected: ref.read(dailyGoalProvider) == m,
        onSelected: (v) {
          if (v) ref.read(dailyGoalProvider.notifier).setGoal(m);
          Navigator.pop(context);
        },
      )).toList()),
    ));
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref, Book book) {
    showDialog(context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('¿Nueva lectura?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: () async {
          // Nueva lectura: empieza hoy. Se conserva la fecha de fin de la
          // anterior hasta terminar de nuevo (el reto de ese año no baja).
          await ref.read(databaseProvider).updateBook(book.copyWith(
            readPages: 0,
            status: 1,
            rating: const Value(0),
            startedAt: Value(DateTime.now()),
          ));
          if (context.mounted) Navigator.pop(context);
        }, child: const Text('¡Vamos!')),
      ],
    ));
  }

  void _showDetailsTutorial() async {
    final tutorialState = ref.read(tutorialProvider);

    // Si viene del widget para terminar la sesión, no se interrumpe con el tutorial
    if (widget.autoFinishSession ||
        widget.autoStartTimer ||
        tutorialState.stage != TutorialStage.bookDetails ||
        tutorialState.hasSeenDetails ||
        _isTutorialShowing) {
      return;
    }

    setState(() => _isTutorialShowing = true);

    // Al abrir, la pantalla muestra "Sintonizando tu lectura..." mientras saca
    // los colores de la portada: hay que esperar a que existan los elementos
    // que señala el tutorial (si no, la librería falla y deja la capa encima).
    for (var i = 0; i < 100 && mounted && _progressKey.currentContext == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (!mounted) return;
    if (_progressKey.currentContext == null) {
      setState(() => _isTutorialShowing = false); // se intentará la próxima vez
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 300)); // que termine la animación de entrada
    if (!mounted) return;

    // SECUENCIA GARANTIZADA:
    // Paso 1: Progreso
    await _showStep(
      key: _progressKey,
      title: "📈​ Tu Progreso",
      desc: "Visualiza cuántas páginas llevas leídas.",
    );

    // Paso 2: Meta
    await _showStep(
      key: _goalKey,
      title: "🏆​ Meta Diaria",
      desc: "Configura tus minutos de lectura diarios.",
    );

    // Paso 3: Cronómetro (Aquí el scroll será automático y perfecto)
    await _showStep(
      key: _timerKey,
      title: "📖​ Sesión de Lectura",
      desc: "Inicia el cronómetro para medir tu tiempo.",
      align: ContentAlign.top,
    );

    // Paso 4: Notas
    await _showStep(
      key: _notesKey,
      title: "​📜​ ​Añadir Notas",
      desc: "Guarda tus citas favoritas aquí.",
      align: ContentAlign.top,
      isCircle: true,
    );

    // Finalización
    ref.read(tutorialProvider.notifier).completeDetails();
    if (mounted) setState(() => _isTutorialShowing = false);
  }

  Future<void> _showStep({
    required GlobalKey key,
    required String title,
    required String desc,
    ContentAlign align = ContentAlign.bottom,
    bool isCircle = false,
  }) async {
    // 1. SCROLL: Primero movemos la pantalla y esperamos a que termine
    if (key.currentContext != null) {
      await Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.3, // Lo deja un poco arriba para que quepa el globo
      );
      // Pausa técnica para que Flutter asiente las coordenadas
      await Future.delayed(const Duration(milliseconds: 150));
    }

    // Si el usuario salió de la pantalla durante el scroll, o el elemento no
    // está (p. ej. sin cronómetro en un libro terminado), se salta el paso
    if (!mounted || key.currentContext == null) return;

    // 2. TUTORIAL: Mostramos el foco solo para ESTE widget
    final completer = Completer<void>();
    
    TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: title,
          keyTarget: key,
          shape: isCircle ? ShapeLightFocus.Circle : ShapeLightFocus.RRect,
          radius: 20,
          contents: [
            TargetContent(
              align: align,
              builder: (context, controller) => _buildTutorialBalloon(
                title: title,
                description: desc,
                theme: Theme.of(context),
              ),
            ),
          ],
        ),
      ],
      colorShadow: Theme.of(context).colorScheme.primary,
      opacityShadow: 0.8,
      hideSkip: true,
      onFinish: () => completer.complete(),
      onSkip: () {
        completer.complete();
        return true;
      },
    ).show(context: context);

    return completer.future; // Espera a que el usuario haga click para seguir
  }

  Widget _buildTutorialBalloon({required String title, required String description, required ThemeData theme}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.cs.surfaceContainerLow, borderRadius: BorderRadius.circular(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.cs.onSurface)),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(fontSize: 14, color: context.cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Path _drawStar(Size size) {
    final path = Path();
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    const numberOfPoints = 5;
    final degreesPerStep = (360 / numberOfPoints) * (pi / 180);
    path.moveTo(halfWidth, 0);
    for (var i = 0; i < numberOfPoints; i++) {
      path.lineTo(halfWidth + externalRadius * sin(i * degreesPerStep), halfWidth - externalRadius * cos(i * degreesPerStep));
      path.lineTo(halfWidth + internalRadius * sin(i * degreesPerStep + degreesPerStep / 2), halfWidth - internalRadius * cos(i * degreesPerStep + degreesPerStep / 2));
    }
    path.close();
    return path;
  }
}

class _NoteEntranceAnimation extends StatelessWidget {
  final Widget child; final Color glowColor;
  const _NoteEntranceAnimation({super.key, required this.child, required this.glowColor});
  @override Widget build(BuildContext context) => TweenAnimationBuilder<double>(duration: const Duration(milliseconds: 800), curve: Curves.easeOutQuart, tween: Tween(begin: 0.0, end: 1.0), builder: (c, v, ch) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 15 * (1 - v)), child: ch)), child: child);
}