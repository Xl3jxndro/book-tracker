import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/isbn.dart';
import '../widgets/isbn_help.dart';

/// Escanea el código de barras de un libro y devuelve su ISBN-13
/// (`Navigator.pop(context, isbn)`), o `null` si se cancela.
class IsbnScannerScreen extends StatefulWidget {
  const IsbnScannerScreen({super.key});

  @override
  State<IsbnScannerScreen> createState() => _IsbnScannerScreenState();
}

class _IsbnScannerScreenState extends State<IsbnScannerScreen> {
  // Los libros usan EAN-13 (ISBN-13 empieza por 978/979)
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.ean13],
    detectionSpeed: DetectionSpeed.normal,
  );

  bool _done = false;
  String? _hint;
  String? _lastRejected;
  Timer? _hintTimer;

  @override
  void dispose() {
    _hintTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  bool _typing = false;

  /// Por si el código de barras está dañado o no se lee: escribirlo a mano.
  Future<void> _typeIsbn() async {
    _typing = true;
    await _controller.stop();
    if (!mounted) return;
    final isbn = await showManualIsbnDialog(context);
    if (!mounted) return;
    if (isbn != null) {
      _done = true;
      Navigator.pop(context, isbn);
      return;
    }
    _typing = false;
    await _controller.start();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done || _typing) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;

      final isbn = Isbn.normalize(raw);
      if (isbn != null) {
        _done = true;
        HapticFeedback.mediumImpact();
        Navigator.pop(context, isbn);
        return;
      }

      // Otro código (precio, producto…): avisar una vez por código
      if (raw != _lastRejected) {
        _lastRejected = raw;
        HapticFeedback.lightImpact();
        _showHint('Ese código no es un ISBN. Busca el que empieza por 978 o 979.');
      }
    }
  }

  void _showHint(String text) {
    _hintTimer?.cancel();
    setState(() => _hint = text);
    _hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _hint = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final frame = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: size.width * 0.8,
      height: size.width * 0.45,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            scanWindow: frame,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _ScannerError(error: error),
          ),
          // Oscurece todo menos el recuadro guía
          IgnorePointer(child: CustomPaint(size: size, painter: _FramePainter(frame))),
          Positioned(
            left: 24,
            right: 24,
            top: frame.bottom + 24,
            child: Column(
              children: [
                const Text(
                  'Apunta al código de barras de la contraportada',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _hint == null ? 0 : 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
                    child: Text(_hint ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.orangeAccent)),
                  ),
                ),
              ],
            ),
          ),
          // Alternativas: escribirlo a mano y ayuda para encontrarlo
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: _typeIsbn,
                      icon: const Icon(Icons.keyboard_rounded),
                      label: const Text('Escribir el ISBN'),
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => showIsbnHelp(context),
                    icon: const Icon(Icons.help_outline_rounded, color: Colors.white70, size: 18),
                    label: const Text('¿Dónde está el ISBN?', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _controller,
                    builder: (context, state, _) {
                      if (state.torchState == TorchState.unavailable) return const SizedBox.shrink();
                      final on = state.torchState == TorchState.on;
                      return IconButton(
                        icon: Icon(on ? Icons.flash_on_rounded : Icons.flash_off_rounded, color: Colors.white, size: 28),
                        tooltip: on ? 'Apagar linterna' : 'Encender linterna',
                        onPressed: _controller.toggleTorch,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerError extends StatelessWidget {
  final MobileScannerException error;
  const _ScannerError({required this.error});

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(denied ? Icons.no_photography_rounded : Icons.error_outline_rounded, color: Colors.white70, size: 56),
          const SizedBox(height: 16),
          Text(
            denied
                ? 'Para escanear necesitamos permiso para usar la cámara.'
                : 'No se pudo abrir la cámara. Puedes buscar el libro escribiendo su título.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          if (denied) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: openAppSettings,
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Abrir ajustes'),
            ),
          ],
        ],
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  final Rect frame;
  _FramePainter(this.frame);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(frame, const Radius.circular(20));
    final overlay = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlay, Paint()..color = Colors.black.withValues(alpha: 0.55));
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) => oldDelegate.frame != frame;
}
