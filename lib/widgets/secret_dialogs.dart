import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../services/device_auth_service.dart';

/// Pide una palabra secreta nueva (escrita dos veces). Devuelve `null` si se cancela.
Future<String?> showNewPassphraseDialog(BuildContext context, {String? title}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NewSecretDialog(title: title ?? context.l10n.secretNewPassphraseTitle, isPin: false),
  );
}

/// Pide un PIN nuevo de 4 dígitos (escrito dos veces). Devuelve `null` si se cancela.
Future<String?> showNewPinDialog(BuildContext context, {String? title}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _NewSecretDialog(title: title ?? context.l10n.secretPinTitle, isPin: true),
  );
}

/// Confirma que quien usa la app es el dueño antes de una acción sensible:
/// primero con huella o el bloqueo del teléfono y, si no se puede o se
/// cancela, escribiendo la palabra secreta o el PIN.
Future<bool> confirmIdentity(BuildContext context, AuthNotifier auth, {required AuthState state}) async {
  // Sin palabra ni PIN no hay nada que proteger todavía
  if (!state.isPassphraseSet && !state.isPinSet) return true;

  final reason = context.l10n.secretConfirmIdentity;
  if (await DeviceAuthService.isDeviceSecure()) {
    final ok = await DeviceAuthService.authenticate(reason: reason);
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
      return v.length == AuthNotifier.pinLength ? null : context.l10n.secretPinLengthError(AuthNotifier.pinLength);
    }
    return v.length >= 3 ? null : context.l10n.secretMinLengthError;
  }

  String? get _secondError =>
      _normalize(_first.text) == _normalize(_second.text) ? null : context.l10n.secretMismatch;

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
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(context.l10n.secretCaseHint, style: const TextStyle(fontSize: 13)),
            ),
          field(_first, isPin ? context.l10n.secretNewPinLabel : context.l10n.secretPassphraseLabel, _firstError),
          const SizedBox(height: 12),
          field(_second, isPin ? context.l10n.secretRepeatPin : context.l10n.secretRepeatPassphrase, _secondError, last: true),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.commonCancel)),
        ElevatedButton(onPressed: _submit, child: Text(context.l10n.commonSave)),
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
      title: Text(context.l10n.secretConfirmIdentity),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: true,
        onChanged: (_) {
          if (_wrong) setState(() => _wrong = false);
        },
        onSubmitted: (_) => _check(),
        decoration: InputDecoration(
          labelText: context.l10n.secretPassphraseOrPin,
          errorText: _wrong ? context.l10n.secretWrong : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.commonCancel)),
        ElevatedButton(onPressed: _checking ? null : _check, child: Text(context.l10n.secretConfirm)),
      ],
    );
  }
}
