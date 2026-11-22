import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../database/database.dart';
import '../services/reading_calendar.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'book_card.dart';

/// Calendario de lectura: cada día del mes coloreado según cuánto se leyó.
/// Al tocar un día se ve qué libros se leyeron, cuánto tiempo y páginas.
class ReadingCalendar extends StatefulWidget {
  final List<ReadingSession> sessions;
  final List<Book> books;

  /// Días con la racha salvada (cuentan para la racha aunque no se leyó).
  final Set<DateTime> savedDays;

  /// "Hoy" (para pruebas); por defecto, la fecha actual.
  final DateTime? today;

  const ReadingCalendar({
    super.key,
    required this.sessions,
    required this.books,
    this.savedDays = const {},
    this.today,
  });

  @override
  State<ReadingCalendar> createState() => _ReadingCalendarState();
}

class _ReadingCalendarState extends State<ReadingCalendar> {
  late DateTime _month; // día 1 del mes que se ve
  DateTime? _selected;

  DateTime get _today {
    final now = widget.today ?? DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _month = DateTime(_today.year, _today.month);
  }

  /// Primer mes con lecturas (no se puede ir más atrás).
  DateTime get _firstMonth {
    if (widget.sessions.isEmpty) return DateTime(_today.year, _today.month);
    final first = widget.sessions.map((s) => s.date).reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime(first.year, first.month);
  }

  bool get _canGoBack => _month.isAfter(_firstMonth);
  bool get _canGoForward => _month.isBefore(DateTime(_today.year, _today.month));

