import 'dart:async';
import 'dart:math';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../providers/database_provider.dart';
import '../services/interstitial_ads.dart';
import '../services/notification_service.dart';
import '../services/session_goal.dart';
import '../services/timer_persistence.dart';
import '../services/home_widget_sync.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../theme/app_colors.dart';

class TimerWidget extends ConsumerStatefulWidget {
  final Book book;

  /// Si hay una sesión de este libro, abre directamente el diálogo de fin de
  /// sesión (botón FINALIZAR del widget de pantalla de inicio).
  final bool autoFinish;

  const TimerWidget({super.key, required this.book, this.autoFinish = false});

  @override
  ConsumerState<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends ConsumerState<TimerWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  
  // --- NUEVAS VARIABLES PARA PRECISIÓN ---
  DateTime? _startTime;
  int _accumulatedSeconds = 0; 
  
  AnimationController? _fadeController;

  /// Meta de la sesión (null = libre) y si ya se celebró en esta sesión.
  SessionGoal? _goal;
  bool _goalCelebrated = false;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((status) {
      if (_isPaused) {
        if (status == AnimationStatus.completed) {
          _fadeController?.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _fadeController?.forward();
        }
      }
    });

    WidgetsBinding.instance.addObserver(this);
    _syncFromPersistence(autoFinish: widget.autoFinish);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // El widget de pantalla de inicio pudo pausar/reanudar mientras no estábamos
    if (state == AppLifecycleState.resumed) _syncFromPersistence();
  }

  /// Alinea la pantalla con la sesión guardada en disco (fuente de verdad).
  Future<void> _syncFromPersistence({bool autoFinish = false}) async {
    final session = await TimerPersistence.getActiveSession();
    final savedGoal = await TimerPersistence.getGoal();
    final ownSession = session != null && session.bookId == widget.book.id;
    final goal = savedGoal ?? (ownSession ? null : await TimerPersistence.lastTimeGoal());
    if (!mounted) return;
    setState(() {
      _goal = goal;
      // Si ya estaba cumplida (p. ej. al volver a la app), no se celebra otra vez
      _goalCelebrated = ownSession && (goal?.timeReached(session.elapsedSeconds) ?? false);
    });

    if (session == null || session.bookId != widget.book.id) {
      // No hay sesión de este libro: si mostrábamos una, la limpiamos
      if (_isRunning || _isPaused) {
        _timer?.cancel();
        _resetAnimation();
        WakelockPlus.disable();
        setState(() {
          _startTime = null;
          _accumulatedSeconds = 0;
          _seconds = 0;
          _isRunning = false;
          _isPaused = false;
        });
      }
      return;
    }

    if (session.isPaused) {
      _timer?.cancel();
      WakelockPlus.disable();
      setState(() {
        _startTime = null;
        _accumulatedSeconds = session.accumulatedSeconds;
        _seconds = session.accumulatedSeconds;
        _isRunning = false;
        _isPaused = true;
      });
      _fadeController?.forward();
    } else {
      _accumulatedSeconds = session.accumulatedSeconds;
      _startTicking(since: session.runningSince ?? DateTime.now());
    }

    if (autoFinish) _stopTimer();
  }

  void _resetAnimation() {
    _isPaused = false;
    _fadeController?.stop();
    _fadeController?.value = 0.0;
  }

  /// Solo la parte visual/local: cuenta desde [since] sobre [_accumulatedSeconds].
  void _startTicking({required DateTime since}) {
    _startTime = since;
    _resetAnimation();
    WakelockPlus.enable();

    setState(() {
      _isRunning = true;
      _isPaused = false;
      _seconds = _accumulatedSeconds + DateTime.now().difference(since).inSeconds;
    });

    _timer?.cancel();
    // Usamos un intervalo menor (500ms) para que el UI se sienta más fluido,
    // pero el cálculo es por DateTime, así que no afecta la precisión.
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_startTime != null && mounted) {
        final difference = DateTime.now().difference(_startTime!).inSeconds;
        setState(() {
          _seconds = _accumulatedSeconds + difference;
        });
        _checkGoal();
      }
    });
  }

  void _checkGoal() {
    final goal = _goal;
    if (goal == null || _goalCelebrated || !goal.timeReached(_seconds)) return;
    _goalCelebrated = true;
    HapticFeedback.heavyImpact();
    NotificationService.cancelSessionGoal();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      content: Text('🎯 ¡Meta de ${goal.minutes} min cumplida! Sigue si quieres o finaliza la lectura.'),
    ));
  }

  Future<void> _setGoal(SessionGoal? goal) async {
    setState(() {
      _goal = goal;
      // Elegir una meta ya superada la da por cumplida, sin celebrarla
      _goalCelebrated = goal?.timeReached(_seconds) ?? false;
    });
    await TimerPersistence.saveGoal(goal);
  }

  Future<void> _showGoalPicker() async {
    HapticFeedback.selectionClick();
    final picked = await showModalBottomSheet<_GoalChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalPickerSheet(current: _goal),
    );
    if (picked == null || !mounted) return;
    if (picked.askPage) {
      final page = await _askGoalPage();
      if (page != null) await _setGoal(SessionGoal.page(page));
    } else {
      await _setGoal(picked.goal);
    }
  }

  Future<int?> _askGoalPage() {
    final book = widget.book;
    final suggested = book.totalPages > 0 ? (book.readPages + 20).clamp(1, book.totalPages) : book.readPages + 20;
    final controller = TextEditingController(text: '$suggested');
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (dialogContext, setDialogState) {
        final value = int.tryParse(controller.text);
        final String? error = value == null
            ? 'Escribe una página'
            : value <= book.readPages
                ? 'Ya vas en la pág. ${book.readPages}'
                : (book.totalPages > 0 && value > book.totalPages ? 'El libro tiene ${book.totalPages} páginas' : null);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('¿Hasta qué página?'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setDialogState(() {}),
            decoration: InputDecoration(
              labelText: 'Llegar a la página',
              suffixText: book.totalPages > 0 ? '/ ${book.totalPages}' : null,
              errorText: error,
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: error != null ? null : () => Navigator.pop(dialogContext, value),
              child: const Text('LISTO'),
            ),
          ],
        );
      }),
    );
  }

  void _startTimer() async {
    HapticFeedback.lightImpact();
    // Deja listo el intersticial por si toca al guardar esta sesión
    InterstitialAds.preloadIfEligible();

    _accumulatedSeconds = _seconds;
    _startTicking(since: DateTime.now());

    await TimerPersistence.saveSession(
      bookId: widget.book.id,
      isPaused: false,
      accumulatedSeconds: _accumulatedSeconds,
    );
    if (_accumulatedSeconds == 0) await TimerPersistence.saveGoal(_goal); // sesión nueva
    HomeWidgetSync.refresh();
  }

  void _pauseTimer() async {
    HapticFeedback.selectionClick();

    _timer?.cancel();
    WakelockPlus.disable();

    // Al pausar, guardamos el progreso total en la acumulada y limpiamos el inicio
    _accumulatedSeconds = _seconds;
    _startTime = null;

    setState(() {
      _isRunning = false;
      _isPaused = true;
    });

    _fadeController?.forward();

    await TimerPersistence.saveSession(
      bookId: widget.book.id,
      isPaused: true,
      accumulatedSeconds: _seconds,
    );
    HomeWidgetSync.refresh();
  }

  void _stopTimer() async {
    HapticFeedback.mediumImpact();

    _timer?.cancel();
    _resetAnimation();

    final int sessionSeconds = _seconds;
    final SessionGoal? goal = _goal;

    // Reset de variables de precisión
    _startTime = null;
    _accumulatedSeconds = 0;

    await TimerPersistence.clearSession();
    await NotificationService.cancelSessionGoal();
    HomeWidgetSync.refresh();
    WakelockPlus.disable();
    if (!mounted) return;

    setState(() {
      _isRunning = false;
      _isPaused = false;
      _seconds = 0;
      // La próxima sesión propone la misma meta de tiempo (la de páginas no)
      _goal = (goal?.isTime ?? false) ? goal : null;
      _goalCelebrated = false;
    });

    _showUpdateProgressDialog(sessionSeconds, goal: goal);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _fadeController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: (_isRunning || _isPaused) 
            ? scheme.primary.withValues(alpha: 0.4) 
            : context.cs.outlineVariant
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isPaused ? 'SESIÓN PAUSADA' : 'TIEMPO DE LECTURA', 
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold, 
                  color: _isPaused ? context.app.streak : scheme.primary, 
                  letterSpacing: 1.5
                )
              ),
              if (_isRunning)
                SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          _fadeController == null 
            ? _RawTimerText(seconds: _seconds)
            : _TimerDisplay(seconds: _seconds, fadeController: _fadeController!),

          const SizedBox(height: 12),
          _GoalRow(
            goal: _goal,
            seconds: _seconds,
            active: _isRunning || _isPaused,
            reached: _goalCelebrated,
            onTap: _showGoalPicker,
          ),

          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _isRunning ? _pauseTimer : () => _startTimer(),
                  icon: Icon(_isRunning ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded),
                  label: Text(
                    _isRunning ? 'PAUSAR' : (_isPaused ? 'REANUDAR' : 'COMENZAR'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning ? context.app.streak.withValues(alpha: 0.2) : scheme.primary,
                    foregroundColor: _isRunning ? context.app.streak : scheme.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
              if (_seconds > 0) ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: _stopTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.errorContainer.withValues(alpha: 0.4),
                      foregroundColor: scheme.error,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text(
                      'FINALIZAR LECTURA',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showUpdateProgressDialog(int seconds, {SessionGoal? goal}) {
    final scheme = Theme.of(context).colorScheme;
    final controller = TextEditingController(text: widget.book.readPages.toString());
    final int mins = seconds ~/ 60;
    final int secs = seconds % 60;
    final String timeText = mins > 0 ? '$mins min $secs seg' : '$secs seg';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final int? inputVal = int.tryParse(controller.text);
          final bool isOverLimit = inputVal != null && inputVal > widget.book.totalPages;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: const Text('¡Sesión terminada!', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined, color: scheme.onPrimaryContainer),
                      const SizedBox(width: 10),
                      Text(timeText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: scheme.onPrimaryContainer)),
                    ],
                  ),
                ),
                if (goal != null) ...[
                  const SizedBox(height: 12),
                  _GoalResult(goal: goal, seconds: seconds, page: inputVal ?? widget.book.readPages),
                ],
                const SizedBox(height: 24),
                _ShakeWidget(
                  shake: isOverLimit,
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofocus: true,
                    onChanged: (val) {
                      final int? currentInput = int.tryParse(val);
                      if (currentInput != null && currentInput > widget.book.totalPages) {
                        HapticFeedback.heavyImpact();
                      }
                      setDialogState(() {});
                    },
                    style: TextStyle(
                      color: isOverLimit ? scheme.error : null,
                      fontWeight: isOverLimit ? FontWeight.bold : null,
                    ),
                    decoration: InputDecoration(
                      labelText: '¿En qué página quedaste?',
                      prefixIcon: Icon(Icons.menu_book, color: isOverLimit ? scheme.error : scheme.primary),
                      suffixText: '/ ${widget.book.totalPages}',
                      errorText: isOverLimit ? 'No puede exceder el total' : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isOverLimit ? scheme.error : scheme.primary, 
                          width: 2
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  // Capturamos el navigator del diálogo ANTES de cualquier operación
                  final navigator = Navigator.of(dialogContext);
                  if (mounted) {
                    setState(() => _seconds = 0);
                  }
                  navigator.pop();
                },
                child: Text('DESCARTAR', style: TextStyle(color: context.cs.onSurfaceVariant)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOverLimit ? context.cs.surfaceContainerHighest : scheme.primary,
                  foregroundColor: isOverLimit ? context.cs.onSurfaceVariant : scheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                onPressed: isOverLimit ? null : () async {
                  final int newPages = int.tryParse(controller.text) ?? widget.book.readPages;
                  final db = ref.read(databaseProvider);

                  // Capturamos el navigator del diálogo ANTES de las operaciones async
                  // que pueden causar que el TimerWidget se desmonte (ej: al completar un libro)
                  final navigator = Navigator.of(dialogContext);

                  // Feedback táctil según el resultado
                  if (newPages >= widget.book.totalPages) {
                    await HapticFeedback.vibrate(); 
                  } else {
                    await HapticFeedback.mediumImpact();
                  }

                  // --- LÓGICA UNIFICADA ---
                  // logProgress se encarga de:
                  // 1. Actualizar el libro (páginas y tiempo total acumulado)
                  // 2. Crear o actualizar la ReadingSession diaria para el Heatmap y Gráficas
                  await db.logProgress(
                    widget.book.id,
                    newPages,
                    additionalSeconds: seconds,
                  );

                  await TimerPersistence.clearSession();

                  // Actualizamos el estado solo si el widget sigue montado
                  if (mounted) {
                    setState(() {
                      _seconds = 0;
                      _isRunning = false;
                      _isPaused = false;
                    });
                  }

                  // Cerramos el diálogo usando el navigator capturado,
                  // independiente de si el TimerWidget fue desmontado
                  navigator.pop();

                  // Pausa natural: quizá un intersticial (como mucho 1 cada 3
                  // sesiones y 1 al día; nunca al terminar el libro)
                  final total = widget.book.totalPages;
                  InterstitialAds.onSessionSaved(finishedBook: total > 0 && newPages >= total);
                },
                child: const Text('GUARDAR'),
              ),
            ],
          );
        }
      ),
    );
  }
}

