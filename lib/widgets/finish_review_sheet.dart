import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';

/// Resumen de la lectura terminada: "12 días · 6 h 30 min · 417 páginas".
String finishSummary(Book book) {
  final parts = <String>[];
  if (book.startedAt != null && book.finishedAt != null) {
    final days = DateUtils.dateOnly(book.finishedAt!).difference(DateUtils.dateOnly(book.startedAt!)).inDays + 1;
    if (days > 0) parts.add(days == 1 ? 'en 1 día' : 'en $days días');
  }
  final minutes = book.totalReadTime ~/ 60;
  if (minutes > 0) {
    final h = minutes ~/ 60, m = minutes % 60;
    parts.add(h == 0 ? '$m min de lectura' : (m == 0 ? '$h h de lectura' : '$h h $m min de lectura'));
  }
  if (book.totalPages > 0) parts.add('${book.totalPages} páginas');
  return parts.join(' · ');
}

/// Hoja que aparece al terminar un libro: calificación y reseña opcional.
Future<void> showFinishReviewSheet(BuildContext context, Book book) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FinishReviewSheet(book: book),
  );
}

class FinishReviewSheet extends ConsumerStatefulWidget {
  final Book book;
  const FinishReviewSheet({super.key, required this.book});

  @override
  ConsumerState<FinishReviewSheet> createState() => _FinishReviewSheetState();
}

class _FinishReviewSheetState extends ConsumerState<FinishReviewSheet> {
  final _controller = TextEditingController();
  late int _rating = widget.book.rating ?? 0;
  bool _saving = false;

  static const _ratingLabels = ['', 'No me gustó', 'Regular', 'Bueno', 'Muy bueno', '¡Me encantó!'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final hasText = _controller.text.trim().isNotEmpty;
    await ref.read(databaseProvider).saveReview(widget.book.id, rating: _rating, text: _controller.text);
    HapticFeedback.mediumImpact();
    navigator.pop();
    if (hasText || _rating > 0) {
      messenger.showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(hasText ? 'Reseña guardada en tus notas ✍️' : 'Calificación guardada ⭐'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = finishSummary(widget.book);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[500], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                const Text('🎉', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                Text('¡Terminaste ${widget.book.title}!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(summary, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 20),
                Text('¿Cómo lo calificas?', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final value = i + 1;
                    return IconButton(
                      tooltip: '$value ${value == 1 ? 'estrella' : 'estrellas'}',
                      iconSize: 38,
                      icon: Icon(value <= _rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber.shade600),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _rating = value);
                      },
                    );
                  }),
                ),
                SizedBox(
                  height: 20,
                  child: Text(_ratingLabels[_rating], style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 2,
                  maxLength: 900,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: '¿Qué te pareció? Una frase basta (opcional)',
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _saving ? null : () => Navigator.pop(context),
                        child: const Text('AHORA NO'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: const Text('GUARDAR'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
