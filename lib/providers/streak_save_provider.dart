import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/streak_save.dart';

/// Días salvados de la racha (anuncio recompensado) y estado de la oferta.
final streakSaveProvider = StateNotifierProvider<StreakSaveNotifier, StreakSaveState>((ref) => StreakSaveNotifier());

class StreakSaveNotifier extends StateNotifier<StreakSaveState> {
  StreakSaveNotifier() : super(const StreakSaveState()) {
    _load();
  }

  final _ready = Completer<void>();

  /// Se completa cuando ya se leyó lo guardado.
  Future<void> get ready => _ready.future;

  Future<void> _load() async {
    final s = await StreakSave.load();
    if (mounted) state = s;
    if (!_ready.isCompleted) _ready.complete();
  }

  Future<void> save(DateTime day) async => state = await StreakSave.save(day, now: DateTime.now());
  Future<void> dismiss() async => state = await StreakSave.dismiss(now: DateTime.now());
}