class _RawTimerText extends StatelessWidget {
  final int seconds;
  const _RawTimerText({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final int mins = seconds ~/ 60;
    final int secs = seconds % 60;
    return Text(
      '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
      style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w200, letterSpacing: -2, fontFamily: 'monospace'),
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  final int seconds;
  final AnimationController fadeController;

  const _TimerDisplay({required this.seconds, required this.fadeController});

  @override
  Widget build(BuildContext context) {
    final int displayMins = seconds ~/ 60;
    final int displaySecs = seconds % 60;
    final String timeText = '${displayMins.toString().padLeft(2, '0')}:${displaySecs.toString().padLeft(2, '0')}';

    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.3).animate(
        CurvedAnimation(parent: fadeController, curve: Curves.easeInOut),
      ),
      child: Text(
        timeText,
        style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w200, letterSpacing: -2, fontFamily: 'monospace'),
      ),
    );
  }
}

class _ShakeWidget extends StatelessWidget {
  final Widget child;
  final bool shake;

  const _ShakeWidget({required this.child, required this.shake});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(shake),
      tween: Tween(begin: 0.0, end: shake ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        if (value == 0) return child!;
        return Transform.translate(
          offset: Offset(sin(value * pi * 4) * 8, 0), 
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Elección del selector de meta: una meta (o libre) o "pedir página".
class _GoalChoice {
  final SessionGoal? goal;
  final bool askPage;
  const _GoalChoice(this.goal, {this.askPage = false});
}

class _GoalPickerSheet extends StatelessWidget {
  final SessionGoal? current;
  const _GoalPickerSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget chip(String label, _GoalChoice choice, bool selected) => ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => Navigator.pop(context, choice),
        );
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: context.cs.onSurfaceVariant, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Text('🎯 Meta de esta sesión', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Te aviso al cumplir la meta de tiempo, aunque tengas la pantalla apagada.',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text('Tiempo', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              chip('Libre', const _GoalChoice(null), current == null),
              for (final m in SessionGoal.timeOptions)
                chip('$m min', _GoalChoice(SessionGoal.time(m)), current == SessionGoal.time(m)),
            ]),
            const SizedBox(height: 16),
            Text('Páginas', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            chip(
              current?.untilPage != null ? 'Hasta la pág. ${current!.untilPage}' : 'Hasta la página…',
              const _GoalChoice(null, askPage: true),
              current?.untilPage != null,
            ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "🎯 Meta: 30 min ▸" y, durante la sesión, el progreso.
class _GoalRow extends StatelessWidget {
  final SessionGoal? goal;
  final int seconds;
  final bool active;
  final bool reached;
  final VoidCallback onTap;
  const _GoalRow({
    required this.goal,
    required this.seconds,
    required this.active,
    required this.reached,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final g = goal;
    final String text;
    if (g == null) {
      text = 'Meta: libre';
    } else if (g.isTime && active) {
      text = reached ? '¡Meta de ${g.minutes} min cumplida!' : 'Meta: ${g.timeProgressLabel(seconds)}';
    } else {
      text = 'Meta: ${g.label}';
    }
    final color = reached ? context.app.statusFinished : scheme.primary;

    return InkWell(
      key: const Key('session_goal_row'),
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(reached ? '✅' : '🎯', style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Flexible(child: Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: color))),
                Icon(Icons.chevron_right_rounded, size: 18, color: color),
              ],
            ),
            if (g != null && g.isTime && active) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: g.progress(seconds),
                  minHeight: 6,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Resultado de la meta en el diálogo de fin de sesión.
class _GoalResult extends StatelessWidget {
  final SessionGoal goal;
  final int seconds;
  final int page;
  const _GoalResult({required this.goal, required this.seconds, required this.page});

  @override
  Widget build(BuildContext context) {
    final bool met;
    final String text;
    if (goal.isTime) {
      met = goal.timeReached(seconds);
      final missing = (goal.remainingSeconds(seconds) / 60).ceil();
      text = met ? '🎯 Meta de ${goal.minutes} min cumplida' : 'Meta: ${goal.minutes} min · te faltaron $missing min';
    } else {
      met = goal.pageReached(page);
      text = met
          ? '🎯 ¡Llegaste a la pág. ${goal.untilPage}!'
          : 'Meta: pág. ${goal.untilPage} · te faltan ${goal.untilPage! - page} páginas';
    }
    final color = met ? context.app.statusFinished : Theme.of(context).colorScheme.onSurfaceVariant;
    return Text(text, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.w700));
  }
}
