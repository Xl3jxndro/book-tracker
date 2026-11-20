import 'package:material_ui/material_ui.dart';

import '../services/remove_ads.dart';
import '../theme/app_colors.dart';

/// Ajustes: comprar "Quitar anuncios" (pago único) o restaurar la compra.
class RemoveAdsCard extends StatefulWidget {
  final RemoveAds? controller;
  const RemoveAdsCard({super.key, this.controller});

  @override
  State<RemoveAdsCard> createState() => _RemoveAdsCardState();
}

class _RemoveAdsCardState extends State<RemoveAdsCard> {
  RemoveAds get _c => widget.controller ?? RemoveAds.instance;

  @override
  void initState() {
    super.initState();
    _c.status.addListener(_onStatus);
  }

  @override
  void dispose() {
    _c.status.removeListener(_onStatus);
    super.dispose();
  }

  void _onStatus() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (_c.status.value) {
      case RemoveAdsStatus.error:
        messenger.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(_c.lastError ?? 'La compra no se completó.')));
      case RemoveAdsStatus.pending:
        messenger.showSnackBar(const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Tu pago está pendiente. Los anuncios se quitarán cuando Google Play lo confirme.'),
        ));
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([_c.active, _c.status, _c.price]),
      builder: (context, _) {
        final active = _c.active.value;
        final status = _c.status.value;
        final busy = status == RemoveAdsStatus.loading;

        if (active) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.app.statusFinished.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: context.app.statusFinished.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_rounded, color: context.app.statusFinished, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sin anuncios', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      Text('¡Gracias por apoyar Book Tracker! 💜',
                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final price = _c.price.value;
        final unavailable = status == RemoveAdsStatus.unavailable;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary.withValues(alpha: 0.14), scheme.tertiary.withValues(alpha: 0.10)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.block_rounded, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Quitar anuncios',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  if (price != null)
                    Text(price, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: scheme.primary)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Pago único, para siempre. Sin anuncios en la biblioteca, estadísticas ni citas, y "Salvar racha" gratis. '
                'Se mantiene si reinstalas o cambias de teléfono con la misma cuenta de Google.',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: (busy || unavailable) ? null : _c.buy,
                      child: busy
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(unavailable ? 'No disponible por ahora' : (price == null ? 'Comprar' : 'Comprar por $price')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(onPressed: busy ? null : _c.restore, child: const Text('Restaurar')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
