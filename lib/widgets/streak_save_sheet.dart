import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/streak_save_provider.dart';
import '../services/ads_gate.dart';
import '../services/rewarded_ads.dart';
import '../services/streak_save.dart';
import '../theme/app_colors.dart';

/// "Perdiste tu racha de N días: ¿la recuperas viendo un anuncio?".
Future<void> showStreakSaveSheet(
  BuildContext context,
  StreakSaveOffer offer, {
  Future<RewardedResult> Function()? showAd,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Con "Quitar anuncios" se salva sin ver nada
    builder: (_) => StreakSaveSheet(
      offer: offer,
      showAd: showAd ?? (AdsGate.adsRemoved ? () async => RewardedResult.rewarded : RewardedAds.showStreakSave),
      free: showAd == null && AdsGate.adsRemoved,
    ),
  );
}

class StreakSaveSheet extends ConsumerStatefulWidget {
  final StreakSaveOffer offer;
  final Future<RewardedResult> Function() showAd;

  /// Usuario sin anuncios: se salva sin ver nada.
  final bool free;
  const StreakSaveSheet({super.key, required this.offer, required this.showAd, this.free = false});

  @override
  ConsumerState<StreakSaveSheet> createState() => _StreakSaveSheetState();
}

class _StreakSaveSheetState extends ConsumerState<StreakSaveSheet> {
  bool _loading = false;
  String? _error;

  Future<void> _watch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.showAd();
    if (!mounted) return;
    switch (result) {
      case RewardedResult.rewarded:
        await ref.read(streakSaveProvider.notifier).save(widget.offer.day);
        HapticFeedback.heavyImpact();
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('🔥 ¡Racha salvada! Sigues con ${widget.offer.lostStreak + 1} días. Lee hoy para mantenerla.'),
        ));
      case RewardedResult.closedEarly:
        setState(() {
          _loading = false;
          _error = 'Hay que ver el anuncio completo para salvar la racha.';
        });
      case RewardedResult.unavailable:
        setState(() {
          _loading = false;
          _error = 'Ahora no hay anuncios disponibles. Revisa tu conexión e inténtalo de nuevo.';
        });
    }
  }

  Future<void> _dismiss() async {
    await ref.read(streakSaveProvider.notifier).dismiss();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final n = widget.offer.lostStreak;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: context.cs.outline, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [context.app.streak.withValues(alpha: 0.8), context.app.streak]),
                  boxShadow: [BoxShadow(color: context.app.streak.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 46),
              ),
              const SizedBox(height: 20),
              Text('Tu racha de $n días se rompió',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                widget.free
                    ? 'Ayer no registraste lectura. Como usuario sin anuncios, puedes recuperarla gratis: ayer contará para tu racha.'
                    : 'Ayer no registraste lectura. Mira un anuncio corto y la recuperamos: ayer contará para tu racha.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 6),
              Text('Puedes hacerlo una vez por semana.',
                  textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _watch,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(widget.free ? Icons.local_fire_department_rounded : Icons.play_circle_fill_rounded),
                  label: Text(_loading
                      ? 'Cargando anuncio…'
                      : (widget.free ? 'Salvar mi racha' : 'Ver anuncio y salvar mi racha')),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: context.app.streak,
                    foregroundColor: context.app.onAccent,
                  ),
                ),
              ),
              TextButton(
                onPressed: _loading ? null : _dismiss,
                child: const Text('Ahora no'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
