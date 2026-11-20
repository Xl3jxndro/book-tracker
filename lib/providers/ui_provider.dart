import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Valor simple que cualquier pantalla puede leer y cambiar (sustituye a
/// `StateProvider`, que en Riverpod 3 pasó a ser API heredada).
class SimpleState<T> extends Notifier<T> {
  SimpleState(this._initial);
  final T _initial;

  @override
  T build() => _initial;

  void set(T value) => state = value;
}

// Controla si la barra de navegación debe ser visible
final navBarVisibleProvider = NotifierProvider<SimpleState<bool>, bool>(() => SimpleState(true));
