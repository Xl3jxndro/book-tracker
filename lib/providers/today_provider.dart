import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// El día de hoy (sin hora). Cambia solo a medianoche y se revisa al volver
/// a la app, así lo que depende de "hoy" (meta diaria, racha, gráficas) no se
/// queda en el día anterior si la app sigue abierta.
final todayProvider = NotifierProvider<TodayNotifier, DateTime>(TodayNotifier.new);

class TodayNotifier extends Notifier<DateTime> with WidgetsBindingObserver {
  final DateTime Function() _now;
  final bool _autoSchedule;
  Timer? _midnightTimer;

  TodayNotifier({DateTime Function()? now, bool autoSchedule = true})
      : _now = now ?? DateTime.now,
        _autoSchedule = autoSchedule;

  @override
  DateTime build() {
    if (_autoSchedule) {
      WidgetsBinding.instance.addObserver(this);
      _scheduleMidnight();
    }
    ref.onDispose(() {
      _midnightTimer?.cancel();
      if (_autoSchedule) WidgetsBinding.instance.removeObserver(this);
    });
    return dateOnly(_now());
  }

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Tiempo que falta para el próximo cambio de día (+1 s de margen).
  static Duration untilNextDay(DateTime now) {
    final next = DateTime(now.year, now.month, now.day + 1);
    return next.difference(now) + const Duration(seconds: 1);
  }

  /// Vuelve a calcular el día; solo notifica si cambió.
  void refresh() {
    final today = dateOnly(_now());
    if (today != state) state = today;
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    _midnightTimer = Timer(untilNextDay(_now()), () {
      refresh();
      _scheduleMidnight();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Los temporizadores no avanzan con el teléfono dormido: revisar al volver
    if (state == AppLifecycleState.resumed) {
      refresh();
      _scheduleMidnight();
    }
  }
}
