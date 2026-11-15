import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';

class ReadingHeatMap extends StatelessWidget {
  final List<ReadingSession> sessions;
  
  const ReadingHeatMap({super.key, required this.sessions});

  // Agrupa las sesiones por fecha (sin hora) y suma las páginas
  Map<DateTime, int> get _processedData {
    final Map<DateTime, int> data = {};
    for (var s in sessions) {
      final date = DateTime(s.date.year, s.date.month, s.date.day);
      data[date] = (data[date] ?? 0) + s.pagesRead;
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _processedData;
    
    // Calculamos las últimas 15 semanas para el grid
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Buscamos el lunes de hace 15 semanas para que el grid esté alineado
    final startDate = today.subtract(Duration(days: today.weekday - 1 + (14 * 7)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            "ACTIVIDAD DE LECTURA",
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary.withOpacity(0.6),
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(15, (weekIndex) {
                return Column(
                  children: List.generate(7, (dayIndex) {
                    final date = startDate.add(Duration(days: (weekIndex * 7) + dayIndex));
                    
                    // Si la fecha es futura, no la pintamos o la pintamos transparente
                    if (date.isAfter(today)) {
                      return Container(width: 14, height: 14, margin: const EdgeInsets.all(2));
                    }

                    final pages = data[date] ?? 0;
                    return _buildDayBox(context, pages, date);
                  }),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildLegend(theme),
      ],
    );
  }

  Widget _buildDayBox(BuildContext context, int pages, DateTime date) {
    final theme = Theme.of(context);
    
    // Definimos la intensidad del color según las páginas leídas
    Color boxColor;
    if (pages == 0) {
      boxColor = theme.brightness == Brightness.dark 
          ? Colors.white.withOpacity(0.05) 
          : Colors.black.withOpacity(0.05);
    } else if (pages < 10) {
      boxColor = theme.colorScheme.primary.withOpacity(0.3);
    } else if (pages < 30) {
      boxColor = theme.colorScheme.primary.withOpacity(0.5);
    } else if (pages < 60) {
      boxColor = theme.colorScheme.primary.withOpacity(0.7);
    } else {
      boxColor = theme.colorScheme.primary;
    }

    return Tooltip(
      message: "${DateFormat('d MMM').format(date)}: $pages pág.",
      child: Container(
        width: 14,
        height: 14,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: boxColor,
          borderRadius: BorderRadius.circular(3.5),
        ),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text("Menos", style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey)),
          const SizedBox(width: 4),
          _legendBox(theme.colorScheme.primary.withOpacity(0.1)),
          _legendBox(theme.colorScheme.primary.withOpacity(0.4)),
          _legendBox(theme.colorScheme.primary.withOpacity(0.7)),
          _legendBox(theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text("Más", style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _legendBox(Color color) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }
}