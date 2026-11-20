import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/database_provider.dart';
import '../providers/today_provider.dart';
import '../widgets/reading_challenge_card.dart';
import '../widgets/share_year_summary.dart';
import '../widgets/streak_save_sheet.dart';
import '../widgets/native_ad_card.dart';
import '../services/ad_helper.dart';
import '../services/streak.dart';
import '../services/streak_save.dart';
import '../providers/streak_save_provider.dart';
import '../services/year_summary.dart';
import '../providers/yearly_goal_provider.dart';
import '../database/database.dart';
import '../theme/app_colors.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatReadingTime(int totalSeconds) {
    if (totalSeconds <= 0) return '0m';
    final duration = Duration(seconds: totalSeconds);
    if (duration.inHours > 0) return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    return '${duration.inMinutes}m';
  }

  void _shareYear(List<Book> books, List<ReadingSession> sessions) {
    final year = ref.read(todayProvider).year;
    final summary = YearSummary.compute(
      year: year,
      books: books,
      sessions: sessions,
      goal: ref.read(yearlyGoalProvider(year)),
      savedDays: ref.read(streakSaveProvider).savedDays,
    );
    if (summary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Aún no hay lecturas en $year para compartir. ¡Empieza un libro!'),
      ));
      return;
    }
    showYearSummaryShare(context, summary);
  }

  /// Racha actual, contando los días salvados con un anuncio.
  int _calculateStreak(List<ReadingSession> sessions) => ReadingStreak.current(
        StreakSave.withSavedDays(sessions.map((s) => s.date), ref.watch(streakSaveProvider).savedDays),
        DateTime.now(),
      );

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksStreamProvider);
    final sessionsAsync = ref.watch(sessionsStreamProvider);
    // Redibuja al cambiar el día (racha, mapa de calor y gráfico usan "hoy")
    ref.watch(todayProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.cs.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        title: Text('Estadísticas',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 28,
                color: context.cs.onSurface,
                letterSpacing: -1)),
        actions: [
          // Compartir "Mi año lector" como imagen
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              tooltip: 'Compartir mi año lector',
              icon: const Icon(Icons.ios_share_rounded),
              onPressed: () => _shareYear(booksAsync.value ?? const [], sessionsAsync.value ?? const []),
            ),
          ),
        ],
      ),
      body: booksAsync.when(
        data: (books) => sessionsAsync.when(
          data: (sessions) => _buildMainLayout(books, sessions, isDark),
          loading: () => const Center(child: CircularProgressIndicator.adaptive()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildMainLayout(List<Book> books, List<ReadingSession> sessions, bool isDark) {
    final completedBooks = books.where((b) => b.status == 2).length;
    // Las sesiones guardan el historial (no se pierde al "Releer"), pero los datos
    // anteriores a que existieran pueden estar solo en el libro: tomamos el mayor.
    final pagesFromBooks = books.fold<int>(0, (sum, b) => sum + b.readPages);
    final pagesFromSessions = sessions.fold<int>(0, (sum, s) => sum + s.pagesRead);
    final totalPagesRead = math.max(pagesFromBooks, pagesFromSessions);
    final totalSeconds = sessions.fold<int>(0, (sum, s) => sum + s.seconds);
    final streak = _calculateStreak(sessions);

    return Column(
      children: [
        const SizedBox(height: 10),
        _buildSummaryCarousel(completedBooks, totalPagesRead, totalSeconds, streak, isDark),
        const SizedBox(height: 25),
        _buildCustomTabBar(isDark),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildActivityTab(books, sessions, isDark),
              _buildLibraryTab(books, completedBooks, totalPagesRead, totalSeconds, streak, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCarousel(int completed, int pages, int seconds, int streak, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          GestureDetector(
            // Solo en versiones de prueba: ver la oferta de "salvar racha"
            onLongPress: kDebugMode
                ? () {
                    final now = DateTime.now();
                    showStreakSaveSheet(context, StreakSaveOffer(5, DateTime(now.year, now.month, now.day - 1)));
                  }
                : null,
            child: _miniStatCard("Racha", "$streak días", Icons.local_fire_department_rounded, context.app.streak, isDark),
          ),
          _miniStatCard("Leídos", completed.toString(), Icons.check_circle_rounded, context.app.accent, isDark),
          _miniStatCard("Páginas", pages.toString(), Icons.auto_stories_rounded, context.app.statusPending, isDark),
          _miniStatCard("Tiempo", _formatReadingTime(seconds), Icons.timer_rounded, context.cs.primary, isDark),
        ],
      ),
    );
  }

  Widget _miniStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Text(label, style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: context.cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(25),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: context.cs.onSurface,
            borderRadius: BorderRadius.circular(25),
          ),
          labelColor: context.cs.surface,
          unselectedLabelColor: context.cs.onSurfaceVariant,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "ACTIVIDAD"),
            Tab(text: "BIBLIOTECA"),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab(List<Book> books, List<ReadingSession> sessions, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          ReadingChallengeCard(books: books),
          const SizedBox(height: 32),
          ReadingHeatMap(sessions: sessions),
          NativeAdCard(adUnitId: AdHelper.statsNativeAdUnitId, margin: const EdgeInsets.only(top: 32)),
          const SizedBox(height: 40),
          _sectionHeader("Rendimiento Mensual", isDark),
          const SizedBox(height: 20),
          _buildMonthlyActivityChart(sessions, isDark),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLibraryTab(List<Book> books, int completed, int pages, int seconds, int streak, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _sectionHeader("Géneros Favoritos", isDark),
          const SizedBox(height: 20),
          _buildGenreSection(books, isDark),
          NativeAdCard(adUnitId: AdHelper.statsNativeAdUnitId, margin: const EdgeInsets.only(top: 32)),
          const SizedBox(height: 40),
          _sectionHeader("Logros y Desafíos", isDark),
          const SizedBox(height: 20),
          _buildAchievements(completed, pages, seconds, streak, isDark),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const Spacer(),
        Container(width: 40, height: 2, color: context.cs.outlineVariant),
      ],
    );
  }

  Widget _buildMonthlyActivityChart(List<ReadingSession> sessions, bool isDark) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final Map<int, int> dailySeconds = {for (var i = 1; i <= daysInMonth; i++) i: 0};

    for (var s in sessions) {
      if (s.date.year == now.year && s.date.month == now.month) {
        dailySeconds[s.date.day] = (dailySeconds[s.date.day] ?? 0) + s.seconds;
      }
    }

    final maxSec = dailySeconds.values.fold(1, (p, c) => c > p ? c : p).toDouble();
    final maxMin = (maxSec / 60).ceil();

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 20, 20, 15),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 45, bottom: 25),
            child: Text(
              DateFormat('MMMM yyyy', 'es').format(now).toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: context.app.accent, letterSpacing: 1),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                height: 150,
                width: 45,
                child: Row(
                  children: [
                    RotatedBox(
                      quarterTurns: 3,
                      child: Text("MINUTOS", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: context.cs.onSurfaceVariant.withValues(alpha: 0.6), letterSpacing: 1.5)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$maxMin', style: TextStyle(fontSize: 9, color: context.cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                          Text('${(maxMin / 2).round()}', style: TextStyle(fontSize: 9, color: context.cs.onSurfaceVariant)),
                          Text('0', style: TextStyle(fontSize: 9, color: context.cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 150,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(3, (i) => Container(height: 0.5, color: context.cs.outlineVariant)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(daysInMonth, (index) {
                          final day = index + 1;
                          final sec = dailySeconds[day] ?? 0;
                          final mins = (sec / 60).round();
                          final isToday = day == now.day;
                          final isSelected = selectedDayIndex == index;
                          final double barHeight = (sec / maxSec * 130).clamp(5.0, 130.0);

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => selectedDayIndex = index);
                                Future.delayed(const Duration(seconds: 3), () {
                                  if (mounted && selectedDayIndex == index) {
                                    setState(() => selectedDayIndex = null);
                                  }
                                });
                              },
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                clipBehavior: Clip.none,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: isSelected ? 8 : 6,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? context.app.streak
                                          : (isToday ? context.app.accent : (sec > 0 ? (context.cs.onSurfaceVariant) : context.cs.onSurfaceVariant.withValues(alpha: 0.15))),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      bottom: barHeight + 8,
                                      child: Material(
                                        elevation: 4,
                                        borderRadius: BorderRadius.circular(6),
                                        color: context.cs.onSurface,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                          child: Text(
                                            "$mins m",
                                            style: TextStyle(color: context.cs.surface, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 45, top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1', style: TextStyle(fontSize: 10, color: context.cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
                Text('${(daysInMonth / 2).round()}', style: TextStyle(fontSize: 10, color: context.cs.onSurfaceVariant)),
                Text('$daysInMonth', style: TextStyle(fontSize: 10, color: context.cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                "DÍA DEL MES",
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2.5, color: context.cs.onSurfaceVariant),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGenreSection(List<Book> books, bool isDark) {
    final Map<String, int> genreCounts = {};
    for (var book in books) {
      final categories = (book.category ?? 'General').split(',');
      for (var cat in categories) {
        final cleanCat = cat.trim();
        if (cleanCat.isNotEmpty) genreCounts[cleanCat] = (genreCounts[cleanCat] ?? 0) + 1;
      }
    }
    final sortedGenres = genreCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = genreCounts.values.fold<int>(0, (sum, val) => sum + val);

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            width: 140,
            child: CustomPaint(painter: PieChartPainter(sortedGenres, total, [context.app.accent, context.cs.primary, context.app.statusPending, context.app.statusFinished], context.cs.surfaceContainerHighest)),
          ),
          const SizedBox(height: 25),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: sortedGenres.take(4).map((e) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text("${e.key} ${total > 0 ? ((e.value / total) * 100).toInt() : 0}%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                )).toList(),
          )
        ],
      ),
    );
  }

  // --- LOGROS DESAFIANTES (CORTO, MEDIO Y LARGO PLAZO) ---
  Widget _buildAchievements(int completed, int pages, int seconds, int streak, bool isDark) {
    final totalHours = seconds / 3600;

    return Column(
      children: [
        _achievementCategory("Disciplina Temprana", isDark),
        _achievementRow("Hábito Formado", "Racha de 21 días", streak, 21, Icons.auto_awesome, isDark),
        _achievementRow("Velocista", "500 páginas leídas", pages, 500, Icons.bolt_rounded, isDark),
        
        const SizedBox(height: 20),
        
        _achievementCategory("Compromiso Serio", isDark),
        _achievementRow("Lector Voraz", "50 libros terminados", completed, 50, Icons.menu_book_rounded, isDark),
        _achievementRow("Medio Maratón", "250 horas de lectura", totalHours.toInt(), 250, Icons.timer_outlined, isDark),
        _achievementRow("Constancia Pura", "Racha de 100 días", streak, 100, Icons.local_fire_department_rounded, isDark),

        const SizedBox(height: 20),

        _achievementCategory("Nivel Erudito (3 años+)", isDark),
        _achievementRow("Bibliófilo de Oro", "100,000 páginas leídas", pages, 100000, Icons.whatshot, isDark, isLegendary: true),
        _achievementRow("Vida Entre Libros", "1,000 horas de lectura", totalHours.toInt(), 1000, Icons.import_contacts, isDark, isLegendary: true),
        _achievementRow("Inquebrantable", "Racha de 365 días", streak, 365, Icons.verified_user, isDark, isLegendary: true),
        _achievementRow("Maestro de Biblioteca", "250 libros completados", completed, 250, Icons.account_balance, isDark, isLegendary: true),
      ],
    );
  }

  Widget _achievementCategory(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title.toUpperCase(), 
          style: TextStyle(
            fontSize: 10, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1.5,
            color: context.cs.onSurfaceVariant
          )
        ),
      ),
    );
  }

  Widget _achievementRow(String title, String desc, num current, num target, IconData icon, bool isDark, {bool isLegendary = false}) {
    final bool unlocked = current >= target;
    final double progress = (current / target).clamp(0.0, 1.0);
    final Color activeColor = isLegendary ? context.app.rating : context.app.accent;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: unlocked 
              ? activeColor.withValues(alpha: isDark ? 0.08 : 0.03) 
              : (context.cs.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unlocked ? activeColor.withValues(alpha: 0.2) : (context.cs.outlineVariant), 
            width: 1
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: unlocked ? activeColor.withValues(alpha: 0.15) : (context.cs.outlineVariant),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    unlocked ? icon : Icons.lock_outline_rounded, 
                    color: unlocked ? activeColor : context.cs.onSurfaceVariant.withValues(alpha: 0.5), 
                    size: 22
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, 
                        style: TextStyle(
                          fontWeight: FontWeight.w800, 
                          fontSize: 15, 
                          color: unlocked ? (context.cs.onSurface) : context.cs.onSurfaceVariant,
                          letterSpacing: -0.3
                        )
                      ),
                      Text(desc, 
                        style: TextStyle(
                          fontSize: 12, 
                          color: context.cs.onSurfaceVariant
                        )
                      ),
                    ],
                  ),
                ),
                if (unlocked)
                  Icon(Icons.stars_rounded, color: activeColor, size: 20)
                else
                  Text("${(progress * 100).toInt()}%", 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.cs.onSurfaceVariant)
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // BARRA DE PROGRESO
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: context.cs.outlineVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  unlocked ? activeColor : activeColor.withValues(alpha: 0.4)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReadingHeatMap extends StatelessWidget {
  final List<ReadingSession> sessions;
  const ReadingHeatMap({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final Map<DateTime, int> data = {};
    final Set<DateTime> daysWithTime = {};
    for (var s in sessions) {
      final date = DateTime(s.date.year, s.date.month, s.date.day);
      data[date] = (data[date] ?? 0) + s.pagesRead;
      if (s.seconds > 0) daysWithTime.add(date);
    }

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final startDate = today.subtract(const Duration(days: 7 * 8)); 

    return Column(
      children: [
        const Text("Constancia", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              Wrap(
                spacing: 4, runSpacing: 4,
                children: List.generate(9, (weekIndex) {
                  return Column(
                    children: List.generate(7, (dayIndex) {
                      final date = startDate.add(Duration(days: (weekIndex * 7) + dayIndex));
                      final p = data[date] ?? 0;
                      // Un día con tiempo de lectura pero 0 páginas también cuenta como activo
                      final isActive = p > 0 || daysWithTime.contains(date);
                      final isFuture = date.isAfter(today);
                      return Container(
                        width: 12, height: 12, margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: isFuture ? Colors.transparent : (!isActive ? (context.cs.outlineVariant) : context.app.accent.withValues(alpha: (p/30).clamp(0.2, 1.0))),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      );
                    }),
                  );
                }),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Menos", style: TextStyle(fontSize: 10, color: context.cs.onSurfaceVariant)),
                  const SizedBox(width: 8),
                  _buildLegendSquare(context.cs.outlineVariant),
                  _buildLegendSquare(context.app.accent.withValues(alpha: 0.3)),
                  _buildLegendSquare(context.app.accent.withValues(alpha: 0.6)),
                  _buildLegendSquare(context.app.accent),
                  const SizedBox(width: 8),
                  Text("Más", style: TextStyle(fontSize: 10, color: context.cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendSquare(Color color) {
    return Container(
      width: 10, height: 10, margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final List<MapEntry<String, int>> data;
  final int total;
  final List<Color> colors;
  final Color trackColor;
  PieChartPainter(this.data, this.total, this.colors, this.trackColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 14..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2);
    double startAngle = -math.pi / 2;
    if (total == 0) {
      paint.color = trackColor;
      canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
      return;
    }
    for (int i = 0; i < math.min(data.length, colors.length); i++) {
      final sweepAngle = (data[i].value / total) * 2 * math.pi;
      paint.color = colors[i];
      canvas.drawArc(rect, startAngle + 0.1, sweepAngle - 0.2, false, paint);
      startAngle += sweepAngle;
    }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}