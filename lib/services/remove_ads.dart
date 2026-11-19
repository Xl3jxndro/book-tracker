import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Acceso a la tienda (Google Play Billing). Separado para poder probar la
/// lógica de compra con una tienda simulada.
abstract class PurchaseStore {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<ProductDetails?> queryProduct(String id);
  Future<bool> buyNonConsumable(ProductDetails product);
  Future<void> restorePurchases();
  Future<void> completePurchase(PurchaseDetails purchase);
}

class PlayPurchaseStore implements PurchaseStore {
  // Solo se accede al plugin al usarlo (no al crear la instancia)
  InAppPurchase get _iap => InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;
  @override
  Future<bool> isAvailable() => _iap.isAvailable();
  @override
  Future<ProductDetails?> queryProduct(String id) async {
    final response = await _iap.queryProductDetails({id});
    return response.productDetails.where((p) => p.id == id).firstOrNull;
  }

  @override
  Future<bool> buyNonConsumable(ProductDetails product) =>
      _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  @override
  Future<void> restorePurchases() => _iap.restorePurchases();
  @override
  Future<void> completePurchase(PurchaseDetails purchase) => _iap.completePurchase(purchase);
}

enum RemoveAdsStatus { idle, loading, pending, error, unavailable }

/// Compra única "Quitar anuncios" (producto no consumible `remove_ads`).
/// Al comprarla desaparecen los anuncios y "Salvar racha" es gratis.
class RemoveAds {
  static const productId = 'remove_ads';
  static const _prefsKey = 'ads_removed';

  RemoveAds(this._store);

  /// Instancia de la app (se reemplaza en los tests).
  static RemoveAds instance = RemoveAds(PlayPurchaseStore());

  final PurchaseStore _store;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// La compra está activa (sin anuncios).
  final ValueNotifier<bool> active = ValueNotifier(false);
  final ValueNotifier<RemoveAdsStatus> status = ValueNotifier(RemoveAdsStatus.idle);

  /// Precio con moneda local ("US$ 2,99", "COP 9.900"...), null si no cargó.
  final ValueNotifier<String?> price = ValueNotifier(null);
  String? lastError;
  ProductDetails? _product;

  /// Al arrancar: estado guardado, escucha de compras y restauración
  /// silenciosa (reinstalación, otro teléfono con la misma cuenta).
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      active.value = prefs.getBool(_prefsKey) ?? false;
      _sub ??= _store.purchaseStream.listen(handlePurchases, onError: (Object e) {
        debugPrint('Compras: $e');
      });
      if (!await _store.isAvailable()) {
        status.value = RemoveAdsStatus.unavailable;
        return;
      }
      await _loadProduct();
      await _store.restorePurchases();
    } catch (e) {
      debugPrint('No se pudo iniciar la tienda: $e');
    }
  }

  Future<void> _loadProduct() async {
    _product ??= await _store.queryProduct(productId);
    price.value = _product?.price;
    if (_product == null && !active.value) status.value = RemoveAdsStatus.unavailable;
  }

  /// Abre el flujo de pago de Google Play.
  Future<void> buy() async {
    if (active.value) return;
    status.value = RemoveAdsStatus.loading;
    try {
      if (!await _store.isAvailable()) {
        status.value = RemoveAdsStatus.unavailable;
        return;
      }
      await _loadProduct();
      final product = _product;
      if (product == null) {
        status.value = RemoveAdsStatus.unavailable;
        return;
      }
      await _store.buyNonConsumable(product);
      // El resultado llega por purchaseStream
    } catch (e) {
      lastError = 'No se pudo iniciar la compra.';
      status.value = RemoveAdsStatus.error;
    }
  }

  /// "Restaurar compra" (Ajustes).
  Future<void> restore() async {
    status.value = RemoveAdsStatus.loading;
    try {
      await _store.restorePurchases();
    } finally {
      if (status.value == RemoveAdsStatus.loading) status.value = RemoveAdsStatus.idle;
    }
  }

  /// Procesa las actualizaciones de compras de la tienda.
  @visibleForTesting
  Future<void> handlePurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases.where((p) => p.productID == productId)) {
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _deliver();
        case PurchaseStatus.pending:
          status.value = RemoveAdsStatus.pending; // p. ej. pago en efectivo aún sin confirmar
        case PurchaseStatus.error:
          lastError = p.error?.message ?? 'La compra no se completó.';
          status.value = RemoveAdsStatus.error;
        case PurchaseStatus.canceled:
          status.value = RemoveAdsStatus.idle;
      }
      // Confirmar ante Google: si no se confirma en 3 días, Play la reembolsa
      if (p.pendingCompletePurchase) await _store.completePurchase(p);
    }
  }

  Future<void> _deliver() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    active.value = true;
    status.value = RemoveAdsStatus.idle;
  }

  Future<void> dispose() async => _sub?.cancel();
}
