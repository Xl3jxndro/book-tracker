import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../database/database.dart';
import '../l10n/l10n.dart';
import '../services/app_language.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'add_book_sheet.dart';

/// Texto de estado de un libro ("Leyendo · 11%", "Pendiente · 394 p."...).
/// Sin [l10n], en el idioma en uso.
String bookStatusLine(Book book, [AppLocalizations? l10n]) {
  final s = l10n ?? AppLanguage.strings;
  final pct = book.totalPages > 0 ? (book.readPages / book.totalPages * 100).clamp(0, 100).toInt() : 0;
  return switch (book.status) {
    1 => s.bookCardStatusReading(pct),
    2 => s.statusFinished,
    3 => s.bookCardStatusAbandoned(book.readPages, book.totalPages),
    _ => s.bookCardStatusPending(book.totalPages),
  };
}

double _progress(Book b) => b.totalPages > 0 ? (b.readPages / b.totalPages).clamp(0.0, 1.0) : 0.0;

void _openEditSheet(BuildContext context, Book book) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddBookSheet(bookToEdit: book),
  );
}

/// Libro en la vista de lista: portada, título, autor, estado y, si se está
/// leyendo, una barra de progreso fina. Mantener pulsado (o el lápiz) edita.
class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final String searchQuery;

  const BookCard({super.key, required this.book, required this.onTap, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = context.cs;
    final app = context.app;
    final isDNF = book.status == 3;
    final isFinished = book.status == 2;
    final statusColor = book.status == 1 ? app.accentText : app.forStatus(book.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        onLongPress: () => _openEditSheet(context, book),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: AppSpace.xs),
          child: Row(
            children: [
              BookCover(path: book.coverUrl, width: 60, height: 90, dimmed: isDNF, heroTag: 'cover_${book.id}'),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HighlightedText(
                      text: book.title,
                      query: searchQuery,
                      maxLines: 2,
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: isDNF ? cs.onSurfaceVariant : cs.onSurface,
                        decoration: isDNF ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    HighlightedText(
                      text: book.author,
                      query: searchQuery,
                      style: theme.textTheme.bodyMedium!.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            bookStatusLine(book, context.l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(color: statusColor),
                          ),
                        ),
                        if (isFinished && (book.rating ?? 0) > 0) ...[
                          const SizedBox(width: AppSpace.xs),
                          RatingStars(rating: book.rating!, size: 14),
                        ],
                      ],
                    ),
                    if (book.status == 1) ...[
                      const SizedBox(height: AppSpace.xs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _progress(book),
                          minHeight: 4,
                          color: app.accent,
                          backgroundColor: cs.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: context.l10n.bookCardEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: cs.onSurfaceVariant,
                onPressed: () => _openEditSheet(context, book),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Libro en la vista de cuadrícula: la portada protagoniza; debajo, título y
/// estado. Mantener pulsado edita.
class BookGridTile extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final String searchQuery;

  const BookGridTile({super.key, required this.book, required this.onTap, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = context.cs;
    final app = context.app;
    final isDNF = book.status == 3;
    final statusColor = book.status == 1 ? app.accentText : app.forStatus(book.status);

    return InkWell(
      borderRadius: AppRadius.mdAll,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      onLongPress: () => _openEditSheet(context, book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                BookCover(path: book.coverUrl, dimmed: isDNF, radius: 12, heroTag: 'cover_${book.id}'),
                if (book.status == 1)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _progress(book),
                        minHeight: 4,
                        color: app.accent,
                        backgroundColor: Colors.black.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          HighlightedText(
            text: book.title,
            query: searchQuery,
            maxLines: 2,
            style: theme.textTheme.titleSmall!.copyWith(
              height: 1.25,
              color: isDNF ? cs.onSurfaceVariant : cs.onSurface,
              decoration: isDNF ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 2),
          if (book.status == 2 && (book.rating ?? 0) > 0)
            RatingStars(rating: book.rating!, size: 12)
          else
            Text(
              switch (book.status) {
                1 => bookStatusLine(book, context.l10n),
                2 => context.l10n.statusFinished,
                3 => context.l10n.statusAbandoned,
                _ => context.l10n.statusPending,
              },
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: statusColor, letterSpacing: 0.2),
            ),
        ],
      ),
    );
  }
}

/// Portada del libro (o un marcador con icono si no tiene).
class BookCover extends StatelessWidget {
  final String? path;
  final double? width;
  final double? height;
  final double radius;
  final bool dimmed;

  /// Si se indica, la portada viaja a la pantalla del libro (Hero).
  final String? heroTag;

  const BookCover({super.key, required this.path, this.width, this.height, this.radius = 8, this.dimmed = false, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final hasFile = path != null && path!.isNotEmpty && File(path!).existsSync();
    final cover = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Opacity(
          opacity: dimmed ? 0.4 : 1,
          child: hasFile
              ? Image.file(File(path!), fit: BoxFit.cover, width: width, height: height)
              : ColoredBox(
                  color: cs.surfaceContainerHighest,
                  child: Center(child: Icon(Icons.menu_book_rounded, color: cs.onSurfaceVariant)),
                ),
        ),
      ),
    );
    return heroTag == null ? cover : Hero(tag: heroTag!, child: cover);
  }
}

/// Estrellas de valoración.
class RatingStars extends StatelessWidget {
  final int rating;
  final double size;
  const RatingStars({super.key, required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (i) => Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded, color: context.app.rating, size: size),
        ),
      );
}

/// Texto con las coincidencias de la búsqueda resaltadas.
class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final int maxLines;

  const HighlightedText({super.key, required this.text, required this.query, required this.style, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    final lower = text.toLowerCase();
    final q = query.trim().toLowerCase();
    if (q.isEmpty || !lower.contains(q)) {
      return Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }
    final highlight = TextStyle(
      fontWeight: FontWeight.w800,
      color: context.app.accentText,
      backgroundColor: context.app.accentSoft,
    );
    final spans = <TextSpan>[];
    var start = 0;
    int match;
    while ((match = lower.indexOf(q, start)) != -1) {
      if (match > start) spans.add(TextSpan(text: text.substring(start, match)));
      spans.add(TextSpan(text: text.substring(match, match + q.length), style: highlight));
      start = match + q.length;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return Text.rich(TextSpan(children: spans), style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
  }
}
