import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../l10n/l10n.dart';
import '../providers/today_provider.dart';
import '../providers/yearly_goal_provider.dart';
import '../services/reading_challenge.dart';
import '../theme/app_colors.dart';

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
    final finishedThisYear = ReadingChallenge.finishedIn(books, year).length;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLow,
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
    final fmt = DateFormat.MMMd(context.languageCode);

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
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.cs.outline, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Text(context.l10n.challengeFinishedBooksTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            if (byYear.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(context.l10n.challengeNoDatedBooks, style: TextStyle(color: context.cs.onSurfaceVariant)),
              ),
            for (final entry in byYear.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 8),
                child: Text(context.l10n.challengeYearHeader('${entry.key}', entry.value.length),
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1, color: Theme.of(context).colorScheme.primary)),
              ),
              for (final book in entry.value)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(Icons.check_circle_rounded, color: context.app.statusFinished),
                  title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(fmt.format(book.finishedAt!), style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 12)),
                ),
            ],
            if (withoutDate > 0)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  context.l10n.challengeUndatedBooks(withoutDate),
                  style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 12),
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
            Icon(Icons.emoji_events_outlined, color: context.app.rating),
            const SizedBox(width: 10),
            Text(context.l10n.challengeTitleWithYear('$year'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          finished == 0
              ? context.l10n.challengeSetGoalPrompt
              : context.l10n.challengeFinishedSoFar(finished),
          style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(onPressed: onCreate, icon: const Icon(Icons.flag_rounded), label: Text(context.l10n.challengeCreate)),
            const SizedBox(width: 8),
            if (finished > 0) TextButton(onPressed: onShowBooks, child: Text(context.l10n.challengeShowBooks)),
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
    final color = done ? context.app.rating : context.app.accent;
    final ahead = progress.booksAhead;
    final messageColor = done ? context.app.rating : (ahead <= -1 ? context.app.streak : context.app.statusFinished);

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
                  ? Icon(Icons.emoji_events_rounded, color: context.app.rating, size: 40)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${progress.finished}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26)),
                        Text(context.l10n.challengeOfGoal(progress.goal), style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 11)),
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
                  Expanded(child: Text(context.l10n.challengeShortTitle('${progress.year}'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.tune_rounded, size: 20),
                    tooltip: context.l10n.challengeChangeGoal,
                    onPressed: onEdit,
                  ),
                ],
              ),
              Text(
                done
                    ? context.l10n.challengeDoneCount(progress.finished, progress.goal)
                    : context.l10n.challengeRemaining(progress.goal - progress.finished),
                style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(progress.message, style: TextStyle(fontWeight: FontWeight.w800, color: messageColor)),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                  onPressed: onShowBooks,
                  child: Text(context.l10n.challengeShowFinished),
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
      title: Text(context.l10n.challengeTitleWithYear('${widget.year}')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.challengeDialogQuestion),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              suffixText: context.l10n.challengeBooksSuffix,
              errorText: value == null ? context.l10n.challengeGoalRange(YearlyGoalNotifier.maxGoal) : null,
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
            child: Text(context.l10n.challengeRemove, style: TextStyle(color: context.cs.error)),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.commonCancel)),
        ElevatedButton(
          onPressed: value == null ? null : () => Navigator.pop(context, _GoalResult(value)),
          child: Text(context.l10n.commonSave),
        ),
      ],
    );
  }
}
