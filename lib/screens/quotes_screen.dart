import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../services/text_normalize.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/quote_share.dart';
import 'book_details_screen.dart';

/// Filtra las citas por texto (en la cita, el título o el autor) y, si se
/// pide, solo las favoritas. Conserva el orden recibido.
List<NoteWithBook> filterQuotes(List<NoteWithBook> all, {String query = '', bool favoritesOnly = false}) {
  final words = normalizeForSearch(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  return all.where((q) {
    if (favoritesOnly && !q.note.isFavorite) return false;
    if (words.isEmpty) return true;
    final haystack = normalizeForSearch('${q.note.content} ${q.book.title} ${q.book.author}');
    return words.every(haystack.contains);
  }).toList();
}

/// "Mis citas": todas las notas de todos los libros, con búsqueda y favoritas.
class QuotesScreen extends ConsumerStatefulWidget {
  const QuotesScreen({super.key});

  @override
  ConsumerState<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends ConsumerState<QuotesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _favoritesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final quotesAsync = ref.watch(notesWithBooksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis citas', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: quotesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudieron cargar las citas: $e')),
        data: (all) {
          if (all.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.format_quote_rounded,
              title: 'Aún no tienes citas',
              description: 'Guarda frases y pensamientos desde la sección "Notas y Citas" de cada libro. Aparecerán todas aquí.',
            );
          }

          final favorites = all.where((q) => q.note.isFavorite).length;
          final visible = filterQuotes(all, query: _query, favoritesOnly: _favoritesOnly);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Buscar en citas, títulos o autores',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Borrar búsqueda',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('Todas (${all.length})'),
                      selected: !_favoritesOnly,
                      onSelected: (_) => setState(() => _favoritesOnly = false),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade700),
                      label: Text('Favoritas ($favorites)'),
                      selected: _favoritesOnly,
                      onSelected: (_) => setState(() => _favoritesOnly = true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: visible.isEmpty
                    ? _EmptyFilter(favoritesOnly: _favoritesOnly && _query.isEmpty)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => _QuoteCard(
                          key: ValueKey(visible[i].note.id),
                          quote: visible[i],
                          scheme: scheme,
                          theme: theme,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyFilter extends StatelessWidget {
  final bool favoritesOnly;
  const _EmptyFilter({required this.favoritesOnly});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          favoritesOnly
              ? 'Aún no tienes favoritas.\nToca la ☆ de una cita para guardarla aquí.'
              : 'Ninguna cita coincide con la búsqueda.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _QuoteCard extends ConsumerWidget {
  final NoteWithBook quote;
  final ColorScheme scheme;
  final ThemeData theme;
  const _QuoteCard({super.key, required this.quote, required this.scheme, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = quote.note;
    final book = quote.book;
    final source = [
      book.title,
      if (note.pageNumber != null) 'pág. ${note.pageNumber}',
    ].join(' · ');

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        // Tocar la cita abre su libro
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailsScreen(book: book))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  '"${note.content}"',
                  style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, height: 1.4),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('— $source',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700)),
                        Text(book.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: note.isFavorite ? 'Quitar de favoritas' : 'Marcar como favorita',
                    icon: Icon(note.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber.shade700),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(databaseProvider).setNoteFavorite(note.id, !note.isFavorite);
                    },
                  ),
                  IconButton(
                    tooltip: 'Compartir como imagen',
                    icon: Icon(Icons.image_outlined, color: scheme.secondary),
                    onPressed: () => shareQuoteAsImage(context, book, note),
                  ),
                  IconButton(
                    tooltip: 'Copiar',
                    icon: Icon(Icons.copy_rounded, color: scheme.primary),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Clipboard.setData(ClipboardData(text: '"${note.content}" — ${book.title}, ${book.author}'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cita copiada'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
