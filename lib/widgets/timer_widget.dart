import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../providers/database_provider.dart';
import '../services/timer_persistence.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class TimerWidget extends ConsumerStatefulWidget {
  final Book book;
  const TimerWidget({super.key, required this.book});

  @override
  ConsumerState<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends ConsumerState<TimerWidget> with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  
  // --- NUEVAS VARIABLES PARA PRECISIÓN ---
  DateTime? _startTime;
  int _accumulatedSeconds = 0; 
  
  AnimationController? _fadeController;

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

    _checkPersistedSession();
  }

  void _checkPersistedSession() async {
    final session = await TimerPersistence.getActiveSession();
    
    if (session != null && session['bookId'] == widget.book.id) {
      if (mounted) {
        setState(() {
          _seconds = session['elapsedSeconds'];
          _accumulatedSeconds = _seconds; // Cargamos lo que ya estaba guardado
          _isPaused = session['isPaused'];
        });
        
        if (_isPaused) {
          _fadeController?.forward();
        } else {
          _startTimer(isResuming: true);
        }
      }
    }
  }

  void _resetAnimation() {
    _isPaused = false; 
    _fadeController?.stop();
    _fadeController?.value = 0.0; 
  }

  void _startTimer({bool isResuming = false}) {
    HapticFeedback.lightImpact();

    // Guardamos el momento exacto en que inicia/reanuda
    _startTime = DateTime.now();

    TimerPersistence.saveSession(
      bookId: widget.book.id,
      isPaused: false,
      accumulatedSeconds: _seconds,
    );

    _resetAnimation();
    WakelockPlus.enable(); 

    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    _timer?.cancel();
    // Usamos un intervalo menor (500ms) para que el UI se sienta más fluido,
    // pero el cálculo es por DateTime, así que no afecta la precisión.
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_startTime != null) {
        final now = DateTime.now();
        final difference = now.difference(_startTime!).inSeconds;
        setState(() {
          _seconds = _accumulatedSeconds + difference;
        });
      }
    });
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
  }

  void _stopTimer() async {
    HapticFeedback.mediumImpact();

    _timer?.cancel();
    _resetAnimation();
    
    final int sessionSeconds = _seconds;
    
    // Reset de variables de precisión
    _startTime = null;
    _accumulatedSeconds = 0;

    await TimerPersistence.clearSession();
    WakelockPlus.disable();
    
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _seconds = 0;
    });
    
    _showUpdateProgressDialog(sessionSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHighest.withOpacity(0.1) : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: (_isRunning || _isPaused) 
            ? scheme.primary.withOpacity(0.4) 
            : (isDark ? Colors.white10 : Colors.grey.shade200)
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
                  color: _isPaused ? Colors.orangeAccent : scheme.primary, 
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
          
          const SizedBox(height: 24),
          
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
                    backgroundColor: _isRunning ? Colors.orangeAccent.withOpacity(0.2) : scheme.primary,
                    foregroundColor: _isRunning ? Colors.orangeAccent : scheme.onPrimary,
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
                      backgroundColor: scheme.errorContainer.withOpacity(0.4),
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

  void _showUpdateProgressDialog(int seconds) {
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
                    color: scheme.primaryContainer.withOpacity(0.4),
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
                child: const Text('DESCARTAR', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOverLimit ? Colors.grey.shade300 : scheme.primary,
                  foregroundColor: isOverLimit ? Colors.grey.shade500 : scheme.onPrimary,
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