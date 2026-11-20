import 'dart:io';
import 'dart:ui';
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

enum NoteFilter { recent, page, length, favorites }

class BookDetailsScreen extends ConsumerStatefulWidget {
  final Book book;

  /// Abierto desde el botón FINALIZAR del widget: muestra el diálogo de fin de sesión.
  final bool autoFinishSession;

  const BookDetailsScreen({super.key, required this.book, this.autoFinishSession = false});

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
        backgroundColor: color,
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
              child: Scaffold(
                body: Stack(
                  children: [
                    _buildBlurredBackground(currentBook.coverUrl, dynamicScheme),
                    CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        _buildSliverAppBar(context, ref, currentBook),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                _buildFloatingCover(currentBook.coverUrl, currentBook.id),
                                const SizedBox(height: 28),
                                _buildTitleAndAuthor(currentBook, theme),
                                const SizedBox(height: 20),
                                _buildTag(currentBook.category ?? 'General', isDark: true),
                                const SizedBox(height: 32),
                                _buildMainContentCard(context, ref, currentBook, progress, isFinished, dynamicScheme, theme),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
              ),
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
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFloatingCover(widget.book.coverUrl, widget.book.id),
            const SizedBox(height: 40),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 20),
            Text(
              'Sintonizando tu lectura...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
                letterSpacing: 1.1,
                fontStyle: FontStyle.italic
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref, Book currentBook) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0, pinned: true,
      leading: _buildCircleIconButton(icon: Icons.arrow_back_ios_new_rounded, onPressed: () => Navigator.pop(context)),
      actions: [
        _buildCircleIconButton(icon: Icons.share_rounded, onPressed: () => _shareBook(currentBook)),
        _buildCircleIconButton(icon: Icons.delete_outline_rounded, onPressed: () => _confirmDelete(context, ref.read(databaseProvider), currentBook)),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildNotesList(WidgetRef ref, Book currentBook, ColorScheme scheme, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return StreamBuilder<List<Note>>(
      stream: ref.read(databaseProvider).watchNotesForBook(currentBook.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.edit_note_rounded, title: 'Sin notas aún', description: 'Agrega tus pensamientos.', 
            actionLabel: 'Nueva nota', onAction: () => _showAddNote(context, currentBook.id)
          );
        }

        final sortedNotes = _getSortedNotes(snapshot.data!);
        return Column(
          children: [
            _buildFilterChips(scheme),
            const SizedBox(height: 8),
            if (sortedNotes.isEmpty && _selectedFilter == NoteFilter.favorites)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Toca la ☆ de una nota para guardarla en tus citas favoritas.',
                    textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedNotes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
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
                      decoration: BoxDecoration(color: context.cs.error, borderRadius: BorderRadius.circular(24)),
                      child: Icon(Icons.delete_forever, color: context.cs.onError)
                    ),
                    child: GestureDetector(
                    // Tocar la nota la abre para editarla
                    onTap: () => _showAddNote(context, currentBook.id, noteToEdit: note),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3), 
                        borderRadius: BorderRadius.circular(24), 
                        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2))
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (note.pageNumber != null) _buildTag('Pág. ${note.pageNumber}', color: scheme.primary, isDark: isDark),
                              Row(
                                children: [
                                  Text(_getRelativeTime(note.createdAt), style: theme.textTheme.labelSmall),
                                  const SizedBox(width: 12),
                                  _buildActionIcon(
                                    icon: Icons.image_outlined,
                                    color: scheme.secondary, 
                                    onTap: () => shareQuoteAsImage(context, currentBook, note),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildActionIcon(
                                    icon: note.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: context.app.rating,
                                    onTap: () => _toggleFavorite(note),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildActionIcon(
                                    icon: Icons.copy_rounded, 
                                    color: scheme.primary, 
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: note.content));
                                      _showFeedback('Copiado', scheme.primary);
                                    }
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('"${note.content}"', style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, height: 1.4)),
                        ],
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

  Widget _buildCircleIconButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(12)),
      child: IconButton(icon: Icon(icon, color: Colors.white, size: 18), onPressed: onPressed),
    );
  }

  Widget _buildActionIcon({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); }, 
      child: Container(
        padding: const EdgeInsets.all(8), 
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle), 
        child: Icon(icon, size: 16, color: color)
      )
    );
  }

  Widget _buildTitleAndAuthor(Book book, ThemeData theme) {
    return Column(
      children: [
        Text(book.title, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(book.author.toUpperCase(), style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w700, letterSpacing: 2.0)),
      ],
    );
  }

  Widget _buildMainContentCard(BuildContext context, WidgetRef ref, Book currentBook, double progress, bool isFinished, ColorScheme scheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(44)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressSection(context, ref, currentBook, progress, isFinished, scheme, theme),
          const SizedBox(height: 32),
          if (isFinished) ...[
            _buildFinishedBadge(currentBook, scheme, theme),
          ] else ...[
            if (currentBook.status == 3) ...[
              _buildAbandonedCard(currentBook, scheme, theme),
              const SizedBox(height: 24),
            ],
            _buildReadingStats(currentBook, scheme, theme),
            const SizedBox(height: 24),
            _buildDailyGoalSection(scheme, theme),
            const SizedBox(height: 32),
            _buildSectionTitle('Sesión de lectura', theme),
            const SizedBox(height: 16),
            TimerWidget(key: _timerKey, book: currentBook, autoFinish: widget.autoFinishSession),
          ],
          const SizedBox(height: 40),
          _buildNotesHeader(currentBook, theme, scheme),
          const Divider(height: 32),
          _buildNotesList(ref, currentBook, scheme, theme),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildNotesHeader(Book currentBook, ThemeData theme, ColorScheme scheme) {
    return StreamBuilder<List<Note>>(
      stream: ref.read(databaseProvider).watchNotesForBook(currentBook.id),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Row(
          children: [
            _buildSectionTitle('Notas y Citas', theme),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(12)),
                child: Text('$count', style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
            const Spacer(),
            IconButton.filledTonal(
              key: _notesKey, icon: const Icon(Icons.add_comment_rounded, size: 20), 
              onPressed: () => _showAddNote(context, currentBook.id)
            ),
          ],
        );
      }
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
      label: Text(label), selected: isSelected,
      onSelected: (val) { if (val) setState(() => _selectedFilter = filter); },
      selectedColor: scheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) => Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontSize: 19));

  Widget _buildTag(String label, {Color? color, bool isDark = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: (color ?? Colors.white).withValues(alpha: isDark ? 0.2 : 0.1), borderRadius: BorderRadius.circular(30)),
      child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white)),
    );
  }

  Widget _buildBlurredBackground(String? url, ColorScheme scheme) {
    return Container(
      height: 520, width: double.infinity,
      decoration: BoxDecoration(color: scheme.primary, image: url != null ? DecorationImage(image: FileImage(File(url)), fit: BoxFit.cover) : null),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), child: Container(color: Colors.black26)),
    );
  }

  Widget _buildFloatingCover(String? url, int bookId) {
    return Hero(tag: 'cover_$bookId', child: Container(height: 260, width: 175, decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 40)]), child: ClipRRect(borderRadius: BorderRadius.circular(28), child: url != null ? Image.file(File(url), fit: BoxFit.cover) : const Icon(Icons.book, size: 60))));
  }

  Widget _buildProgressSection(BuildContext context, WidgetRef ref, Book book, double progress, bool isFinished, ColorScheme scheme, ThemeData theme) {
    return Column(
      key: _progressKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Tu Progreso', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          if (isFinished) TextButton.icon(onPressed: () => _showResetConfirmation(context, ref, book), icon: Icon(Icons.replay, color: context.app.accentText), label: const Text('RELEER', style: TextStyle(color: Colors.orange)))
          else TextButton.icon(onPressed: () => _showUpdateDialog(context, ref, book), icon: const Icon(Icons.edit), label: const Text('Actualizar')),
        ]),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: progress, minHeight: 14, borderRadius: BorderRadius.circular(20), color: isFinished ? context.app.statusFinished : scheme.primary),
        const SizedBox(height: 8),
        Text('${book.readPages} de ${book.totalPages} páginas (${(progress * 100).toInt()}%)'),
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
          avatar: Icon(icon, size: 16, color: scheme.primary),
          label: Text(label, style: const TextStyle(fontSize: 12)),
          onPressed: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      helpText: isStart ? '¿CUÁNDO LO EMPEZASTE?' : '¿CUÁNDO LO TERMINASTE?',
    );
    if (picked == null || !mounted) return;

    await ref.read(databaseProvider).updateBook(isStart
        ? book.copyWith(startedAt: Value(picked))
        : book.copyWith(finishedAt: Value(picked)));
    HapticFeedback.selectionClick();
  }

  Widget _buildReadingStats(Book book, ColorScheme scheme, ThemeData theme) {
    if (book.totalReadTime <= 0 || book.readPages <= 0) return const SizedBox.shrink(); 
    final double ppm = book.readPages / (book.totalReadTime / 60);
    final int left = book.totalPages - book.readPages;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Icon(Icons.auto_graph, color: scheme.primary),
        const SizedBox(width: 14),
        Text("Ritmo: ${ppm.toStringAsFixed(1)} pág/min | Faltan: ${(left/ppm).round()} min"),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: scheme.primary.withValues(alpha: 0.1))),
          child: Row(children: [
            CircularProgressIndicator(value: progress, strokeWidth: 6, color: progress >= 1 ? context.app.statusFinished : scheme.primary),
            const SizedBox(width: 20),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text("Meta Diaria", style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.tune, size: 18), onPressed: () => _showSetGoalDialog(scheme)),
              ]),
              Text("${(sec/60).toInt()} de $goalMinutes min hoy"),
            ])),
          ]),
        );
      },
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
    );
  }

  Widget _buildFinishedBadge(Book book, ColorScheme scheme, ThemeData theme) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(32), border: Border.all(color: scheme.primary.withValues(alpha: 0.2))),
      child: Column(children: [
        Icon(Icons.auto_awesome, color: context.app.rating, size: 48),
        const SizedBox(height: 16),
        const Text("¡LECTURA COMPLETADA!", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(
          icon: Icon(i < (book.rating ?? 0) ? Icons.star : Icons.star_border, color: context.app.rating, size: 32),
          onPressed: () => ref.read(databaseProvider).updateBook(book.copyWith(rating: Value(i + 1))),
        ))),
        const SizedBox(height: 8),
        _buildReviewSection(book, scheme, theme),
      ]),
    );
  }

  /// Recuadro de un libro abandonado: estrellas y reseña ("¿por qué lo dejaste?").
  Widget _buildAbandonedCard(Book book, ColorScheme scheme, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.app.statusAbandoned.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.app.statusAbandoned.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.bookmark_remove_rounded, color: context.app.statusAbandoned),
          const SizedBox(width: 8),
          const Text('ABANDONADO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(
          icon: Icon(i < (book.rating ?? 0) ? Icons.star : Icons.star_border, color: context.app.rating, size: 28),
          onPressed: () => ref.read(databaseProvider).updateBook(book.copyWith(rating: Value(i + 1))),
        ))),
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
            label: Text(review == null ? 'ESCRIBIR RESEÑA' : 'EDITAR RESEÑA'),
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
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: error != null ? null : () async {
                final navigator = Navigator.of(dialogContext);
                // Si con esto se termina el libro, _onBooksChanged lanza el confeti y la reseña
                await ref.read(databaseProvider).logProgress(book.id, val!);
                navigator.pop();
              },
              child: const Text('GUARDAR'),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: context.cs.error, foregroundColor: context.cs.onError), onPressed: () async {
          await db.deleteBookComplete(book);
          if (context.mounted) { Navigator.pop(context); Navigator.pop(context); }
        }, child: const Text('ELIMINAR')),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
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
        }, child: const Text('¡VAMOS!')),
      ],
    ));
  }

  void _showDetailsTutorial() async {
    final tutorialState = ref.read(tutorialProvider);

    // Si viene del widget para terminar la sesión, no se interrumpe con el tutorial
    if (widget.autoFinishSession ||
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