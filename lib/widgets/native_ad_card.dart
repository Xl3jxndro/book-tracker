import 'package:material_ui/material_ui.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads_gate.dart';

/// Anuncio nativo con el mismo estilo de tarjeta de la app. Carga su propio
/// anuncio (cada tarjeta muestra uno distinto) cuando hay permiso para pedir
/// anuncios; mientras no carga, no ocupa espacio. Se mantiene vivo al hacer
/// scroll para no pedir el anuncio de nuevo.
class NativeAdCard extends StatefulWidget {
  final String adUnitId;
  final EdgeInsetsGeometry margin;
  const NativeAdCard({super.key, required this.adUnitId, this.margin = EdgeInsets.zero});

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> with AutomaticKeepAliveClientMixin {
  NativeAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  bool get wantKeepAlive => _loaded;

  @override
  void initState() {
    super.initState();
    AdsGate.showAds.addListener(_onGateChanged);
    _load();
  }

  void _onGateChanged() {
    if (!mounted) return;
    setState(() {}); // p. ej. se compró "Quitar anuncios": se oculta
    _load();
  }

  void _load() {
    if (_requested || !AdsGate.showAds.value) return;
    _requested = true;
    _ad = NativeAd(
      adUnitId: widget.adUnitId,
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
          updateKeepAlive();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _ad = null;
          debugPrint('Anuncio nativo no disponible: ${error.message}');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    AdsGate.showAds.removeListener(_onGateChanged);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ad = _ad;
    if (!_loaded || ad == null || !AdsGate.showAds.value) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      margin: widget.margin,
      height: 90,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