  void _changeMonth(int delta) {
    if (delta < 0 && !_canGoBack || delta > 0 && !_canGoForward) return;
    HapticFeedback.selectionClick();
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = readingByDay(widget.sessions);
    final summary = summarizeMonth(days, _month.year, _month.month);
    final monthName = toBeginningOfSentenceCase(DateFormat('MMMM y', 'es').format(_month));

    return GestureDetector(
      // Deslizar a los lados también cambia de mes
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v.abs() > 250) _changeMonth(v < 0 ? 1 : -1);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calendario', style: theme.textTheme.titleMedium),
                    Text(monthName, style: theme.textTheme.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Mes anterior',
                onPressed: _canGoBack ? () => _changeMonth(-1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Mes siguiente',
                onPressed: _canGoForward ? () => _changeMonth(1) : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          _weekdayHeader(context),
          const SizedBox(height: AppSpace.xs),
          _grid(context, days),
          const SizedBox(height: AppSpace.sm),
          _legend(context),
          const SizedBox(height: AppSpace.md),
          AnimatedSize(
            duration: AppMotion.medium,
            alignment: Alignment.topCenter,
            child: _selected == null
                ? _monthSummary(context, summary)
                : _dayDetail(context, _selected!, days[_selected!]),
          ),
        ],
      ),
    );
  }

  Widget _weekdayHeader(BuildContext context) {
    final letter = DateFormat('EEEEE', 'es');
    final monday = DateTime(2024, 1, 1); // un lunes
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Center(
              child: Text(
                letter.format(monday.add(Duration(days: i))).toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.cs.onSurfaceVariant),
              ),
            ),
          ),
      ],
    );
  }

  Color _levelColor(BuildContext context, int level) => switch (level) {
        0 => context.cs.surfaceContainerHigh,
        1 => context.app.accent.withValues(alpha: 0.25),
        2 => context.app.accent.withValues(alpha: 0.5),
        3 => context.app.accent.withValues(alpha: 0.75),
        _ => context.app.accent,
      };

  Widget _grid(BuildContext context, Map<DateTime, DayReading> days) {
    final cells = monthGrid(_month.year, _month.month);
    final saved = {for (final d in widget.savedDays) DateTime(d.year, d.month, d.day)};
    return Column(
      children: [
        for (var row = 0; row < cells.length ~/ 7; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(child: _dayCell(context, cells[row * 7 + col], days, saved)),
            ],
          ),
      ],
    );
  }

  Widget _dayCell(BuildContext context, DateTime? day, Map<DateTime, DayReading> days, Set<DateTime> saved) {
    if (day == null) return const AspectRatio(aspectRatio: 1, child: SizedBox());
    final theme = Theme.of(context);
    final reading = days[day];
    final level = readingLevel(reading);
    final isFuture = day.isAfter(_today);
    final isToday = day == _today;
    final isSelected = day == _selected;
    final isSaved = level == 0 && saved.contains(day);
    final strong = level >= 3;

    final label = DateFormat("EEEE d 'de' MMMM", 'es').format(day);
    final description = reading == null || !reading.hasReading
        ? (isSaved ? '$label, racha salvada' : '$label, sin lectura')
        : '$label, ${formatReadingDuration(reading.seconds)}, ${reading.pages} páginas';

    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(2.5),
        child: Semantics(
          button: !isFuture,
          selected: isSelected,
          label: description,
          excludeSemantics: true,
          child: Material(
            color: isFuture ? Colors.transparent : _levelColor(context, level),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.smAll,
              side: isSelected
                  ? BorderSide(color: context.cs.onSurface, width: 2)
                  : isToday
                      ? BorderSide(color: context.app.accent, width: 1.5)
                      : BorderSide.none,
            ),
            child: InkWell(
              borderRadius: AppRadius.smAll,
              onTap: isFuture
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      setState(() => _selected = isSelected ? null : day);
                    },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                      color: isFuture
                          ? context.cs.onSurfaceVariant.withValues(alpha: 0.4)
                          : strong
                              ? context.app.onAccent
                              : context.cs.onSurface,
                    ),
                  ),
                  if (isSaved)
                    Positioned(
                      bottom: 2,
                      child: Icon(Icons.local_fire_department_rounded, size: 10, color: context.app.streak),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _legend(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(color: context.cs.onSurfaceVariant);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Menos', style: style),
        const SizedBox(width: 6),
        for (var level = 0; level <= 4; level++)
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(color: _levelColor(context, level), borderRadius: BorderRadius.circular(3)),
          ),
        const SizedBox(width: 6),
        Text('Más', style: style),
      ],
    );
  }

  Widget _monthSummary(BuildContext context, MonthSummary summary) {
    final theme = Theme.of(context);
    if (summary.daysRead == 0) {
      return Text(
        _month.year == _today.year && _month.month == _today.month
            ? 'Aún no has leído este mes. Toca un día para ver su detalle.'
            : 'No hay lecturas este mes.',
        style: theme.textTheme.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant),
      );
    }
    final best = summary.bestDay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _stat(context, '${summary.daysRead}', summary.daysRead == 1 ? 'día leído' : 'días leídos'),
            _stat(context, formatReadingDuration(summary.seconds), 'en total'),
            _stat(context, NumberFormat.decimalPattern('es').format(summary.pages), 'páginas'),
          ],
        ),
        if (best != null) ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            'Tu mejor día: ${DateFormat("d 'de' MMMM", 'es').format(best.day)} · '
            '${best.seconds > 0 ? formatReadingDuration(best.seconds) : '${best.pages} páginas'}',
            style: theme.textTheme.bodySmall?.copyWith(color: context.cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: context.cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _dayDetail(BuildContext context, DateTime day, DayReading? reading) {
    final theme = Theme.of(context);
    final title = toBeginningOfSentenceCase(DateFormat("EEEE d 'de' MMMM", 'es').format(day));
    final booksById = {for (final b in widget.books) b.id: b};
    final saved = widget.savedDays.any((d) => d.year == day.year && d.month == day.month && d.day == day.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
            if (reading != null && reading.hasReading)
              Text(
                '${formatReadingDuration(reading.seconds)} · ${reading.pages} págs.',
                style: theme.textTheme.bodySmall?.copyWith(color: context.cs.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        if (reading == null || !reading.hasReading)
          Text(
            saved ? 'No leíste, pero salvaste tu racha este día.' : 'Este día no leíste.',
            style: theme.textTheme.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant),
          )
        else
          for (final entry in reading.books)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  BookCover(path: booksById[entry.bookId]?.coverUrl, width: 28, height: 42, radius: 4),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      booksById[entry.bookId]?.title ?? 'Libro eliminado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    [
                      if (entry.seconds > 0) formatReadingDuration(entry.seconds),
                      if (entry.pages > 0) '${entry.pages} págs.',
                    ].join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(color: context.cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
