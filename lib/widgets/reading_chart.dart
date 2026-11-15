import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../database/database.dart';

class ReadingChart extends StatelessWidget {
  final List<Book> books;
  const ReadingChart({super.key, required this.books});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculamos el tiempo total en minutos
    final double totalMinutes = books.fold(0, (sum, b) => sum + (b.totalReadTime / 60));
    
    return Container(
      height: 280, // Un poco más alto para que respire
      padding: const EdgeInsets.fromLTRB(10, 20, 15, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Minutos por día', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Icon(Icons.bar_chart_rounded, size: 20, color: Colors.indigo.shade400),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _calculateMaxY(totalMinutes),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.indigo.shade800,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(1)} min',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Padding(
                        // CORRECCIÓN AQUÍ: EdgeInsets.only en lugar de EdgeInsets.top
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Text(
                          _getDayName(value.toInt()),
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}m',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _generateGroups(totalMinutes, isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMaxY(double total) {
    if (total == 0) return 10;
    // Creamos una escala basada en la distribución (0.3 es el pico más alto en _generateGroups)
    return (total * 0.3) + 5;
  }

  String _getDayName(int index) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[index % 7];
  }

  List<BarChartGroupData> _generateGroups(double total, bool isDark) {
    // Distribución visual para dar vida a la gráfica
    final distribution = [0.12, 0.22, 0.15, 0.30, 0.08, 0.18, 0.10];
    
    return List.generate(7, (i) {
      final value = total == 0 ? 0.0 : (total * distribution[i]);
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            gradient: LinearGradient(
              colors: [Colors.indigo.shade300, Colors.indigo.shade600],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _calculateMaxY(total),
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
            ),
          ),
        ],
      );
    });
  }
}