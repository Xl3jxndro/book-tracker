import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../providers/today_provider.dart';
import '../providers/yearly_goal_provider.dart';
import '../services/reading_challenge.dart';

/// Tarjeta del reto anual en Estadísticas: crear la meta, ver el progreso
/// (adelantado/atrasado) y la lista de libros terminados por año.
class ReadingChallengeCard extends ConsumerWidget {
  final List<Book> books;
  const ReadingChallengeCard({super.key, required this.books});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final year = today.year;
    final goal = ref.watch(yearlyGoalProvider(year));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final finishedThisYear = ReadingChallenge.finishedIn(books, year).length;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: goal == null
          ? _NoGoal(year: year, finished: finishedThisYear, onCreate: () => _editGoal(context, ref, year, null), onShowBooks: () => _showBooksByYear(context))
          : _Progress(
              progress: ReadingChallenge.progress(goal: goal, books: books, now: DateTime.now()),
              onEdit: () => _editGoal(context, ref, year, goal),
              onShowBooks: () => _showBooksByYear(context),
            ),
    );
  }

  Future<void> _editGoal(BuildContext context, WidgetRef ref, int year, int? current) async {
    final result = await showDialog<_GoalResult>(
      context: context,
      builder: (_) => _GoalDialog(year: year, current: current),
    );
    if (result == null) return;
    HapticFeedback.selectionClick();
    await ref.read(yearlyGoalProvider(year).notifier).setGoal(result.goal);
  }

  void _showBooksByYear(BuildContext context) {
    final byYear = ReadingChallenge.finishedByYear(books);
    final withoutDate = ReadingChallenge.finishedWithoutDate(books);
    final fmt = DateFormat("d MMM", 'es');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            const Text('Libros terminados', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            if (byYear.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Text('Aún no hay libros terminados con fecha.', style: TextStyle(color: Colors.grey)),
              ),
            for (final entry in byYear.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 8),
                child: Text('${entry.key} · ${entry.value.length} ${entry.value.length == 1 ? 'libro' : 'libros'}',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1, color: Theme.of(context).colorScheme.primary)),
              ),
              for (final book in entry.value)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.check_circle_rounded, color: Colors.green),
                  title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(fmt.format(book.finishedAt!), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ),
            ],
            if (withoutDate > 0)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  '$withoutDate ${withoutDate == 1 ? 'libro terminado no tiene' : 'libros terminados no tienen'} fecha de fin. '
                  'Puedes añadirla en el detalle de cada libro para que cuente en su año.',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoGoal extends StatelessWidget {
  final int year;
  final int finished;
  final VoidCallback onCreate;
  final VoidCallback onShowBooks;
  const _NoGoal({required this.year, required this.finished, required this.onCreate, required this.onShowBooks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events_outlined, color: Colors.amber),
            const SizedBox(width: 10),
            Text('Reto de lectura $year', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          finished == 0
              ? 'Ponte una meta de libros para este año.'
              : 'Llevas $finished ${finished == 1 ? 'libro terminado' : 'libros terminados'} este año. ¿Te pones una meta?',
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(onPressed: onCreate, icon: const Icon(Icons.flag_rounded), label: const Text('Crear reto')),
            const SizedBox(width: 8),
            if (finished > 0) TextButton(onPressed: onShowBooks, child: const Text('Ver libros')),
          ],
        ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  final ChallengeProgress progress;
  final VoidCallback onEdit;
  final VoidCallback onShowBooks;
  const _Progress({required this.progress, required this.onEdit, required this.onShowBooks});

  @override
  Widget build(BuildContext context) {
    final done = progress.isCompleted;
    final color = done ? Colors.amber : Colors.indigoAccent;
    final ahead = progress.booksAhead;
    final messageColor = done ? Colors.amber.shade700 : (ahead <= -1 ? Colors.orange : Colors.green);

    return Row(
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: progress.fraction,
                  strokeWidth: 9,
                  strokeCap: StrokeCap.round,
                  backgroundColor: color.withValues(alpha: 0.15),
                  color: color,
                ),
              ),
              done
                  ? const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 40)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${progress.finished}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26)),
                        Text('de ${progress.goal}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Reto ${progress.year}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.tune_rounded, size: 20),
                    tooltip: 'Cambiar meta',
                    onPressed: onEdit,
                  ),
                ],
              ),
              Text(
                done ? '${progress.finished} de ${progress.goal} libros' : '${progress.goal - progress.finished} por leer para tu meta',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(progress.message, style: TextStyle(fontWeight: FontWeight.w800, color: messageColor)),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                  onPressed: onShowBooks,
                  child: const Text('Ver libros terminados'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalResult {
  final int? goal; // null = quitar el reto
  const _GoalResult(this.goal);
}

class _GoalDialog extends StatefulWidget {
  final int year;
  final int? current;
  const _GoalDialog({required this.year, required this.current});

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.current?.toString() ?? '12');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _value {
    final v = int.tryParse(_controller.text.trim());
    return (v == null || v <= 0 || v > YearlyGoalNotifier.maxGoal) ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    final value = _value;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text('Reto de lectura ${widget.year}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¿Cuántos libros quieres leer este año?'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              suffixText: 'libros',
              errorText: value == null ? 'Entre 1 y ${YearlyGoalNotifier.maxGoal}' : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final s in YearlyGoalNotifier.suggestions)
                ChoiceChip(
                  label: Text('$s'),
                  selected: value == s,
                  onSelected: (_) => setState(() => _controller.text = '$s'),
                ),
            ],
          ),
        ],
      ),
      actions: [
        if (widget.current != null)
          TextButton(
            onPressed: () => Navigator.pop(context, const _GoalResult(null)),
            child: const Text('QUITAR RETO', style: TextStyle(color: Colors.redAccent)),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
        ElevatedButton(
          onPressed: value == null ? null : () => Navigator.pop(context, _GoalResult(value)),
          child: const Text('GUARDAR'),
        ),
      ],
    );
  }
}
