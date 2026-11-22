import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../providers/continue_reading_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'book_card.dart';

/// Tarjeta destacada de la biblioteca con el libro actual: tocarla abre el
/// libro; el botón de reproducir abre el libro con el cronómetro en marcha.
class ContinueReadingCard extends StatelessWidget {
  final ContinueReading item;
  final VoidCallback onOpen;
  final VoidCallback onStart;

  const ContinueReadingCard({super.key, required this.item, required this.onOpen, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = context.cs;
    final app = context.app;
    final book = item.book;
    final progress = book.totalPages > 0 ? (book.readPages / book.totalPages).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).toInt();
    final l10n = context.l10n;
    final label = item.inSession
        ? l10n.homeContinueInSession
        : (book.status == 0 ? l10n.homeContinueStart : l10n.homeContinueReading);

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: AppRadius.xxlAll,
      child: InkWell(
        borderRadius: AppRadius.xxlAll,
        onTap: () {
          HapticFeedback.lightImpact();
          onOpen();
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Row(
            children: [
              BookCover(path: book.coverUrl, width: 72, height: 108, radius: 10, heroTag: 'continue_cover_${book.id}'),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.labelSmall?.copyWith(color: app.accentText, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleLarge),
                    Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: AppSpace.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        color: app.accent,
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      book.totalPages > 0
                          ? l10n.homeContinueProgress(pct, book.readPages, book.totalPages)
                          : l10n.homeContinuePages(book.readPages),
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              IconButton(
                tooltip: item.inSession ? l10n.homeContinueViewSession : l10n.homeQuickStart,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onStart();
                },
                icon: Icon(item.inSession ? Icons.timer_outlined : Icons.play_arrow_rounded, size: 28),
                style: IconButton.styleFrom(
                  fixedSize: const Size(56, 56),
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
