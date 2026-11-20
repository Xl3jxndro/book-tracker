import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../theme/app_colors.dart';

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

/// Hoja de calificación y reseña. Con [celebrate] es la que aparece justo al
/// terminar el libro; sin él, la de "Escribir/Editar reseña" (en cualquier
/// momento, también para libros abandonados).
Future<void> showFinishReviewSheet(BuildContext context, Book book, {bool celebrate = true}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FinishReviewSheet(book: book, celebrate: celebrate),
  );
}

class FinishReviewSheet extends ConsumerStatefulWidget {
  final Book book;
  final bool celebrate;
  const FinishReviewSheet({super.key, required this.book, this.celebrate = true});

  @override
  ConsumerState<FinishReviewSheet> createState() => _FinishReviewSheetState();
}

class _FinishReviewSheetState extends ConsumerState<FinishReviewSheet> {
  final _controller = TextEditingController();
  late int _rating = widget.book.rating ?? 0;
  bool _saving = false;
  bool _hadReview = false;

  bool get _abandoned => widget.book.status == 3;

  @override
  void initState() {
    super.initState();
    // Si ya tiene reseña, se edita (no se crea otra)
    ref.read(databaseProvider).getReview(widget.book.id).then((note) {
      if (note == null || !mounted || _controller.text.isNotEmpty) return;
      setState(() {
        _hadReview = true;
        _controller.text = AppDatabase.reviewText(note);
      });
    });
  }

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
    final message = hasText
        ? 'Reseña guardada en tus notas ✍️'
        : _hadReview
            ? 'Reseña eliminada'
            : (_rating > 0 ? 'Calificación guardada ⭐' : null);
    if (message != null) {
      messenger.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)));
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
                Container(width: 40, height: 4, decoration: BoxDecoration(color: context.cs.outline, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text(widget.celebrate ? '🎉' : (_abandoned ? '📕' : '✍️'), style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                Text(
                    widget.celebrate
                        ? '¡Terminaste ${widget.book.title}!'
                        : (_hadReview ? 'Tu reseña de ${widget.book.title}' : 'Reseña de ${widget.book.title}'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                if (_abandoned && !widget.celebrate) ...[
                  const SizedBox(height: 6),
                  Text('Lo dejaste sin terminar', textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
                ] else if (summary.isNotEmpty && widget.book.status == 2) ...[
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
                      icon: Icon(value <= _rating ? Icons.star_rounded : Icons.star_outline_rounded, color: context.app.rating),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _rating = value);
                      },
                    );
                  }),
                ),
                SizedBox(
                  height: 20,
                  child: Text(_ratingLabels[_rating], style: TextStyle(color: context.app.rating, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 2,
                  maxLength: 900,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: _abandoned
                        ? '¿Por qué lo dejaste? (opcional)'
                        : '¿Qué te pareció? Una frase basta (opcional)',
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
                        child: Text(widget.celebrate ? 'AHORA NO' : 'CANCELAR'),
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
