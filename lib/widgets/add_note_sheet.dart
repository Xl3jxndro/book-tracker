import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';
import '../providers/database_provider.dart';
import '../services/voice_service.dart';
import '../screens/scan_quote_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../l10n/l10n.dart';

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

  /// Cita desde una foto de la página: se reconoce el texto en el teléfono
  /// y se eligen las líneas; el texto se añade a la nota para revisarlo.
  Future<void> _scanText() async {
    if (_isListening) _stopVoice();
    FocusScope.of(context).unfocus();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ScanSourceSheet(),
    );
    if (source == null || !mounted) return;

    XFile? photo;
    try {
      photo = await ImagePicker().pickImage(source: source, maxWidth: 2000, maxHeight: 2000, imageQuality: 92);
    } catch (e) {
      debugPrint('Foto para escanear: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.l10n.noteCameraError),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }
    if (photo == null || !mounted) return;

    final text = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => ScanQuoteScreen(imagePath: photo!.path)),
    );
    if (text == null || text.isEmpty || !mounted) return;
    final current = _contentController.text.trimRight();
    var combined = current.isEmpty ? text : '$current\n$text';
    if (combined.length > AddNoteSheet.maxLength) combined = combined.substring(0, AddNoteSheet.maxLength);
    setState(() {
      _contentController.text = combined;
      _contentController.selection = TextSelection.collapsed(offset: combined.length);
    });
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
            content: Text(context.l10n.noteSaveError),
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

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 12, left: 24, right: 24
      ),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLow,
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
                      widget.noteToEdit == null ? context.l10n.noteNewTitle : context.l10n.noteEditTitle,
                      style: TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.w800, 
                        letterSpacing: -0.7,
                        color: scheme.onSurface
                      )
                    ),
                    Text(
                      _isListening ? context.l10n.noteListening : context.l10n.noteSubtitle,
                      style: TextStyle(
                        fontSize: 14, 
                        color: _isListening ? scheme.primary : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ],
                ),
              ),
              
              // Escanear una cita con la cámara
              IconButton(
                tooltip: context.l10n.noteScanTooltip,
                onPressed: _scanText,
                style: IconButton.styleFrom(
                  fixedSize: const Size(48, 48),
                  backgroundColor: scheme.surfaceContainerHigh,
                  foregroundColor: scheme.onSurfaceVariant,
                ),
                icon: const Icon(Icons.document_scanner_outlined, size: 22),
              ),
              const SizedBox(width: 4),
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
                          color: _isListening ? scheme.onPrimary : scheme.onSurfaceVariant,
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
              hintText: context.l10n.noteContentHint,
              hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
              filled: true,
              fillColor: scheme.surfaceContainerHigh,
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
              labelText: context.l10n.notePageLabel,
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
                    widget.noteToEdit == null ? context.l10n.noteSave : context.l10n.noteSaveChanges,
                    style: TextStyle(
                      color: _isEmpty ? scheme.onSurfaceVariant : scheme.onPrimary,
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

/// Cámara o galería para escanear una cita.
class _ScanSourceSheet extends StatelessWidget {
  const _ScanSourceSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: context.cs.outline, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(context.l10n.scanSourceTitle, style: theme.textTheme.titleLarge),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                child: Text(
                  context.l10n.scanSourcePrivacy,
                  style: theme.textTheme.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant),
                ),
              ),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: Icon(Icons.photo_camera_outlined, color: context.app.accent),
                title: Text(context.l10n.scanSourceCamera),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: Icon(Icons.photo_library_outlined, color: context.app.accent),
                title: Text(context.l10n.scanSourceGallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
