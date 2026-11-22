import 'dart:async';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../database/database.dart';
import '../l10n/l10n.dart';
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

  /// Hacia dónde se movió el último cambio de mes (para la animación).
  int _direction = 0;

  /// Aviso breve al intentar pasar del primer mes con lecturas o del actual.
  String? _limitMessage;
  Timer? _limitTimer;

  @override
  void dispose() {
    _limitTimer?.cancel();
    super.dispose();
  }

  void _changeMonth(int delta) {
    if (delta < 0 && !_canGoBack || delta > 0 && !_canGoForward) {
      HapticFeedback.lightImpact();
      final l10n = context.l10n;
      _showLimit(delta < 0
          ? (widget.sessions.isEmpty
              ? l10n.calendarHistoryStartsHere
              : l10n.calendarHistoryStartsIn(DateFormat.yMMMM(context.languageCode).format(_firstMonth)))
          : l10n.calendarCurrentMonth);
      return;
    }
    HapticFeedback.selectionClick();
    _limitTimer?.cancel();
    setState(() {
      _direction = delta;
      _month = DateTime(_month.year, _month.month + delta);
      _selected = null;
      _limitMessage = null;
    });
  }

  void _showLimit(String message) {
    _limitTimer?.cancel();
    setState(() => _limitMessage = message);
    _limitTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _limitMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = readingByDay(widget.sessions);
    final summary = summarizeMonth(days, _month.year, _month.month);
    final monthName = toBeginningOfSentenceCase(DateFormat.yMMMM(context.languageCode).format(_month), context.languageCode);

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
                    Text(context.l10n.calendarTitle, style: theme.textTheme.titleMedium),
                    Text(monthName, style: theme.textTheme.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant)),
                  ],
                ),
              ),
              // Siempre se pueden tocar: en el límite explican por qué no hay más
              IconButton(
                tooltip: context.l10n.calendarPreviousMonth,
                onPressed: () => _changeMonth(-1),
                color: _canGoBack ? null : context.cs.onSurfaceVariant.withValues(alpha: 0.38),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: context.l10n.calendarNextMonth,
                onPressed: () => _changeMonth(1),
                color: _canGoForward ? null : context.cs.onSurfaceVariant.withValues(alpha: 0.38),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          AnimatedSize(
            duration: AppMotion.fast,
            alignment: Alignment.topCenter,
            child: _limitMessage == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpace.xxs),
                    child: Text(
                      _limitMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(color: context.app.accentText),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpace.sm),
          _weekdayHeader(context),
          const SizedBox(height: AppSpace.xs),
          ClipRect(
            child: AnimatedSwitcher(
              duration: AppMotion.medium,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              transitionBuilder: (child, animation) {
                final incoming = child.key == ValueKey(_month);
                final dx = _direction == 0 ? 0.0 : (incoming ? _direction * 0.25 : -_direction * 0.25);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: Offset(dx, 0), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(key: ValueKey(_month), child: _grid(context, days)),
            ),
          ),
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
    final letter = DateFormat('EEEEE', context.languageCode);
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

    final l10n = context.l10n;
    final label = DateFormat.MMMMEEEEd(context.languageCode).format(day);
    final description = reading == null || !reading.hasReading
        ? (isSaved ? l10n.calendarDaySavedSemantics(label) : l10n.calendarDayNoReadingSemantics(label))
        : l10n.calendarDayReadingSemantics(label, formatReadingDuration(reading.seconds), reading.pages);

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
        Text(context.l10n.calendarLegendLess, style: style),
        const SizedBox(width: 6),
        for (var level = 0; level <= 4; level++)
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(color: _levelColor(context, level), borderRadius: BorderRadius.circular(3)),
          ),
        const SizedBox(width: 6),
        Text(context.l10n.calendarLegendMore, style: style),
      ],
    );
  }

  Widget _monthSummary(BuildContext context, MonthSummary summary) {
    final theme = Theme.of(context);
    if (summary.daysRead == 0) {
      return Text(
        _month.year == _today.year && _month.month == _today.month
            ? context.l10n.calendarNoReadingYetThisMonth
            : context.l10n.calendarNoReadingThisMonth,
        style: theme.textTheme.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant),
      );
    }
    final best = summary.bestDay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _stat(context, '${summary.daysRead}', context.l10n.calendarDaysReadLabel(summary.daysRead)),
            _stat(context, formatReadingDuration(summary.seconds), context.l10n.calendarTotalLabel),
            _stat(context, NumberFormat.decimalPattern(context.languageCode).format(summary.pages),
                context.l10n.calendarPagesLabel(summary.pages)),
          ],
        ),
        if (best != null) ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            context.l10n.calendarBestDay(
              DateFormat.MMMMd(context.languageCode).format(best.day),
              best.seconds > 0 ? formatReadingDuration(best.seconds) : context.l10n.calendarPagesCount(best.pages),
            ),
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
    final title = toBeginningOfSentenceCase(DateFormat.MMMMEEEEd(context.languageCode).format(day), context.languageCode);
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
                '${formatReadingDuration(reading.seconds)} · ${context.l10n.calendarPagesShort(reading.pages)}',
                style: theme.textTheme.bodySmall?.copyWith(color: context.cs.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        if (reading == null || !reading.hasReading)
          Text(
            saved ? context.l10n.calendarDaySavedDetail : context.l10n.calendarDayNoReadingDetail,
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
                      booksById[entry.bookId]?.title ?? context.l10n.calendarDeletedBook,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Text(
                    [
                      if (entry.seconds > 0) formatReadingDuration(entry.seconds),
                      if (entry.pages > 0) context.l10n.calendarPagesShort(entry.pages),
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
