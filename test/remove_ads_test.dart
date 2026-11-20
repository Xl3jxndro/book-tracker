import 'dart:async';

import 'package:book_tracker/services/ads_consent.dart';
import 'package:book_tracker/services/ads_gate.dart';
import 'package:book_tracker/services/remove_ads.dart';
import 'package:book_tracker/widgets/remove_ads_card.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeStore implements PurchaseStore {
  final controller = StreamController<List<PurchaseDetails>>.broadcast();
  bool available = true;
  ProductDetails? product = ProductDetails(
    id: RemoveAds.productId,
    title: 'Quitar anuncios',
    description: 'Sin anuncios',
    price: 'COP 9.900',
    rawPrice: 9900,
    currencyCode: 'COP',
  );
  final completed = <PurchaseDetails>[];
  int buys = 0, restores = 0;
  Set<String>? owned = {};
  final awaitingPayment = <PurchaseDetails>{};

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<ProductDetails?> queryProduct(String id) async => product;
  @override
  Future<bool> buyNonConsumable(ProductDetails product) async {
    buys++;
    return true;
  }

  @override
  Future<void> restorePurchases() async => restores++;
  @override
  Future<void> completePurchase(PurchaseDetails purchase) async => completed.add(purchase);
  @override
  Future<Set<String>?> ownedProducts() async => owned;
  @override
  bool isAwaitingPayment(PurchaseDetails purchase) => awaitingPayment.contains(purchase);
}

PurchaseDetails _purchase(PurchaseStatus status, {String id = RemoveAds.productId, bool pendingComplete = true}) =>
    PurchaseDetails(
      purchaseID: 'GPA.1234',
      productID: id,
      verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: 'google_play'),
      transactionDate: '0',
      status: status,
    )..pendingCompletePurchase = pendingComplete;

void main() {
  late _FakeStore store;
  late RemoveAds ads;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = _FakeStore();
    ads = RemoveAds(store);
    await ads.initialize();
  });

  test('al iniciar carga el precio y restaura en silencio', () {
    expect(ads.price.value, 'COP 9.900');
    expect(store.restores, 1);
    expect(ads.active.value, isFalse);
  });

  test('compra completada: quita anuncios, se guarda y se confirma ante Google', () async {
    await ads.buy();
    expect(store.buys, 1);
    await ads.handlePurchases([_purchase(PurchaseStatus.purchased)]);
    expect(ads.active.value, isTrue);
    expect(store.completed, hasLength(1), reason: 'sin confirmar, Play la reembolsa a los 3 días');

    // Otra instancia (reinicio de la app) lo recuerda
    final again = RemoveAds(_FakeStore()
      ..product = null
      ..owned = null);
    await again.initialize();
    expect(again.active.value, isTrue);
  });

  test('restaurada (reinstalación u otro teléfono) también la activa', () async {
    await ads.handlePurchases([_purchase(PurchaseStatus.restored, pendingComplete: false)]);
    expect(ads.active.value, isTrue);
    expect(store.completed, isEmpty);
  });

  test('pendiente, error o cancelada no la activan', () async {
    await ads.handlePurchases([_purchase(PurchaseStatus.pending, pendingComplete: false)]);
    expect(ads.status.value, RemoveAdsStatus.pending);
    await ads.handlePurchases([_purchase(PurchaseStatus.error)]);
    expect(ads.status.value, RemoveAdsStatus.error);
    await ads.handlePurchases([_purchase(PurchaseStatus.canceled, pendingComplete: false)]);
    expect(ads.status.value, RemoveAdsStatus.idle);
    expect(ads.active.value, isFalse);
  });

  test('pago pendiente marcado como restaurado: ni se activa ni se confirma', () async {
    final p = _purchase(PurchaseStatus.restored);
    store.awaitingPayment.add(p);
    await ads.handlePurchases([p]);
    expect(ads.active.value, isFalse);
    expect(ads.status.value, RemoveAdsStatus.pending);
    expect(store.completed, isEmpty);
  });

  test('reembolsada: al abrir la app vuelven los anuncios', () async {
    await ads.handlePurchases([_purchase(PurchaseStatus.purchased)]);
    expect(ads.active.value, isTrue);

    final refunded = RemoveAds(_FakeStore()..owned = {});
    await refunded.initialize();
    expect(refunded.active.value, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('ads_removed'), isFalse);
  });

  test('sin poder consultar Play no se retira la compra', () async {
    await ads.handlePurchases([_purchase(PurchaseStatus.purchased)]);
    final offline = RemoveAds(_FakeStore()..owned = null);
    await offline.initialize();
    expect(offline.active.value, isTrue);

    final stillOwned = RemoveAds(_FakeStore()..owned = {RemoveAds.productId});
    await stillOwned.initialize();
    expect(stillOwned.active.value, isTrue);
  });

  test('ignora compras de otros productos', () async {
    await ads.handlePurchases([_purchase(PurchaseStatus.purchased, id: 'otro')]);
    expect(ads.active.value, isFalse);
  });

  test('si el producto no existe en Play: no disponible', () async {
    final s = _FakeStore()..product = null;
    final r = RemoveAds(s);
    await r.initialize();
    await r.buy();
    expect(r.status.value, RemoveAdsStatus.unavailable);
    expect(s.buys, 0);
  });

  test('con la compra, se dejan de mostrar anuncios', () async {
    final previous = RemoveAds.instance;
    addTearDown(() => RemoveAds.instance = previous);
    RemoveAds.instance = ads;
    AdsConsent.canRequestAds.value = true;
    AdsGate.init();
    expect(AdsGate.showAds.value, isTrue);

    await ads.handlePurchases([_purchase(PurchaseStatus.purchased)]);
    expect(AdsGate.showAds.value, isFalse);
    expect(AdsGate.adsRemoved, isTrue);
  });

  testWidgets('tarjeta de Ajustes: precio, comprar y estado "sin anuncios"', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: RemoveAdsCard(controller: ads)))));
    expect(find.text('Quitar anuncios'), findsOneWidget);
    expect(find.text('Comprar por COP 9.900'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Comprar por COP 9.900'));
    await tester.pump();
    expect(store.buys, 1);

    await tester.runAsync(() => ads.handlePurchases([_purchase(PurchaseStatus.purchased)]));
    await tester.pump();
    expect(find.text('Sin anuncios'), findsOneWidget);
    expect(find.textContaining('Gracias'), findsOneWidget);
  });
}
