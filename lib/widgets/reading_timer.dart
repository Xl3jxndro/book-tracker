import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../providers/database_provider.dart';

class ReadingTimer extends ConsumerStatefulWidget {
  final Book book;
  const ReadingTimer({super.key, required this.book});

  @override
  ConsumerState<ReadingTimer> createState() => _ReadingTimerState();
}

class _ReadingTimerState extends ConsumerState<ReadingTimer> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;

  void _toggleTimer() {
    if (_isRunning) {
      _stopTimer();
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _seconds++);
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _isRunning = false;
    _showSummaryDialog();
    setState(() {});
  }

  void _showSummaryDialog() {
    final controller = TextEditingController(text: widget.book.readPages.toString());
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Sesión terminada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tiempo registrado: ${_formatTime(_seconds)}'),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '¿En qué página terminaste?',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final newPages = int.tryParse(controller.text) ?? widget.book.readPages;
              
              // SUMA IMPORTANTE: Tiempo anterior + Tiempo de esta sesión
              final totalTimeAccumulated = widget.book.totalReadTime + _seconds;
              
              int status = (newPages >= widget.book.totalPages) ? 2 : 1;

              ref.read(databaseProvider).updateBook(widget.book.copyWith(
                readPages: newPages,
                totalReadTime: totalTimeAccumulated,
                status: status,
              ));

              setState(() => _seconds = 0);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isRunning ? Colors.orange.shade50 : Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _isRunning ? Colors.orange.shade100 : Colors.indigo.shade100),
      ),
      child: Column(
        children: [
          Text(_isRunning ? 'LEYENDO AHORA' : 'SESIÓN DE LECTURA', 
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.w800, 
              color: _isRunning ? Colors.orange.shade700 : Colors.indigo.shade700,
              letterSpacing: 1.2
            )),
          const SizedBox(height: 12),
          Text(_formatTime(_seconds), 
            style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _toggleTimer,
            icon: Icon(_isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded),
            label: Text(_isRunning ? 'DETENER' : 'EMPEZAR A LEER'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isRunning ? Colors.redAccent : Colors.indigo,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}