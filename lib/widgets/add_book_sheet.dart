import 'dart:io';
import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/database.dart';
import '../l10n/l10n.dart';
import '../providers/database_provider.dart';
import '../services/book_api_service.dart';
import 'book_search_field.dart';
import '../screens/isbn_scanner_screen.dart';
import 'isbn_help.dart';
import '../theme/app_colors.dart';

class AddBookSheet extends ConsumerStatefulWidget {
  final Book? bookToEdit;
  const AddBookSheet({super.key, this.bookToEdit});

  @override
  ConsumerState<AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends ConsumerState<AddBookSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _pagesController;
  late TextEditingController _categoryController;
  
  late int _selectedStatus;
  File? _imagePreview;
  bool _isSaving = false;

  // Búsqueda de libros en internet (solo al añadir un libro)
  final _bookApi = BookApiService();
  bool _isDownloadingCover = false;
  int _coverRequestId = 0; // evita que una descarga lenta pise una foto elegida después

  // Escáner de ISBN
  bool _isLookingUpIsbn = false;
  String? _isbnMessage;
  bool _isbnMessageIsError = false;

  /// Abre el escáner y, con el ISBN leído, rellena el formulario.
  Future<void> _scanIsbn() async {
    FocusScope.of(context).unfocus();
    final isbn = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const IsbnScannerScreen()),
    );
    if (isbn == null || !mounted) return;

    setState(() {
      _isLookingUpIsbn = true;
      _isbnMessage = null;
    });
    try {
      final results = await _bookApi.searchByIsbn(isbn);
      if (!mounted) return;
      if (results.isEmpty) {
        setState(() {
          _isbnMessage = context.l10n.addBookIsbnNotFound(isbn);
          _isbnMessageIsError = true;
        });
        return;
      }
      setState(() {
        _isbnMessage = context.l10n.addBookIsbnFound(isbn);
        _isbnMessageIsError = false;
      });
      await _applySearchResult(results.first);
    } on BookSearchException catch (e) {
      if (mounted) {
        setState(() {
          _isbnMessage = e.message;
          _isbnMessageIsError = true;
        });
      }
    } catch (e) {
      debugPrint('Error buscando ISBN: $e');
      if (mounted) {
        setState(() {
          _isbnMessage = context.l10n.addBookIsbnSearchFailed;
          _isbnMessageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isLookingUpIsbn = false);
    }
  }

  // Límites definidos en la tabla Books (database.dart)
  static const _maxTextLength = 100;
  static const _maxPages = 100000;

  /// [requiredMessage]: el aviso si está vacío ("El título es obligatorio").
  String? _validateText(String? value, String requiredMessage) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return requiredMessage;
    if (text.length > _maxTextLength) return context.l10n.addBookMaxChars(_maxTextLength);
    return null;
  }

  String? _validatePages(String? value) {
    final pages = int.tryParse(value?.trim() ?? '');
    if (pages == null || pages <= 0) return context.l10n.addBookPagesRequired;
    if (pages > _maxPages) return context.l10n.addBookInvalidNumber;
    final readPages = widget.bookToEdit?.readPages ?? 0;
    if (pages < readPages) return context.l10n.addBookAlreadyRead(readPages);
    return null;
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.bookToEdit?.title ?? '');
    _authorController = TextEditingController(text: widget.bookToEdit?.author ?? '');
    _pagesController = TextEditingController(text: widget.bookToEdit?.totalPages.toString() ?? '');
    _categoryController = TextEditingController(text: widget.bookToEdit?.category ?? 'General');
    _selectedStatus = widget.bookToEdit?.status ?? 0;
    
    if (widget.bookToEdit?.coverUrl != null) {
      _imagePreview = File(widget.bookToEdit!.coverUrl!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _pagesController.dispose();
    _categoryController.dispose();
    _bookApi.dispose();
    super.dispose();
  }

  String _fitText(String text) {
    final clean = text.trim();
    return clean.length <= _maxTextLength ? clean : clean.substring(0, _maxTextLength).trim();
  }

  /// Rellena el formulario con un resultado de la búsqueda y descarga su portada.
  Future<void> _applySearchResult(BookModel book) async {
    setState(() {
      _titleController.text = _fitText(book.title);
      _authorController.text = _fitText(book.author);
      if (book.pageCount > 0) _pagesController.text = book.pageCount.toString();
      if (book.category != null && book.category!.isNotEmpty) {
        _categoryController.text = _fitText(book.category!);
      }
    });

    final thumbnail = book.thumbnail;
    if (thumbnail == null) return;

    final requestId = ++_coverRequestId;
    setState(() => _isDownloadingCover = true);

    // Se descarga en la carpeta temporal; al guardar se copia a documentos.
    final tempDir = await getTemporaryDirectory();
    final cover = await _bookApi.downloadCover(thumbnail, tempDir);

    if (!mounted || requestId != _coverRequestId) return;
    setState(() {
      _isDownloadingCover = false;
      if (cover != null) _imagePreview = cover;
    });
  }

  Future<void> _showImageSourceOptions() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: context.cs.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.cs.outlineVariant, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            Text(context.l10n.addBookChangeCover, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(icon: Icons.camera_rounded, label: context.l10n.addBookCamera, onTap: () => _pickImage(ImageSource.camera), isDark: isDark),
                _buildSourceOption(icon: Icons.image_rounded, label: context.l10n.addBookGallery, onTap: () => _pickImage(ImageSource.gallery), isDark: isDark),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({required IconData icon, required String label, required VoidCallback onTap, required bool isDark}) {
    return InkWell(
      onTap: () { Navigator.pop(context); onTap(); },
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: context.app.accent, size: 32),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null && mounted) {
      _coverRequestId++; // la foto elegida a mano manda sobre una descarga en curso
      setState(() {
        _isDownloadingCover = false;
        _imagePreview = File(pickedFile.path);
      });
    }
  }

  Future<String?> _saveImagePermanently(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    if (image.path.contains(directory.path)) return image.path;
    final name = p.basename(image.path);
    final permanentImage = await image.copy('${directory.path}/$name');
    return permanentImage.path;
  }

  void _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    try {
      final db = ref.read(databaseProvider);
      final title = _titleController.text.trim();
      final author = _authorController.text.trim();
      final int totalPages = int.parse(_pagesController.text.trim());
      final categoryText = _categoryController.text.trim();
      final category = categoryText.isEmpty ? 'General' : categoryText;

      String? finalImagePath;
      if (_imagePreview != null) finalImagePath = await _saveImagePermanently(_imagePreview!);

      final bookToEdit = widget.bookToEdit;
      if (bookToEdit == null) {
        await db.insertBook(BooksCompanion(
          title: drift.Value(title),
          author: drift.Value(author),
          totalPages: drift.Value(totalPages),
          category: drift.Value(category),
          status: drift.Value(_selectedStatus),
          coverUrl: drift.Value(finalImagePath),
        ));
      } else {
        // Coherencia estado/progreso: marcar "Leído" completa las páginas.
        final readPages = _selectedStatus == 2 ? totalPages : bookToEdit.readPages;
        // Fechas de inicio y fin según el cambio de estado (mismas reglas que el progreso)
        final dates = AppDatabase.readingDatesAfter(
          oldStatus: bookToEdit.status,
          newStatus: _selectedStatus,
          startedAt: bookToEdit.startedAt,
          finishedAt: bookToEdit.finishedAt,
          hasProgress: readPages > 0,
          now: DateTime.now(),
        );
        await db.updateBook(bookToEdit.copyWith(
          title: title,
          author: author,
          totalPages: totalPages,
          readPages: readPages,
          category: drift.Value(category),
          status: _selectedStatus,
          coverUrl: drift.Value(finalImagePath),
          startedAt: drift.Value(dates.startedAt),
          finishedAt: drift.Value(dates.finishedAt),
        ));
        // Si cambió la portada, la anterior ya no ocupa espacio (si nadie más la usa)
        if (bookToEdit.coverUrl != finalImagePath) {
          await db.deleteCoverIfUnused(bookToEdit.coverUrl);
        }
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error guardando libro: $e");
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.addBookSaveError),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDNF = _selectedStatus == 3;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        // CORRECCIÓN: Se usa constraints para maxHeight
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          top: 16, left: 28, right: 28
        ),
        decoration: BoxDecoration(
          color: context.cs.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40)],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 45, height: 5, decoration: BoxDecoration(color: context.cs.outline, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 32),

                if (widget.bookToEdit == null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: BookSearchField(service: _bookApi, onSelected: _applySearchResult)),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 52,
                        width: 52,
                        child: IconButton.filledTonal(
                          tooltip: context.l10n.addBookScanBarcode,
                          style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                          onPressed: _isLookingUpIsbn ? null : _scanIsbn,
                          icon: _isLookingUpIsbn
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.qr_code_scanner_rounded),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => showIsbnHelp(context),
                      icon: const Icon(Icons.help_outline_rounded, size: 16),
                      label: Text(context.l10n.isbnHelpTitle, style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                  if (_isbnMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 8),
                      child: Row(
                        children: [
                          Icon(
                            _isbnMessageIsError ? Icons.info_outline_rounded : Icons.check_circle_rounded,
                            size: 16,
                            color: _isbnMessageIsError ? theme.colorScheme.error : context.app.statusFinished,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isbnMessage!,
                              style: TextStyle(fontSize: 12, color: _isbnMessageIsError ? theme.colorScheme.error : context.app.statusFinished),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                ],

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceOptions,
                      child: Hero(
                        tag: 'cover_edit',
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 150, width: 105,
                          decoration: BoxDecoration(
                            color: context.cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: isDNF ? context.app.statusAbandoned.withValues(alpha: 0.4) : Colors.transparent),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 20, offset: const Offset(0, 10)
                              )
                            ],
                            image: _imagePreview != null ? DecorationImage(image: FileImage(_imagePreview!), fit: BoxFit.cover) : null,
                          ),
                          child: _isDownloadingCover
                            ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                            : _imagePreview == null
                              ? Icon(Icons.add_a_photo_rounded, color: theme.colorScheme.primary, size: 30)
                              : isDNF ? const Center(child: Icon(Icons.heart_broken_rounded, color: Colors.white, size: 32)) : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _buildModernField(controller: _titleController, label: context.l10n.addBookTitleLabel, icon: Icons.book_rounded, isBold: true, validator: (v) => _validateText(v, context.l10n.addBookTitleRequired)),
                          const SizedBox(height: 16),
                          _buildModernField(controller: _authorController, label: context.l10n.addBookAuthorLabel, icon: Icons.person_rounded, validator: (v) => _validateText(v, context.l10n.addBookAuthorRequired)),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                // CORRECCIÓN: El estilo no acepta opacity, se aplica al color
                Text(
                  context.l10n.addBookDetails,
                  style: TextStyle(
                    fontWeight: FontWeight.w800, 
                    fontSize: 16, 
                    color: (context.cs.onSurface).withValues(alpha: 0.8)
                  )
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildModernField(controller: _categoryController, label: context.l10n.addBookCategoryLabel, icon: Icons.local_offer_rounded, validator: (v) => (v?.trim().length ?? 0) > _maxTextLength ? context.l10n.addBookMaxChars(_maxTextLength) : null)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildModernField(controller: _pagesController, label: context.l10n.addBookPagesLabel, icon: Icons.auto_stories_rounded, isNumber: true, validator: _validatePages)),
                  ],
                ),
                
                const SizedBox(height: 32),
                if (widget.bookToEdit != null) ...[
                  // CORRECCIÓN: El estilo no acepta opacity, se aplica al color
                  Text(
                    context.l10n.addBookReadingStatus,
                    style: TextStyle(
                      fontWeight: FontWeight.w800, 
                      fontSize: 16, 
                      color: (context.cs.onSurface).withValues(alpha: 0.8)
                    )
                  ),
                  const SizedBox(height: 16),
                  _buildStatusSelector(isDark, theme, isDNF),
                ],

                const SizedBox(height: 40),
                
                InkWell(
                  onTap: _isSaving ? null : _save,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: double.infinity, height: 65,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        colors: isDNF 
                          ? [context.app.statusAbandoned.withValues(alpha: 0.75), context.app.statusAbandoned] 
                          : [theme.colorScheme.primary, theme.colorScheme.secondary.withValues(alpha: 0.8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDNF ? context.app.statusAbandoned : theme.colorScheme.primary).withValues(alpha: 0.3),
                          blurRadius: 20, offset: const Offset(0, 10)
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.bookToEdit == null ? context.l10n.addBookAddToCollection : context.l10n.addBookUpdateLibrary,
                        style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    bool isNumber = false,
    bool isBold = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
          textCapitalization: isNumber ? TextCapitalization.none : TextCapitalization.sentences,
          style: TextStyle(
            fontSize: 16, 
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: context.cs.onSurface
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w400),
            prefixIcon: Icon(icon, size: 20, color: context.app.accent.withValues(alpha: 0.5)),
            filled: true,
            fillColor: context.cs.surfaceContainerHigh,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20), 
              borderSide: BorderSide(color: context.app.accent.withValues(alpha: 0.3), width: 1)
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSelector(bool isDark, ThemeData theme, bool isDNF) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _statusItem(0, context.l10n.statusPending, Icons.hourglass_empty_rounded, isDark),
          _statusItem(1, context.l10n.statusReading, Icons.menu_book_rounded, isDark),
          _statusItem(2, context.l10n.addBookStatusRead, Icons.check_circle_rounded, isDark),
          _statusItem(3, context.l10n.addBookStatusDnf, Icons.heart_broken_rounded, isDark, isDnfColor: true),
        ],
      ),
    );
  }

  Widget _statusItem(int value, String label, IconData icon, bool isDark, {bool isDnfColor = false}) {
    final isSelected = _selectedStatus == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatus = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
              ? (isDnfColor ? context.app.statusAbandoned : context.app.accent) 
              : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? context.app.onAccent : (context.cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                fontSize: 10, 
                fontWeight: FontWeight.bold,
                color: isSelected ? context.app.onAccent : (context.cs.onSurfaceVariant)
              )),
            ],
          ),
        ),
      ),
    );
  }
}