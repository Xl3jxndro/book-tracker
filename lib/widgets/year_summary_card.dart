import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../services/year_summary.dart';

/// Tarjeta "Mi año lector" para compartir como imagen (formato 9:16, el de
/// historias y estados). Colores fijos: se ve igual con tema claro u oscuro.
class YearSummaryCard extends StatelessWidget {
  final YearSummary summary;
  const YearSummaryCard({super.key, required this.summary});

  static const size = Size(360, 640);

  static String _thousands(int n) {
    final s = n.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final goal = s.goal;
    final goalDone = goal != null && s.booksFinished >= goal;

    return SizedBox.fromSize(
      size: size,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F1426), Color(0xFF2B1C33), Color(0xFF47334F)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white, decoration: TextDecoration.none, fontFamily: 'Roboto'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MI AÑO LECTOR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 3, color: Colors.white70)),
                Text('${s.year}', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, height: 1.05)),
                const SizedBox(height: 20),
                // Se reduce si el número es muy grande, en vez de desbordarse
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${s.booksFinished}', style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, height: 0.9)),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(s.booksFinished == 1 ? 'libro\nterminado' : 'libros\nterminados',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.15)),
                      ),
                    ],
                  ),
                ),
                if (goal != null) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (s.booksFinished / goal).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      color: goalDone ? const Color(0xFFFF8C12) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    goalDone ? '🏆 ¡Reto de $goal libros cumplido!' : 'Reto: ${s.booksFinished} de $goal libros',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    _Stat(value: _thousands(s.pagesRead), label: 'páginas'),
                    _Stat(value: s.readingTimeLabel, label: 'leyendo'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Stat(value: '${s.readingDays}', label: s.readingDays == 1 ? 'día con lectura' : 'días con lectura'),
                    _Stat(value: '${s.longestStreak}', label: s.longestStreak == 1 ? 'día de racha' : 'días de racha máx.'),
                  ],
                ),
                if (s.topCategory != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text('Género favorito: ${s.topCategory}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ],
                const Spacer(),
                if (s.recentFinished.isNotEmpty) ...[
                  const Text('Últimos terminados', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final book in s.recentFinished)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _Cover(path: book.coverUrl, title: book.title),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
                const Row(
                  children: [
                    Icon(Icons.auto_stories_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Book Tracker', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
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

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Se reduce para caber entero ("62 h 15 min") en vez de cortarse
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, maxLines: 1, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  final String? path;
  final String title;
  const _Cover({required this.path, required this.title});

  @override
  Widget build(BuildContext context) {
    final file = (path == null || path!.isEmpty) ? null : File(path!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 58,
        height: 86,
        child: file != null && file.existsSync()
            ? Image.file(file, fit: BoxFit.cover)
            : Container(
                color: Colors.white.withValues(alpha: 0.15),
                padding: const EdgeInsets.all(4),
                alignment: Alignment.center,
                child: Text(title, maxLines: 4, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
              ),
      ),
    );
  }
}
