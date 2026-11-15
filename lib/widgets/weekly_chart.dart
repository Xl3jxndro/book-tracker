import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../database/database.dart';

class WeeklyChart extends StatelessWidget {
  final List<ReadingSession> sessions;
  const WeeklyChart({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Color dinámico: Si el fondo es blanco, usamos Indigo. Si es oscuro, usamos Blanco.
    final barColor = isDark ? Colors.white : Colors.indigoAccent;
    
    // Agrupar minutos por día de la semana
    Map<int, double> dailyMinutes = {};
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final daySessions = sessions.where((s) => 
        s.date.day == date.day && s.date.month == date.month && s.date.year == date.year).toList();
      
      double totalMins = daySessions.fold(0, (sum, s) => sum + (s.seconds / 60));
      dailyMinutes[date.weekday] = totalMins;
    }

    // Calculamos el máximo para que el gráfico no se vea vacío
    double maxMins = dailyMinutes.values.isEmpty 
        ? 10 
        : dailyMinutes.values.reduce((a, b) => a > b ? a : b);
    if (maxMins < 5) maxMins = 5; // Altura mínima de escala

    return Container(
      height: 180,
      padding: const EdgeInsets.only(top: 20),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxMins * 1.2, // Damos un 20% de aire arriba
          barGroups: _generateGroups(dailyMinutes, barColor),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['', 'L', 'M', 'X', 'J', 'V', 'S', 'D'];
                  if (value < 1 || value > 7) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(days[value.toInt()], 
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey, 
                        fontSize: 10,
                        fontWeight: FontWeight.bold
                      )),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.indigoAccent,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toStringAsFixed(1)} min',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateGroups(Map<int, double> data, Color color) {
    return List.generate(7, (index) {
      final weekDay = index + 1;
      final value = data[weekDay] ?? 0.0;
      
      return BarChartGroupData(
        x: weekDay,
        barRods: [
          BarChartRodData(
            toY: value,
            color: color,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 0, // Opcional: podrías poner una sombra de fondo aquí
              color: color.withOpacity(0.1),
            ),
          )
        ],
      );
    });
  }
}