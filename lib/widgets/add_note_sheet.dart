import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../providers/database_provider.dart';
import '../services/voice_service.dart';

class AddNoteSheet extends ConsumerStatefulWidget {
  final int bookId;
  final VoiceService voiceService;

  /// Si se indica, el formulario edita esta nota en lugar de crear una nueva.
  final Note? noteToEdit;

  /// Límite de la columna `content` en la base de datos.
  static const maxLength = 1000;

  const AddNoteSheet({
    super.key,
    required this.bookId,
    required this.voiceService,
    this.noteToEdit,
  });

  @override
  ConsumerState<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends ConsumerState<AddNoteSheet> with SingleTickerProviderStateMixin {
  final _contentController = TextEditingController();
  final _pageController = TextEditingController();
  late AnimationController _pulseController;
  bool _isEmpty = true;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    final note = widget.noteToEdit;
    if (note != null) {
      _contentController.text = note.content;
      _pageController.text = note.pageNumber?.toString() ?? '';
      _isEmpty = note.content.trim().isEmpty;
    }

    _contentController.addListener(() {
      if (mounted) {
        setState(() => _isEmpty = _contentController.text.trim().isEmpty);
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startVoice() async {
    if (_isListening) return;
    bool available = await widget.voiceService.initVoice();
    if (!available) return;

    setState(() {
      _isListening = true;
      _pulseController.repeat(); 
    });
    HapticFeedback.mediumImpact();

    await widget.voiceService.startListening(
      onResult: (text) {
        if (mounted) {
          setState(() {
            _contentController.text = text.length > AddNoteSheet.maxLength
                ? text.substring(0, AddNoteSheet.maxLength)
                : text;
            _contentController.selection = TextSelection.fromPosition(
              TextPosition(offset: _contentController.text.length),
            );
          });
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _isListening = false;
            _pulseController.stop();
          });
        }
      },
    );
  }

  void _stopVoice() async {
    if (widget.voiceService.isListening) {
      await widget.voiceService.stopListening();
    }
    if (mounted) {
      setState(() {
        _isListening = false;
        _pulseController.stop();
        _pulseController.reset();
      });
    }
    HapticFeedback.lightImpact();
  }

  void _toggleListening() {
    if (_isListening) {
      _stopVoice();
    } else {
      _startVoice();
    }
  }

  void _saveNote() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    HapticFeedback.mediumImpact();
    final db = ref.read(databaseProvider);
    final page = int.tryParse(_pageController.text);
    try {
      final note = widget.noteToEdit;
      if (note == null) {
        await db.insertNote(NotesCompanion(
          bookId: drift.Value(widget.bookId),
          content: drift.Value(content),
          pageNumber: drift.Value(page),
        ));
      } else {
        await db.updateNote(note, content: content, pageNumber: page);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error guardando nota: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo guardar la nota. Inténtalo de nuevo.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 12, left: 24, right: 24
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32, height: 4, 
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.15), 
              borderRadius: BorderRadius.circular(10)
            )
          ),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded( // Asegura que el texto no sea empujado
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.noteToEdit == null ? 'Nueva Anotación' : 'Editar anotación',
                      style: TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.w800, 
                        letterSpacing: -0.7,
                        color: scheme.onSurface
                      )
                    ),
                    Text(
                      _isListening ? 'Escuchando voz...' : 'Escribe tus ideas',
                      style: TextStyle(
                        fontSize: 14, 
                        color: _isListening ? scheme.primary : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ],
                ),
              ),
              
              // CONTENEDOR DE TAMAÑO FIJO PARA EVITAR SALTOS
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none, // Permite que las ondas salgan sin mover el Row
                  children: [
                    if (_isListening)
                      ...List.generate(3, (index) {
                        return AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            double progress = (_pulseController.value - (index * 0.25)) % 1.0;
                            if (progress < 0) progress = 0;
                            
                            return Container(
                              // Usamos un tamaño que exceda los 60px pero sin afectar al layout
                              width: 44 + (80 * progress),
                              height: 44 + (80 * progress),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: scheme.primary.withValues(alpha: 0.3 * (1 - progress)),
                              ),
                            );
                          },
                        );
                      }),
                    // Botón Central
                    GestureDetector(
                      onTap: _toggleListening,
                      onLongPress: _startVoice,
                      onLongPressUp: _stopVoice,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isListening ? scheme.primary : scheme.surfaceContainerHigh,
                          shape: BoxShape.circle,
                          boxShadow: _isListening ? [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.3), 
                              blurRadius: 15, 
                              spreadRadius: 2
                            )
                          ] : [],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                          color: _isListening ? Colors.white : scheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          TextField(
            controller: _contentController,
            maxLines: 5,
            minLines: 1,
            inputFormatters: [LengthLimitingTextInputFormatter(AddNoteSheet.maxLength)],
            autofocus: true,
            style: const TextStyle(fontSize: 17, height: 1.4),
            decoration: InputDecoration(
              hintText: 'Comienza a hablar o escribir...',
              hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(24),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _pageController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.bookmark_outline_rounded, size: 20, color: scheme.primary),
              labelText: 'Página del libro',
              labelStyle: TextStyle(color: scheme.onSurfaceVariant),
              filled: true,
              fillColor: Colors.transparent,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: scheme.outlineVariant),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: scheme.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 32),

          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: _isEmpty 
                ? null 
                : LinearGradient(
                    colors: [scheme.primary, scheme.primary.withBlue(255)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
              color: _isEmpty ? scheme.surfaceContainerHighest : null,
              boxShadow: _isEmpty ? [] : [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6)
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isEmpty ? null : _saveNote,
                borderRadius: BorderRadius.circular(30),
                child: Center(
                  child: Text(
                    widget.noteToEdit == null ? 'Guardar nota' : 'Guardar cambios',
                    style: TextStyle(
                      color: _isEmpty ? scheme.onSurfaceVariant : Colors.white, 
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5
                    )
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}