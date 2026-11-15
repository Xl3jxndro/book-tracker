import 'package:flutter_riverpod/flutter_riverpod.dart';

// Controla si la barra de navegación debe ser visible
final navBarVisibleProvider = StateProvider<bool>((ref) => true);