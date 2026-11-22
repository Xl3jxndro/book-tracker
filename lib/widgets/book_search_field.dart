import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../services/book_api_service.dart';
import '../services/isbn.dart';
import '../theme/app_colors.dart';

/// Buscador de libros (Open Library y, si hay clave, Google Books): muestra resultados mientras se escribe y avisa
/// con [onSelected] cuando el usuario elige uno.
class BookSearchField extends StatefulWidget {
  final BookApiService service;
  final ValueChanged<BookModel> onSelected;

  const BookSearchField({super.key, required this.service, required this.onSelected});

  @override
  State<BookSearchField> createState() => _BookSearchFieldState();
}

class _BookSearchFieldState extends State<BookSearchField> {
  static const _debounce = Duration(milliseconds: 600);

  final _controller = TextEditingController();
  Timer? _debounceTimer;

  /// Identifica la última búsqueda: las respuestas de búsquedas anteriores
  /// que lleguen tarde se descartan.
  int _requestId = 0;

  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;
  List<BookModel> _results = const [];

  /// ISBN de la última búsqueda, si lo escrito era un ISBN.
  String? _searchedIsbn;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounceTimer?.cancel();
    if (text.trim().length < BookApiService.minQueryLength) {
      _requestId++; // invalida búsquedas en curso
      setState(() {
        _isLoading = false;
        _hasSearched = false;
        _searchedIsbn = null;
        _error = null;
        _results = const [];
      });
      return;
    }
    _debounceTimer = Timer(_debounce, () => _search(text));
  }

  Future<void> _search(String query) async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Un ISBN escrito (13 o 10 dígitos, con o sin guiones) → búsqueda exacta
      final isbn = Isbn.normalize(query);
      _searchedIsbn = isbn;
      final results = isbn != null
          ? await widget.service.searchByIsbn(isbn)
          : await widget.service.searchBooks(query);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = results;
        _hasSearched = true;
        _isLoading = false;
      });
    } on BookSearchException catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = e.message;
        _results = const [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error buscando libros: $e');
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = context.l10n.searchFailed;
        _results = const [];
        _isLoading = false;
      });
    }
  }

  void _clear() {
    _debounceTimer?.cancel();
    _requestId++;
    _controller.clear();
    setState(() {
      _isLoading = false;
      _hasSearched = false;
      _searchedIsbn = null;
      _error = null;
      _results = const [];
    });
  }

  void _select(BookModel book) {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    widget.onSelected(book);
    _clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = context.cs.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          onSubmitted: (text) {
            _debounceTimer?.cancel();
            if (text.trim().length >= BookApiService.minQueryLength) _search(text);
          },
          decoration: InputDecoration(
            hintText: context.l10n.searchHint,
            hintStyle: TextStyle(color: muted, fontSize: 14),
            prefixIcon: Icon(Icons.travel_explore_rounded, size: 20, color: theme.colorScheme.primary),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : (_controller.text.isEmpty
                    ? null
                    : IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: _clear)),
            filled: true,
            fillColor: theme.colorScheme.primary.withValues(alpha: isDark ? 0.10 : 0.06),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
          ),
        ),
        if (_error != null)
          _message(Icons.cloud_off_rounded, _error!, theme.colorScheme.error)
        else if (_hasSearched && _results.isEmpty && !_isLoading)
          _message(
            Icons.search_off_rounded,
            _searchedIsbn != null
                ? context.l10n.searchIsbnNotFound(_searchedIsbn!)
                : context.l10n.searchNotFound,
            muted,
          )
        else if (_searchedIsbn != null && _results.isNotEmpty)
          _message(Icons.pin_rounded, context.l10n.searchIsbnResult(_searchedIsbn!), theme.colorScheme.primary),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: context.cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                for (final book in _results) _resultTile(book, theme, muted),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _message(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color))),
        ],
      ),
    );
  }

  Widget _resultTile(BookModel book, ThemeData theme, Color muted) {
    final details = [
      book.author,
      if (book.pageCount > 0) context.l10n.searchPageCount(book.pageCount),
    ].join(' · ');

    return InkWell(
      onTap: () => _select(book),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 36,
                height: 52,
                child: book.thumbnail == null
                    ? _coverPlaceholder(muted)
                    : Image.network(
                        book.thumbnail!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _coverPlaceholder(muted),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(details, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: muted)),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline_rounded, size: 20, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder(Color color) => Container(
        color: color.withValues(alpha: 0.1),
        child: Icon(Icons.menu_book_rounded, size: 18, color: color),
      );
}
