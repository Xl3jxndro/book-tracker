import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../services/device_auth_service.dart';
import '../widgets/secret_dialogs.dart';

/// Pantalla de bloqueo. Al identificarse, `authProvider` marca el acceso y
/// `main.dart` muestra la app.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _passphraseController = TextEditingController();

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  String _currentPin = "";
  bool _isAuthenticating = false;
  bool _showPinField = false;
  bool _canUseBiometrics = false;

  /// Refresca la cuenta atrás mientras hay espera por intentos fallidos.
  Timer? _lockTimer;

  bool get _isLockedOut {
    final until = ref.read(authProvider).lockedUntil;
    return until != null && until.isAfter(DateTime.now());
  }

  String get _remainingText {
    final until = ref.read(authProvider).lockedUntil;
    if (until == null) return '';
    final left = until.difference(DateTime.now());
    final seconds = left.inSeconds < 0 ? 0 : left.inSeconds + 1;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  void _syncLockTimer() {
    if (!_isLockedOut) {
      _lockTimer?.cancel();
      _lockTimer = null;
      return;
    }
    _lockTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {}); // actualiza la cuenta atrás
      if (!_isLockedOut) {
        _lockTimer?.cancel();
        _lockTimer = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);

    final auth = ref.read(authProvider);
    // Instalaciones antiguas con PIN pero sin palabra: se entra con el PIN
    _showPinField = !auth.isPassphraseSet && auth.isPinSet;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncLockTimer();
      _initBiometrics();
    });
  }

  /// Si hay huella registrada, la ofrece en cuanto se abre la pantalla.
  Future<void> _initBiometrics() async {
    final auth = ref.read(authProvider);
    final hasSecret = auth.isPassphraseSet || auth.isPinSet;
    if (!hasSecret) return;

    final available = await DeviceAuthService.canUseBiometrics();
    if (!mounted) return;
    setState(() => _canUseBiometrics = available);
    if (available) _authenticateWithBiometrics();
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _shakeController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  void _handleError(String message) {
    HapticFeedback.vibrate();
    _shakeController.forward(from: 0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() {
      _currentPin = "";
      _passphraseController.clear();
    });
  }

  // --- Configuración inicial ---

  Future<void> _createPassphrase() async {
    final phrase = await showNewPassphraseDialog(context, title: 'Crea tu Santo y Seña');
    if (phrase == null || !mounted) return;

    final auth = ref.read(authProvider.notifier);
    await auth.savePassphrase(phrase);
    if (!mounted) return;

    final wantsPin = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("✨ Palabra Guardada"),
        content: const Text(
          "¿Quieres un PIN de 4 dígitos como respaldo? Podrás configurarlo después en Ajustes.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Ahora no")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Configurar PIN")),
        ],
      ),
    );

    if (wantsPin == true && mounted) {
      final pin = await showNewPinDialog(context);
      if (pin != null) await auth.saveNewPin(pin);
    }

    HapticFeedback.lightImpact();
    await auth.completeSetup();
  }

  Future<void> _skipLock() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Usar sin bloqueo?'),
        content: const Text(
          'Cualquiera con acceso a tu teléfono podrá abrir tu biblioteca. '
          'Puedes activar el bloqueo cuando quieras en Ajustes → Seguridad.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Usar sin bloqueo')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).setLockEnabled(false);
    }
  }

  // --- Acceso ---

  void _submitPassphrase() async {
    final phrase = _passphraseController.text.trim();
    if (phrase.isEmpty) return;

    final result = await ref.read(authProvider.notifier).verifyPassphrase(phrase);
    if (!mounted) return;
    _handleResult(result, "Esa no es la palabra mágica...");
  }

  void _handleResult(LoginResult result, String wrongMessage) {
    switch (result) {
      case LoginResult.success:
        HapticFeedback.lightImpact();
      case LoginResult.wrong:
        _syncLockTimer();
        _handleError(_isLockedOut
            ? 'Demasiados intentos. Espera $_remainingText para volver a probar.'
            : wrongMessage);
      case LoginResult.locked:
        _syncLockTimer();
        _handleError('Espera $_remainingText para volver a probar.');
    }
  }

  void _onNumberPressed(String number) async {
    if (_isLockedOut || _currentPin.length >= AuthNotifier.pinLength) return;
    setState(() => _currentPin += number);

    if (_currentPin.length == AuthNotifier.pinLength) {
      final result = await ref.read(authProvider.notifier).verifyPin(_currentPin);
      if (!mounted) return;
      _handleResult(result, "El PIN no es correcto.");
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    final didAuth = await DeviceAuthService.authenticate(
      reason: 'Acceso rápido a tu biblioteca',
      biometricOnly: true,
    );
    if (!mounted) return;
    setState(() => _isAuthenticating = false);
    if (didAuth) {
      HapticFeedback.lightImpact();
      ref.read(authProvider.notifier).markAuthenticated();
    }
  }

  /// "Olvidé mi palabra": se verifica con el bloqueo del teléfono y se elige otra.
  Future<void> _recoverAccess() async {
    if (!await DeviceAuthService.isDeviceSecure()) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No podemos verificar que eres tú'),
          content: const Text(
            'Para recuperar el acceso, activa un bloqueo de pantalla (PIN, patrón o huella) '
            'en los ajustes de tu teléfono y vuelve a intentarlo. Tus libros siguen a salvo.',
          ),
          actions: [
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
          ],
        ),
      );
      return;
    }

    final verified = await DeviceAuthService.authenticate(
      reason: 'Verifica que eres tú para elegir una palabra nueva',
    );
    if (!verified || !mounted) return;

    final phrase = await showNewPassphraseDialog(context, title: 'Elige una palabra nueva');
    if (phrase == null) return;
    HapticFeedback.lightImpact();
    await ref.read(authProvider.notifier).resetPassphrase(phrase);
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final isSetup = !authState.isPassphraseSet && !authState.isPinSet;

    final String title = isSetup
        ? "Crea tu Santo y Seña para iniciar la aventura"
        : (_showPinField ? "Introduce tu PIN de respaldo" : "Di la palabra mágica para entrar");

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) => Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showPinField ? Icons.dialpad_rounded : Icons.auto_stories_rounded,
                      size: 70,
                      color: theme.colorScheme.primary
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (!isSetup && _isLockedOut) _buildLockoutBanner(theme),

                    if (isSetup)
                      _buildSetup(theme)
                    else if (!_showPinField)
                      _buildPassphraseInput(theme)
                    else ...[
                      _buildPinIndicators(theme),
                      const SizedBox(height: 32),
                      _buildNumpadGrid(theme),
                    ],

                    if (!isSetup) ...[
                      const SizedBox(height: 24),
                      if (authState.isPassphraseSet && authState.isPinSet)
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _showPinField = !_showPinField;
                            _currentPin = "";
                          }),
                          icon: Icon(_showPinField ? Icons.auto_fix_high : Icons.dialpad),
                          label: Text(_showPinField ? "Usar Santo y Seña" : "Usar PIN de respaldo"),
                        ),
                      TextButton(
                        onPressed: _recoverAccess,
                        child: Text(
                          _showPinField ? '¿Olvidaste tu PIN?' : '¿Olvidaste tu palabra secreta?',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockoutBanner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(40, 0, 40, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Demasiados intentos. Podrás volver a probar en $_remainingText.\n'
              'Mientras, puedes usar la huella o «¿Olvidaste…?».',
              style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetup(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(
            'Una palabra secreta protege tu biblioteca. Si la olvidas, podrás recuperarla '
            'con el bloqueo de tu teléfono.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createPassphrase,
            icon: const Icon(Icons.vpn_key_rounded),
            label: const Text("Crear palabra secreta"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: _skipLock, child: const Text('Usar sin bloqueo')),
        ],
      ),
    );
  }

  Widget _buildPassphraseInput(ThemeData theme) {
    final hasText = _passphraseController.text.trim().isNotEmpty && !_isLockedOut;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          TextField(
            controller: _passphraseController,
            autofocus: !_canUseBiometrics,
            textAlign: TextAlign.center,
            style: const TextStyle(letterSpacing: 1.5, fontSize: 18),
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              hintText: "Escribe la palabra...",
              prefixIcon: const Icon(Icons.vpn_key_rounded),
              suffixIcon: _canUseBiometrics
                  ? IconButton(
                      icon: Icon(Icons.fingerprint, color: theme.colorScheme.primary),
                      tooltip: 'Usar huella',
                      onPressed: _authenticateWithBiometrics,
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            onSubmitted: (_) => _submitPassphrase(),
          ),
          const SizedBox(height: 24),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: hasText ? 1.0 : 0.0,
            child: ElevatedButton.icon(
              onPressed: hasText ? _submitPassphrase : null,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text("Revelar biblioteca"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinIndicators(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(AuthNotifier.pinLength, (index) {
        final filled = index < _currentPin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 14, height: 14,
          decoration: BoxDecoration(
            color: filled ? theme.colorScheme.primary : theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  // TECLADO EN GRID 3x4
  Widget _buildNumpadGrid(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _buildNumpadRow(theme, ["1", "2", "3"]),
          const SizedBox(height: 16),
          _buildNumpadRow(theme, ["4", "5", "6"]),
          const SizedBox(height: 16),
          _buildNumpadRow(theme, ["7", "8", "9"]),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Espacio para biometría a la izquierda del 0
              SizedBox(
                width: 65,
                child: _canUseBiometrics ? IconButton(
                  icon: Icon(Icons.fingerprint, color: theme.colorScheme.primary, size: 35),
                  onPressed: _authenticateWithBiometrics,
                ) : null,
              ),
              const SizedBox(width: 16),
              _buildKey(theme, "0"),
              const SizedBox(width: 16),
              _buildKey(theme, "backspace"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadRow(ThemeData theme, List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: values.map((v) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: _buildKey(theme, v),
      )).toList(),
    );
  }

  Widget _buildKey(ThemeData theme, String value) {
    final isBackspace = value == "backspace";
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        if (isBackspace) {
          if (_currentPin.isNotEmpty) {
            setState(() => _currentPin = _currentPin.substring(0, _currentPin.length - 1));
          }
        } else {
          _onNumberPressed(value);
        }
      },
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 65, height: 65,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        ),
        child: isBackspace
            ? const Icon(Icons.backspace_outlined, size: 22)
            : Text(value, style: theme.textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
