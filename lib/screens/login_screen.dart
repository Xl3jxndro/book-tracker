import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final TextEditingController _passphraseController = TextEditingController();
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  String _currentPin = "";
  bool _isAuthenticating = false;
  bool _showPinField = false; 

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
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  void _handleSuccess() {
    HapticFeedback.lightImpact();
    widget.onLoginSuccess();
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

  void _submitPassphrase() async {
    final phrase = _passphraseController.text.trim();
    if (phrase.isEmpty) return;

    final authNotifier = ref.read(authProvider.notifier);
    final authState = ref.read(authProvider);

    if (!authState.isPassphraseSet) {
      await authNotifier.savePassphrase(phrase);
      _showPinOnboardingDialog();
    } else {
      final isValid = await authNotifier.verifyPassphrase(phrase);
      if (isValid) {
        _handleSuccess();
      } else {
        _handleError("Esa no es la palabra mágica...");
      }
    }
  }

  void _onNumberPressed(String number) async {
    if (_currentPin.length < 4) {
      setState(() => _currentPin += number);
      
      if (_currentPin.length == 4) {
        final authNotifier = ref.read(authProvider.notifier);
        final authState = ref.read(authProvider);

        if (!authState.isPinSet) {
          await authNotifier.saveNewPin(_currentPin);
          _handleSuccess();
        } else {
          final isValid = await authNotifier.verifyPin(_currentPin);
          if (isValid) {
            _handleSuccess();
          } else {
            _handleError("El PIN no es correcto.");
          }
        }
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;
    try {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return;

      setState(() => _isAuthenticating = true);
      final bool didAuth = await _localAuth.authenticate(
        localizedReason: 'Acceso rápido a tu biblioteca',
        options: const AuthenticationOptions(stickyAuth: true),
      );

      if (didAuth && mounted) _handleSuccess();
    } on PlatformException catch (e) {
      debugPrint("Error biometría: $e");
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  void _showPinOnboardingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("✨ Palabra Guardada"),
        content: const Text("¡Excelente! Ahora, por seguridad, configura un PIN de 4 dígitos como método de respaldo."),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentPin = "";
                _showPinField = true;
              });
            },
            child: const Text("CONFIGURAR PIN"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    
    if (authState.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final String title = !authState.isPassphraseSet 
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

                    if (!_showPinField) ...[
                      _buildPassphraseInput(theme, authState.isPassphraseSet),
                    ] else ...[
                      _buildPinIndicators(theme),
                      const SizedBox(height: 32),
                      _buildNumpadGrid(theme, authState.isPinSet),
                    ],

                    const SizedBox(height: 24),
                    if (authState.isPassphraseSet && authState.isPinSet)
                      TextButton.icon(
                        onPressed: () => setState(() => _showPinField = !_showPinField),
                        icon: Icon(_showPinField ? Icons.auto_fix_high : Icons.dialpad),
                        label: Text(_showPinField ? "Usar Santo y Seña" : "Usar PIN de respaldo"),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPassphraseInput(ThemeData theme, bool isSet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          TextField(
            controller: _passphraseController,
            autofocus: true,
            textAlign: TextAlign.center,
            style: const TextStyle(letterSpacing: 1.5, fontSize: 18),
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              hintText: isSet ? "Escribe la palabra..." : "Tu palabra secreta...",
              prefixIcon: const Icon(Icons.vpn_key_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ),
            onSubmitted: (_) => _submitPassphrase(),
          ),
          const SizedBox(height: 24),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _passphraseController.text.trim().isNotEmpty ? 1.0 : 0.0,
            child: ElevatedButton.icon(
              onPressed: _passphraseController.text.trim().isNotEmpty ? _submitPassphrase : null,
              icon: const Icon(Icons.auto_fix_high),
              label: Text(isSet ? "REVELAR BIBLIOTECA" : "CONTINUAR"),
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
      children: List.generate(4, (index) {
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

  // NUEVO TECLADO EN GRID 3x4
  Widget _buildNumpadGrid(ThemeData theme, bool showBiometrics) {
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
                child: showBiometrics ? IconButton(
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
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        ),
        child: isBackspace 
            ? const Icon(Icons.backspace_outlined, size: 22) 
            : Text(value, style: theme.textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
    );
  }
}