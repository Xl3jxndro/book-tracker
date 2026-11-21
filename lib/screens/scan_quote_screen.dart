import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../services/text_scan.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// ¿El error es porque Google Play aún no descargó el modelo de texto?
/// (ML Kit: "Waiting for the text optional module to be downloaded").
bool isModelDownloading(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('download') || message.contains('optional module');
}

/// Reconoce el texto de la foto de una página y deja elegir las líneas de la
/// cita. Devuelve (al cerrar) el texto elegido, ya unido.
class ScanQuoteScreen extends StatefulWidget {
  final String imagePath;

  /// Para pruebas: líneas ya reconocidas (no se usa la cámara ni ML Kit).
  final Future<List<String>> Function(String path)? recognize;

  const ScanQuoteScreen({super.key, required this.imagePath, this.recognize});

  @override
  State<ScanQuoteScreen> createState() => _ScanQuoteScreenState();
}

class _ScanQuoteScreenState extends State<ScanQuoteScreen> {
  List<String>? _lines;
  Object? _error;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _recognize();
  }

  Future<void> _recognize() async {
    try {
      final lines = await (widget.recognize ?? TextScan.recognizeLines)(widget.imagePath);
      if (mounted) setState(() => _lines = lines);
    } catch (e) {
      debugPrint('Reconocer texto: $e');
      if (mounted) setState(() => _error = e);
    }
  }

  String get _text => joinScannedLines([
        for (var i = 0; i < (_lines?.length ?? 0); i++)
          if (_selected.contains(i)) _lines![i],
      ]);

  void _toggle(int i) {
    HapticFeedback.selectionClick();
    setState(() => _selected.contains(i) ? _selected.remove(i) : _selected.add(i));
  }

  void _toggleAll() {
    final lines = _lines ?? const [];
    setState(() {
      if (_selected.length == lines.length) {
        _selected.clear();
      } else {
        _selected.addAll(List.generate(lines.length, (i) => i));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = _lines;
    return Scaffold(
      backgroundColor: context.cs.surface,
      appBar: AppBar(
        title: const Text('Elige el texto'),
        actions: [
          if (lines != null && lines.isNotEmpty)
            TextButton(
              onPressed: _toggleAll,
              child: Text(_selected.length == lines.length ? 'Ninguna' : 'Todas'),
            ),
          const SizedBox(width: AppSpace.xs),
        ],
      ),
      body: _error != null
          ? (isModelDownloading(_error!)
              ? _message(
                  context,
                  icon: Icons.downloading_rounded,
                  title: 'Preparando el lector de texto',
                  text: 'Google Play lo está descargando (unos 4 MB). Conéctate a internet e inténtalo en unos minutos.',
                )
              : _message(
                  context,
                  icon: Icons.error_outline_rounded,
                  title: 'No se pudo leer la foto',
                  text: 'Inténtalo de nuevo con otra foto.',
                ))
          : lines == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpace.md),
                      Text('Leyendo la página…', style: theme.textTheme.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : lines.isEmpty
                  ? _message(
                      context,
                      icon: Icons.text_fields_rounded,
                      title: 'No encontré texto',
                      text: 'Prueba con más luz, la página recta y el texto enfocado.',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.xs, AppSpace.screen, AppSpace.xxl),
                      children: [
                        _photo(context),
                        const SizedBox(height: AppSpace.md),
                        Text('Toca las líneas que quieres guardar.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant)),
                        const SizedBox(height: AppSpace.sm),
                        for (var i = 0; i < lines.length; i++) _lineTile(context, i, lines[i]),
                      ],
                    ),
      bottomNavigationBar: lines == null || lines.isEmpty ? null : _bottomBar(context),
    );
  }

  /// La foto en pequeño, para ubicarse.
  Widget _photo(BuildContext context) => ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: SizedBox(
          height: 140,
          width: double.infinity,
          child: Image.file(
            File(widget.imagePath),
            fit: BoxFit.cover,
            cacheWidth: 800,
            errorBuilder: (_, _, _) => ColoredBox(color: context.cs.surfaceContainerHigh),
          ),
        ),
      );

  Widget _lineTile(BuildContext context, int i, String line) {
    final selected = _selected.contains(i);
    final app = context.app;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? app.accentSoft : context.cs.surfaceContainerLow,
        borderRadius: AppRadius.mdAll,
        child: InkWell(
          borderRadius: AppRadius.mdAll,
          onTap: () => _toggle(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 10),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 22,
                  color: selected ? app.accent : context.cs.outline,
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(line, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.3)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final text = _text;
    return Container(
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: text.isEmpty
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.sm),
                      child: Text(
                        '“$text”',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: context.cs.onSurfaceVariant),
                      ),
                    ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: text.isEmpty ? null : () => Navigator.pop(context, text),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                icon: const Icon(Icons.format_quote_rounded),
                label: Text(_selected.isEmpty
                    ? 'Elige al menos una línea'
                    : 'Usar ${_selected.length == 1 ? '1 línea' : '${_selected.length} líneas'}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(BuildContext context, {required IconData icon, required String title, required String text}) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: context.cs.onSurfaceVariant),
            const SizedBox(height: AppSpace.md),
            Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.xs),
            Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant), textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.lg),
            FilledButton.tonal(onPressed: () => Navigator.pop(context), child: const Text('Volver')),
          ],
        ),
      ),
    );
  }
}
