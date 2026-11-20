import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../providers/auth_provider.dart';
import '../services/device_auth_service.dart';

/// Pide una palabra secreta nueva (escrita dos veces). Devuelve `null` si se cancela.
Future<String?> showNewPassphraseDialog(BuildContext context, {String title = 'Nueva palabra secreta'}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NewSecretDialog(title: title, isPin: false),
  );
}

/// Pide un PIN nuevo de 4 dígitos (escrito dos veces). Devuelve `null` si se cancela.
Future<String?> showNewPinDialog(BuildContext context, {String title = 'PIN de respaldo'}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NewSecretDialog(title: title, isPin: true),
  );
}

/// Confirma que quien usa la app es el dueño antes de una acción sensible:
/// primero con huella o el bloqueo del teléfono y, si no se puede o se
/// cancela, escribiendo la palabra secreta o el PIN.
Future<bool> confirmIdentity(BuildContext context, AuthNotifier auth, {required AuthState state}) async {
  // Sin palabra ni PIN no hay nada que proteger todavía
  if (!state.isPassphraseSet && !state.isPinSet) return true;

  if (await DeviceAuthService.isDeviceSecure()) {
    final ok = await DeviceAuthService.authenticate(reason: 'Confirma que eres tú');
    if (ok) return true;
  }
  if (!context.mounted) return false;

  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => _VerifySecretDialog(verify: auth.verifySecret),
  );
  return ok ?? false;
}

class _NewSecretDialog extends StatefulWidget {
  final String title;
  final bool isPin;
  const _NewSecretDialog({required this.title, required this.isPin});

  @override
  State<_NewSecretDialog> createState() => _NewSecretDialogState();
}

class _NewSecretDialogState extends State<_NewSecretDialog> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  String _normalize(String v) => widget.isPin ? v.trim() : v.trim().toLowerCase();

  String? get _firstError {
    final v = _first.text.trim();
    if (widget.isPin) {
      return v.length == AuthNotifier.pinLength ? null : 'Deben ser ${AuthNotifier.pinLength} dígitos';
    }
    return v.length >= 3 ? null : 'Al menos 3 caracteres';
  }

  String? get _secondError =>
      _normalize(_first.text) == _normalize(_second.text) ? null : 'No coinciden';

  void _submit() {
    setState(() => _submitted = true);
    if (_firstError != null || _secondError != null) {
      HapticFeedback.heavyImpact();
      return;
    }
    Navigator.pop(context, _first.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final isPin = widget.isPin;
    InputDecoration deco(String label, String? error) => InputDecoration(
          labelText: label,
          errorText: _submitted ? error : null,
          counterText: '',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        );

    TextField field(TextEditingController c, String label, String? error, {bool last = false}) => TextField(
          controller: c,
          obscureText: isPin,
          autofocus: !last,
          maxLength: isPin ? AuthNotifier.pinLength : 100,
          keyboardType: isPin ? TextInputType.number : TextInputType.text,
          inputFormatters: isPin ? [FilteringTextInputFormatter.digitsOnly] : null,
          textInputAction: last ? TextInputAction.done : TextInputAction.next,
          onChanged: (_) => setState(() {}),
          onSubmitted: last ? (_) => _submit() : null,
          decoration: deco(label, error),
        );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isPin)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('No distingue mayúsculas. Elige algo que recuerdes.', style: TextStyle(fontSize: 13)),
            ),
          field(_first, isPin ? 'Nuevo PIN' : 'Palabra secreta', _firstError),
          const SizedBox(height: 12),
          field(_second, isPin ? 'Repite el PIN' : 'Repite la palabra', _secondError, last: true),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}

class _VerifySecretDialog extends StatefulWidget {
  final Future<bool> Function(String) verify;
  const _VerifySecretDialog({required this.verify});

  @override
  State<_VerifySecretDialog> createState() => _VerifySecretDialogState();
}

class _VerifySecretDialogState extends State<_VerifySecretDialog> {
  final _controller = TextEditingController();
  bool _wrong = false;
  bool _checking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking || _controller.text.trim().isEmpty) return;
    setState(() => _checking = true);
    final ok = await widget.verify(_controller.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _wrong = true;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Confirma que eres tú'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        onChanged: (_) {
          if (_wrong) setState(() => _wrong = false);
        },
        onSubmitted: (_) => _check(),
        decoration: InputDecoration(
          labelText: 'Palabra secreta o PIN',
          errorText: _wrong ? 'No es correcta' : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _checking ? null : _check, child: const Text('Confirmar')),
      ],
    );
  }
}
