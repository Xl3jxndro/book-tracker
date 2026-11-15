import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/database.dart';
import '../providers/database_provider.dart';

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

  // Límites definidos en la tabla Books (database.dart)
  static const _maxTextLength = 100;
  static const _maxPages = 100000;

  String? _validateText(String? value, String fieldName) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$fieldName es obligatorio';
    if (text.length > _maxTextLength) return 'Máximo $_maxTextLength caracteres';
    return null;
  }

  String? _validatePages(String? value) {
    final pages = int.tryParse(value?.trim() ?? '');
    if (pages == null || pages <= 0) return 'Indica las páginas';
    if (pages > _maxPages) return 'Número no válido';
    final readPages = widget.bookToEdit?.readPages ?? 0;
    if (pages < readPages) return 'Ya leíste $readPages';
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
    super.dispose();
  }

  Future<void> _showImageSourceOptions() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            const Text("Cambiar portada", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(icon: Icons.camera_rounded, label: "Cámara", onTap: () => _pickImage(ImageSource.camera), isDark: isDark),
                _buildSourceOption(icon: Icons.image_rounded, label: "Galería", onTap: () => _pickImage(ImageSource.gallery), isDark: isDark),
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
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.indigo.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: Colors.indigoAccent, size: 32),
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
    if (pickedFile != null) setState(() => _imagePreview = File(pickedFile.path));
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
        await db.updateBook(bookToEdit.copyWith(
          title: title,
          author: author,
          totalPages: totalPages,
          readPages: readPages,
          category: drift.Value(category),
          status: _selectedStatus,
          coverUrl: drift.Value(finalImagePath),
        ));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error guardando libro: $e");
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo guardar el libro. Inténtalo de nuevo.'),
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
          color: isDark ? const Color(0xFF0F0F0F).withOpacity(0.9) : Colors.white.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40)],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 45, height: 5, decoration: BoxDecoration(color: isDark ? Colors.white12 : Colors.black12, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 32),
                
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
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: isDNF ? Colors.redAccent.withOpacity(0.3) : Colors.transparent),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20, offset: const Offset(0, 10)
                              )
                            ],
                            image: _imagePreview != null ? DecorationImage(image: FileImage(_imagePreview!), fit: BoxFit.cover) : null,
                          ),
                          child: _imagePreview == null 
                            ? Icon(Icons.add_a_photo_rounded, color: theme.colorScheme.primary, size: 30) 
                            : isDNF ? const Center(child: Icon(Icons.heart_broken_rounded, color: Colors.white, size: 32)) : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _buildModernField(controller: _titleController, label: 'Título del libro', icon: Icons.book_rounded, isBold: true, validator: (v) => _validateText(v, 'El título')),
                          const SizedBox(height: 16),
                          _buildModernField(controller: _authorController, label: 'Autor', icon: Icons.person_rounded, validator: (v) => _validateText(v, 'El autor')),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                // CORRECCIÓN: El estilo no acepta opacity, se aplica al color
                Text(
                  "Detalles del libro", 
                  style: TextStyle(
                    fontWeight: FontWeight.w800, 
                    fontSize: 16, 
                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.8)
                  )
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildModernField(controller: _categoryController, label: 'Categoría', icon: Icons.local_offer_rounded, validator: (v) => (v?.trim().length ?? 0) > _maxTextLength ? 'Máximo $_maxTextLength caracteres' : null)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildModernField(controller: _pagesController, label: 'Páginas', icon: Icons.auto_stories_rounded, isNumber: true, validator: _validatePages)),
                  ],
                ),
                
                const SizedBox(height: 32),
                if (widget.bookToEdit != null) ...[
                  // CORRECCIÓN: El estilo no acepta opacity, se aplica al color
                  Text(
                    "Estado de lectura", 
                    style: TextStyle(
                      fontWeight: FontWeight.w800, 
                      fontSize: 16, 
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.8)
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
                          ? [Colors.redAccent.shade200, Colors.redAccent.shade700] 
                          : [theme.colorScheme.primary, theme.colorScheme.secondary.withOpacity(0.8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDNF ? Colors.redAccent : theme.colorScheme.primary).withOpacity(0.3),
                          blurRadius: 20, offset: const Offset(0, 10)
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.bookToEdit == null ? "Añadir a la Colección" : "Actualizar Biblioteca",
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            color: isDark ? Colors.white : Colors.black87
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14, fontWeight: FontWeight.w400),
            prefixIcon: Icon(icon, size: 20, color: Colors.indigoAccent.withOpacity(0.5)),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20), 
              borderSide: BorderSide(color: Colors.indigoAccent.withOpacity(0.3), width: 1)
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
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _statusItem(0, "Pendiente", Icons.hourglass_empty_rounded, isDark),
          _statusItem(1, "Leyendo", Icons.menu_book_rounded, isDark),
          _statusItem(2, "Leído", Icons.check_circle_rounded, isDark),
          _statusItem(3, "DNF", Icons.heart_broken_rounded, isDark, isDnfColor: true),
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
              ? (isDnfColor ? Colors.redAccent : Colors.indigoAccent) 
              : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : (isDark ? Colors.white38 : Colors.black38)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                fontSize: 10, 
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : (isDark ? Colors.white38 : Colors.black38)
              )),
            ],
          ),
        ),
      ),
    );
  }
}