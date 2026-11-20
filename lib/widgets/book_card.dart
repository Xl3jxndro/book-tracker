import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import '../database/database.dart';
import 'add_book_sheet.dart';
import '../theme/app_colors.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final String searchQuery; // Añadido para el resaltado

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.searchQuery = '', // Por defecto vacío
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDNF = book.status == 3;
    final isFinished = book.status == 2;

    final double progress = book.totalPages > 0
        ? (book.readPages / book.totalPages).clamp(0.0, 1.0)
        : 0.0;
    final int percentage = (progress * 100).toInt();

    final Color accentColor = isDNF 
        ? context.app.statusAbandoned
        : (isFinished ? context.app.statusFinished : context.app.accent);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDNF 
            ? context.app.statusAbandoned.withValues(alpha: 0.06)
            : context.cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDNF 
              ? context.app.statusAbandoned.withValues(alpha: 0.2)
              : context.cs.outlineVariant,
          width: 1,
        ),
        boxShadow: [
          if (!isDNF)
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                _buildCoverImage(context, book.coverUrl, isDark, isDNF, accentColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusBadge(book.status, accentColor),
                          if (isFinished && (book.rating ?? 0) > 0)
                            _buildRatingStars(context, book.rating!)
                          else
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(Icons.edit_note_rounded, 
                                size: 20, 
                                color: isDNF ? context.cs.onSurfaceVariant : theme.colorScheme.primary.withValues(alpha: 0.7)),
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                _showEditSheet(context);
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // TÍTULO RESALTADO
                      _buildHighlightedText(
                        book.title, 
                        searchQuery, 
                        theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDNF ? context.cs.onSurfaceVariant : (context.cs.onSurface),
                          decoration: isDNF ? TextDecoration.lineThrough : null,
                        ) ?? const TextStyle(),
                        theme.colorScheme.primary,
                      ),
                      // AUTOR RESALTADO
                      _buildHighlightedText(
                        book.author, 
                        searchQuery, 
                        theme.textTheme.bodySmall?.copyWith(
                          color: isDNF ? context.cs.onSurfaceVariant.withValues(alpha: 0.6) : context.cs.onSurfaceVariant,
                        ) ?? const TextStyle(),
                        theme.colorScheme.primary.withValues(alpha: 0.8),
                      ),
                      const SizedBox(height: 12),
                      _buildProgressInfo(context, progress, percentage, isDNF, accentColor, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // NUEVA FUNCIÓN: Resaltado de texto
  Widget _buildHighlightedText(String text, String query, TextStyle baseStyle, Color highlightColor) {
    if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      return Text(text, style: baseStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final String lowercaseText = text.toLowerCase();
    final String lowercaseQuery = query.toLowerCase();
    
    List<TextSpan> spans = [];
    int start = 0;
    int indexOfMatch;

    while ((indexOfMatch = lowercaseText.indexOf(lowercaseQuery, start)) != -1) {
      if (indexOfMatch > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfMatch)));
      }
      spans.add(TextSpan(
        text: text.substring(indexOfMatch, indexOfMatch + query.length),
        style: TextStyle(
          color: highlightColor, 
          fontWeight: FontWeight.w900, // <--- Cambiado de .black a .w900
          backgroundColor: highlightColor.withValues(alpha: 0.15)
        ),
      ));
      start = indexOfMatch + query.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: baseStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProgressInfo(BuildContext context, double progress, int percentage, bool isDNF, Color accentColor, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isDNF ? 'ABANDONADO' : '$percentage%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: accentColor.withValues(alpha: 0.8),
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${book.readPages}/${book.totalPages} p.',
              style: TextStyle(fontSize: 10, color: context.cs.onSurfaceVariant, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: accentColor.withValues(alpha: 0.1),
            color: accentColor.withValues(alpha: isDNF ? 0.4 : 1.0),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingStars(BuildContext context, int rating) {
    return Row(
      children: List.generate(5, (index) => Icon(
        index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
        color: context.app.rating,
        size: 14,
      )),
    );
  }

  Widget _buildCoverImage(BuildContext context, String? url, bool isDark, bool isDNF, Color accentColor) {
    return Container(
      width: 80,
      height: 115,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Opacity(
                opacity: isDNF ? 0.3 : 1.0,
                child: url != null && url.isNotEmpty && File(url).existsSync()
                    ? Image.file(File(url), fit: BoxFit.cover)
                    : Container(
                        color: context.cs.surfaceContainerHighest,
                        child: Icon(Icons.book_rounded, color: context.cs.onSurfaceVariant),
                      ),
              ),
            ),
          ),
          if (isDNF)
            Center(
              child: Icon(Icons.close_rounded, color: context.app.statusAbandoned, size: 30),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(int status, Color color) {
    String text;
    IconData icon;

    switch (status) {
      case 2:
        text = 'TERMINADO';
        icon = Icons.check_circle_outline_rounded;
        break;
      case 1:
        text = 'LEYENDO';
        icon = Icons.import_contacts_rounded;
        break;
      case 3:
        text = 'DNF';
        icon = Icons.heart_broken_rounded;
        break;
      default:
        text = 'PENDIENTE';
        icon = Icons.schedule_rounded;
        color = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddBookSheet(bookToEdit: book),
    );
  }
}